import 'package:flutter/foundation.dart';
import '../shared/models/discovery.dart';
import '../shared/models/mission.dart';
import '../shared/models/user_mission.dart';
import 'supabase_service.dart';

/// Abstract interface for nature challenges and exploration adventures.
abstract class MissionService {
  Future<List<Mission>> getAvailableMissions();
  Future<List<UserMission>> getUserMissions(String userId);
  Future<UserMission> startMission(String userId, String missionId);
  Future<UserMission> updateMissionProgress(String userMissionId, UserMissionStatus status);
  Future<UserMission> completeMission(String userMissionId, {Map<String, dynamic>? verificationData});
  Future<UserMission?> verifyMissionWithDiscovery(String userId, String missionId, Discovery discovery);
}

/// Realistic demo implementation with 10 engaging nature adventures.
class DemoMissionService implements MissionService {
  static final List<Mission> _sampleMissions = [
    const Mission(
      id: 'mission-001',
      title: 'Find a Golden Yellow Flower',
      description: 'Search sunny lawn edges, meadows, or gardens for bright yellow petals like Dandelions or Buttercups.',
      category: MissionCategory.daily,
      difficulty: MissionDifficulty.easy,
      rewardPoints: 60,
      verificationCriteria: {'flower_color': 'yellow', 'target_family': 'Asteraceae'},
    ),
    const Mission(
      id: 'mission-002',
      title: 'Nature\'s Geometry: 5-Petaled Bloom',
      description: 'Observe flower anatomy and find a wild flower displaying five distinct symmetrical petals.',
      category: MissionCategory.daily,
      difficulty: MissionDifficulty.medium,
      rewardPoints: 80,
      verificationCriteria: {'petal_count': 5},
    ),
    const Mission(
      id: 'mission-003',
      title: 'The Ivy Wall Detective',
      description: 'Find evergreen climbing Ivy (Hedera helix) gripping an old wall or tree trunk.',
      category: MissionCategory.daily,
      difficulty: MissionDifficulty.easy,
      rewardPoints: 50,
      verificationCriteria: {'scientific_name': 'Hedera helix'},
    ),
    const Mission(
      id: 'mission-004',
      title: 'Botanical Diversity Trio',
      description: 'Discover and document plants belonging to three distinct botanical families.',
      category: MissionCategory.general,
      difficulty: MissionDifficulty.medium,
      rewardPoints: 120,
      verificationCriteria: {'distinct_families_count': 3},
    ),
    const Mission(
      id: 'mission-005',
      title: 'Lavender & Purple Hues',
      description: 'Spot a flower boasting purple, violet, or lavender tones blooming in the wild or garden.',
      category: MissionCategory.general,
      difficulty: MissionDifficulty.medium,
      rewardPoints: 75,
      verificationCriteria: {'color': 'purple'},
    ),
    const Mission(
      id: 'mission-006',
      title: 'Aromatic Herb Quest',
      description: 'Find an aromatic plant from the mint family (Lamiaceae), such as Lavender, Sage, or Mint.',
      category: MissionCategory.general,
      difficulty: MissionDifficulty.medium,
      rewardPoints: 90,
      verificationCriteria: {'family': 'Lamiaceae'},
    ),
    const Mission(
      id: 'mission-007',
      title: 'Hedgerow Wild Rose Hunter',
      description: 'Identify a wild thorny shrub from the Rosaceae family such as the fragrant Dog Rose.',
      category: MissionCategory.general,
      difficulty: MissionDifficulty.hard,
      rewardPoints: 150,
      verificationCriteria: {'family': 'Rosaceae'},
    ),
    const Mission(
      id: 'mission-008',
      title: 'Four-Leaf Clover Hope',
      description: 'Inspect a lush patch of White Clover (Trifolium repens) and observe its delicate leaflets.',
      category: MissionCategory.general,
      difficulty: MissionDifficulty.easy,
      rewardPoints: 50,
      verificationCriteria: {'scientific_name': 'Trifolium repens'},
    ),
    const Mission(
      id: 'mission-009',
      title: 'Ancient Forest Monarch',
      description: 'Identify a majestic mature woodland tree and examine its bark patterns and leaf veins.',
      category: MissionCategory.special,
      difficulty: MissionDifficulty.hard,
      rewardPoints: 200,
      verificationCriteria: {'growth_form': 'tree'},
    ),
    const Mission(
      id: 'mission-010',
      title: 'Asteraceae Grand Tour',
      description: 'Identify 3 distinct species from the Asteraceae (composite flower) family.',
      category: MissionCategory.special,
      difficulty: MissionDifficulty.hard,
      rewardPoints: 250,
      verificationCriteria: {'family': 'Asteraceae', 'required_count': 3},
    ),
  ];

  late final List<UserMission> _userMissions;

  DemoMissionService() {
    _initUserMissions();
  }

