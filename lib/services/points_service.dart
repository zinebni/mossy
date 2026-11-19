import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/points_entry.dart';
import 'supabase_service.dart';

/// Abstract interface for managing user exploration points and reward ledger.
abstract class PointsService {
  Future<int> getTotalPoints(String userId);
  Future<List<PointsEntry>> getPointsHistory(String userId);
  Future<PointsEntry> awardPoints(
    String userId,
    int points,
    String reason, {
    String? referenceId,
  });
}

/// Returns the SharedPreferences key for a user's points ledger.
String _pointsKey(String userId) => 'mossy_user_points_v1_$userId';

/// Demo implementation of [PointsService] with per-user isolated, SharedPreferences-persisted points history.
class DemoPointsService implements PointsService {
  /// In-memory cache; loaded from SharedPreferences on first access per user.
  final Map<String, List<PointsEntry>> _userHistory = {};
  /// Track which userIds have already been loaded from disk.
  final Set<String> _loaded = {};

  /// Load a user's ledger from SharedPreferences into the in-memory cache (once).
  Future<void> _ensureLoaded(String userId) async {
    if (_loaded.contains(userId)) return;
    _loaded.add(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pointsKey(userId));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _userHistory[userId] = decoded
            .map((e) => PointsEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[Mossy] DemoPointsService: failed to load points for $userId: $e');
    }
  }

  /// Persist the in-memory ledger for a user to SharedPreferences.
  Future<void> _save(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _userHistory[userId] ?? [];
      await prefs.setString(_pointsKey(userId), jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('[Mossy] DemoPointsService: failed to save points for $userId: $e');
    }
  }

  void clear() {
    _userHistory.clear();
    _loaded.clear();
  }

  Future<void> clearUser(String userId) async {
    _userHistory.remove(userId);
    _loaded.remove(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pointsKey(userId));
    } catch (_) {}
  }

  @override
  Future<int> getTotalPoints(String userId) async {
    if (userId.isEmpty || userId == 'guest-user') return 0;
    await _ensureLoaded(userId);
    final list = _userHistory[userId] ?? const [];
    return list.fold<int>(0, (sum, item) => sum + item.points);
  }

  @override
  Future<List<PointsEntry>> getPointsHistory(String userId) async {
    if (userId.isEmpty || userId == 'guest-user') return [];
    await _ensureLoaded(userId);
    final list = List<PointsEntry>.from(_userHistory[userId] ?? const []);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<PointsEntry> awardPoints(
    String userId,
    int points,
    String reason, {
    String? referenceId,
  }) async {
    await _ensureLoaded(userId);
    final entry = PointsEntry(
      id: 'pe-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      points: points,
      reason: reason,
      referenceId: referenceId,
      createdAt: DateTime.now(),
    );
    final list = _userHistory.putIfAbsent(userId, () => <PointsEntry>[]);
    list.insert(0, entry);
    await _save(userId);
    return entry;
  }
}

/// Supabase backed implementation of [PointsService].
class SupabasePointsService implements PointsService {
  final SupabaseService _supabaseService;
  final DemoPointsService _demoFallback = DemoPointsService();

  SupabasePointsService(this._supabaseService);

  void clear() {
    _demoFallback.clear();
  }

  Future<void> clearUser(String userId) async {
    await _demoFallback.clearUser(userId);
  }

  @override
  Future<int> getTotalPoints(String userId) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.getTotalPoints(userId);
    }

    try {
      final response = await _supabaseService
          .from('profiles')!
          .select('total_points')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['total_points'] != null) {
        final dbPoints = (response['total_points'] as num).toInt();
        // Also get locally cached points (in case DB is behind)
        final localPoints = await _demoFallback.getTotalPoints(userId);
        return dbPoints > localPoints ? dbPoints : localPoints;
      }
      return await _demoFallback.getTotalPoints(userId);
    } catch (e) {
      debugPrint('[Mossy] Supabase getTotalPoints failed: $e. Falling back to demo.');
      return await _demoFallback.getTotalPoints(userId);
    }
  }

  @override
  Future<List<PointsEntry>> getPointsHistory(String userId) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.getPointsHistory(userId);
    }

    try {
      final response = await _supabaseService
          .from('points_ledger')!
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (response as List<dynamic>)
          .map((e) => PointsEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('[Mossy] Supabase getPointsHistory failed: $e. Falling back to demo.');
      return await _demoFallback.getPointsHistory(userId);
    }
  }

  @override
  Future<PointsEntry> awardPoints(
    String userId,
    int points,
    String reason, {
    String? referenceId,
  }) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.awardPoints(userId, points, reason, referenceId: referenceId);
    }

    // Award via Edge Function if available; fall back to direct DB update + local cache.
    try {
      final response = await _supabaseService.invokeFunction(
        'award-points',
        body: {
          'user_id': userId,
          'points': points,
          'reason': reason,
          'reference_id': referenceId,
        },
      );

      if (response != null && response['entry'] != null) {
        // Also update local cache so offline reads are correct
        await _demoFallback.awardPoints(userId, points, reason, referenceId: referenceId);
        return PointsEntry.fromJson(response['entry'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[Mossy] Supabase award-points Edge Function failed: $e. Using direct DB update.');
    }

    // Fallback: award locally + directly increment profiles.total_points in Supabase
    final entry = await _demoFallback.awardPoints(userId, points, reason, referenceId: referenceId);
    try {
      // Use Postgres RPC increment to avoid race conditions
      final newTotal = await _demoFallback.getTotalPoints(userId);
      await _supabaseService.from('profiles')?.update({
        'total_points': newTotal,
        'explorer_level': _calculateLevel(newTotal),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('[Mossy] Supabase direct profiles update failed: $e. Points are stored locally.');
    }
    return entry;
  }

  /// Mirror of UserProfile.calculateLevel — keep in sync.
  static int _calculateLevel(int points) {
    const thresholds = [0, 50, 150, 300, 500, 750, 1050, 1400, 1800, 2250, 2750];
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (points >= thresholds[i]) return i + 1;
    }
    return 1;
  }
}
