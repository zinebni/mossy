import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../services/discovery_service.dart';
import '../../services/garden_service.dart';
import '../../services/points_service.dart';
import '../../services/quest_service.dart';
import '../../services/supabase_service.dart';
import '../models/user_profile.dart';

/// Represents the current authentication state of the application.
class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final bool isDemoMode;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isDemoMode = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isAuthenticated => user != null;
  bool get isGuest => false; // Guest mode completely removed per strict authentication policy

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    bool? isDemoMode,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  String toString() =>
      'AuthState(user: ${user?.username}, isDemo: $isDemoMode, loading: $isLoading, error: $errorMessage)';
}

/// State notifier managing authentication, user profiles, and session changes.
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;
  StreamSubscription<supa.AuthState>? _authSubscription;
  bool _userActionOccurred = false;

  /// External callback to purge all user data, database records, and in-memory caches on sign out
  Future<void> Function(String? userId)? onPurgeUserData;

  static const String _sessionKey = 'mossy_active_session_profile';
  static const String _usersStoreKey = 'mossy_registered_users_store';
  static const String _loggedOutKey = 'mossy_explicitly_logged_out';

  AuthNotifier(this._supabaseService)
      : super(const AuthState(
          user: null,
          isDemoMode: false,
        )) {
    _init();
  }

  Future<void> _init() async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      await _restorePersistedSession();
      return;
    }

    final client = _supabaseService.client;
    if (client == null) {
      await _restorePersistedSession();
      return;
    }

    // Listen to real Supabase auth state transitions
    _authSubscription = client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _loadUserProfile(session.user.id);
      } else {
        await _clearPersistedSession();
        if (mounted) {
          state = state.copyWith(clearUser: true, isDemoMode: false);
        }
      }
    });

    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser.id);
    } else {
      await _clearPersistedSession();
      if (!_userActionOccurred && mounted) {
        state = state.copyWith(clearUser: true, isDemoMode: false);
      }
    }
  }

  /// Restores active session from local storage.
  Future<void> _restorePersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userActionOccurred) return;

      final isLoggedOut = prefs.getBool(_loggedOutKey) ?? false;
      if (isLoggedOut) {
        if (!_userActionOccurred && mounted) {
          state = state.copyWith(clearUser: true, isDemoMode: false);
        }
        return;
      }

      final sessionJson = prefs.getString(_sessionKey);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(sessionJson);
        final profile = UserProfile.fromJson(data);
        // Strictly filter out any legacy guest or demo users
        if (profile.id == 'guest-user' || profile.id == 'demo-user') {
          await _clearPersistedSession();
          if (!_userActionOccurred && mounted) {
            state = state.copyWith(clearUser: true, isDemoMode: false);
          }
          return;
        }

        if (!_userActionOccurred && mounted) {
          state = state.copyWith(user: profile, isDemoMode: false);
        }
        return;
      }
    } catch (e) {
      debugPrint('[Mossy] Error restoring session: $e');
    }

    // Default to unauthenticated when no valid session is saved
    if (!_userActionOccurred && mounted) {
      state = state.copyWith(clearUser: true, isDemoMode: false);
    }
  }

  /// Persists the active session profile into local storage.
  Future<void> _persistSession(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loggedOutKey);
      await prefs.setString(_sessionKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('[Mossy] Error persisting session: $e');
    }
  }

  /// Clears persisted session from local storage.
  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.setBool(_loggedOutKey, true);
    } catch (e) {
      debugPrint('[Mossy] Error clearing persisted session: $e');
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Read the locally persisted session first so we can protect accumulated points.
      int localPoints = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        final sessionJson = prefs.getString(_sessionKey);
        if (sessionJson != null && sessionJson.isNotEmpty) {
          final Map<String, dynamic> sessionData = jsonDecode(sessionJson);
          if (sessionData['id'] == userId) {
            localPoints = (sessionData['total_points'] as int?) ?? 0;
          }
        }
      } catch (_) {}

      final response = await _supabaseService
          .from('profiles')
          ?.select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final dbProfile = UserProfile.fromJson(response);
        // Use the MAXIMUM of DB points and locally stored points to prevent reset.
        final mergedPoints = dbProfile.totalPoints > localPoints ? dbProfile.totalPoints : localPoints;
        final profile = dbProfile.copyWith(
          totalPoints: mergedPoints,
          explorerLevel: UserProfile.calculateLevel(mergedPoints),
        );
        await _persistSession(profile);
        if (mounted) {
          state = state.copyWith(user: profile, isLoading: false, isDemoMode: false);
        }
        // If local points are ahead of DB, sync them back to Supabase.
        if (localPoints > dbProfile.totalPoints) {
          _supabaseService.from('profiles')?.update({
            'total_points': mergedPoints,
            'explorer_level': UserProfile.calculateLevel(mergedPoints),
          }).eq('id', userId).then((_) {}).catchError((e) {
            debugPrint('[Mossy] Failed to sync local points to Supabase: $e');
          });
        }
      } else {
        // No DB row yet — create a base profile, preserving any locally accumulated points.
        final newProfile = UserProfile(
          id: userId,
          username: _supabaseService.auth?.currentUser?.email?.split('@').first ?? 'Explorer',
          totalPoints: localPoints,
          explorerLevel: UserProfile.calculateLevel(localPoints),
          createdAt: DateTime.now(),
        );
        await _persistSession(newProfile);
        if (mounted) {
          state = state.copyWith(user: newProfile, isLoading: false, isDemoMode: false);
        }
      }
    } catch (e) {
      debugPrint('[Mossy] Error loading user profile: $e');
      // On network error, restore from persisted session rather than showing 0 XP.
      try {
        final prefs = await SharedPreferences.getInstance();
        final sessionJson = prefs.getString(_sessionKey);
        if (sessionJson != null && sessionJson.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(sessionJson);
          if (data['id'] == userId) {
            final restoredProfile = UserProfile.fromJson(data);
            if (mounted) {
              state = state.copyWith(user: restoredProfile, isLoading: false);
            }
            return;
          }
        }
      } catch (_) {}
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load profile. Using cached data.',
        );
      }
    }
  }

  /// Sign in with email and password via Supabase or local persistent store.
  Future<bool> signInWithEmail(String email, String password) async {
    _userActionOccurred = true;
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      state = state.copyWith(isLoading: false, errorMessage: 'Please enter a valid email address.');
      return false;
    }
    if (cleanPassword.length < 6) {
      state = state.copyWith(isLoading: false, errorMessage: 'Password must be at least 6 characters.');
      return false;
    }

    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 300));
      return await _signInOfflineMode(cleanEmail, cleanPassword);
    }

    try {
      final response = await _supabaseService.auth?.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      if (response?.user != null) {
        await _loadUserProfile(response!.user!.id);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Login failed. Please verify your credentials.');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
      return false;
    }
  }

  /// Sign up with email and password via Supabase or local store.
  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? username,
  }) async {
    _userActionOccurred = true;
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final chosenUsername = (username?.trim().isNotEmpty == true)
        ? username!.trim()
        : cleanEmail.split('@').first;

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      state = state.copyWith(isLoading: false, errorMessage: 'Please enter a valid email address.');
      return false;
    }
    if (cleanPassword.length < 6) {
      state = state.copyWith(isLoading: false, errorMessage: 'Password must be at least 6 characters.');
      return false;
    }

    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 300));
      return await _signUpOfflineMode(cleanEmail, cleanPassword, chosenUsername);
    }

    try {
      final response = await _supabaseService.auth?.signUp(
        email: cleanEmail,
        password: cleanPassword,
        data: {'username': chosenUsername},
      );
      if (response?.user != null) {
        await _loadUserProfile(response!.user!.id);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Signup failed. Please try again.');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
      return false;
    }
  }

  /// Offline sign up implementation that persists user accounts locally when offline.
  Future<bool> _signUpOfflineMode(String email, String password, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeStr = prefs.getString(_usersStoreKey) ?? '{}';
      final Map<String, dynamic> users = jsonDecode(storeStr);

      if (users.containsKey(email)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'An account with this email already exists.',
        );
        return false;
      }

      final userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
      final newProfile = UserProfile(
        id: userId,
        username: username,
        totalPoints: 0,
        explorerLevel: 1,
        createdAt: DateTime.now(),
      );

      users[email] = {
        'id': userId,
        'password': password,
        'profile': newProfile.toJson(),
      };

      await prefs.setString(_usersStoreKey, jsonEncode(users));
      await _persistSession(newProfile);

      state = state.copyWith(
        user: newProfile,
        isLoading: false,
        isDemoMode: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Local signup error: $e');
      return false;
    }
  }

  /// Offline sign in implementation verifying against saved local accounts.
  Future<bool> _signInOfflineMode(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeStr = prefs.getString(_usersStoreKey) ?? '{}';
      final Map<String, dynamic> users = jsonDecode(storeStr);

      if (users.containsKey(email)) {
        final userData = users[email] as Map<String, dynamic>;
        if (userData['password'] == password) {
          final profile = UserProfile.fromJson(userData['profile'] as Map<String, dynamic>);
          await _persistSession(profile);
          state = state.copyWith(user: profile, isLoading: false, isDemoMode: false);
          return true;
        } else {
          state = state.copyWith(isLoading: false, errorMessage: 'Incorrect password.');
          return false;
        }
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Account not found. Please sign up first.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Sign in error: $e');
      return false;
    }
  }

  /// Sends a password reset email via Supabase or local notification.
  Future<bool> resetPassword(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      state = state.copyWith(errorMessage: 'Please enter a valid email address.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent to $cleanEmail',
      );
      return true;
    }

    try {
      await _supabaseService.auth?.resetPasswordForEmail(cleanEmail);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent to $cleanEmail',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
      return false;
    }
  }

  /// Sign out, purge all local state and storage, and return strictly to unauthenticated state.
  Future<void> signOut() async {
    _userActionOccurred = true;
    final exitingUserId = state.user?.id;
    try {
      if (!_supabaseService.isDemoMode && _supabaseService.isInitialized) {
        await _supabaseService.auth?.signOut();
      }
    } catch (e) {
      debugPrint('[Mossy] Sign out error: $e');
    } finally {
      // Execute comprehensive state and storage purge
      if (onPurgeUserData != null) {
        try {
          await onPurgeUserData!(exitingUserId);
        } catch (e) {
          debugPrint('[Mossy] onPurgeUserData error: $e');
        }
      }
      await _clearPersistedSession();
      state = const AuthState(user: null, isLoading: false, isDemoMode: false);
    }
  }

  /// Clear any active error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear any active success message.
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  /// Update user profile details.
  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    if (state.user == null) return;

    final updated = state.user!.copyWith(
      username: username,
      avatarUrl: avatarUrl,
    );

    state = state.copyWith(user: updated);
    await _persistSession(updated);

    if (!_supabaseService.isDemoMode && _supabaseService.isInitialized) {
      try {
        await _supabaseService.from('profiles')?.update({
          if (username != null) 'username': username,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }).eq('id', updated.id);
      } catch (e) {
        debugPrint('[Mossy] Error updating profile: $e');
      }
    }
  }

  /// Increment points locally in user state.
  void addPoints(int points) {
    if (state.user == null) return;
    final newPoints = state.user!.totalPoints + points;
    final updated = state.user!.copyWith(
      totalPoints: newPoints,
      explorerLevel: UserProfile.calculateLevel(newPoints),
    );
    state = state.copyWith(user: updated);
    _persistSession(updated);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Global provider for authentication state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = SupabaseService.instance;
  final notifier = AuthNotifier(supabaseService);
  notifier.onPurgeUserData = (userId) async {
    if (userId != null && userId.isNotEmpty) {
      await LocalDiscoveryStore.clearUser(userId);
      // Clear persisted points ledger for this user
      await DemoPointsService().clearUser(userId);
      // Clear persisted garden state for this user
      await DemoGardenService().clearUser(userId);
    }
    await LocalDiscoveryStore.clearAll();
    await LocalQuestService().clearAll();
  };
  return notifier;
});