  void _initUserMissions() {
    _userMissions = [
      UserMission(
        id: 'um-001',
        userId: 'demo-user',
        missionId: 'mission-001',
        mission: _sampleMissions[0],
        status: UserMissionStatus.completed,
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
        verificationResult: {
          'verified': true,
          'matched_species': 'Taraxacum officinale',
        },
      ),
      UserMission(
        id: 'um-002',
        userId: 'demo-user',
        missionId: 'mission-002',
        mission: _sampleMissions[1],
        status: UserMissionStatus.inProgress,
      ),
      UserMission(
        id: 'um-003',
        userId: 'demo-user',
        missionId: 'mission-003',
        mission: _sampleMissions[2],
        status: UserMissionStatus.completed,
        completedAt: DateTime.now().subtract(const Duration(days: 7)),
        verificationResult: {
          'verified': true,
          'matched_species': 'Hedera helix',
        },
      ),
      UserMission(
        id: 'um-004',
        userId: 'demo-user',
        missionId: 'mission-004',
        mission: _sampleMissions[3],
        status: UserMissionStatus.inProgress,
      ),
      UserMission(
        id: 'um-005',
        userId: 'demo-user',
        missionId: 'mission-005',
        mission: _sampleMissions[4],
        status: UserMissionStatus.available,
      ),
      UserMission(
        id: 'um-006',
        userId: 'demo-user',
        missionId: 'mission-006',
        mission: _sampleMissions[5],
        status: UserMissionStatus.completed,
        completedAt: DateTime.now().subtract(const Duration(days: 5)),
        verificationResult: {
          'verified': true,
          'matched_species': 'Lavandula angustifolia',
        },
      ),
      UserMission(
        id: 'um-007',
        userId: 'demo-user',
        missionId: 'mission-007',
        mission: _sampleMissions[6],
        status: UserMissionStatus.available,
      ),
      UserMission(
        id: 'um-008',
        userId: 'demo-user',
        missionId: 'mission-008',
        mission: _sampleMissions[7],
        status: UserMissionStatus.available,
      ),
      UserMission(
        id: 'um-009',
        userId: 'demo-user',
        missionId: 'mission-009',
        mission: _sampleMissions[8],
        status: UserMissionStatus.available,
      ),
      UserMission(
        id: 'um-010',
        userId: 'demo-user',
        missionId: 'mission-010',
        mission: _sampleMissions[9],
        status: UserMissionStatus.available,
      ),
    ];
  }

  @override
  Future<List<Mission>> getAvailableMissions() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_sampleMissions);
  }

  @override
  Future<List<UserMission>> getUserMissions(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(_userMissions);
  }

  @override
  Future<UserMission> startMission(String userId, String missionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _userMissions.indexWhere((um) => um.missionId == missionId);
    final mission = _sampleMissions.firstWhere((m) => m.id == missionId);

    if (index >= 0) {
      final updated = _userMissions[index].copyWith(
        status: UserMissionStatus.inProgress,
        mission: mission,
      );
      _userMissions[index] = updated;
      return updated;
    } else {
      final newUm = UserMission(
        id: 'um-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        missionId: missionId,
        mission: mission,
        status: UserMissionStatus.inProgress,
      );
      _userMissions.add(newUm);
      return newUm;
    }
  }

  @override
  Future<UserMission> updateMissionProgress(
    String userMissionId,
    UserMissionStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _userMissions.indexWhere((um) => um.id == userMissionId);
    if (index < 0) {
      throw Exception('User mission not found: $userMissionId');
    }
    final updated = _userMissions[index].copyWith(
      status: status,
      completedAt: status == UserMissionStatus.completed ? DateTime.now() : null,
    );
    _userMissions[index] = updated;
    return updated;
  }

  @override
  Future<UserMission> completeMission(
    String userMissionId, {
    Map<String, dynamic>? verificationData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final index = _userMissions.indexWhere((um) => um.id == userMissionId);
    if (index < 0) {
      throw Exception('User mission not found: $userMissionId');
    }
    final updated = _userMissions[index].copyWith(
      status: UserMissionStatus.completed,
      completedAt: DateTime.now(),
      verificationResult: verificationData ?? {'verified': true},
    );
    _userMissions[index] = updated;
    return updated;
  }

  @override
  Future<UserMission?> verifyMissionWithDiscovery(
    String userId,
    String missionId,
    Discovery discovery,
  ) async {
    final mission = _sampleMissions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => _sampleMissions.first,
    );

    bool matches = false;
    final criteria = mission.verificationCriteria;

    if (criteria.containsKey('scientific_name')) {
      matches = discovery.scientificName.toLowerCase() ==
          criteria['scientific_name'].toString().toLowerCase();
    } else if (criteria.containsKey('family')) {
      matches = discovery.family.toLowerCase() ==
          criteria['family'].toString().toLowerCase();
    } else if (criteria.containsKey('target_family')) {
      matches = discovery.family.toLowerCase() ==
          criteria['target_family'].toString().toLowerCase();
    } else {
      // Default to matching if discovery is verified
      matches = discovery.identificationScore >= 0.7;
    }

    if (matches) {
      final userMissions = await getUserMissions(userId);
      final existing = userMissions.firstWhere(
        (um) => um.missionId == missionId,
        orElse: () => UserMission(
          id: 'um-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          missionId: missionId,
          mission: mission,
        ),
      );

      return completeMission(
        existing.id,
        verificationData: {
          'verified': true,
          'matched_species': discovery.scientificName,
          'discovery_id': discovery.id,
        },
      );
    }

    return null;
  }
}

