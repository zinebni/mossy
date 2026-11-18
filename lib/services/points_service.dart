import 'package:flutter/foundation.dart';
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

/// Demo implementation of [PointsService] with clean, per-user isolated points history.
class DemoPointsService implements PointsService {
  final Map<String, List<PointsEntry>> _userHistory = {};

  void clear() {
    _userHistory.clear();
  }

  void clearUser(String userId) {
    _userHistory.remove(userId);
  }

  @override
  Future<int> getTotalPoints(String userId) async {
    if (userId.isEmpty || userId == 'guest-user') return 0;
    await Future.delayed(const Duration(milliseconds: 30));
    final list = _userHistory[userId] ?? const [];
    return list.fold<int>(0, (sum, item) => sum + item.points);
  }

  @override
  Future<List<PointsEntry>> getPointsHistory(String userId) async {
    if (userId.isEmpty || userId == 'guest-user') return [];
    await Future.delayed(const Duration(milliseconds: 40));
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
    await Future.delayed(const Duration(milliseconds: 40));
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
        return (response['total_points'] as num).toInt();
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
        return PointsEntry.fromJson(response['entry'] as Map<String, dynamic>);
      }
      return await _demoFallback.awardPoints(userId, points, reason, referenceId: referenceId);
    } catch (e) {
      debugPrint('[Mossy] Supabase awardPoints failed: $e. Using demo fallback.');
      return await _demoFallback.awardPoints(userId, points, reason, referenceId: referenceId);
    }
  }
}
