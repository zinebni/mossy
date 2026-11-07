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

/// Demo implementation of [PointsService] with realistic historical transactions.
class DemoPointsService implements PointsService {
  static final List<PointsEntry> _initialHistory = [
    PointsEntry(
      id: 'pe-001',
      userId: 'demo-user',
      points: 50,
      reason: 'First Botanical Discovery bonus: Bellis perennis',
      referenceId: 'disc-001',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    PointsEntry(
      id: 'pe-002',
      userId: 'demo-user',
      points: 50,
      reason: 'Achievement Unlocked: First Discovery',
      referenceId: 'ach-first-discovery',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    PointsEntry(
      id: 'pe-003',
      userId: 'demo-user',
      points: 50,
      reason: 'Discovered Common Ivy in the woodland',
      referenceId: 'disc-005',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    PointsEntry(
      id: 'pe-004',
      userId: 'demo-user',
      points: 50,
      reason: 'Mission Complete: The Ivy Wall Detective',
      referenceId: 'mission-003',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    PointsEntry(
      id: 'pe-005',
      userId: 'demo-user',
      points: 50,
      reason: 'Discovered English Lavender',
      referenceId: 'disc-004',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    PointsEntry(
      id: 'pe-006',
      userId: 'demo-user',
      points: 90,
      reason: 'Mission Complete: Aromatic Herb Quest',
      referenceId: 'mission-006',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    PointsEntry(
      id: 'pe-007',
      userId: 'demo-user',
      points: 50,
      reason: 'Discovered Wild Dog Rose',
      referenceId: 'disc-003',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    PointsEntry(
      id: 'pe-008',
      userId: 'demo-user',
      points: 60,
      reason: 'Mission Complete: Find a Golden Yellow Flower',
      referenceId: 'mission-001',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<PointsEntry> _history = List.from(_initialHistory);

  @override
  Future<int> getTotalPoints(String userId) async {
    await Future.delayed(const Duration(milliseconds: 60));
    return _history
        .where((e) => e.userId == userId || e.userId == 'demo-user')
        .fold<int>(0, (sum, item) => sum + item.points);
  }

  @override
  Future<List<PointsEntry>> getPointsHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _history
        .where((e) => e.userId == userId || e.userId == 'demo-user')
        .toList();
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
    await Future.delayed(const Duration(milliseconds: 100));
    final entry = PointsEntry(
      id: 'pe-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      points: points,
      reason: reason,
      referenceId: referenceId,
      createdAt: DateTime.now(),
    );
    _history.insert(0, entry);
    return entry;
  }
}

/// Supabase backed implementation of [PointsService].
class SupabasePointsService implements PointsService {
  final SupabaseService _supabaseService;
  final DemoPointsService _demoFallback = DemoPointsService();

  SupabasePointsService(this._supabaseService);

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