/// Supabase backed implementation of [MissionService].
class SupabaseMissionService implements MissionService {
  final SupabaseService _supabaseService;
  final DemoMissionService _demoFallback = DemoMissionService();

  SupabaseMissionService(this._supabaseService);

  @override
  Future<List<Mission>> getAvailableMissions() async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return _demoFallback.getAvailableMissions();
    }

    try {
      final response = await _supabaseService
          .from('missions')!
          .select()
          .eq('is_active', true);

      final list = (response as List<dynamic>)
          .map((e) => Mission.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('[Mossy] Supabase getAvailableMissions failed: $e. Falling back to demo.');
      return _demoFallback.getAvailableMissions();
    }
  }

  @override
  Future<List<UserMission>> getUserMissions(String userId) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return _demoFallback.getUserMissions(userId);
    }

    try {
      final response = await _supabaseService
          .from('user_missions')!
          .select('*, mission:missions(*)')
          .eq('user_id', userId);

      final list = (response as List<dynamic>)
          .map((e) => UserMission.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('[Mossy] Supabase getUserMissions failed: $e. Falling back to demo.');
      return _demoFallback.getUserMissions(userId);
    }
  }

  @override
  Future<UserMission> startMission(String userId, String missionId) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return _demoFallback.startMission(userId, missionId);
    }

    try {
      final response = await _supabaseService
          .from('user_missions')!
          .upsert({
            'user_id': userId,
            'mission_id': missionId,
            'status': UserMissionStatus.inProgress.value,
          })
          .select('*, mission:missions(*)')
          .single();

      return UserMission.fromJson(response);
    } catch (e) {
      debugPrint('[Mossy] Supabase startMission failed: $e. Falling back to demo.');
      return _demoFallback.startMission(userId, missionId);
    }
  }

  @override
  Future<UserMission> updateMissionProgress(
    String userMissionId,
    UserMissionStatus status,
  ) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return _demoFallback.updateMissionProgress(userMissionId, status);
    }

    try {
      final response = await _supabaseService
          .from('user_missions')!
          .update({
            'status': status.value,
            'completed_at': status == UserMissionStatus.completed ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', userMissionId)
          .select('*, mission:missions(*)')
          .single();

      return UserMission.fromJson(response);
    } catch (e) {
      debugPrint('[Mossy] Supabase updateMissionProgress failed: $e. Falling back to demo.');
      return _demoFallback.updateMissionProgress(userMissionId, status);
    }
  }

  @override
  Future<UserMission> completeMission(
    String userMissionId, {
    Map<String, dynamic>? verificationData,
  }) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return _demoFallback.completeMission(userMissionId, verificationData: verificationData);
    }

    try {
      final response = await _supabaseService
          .from('user_missions')!
          .update({
            'status': UserMissionStatus.completed.value,
            'completed_at': DateTime.now().toIso8601String(),
            'verification_result': verificationData ?? {'verified': true},
          })
          .eq('id', userMissionId)
          .select('*, mission:missions(*)')
          .single();

      return UserMission.fromJson(response);
    } catch (e) {
      debugPrint('[Mossy] Supabase completeMission failed: $e. Falling back to demo.');
      return _demoFallback.completeMission(userMissionId, verificationData: verificationData);
    }
  }

  @override
  Future<UserMission?> verifyMissionWithDiscovery(
    String userId,
    String missionId,
    Discovery discovery,
  ) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return _demoFallback.verifyMissionWithDiscovery(userId, missionId, discovery);
    }

    try {
      final response = await _supabaseService.invokeFunction(
        'verify-mission',
        body: {
          'user_id': userId,
          'mission_id': missionId,
          'discovery_id': discovery.id,
          'scientific_name': discovery.scientificName,
          'family': discovery.family,
        },
      );

      if (response != null && response['verified'] == true) {
        final umData = response['user_mission'] as Map<String, dynamic>?;
        if (umData != null) {
          return UserMission.fromJson(umData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Mossy] Supabase verifyMissionWithDiscovery failed: $e. Falling back to demo.');
      return _demoFallback.verifyMissionWithDiscovery(userId, missionId, discovery);
    }
  }
}
