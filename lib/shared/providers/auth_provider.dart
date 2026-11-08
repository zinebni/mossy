import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
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
    this.isDemoMode = true,
    this.errorMessage,
    this.successMessage,
  });

  bool get isAuthenticated => user != null;
  bool get isGuest => user?.id == 'guest-user';

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

/// State notifier managing authentication, demo user profiles, and session changes.
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;
  StreamSubscription<supa.AuthState>? _authSubscription;
  bool _userActionOccurred = false;

  static const String _sessionKey = 'mossy_active_session_profile';
  static const String _usersStoreKey = 'mossy_registered_users_store';
  static const String _loggedOutKey = 'mossy_explicitly_logged_out';

  static final UserProfile demoUser = UserProfile(
    id: 'demo-user',
    username: 'Fern Wanderer',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    totalPoints: 460,
    explorerLevel: 4,
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
  );

  AuthNotifier(this._supabaseService)
      : super(AuthState(
          user: _supabaseService.isDemoMode ? demoUser : null,
          isDemoMode: _supabaseService.isDemoMode,
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
        state = state.copyWith(clearUser: true, isDemoMode: false);
      }
    });

    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser.id);
    } else {
      await _clearPersistedSession();
      state = state.copyWith(clearUser: true, isDemoMode: false);
    }
  }

  /// Restores active session from local storage in demo/offline mode.
  Future<void> _restorePersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userActionOccurred) return;

      final sessionJson = prefs.getString(_sessionKey);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(sessionJson);
        final profile = UserProfile.fromJson(data);
        if (!_userActionOccurred) {
          state = state.copyWith(user: profile, isDemoMode: _supabaseService.isDemoMode);
        }
        return;
      }

      final isLoggedOut = prefs.getBool(_loggedOutKey) ?? false;
      if (isLoggedOut) {
        if (!_userActionOccurred) {
          state = state.copyWith(clearUser: true, isDemoMode: false);
        }
        return;
      }
    } catch (e) {
      debugPrint('[Mossy] Error restoring session: $e');
    }

    // Default to demo user if no explicit session saved and not logged out
    if (!_userActionOccurred) {
      state = state.copyWith(user: demoUser, isDemoMode: true);
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
      final response = await _supabaseService
          .from('profiles')!
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final profile = UserProfile.fromJson(response);
        await _persistSession(profile);
        state = state.copyWith(user: profile, isLoading: false, isDemoMode: false);
      } else {
        // Fallback or create base profile
        final newProfile = UserProfile(
          id: userId,
          username: _supabaseService.auth?.currentUser?.email?.split('@').first ?? 'Explorer',
          totalPoints: 0,
          explorerLevel: 1,
          createdAt: DateTime.now(),
        );
        await _persistSession(newProfile);
        state = state.copyWith(user: newProfile, isLoading: false, isDemoMode: false);
      }
    } catch (e) {
      debugPrint('[Mossy] Error loading user profile: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile. Running in demo mode.',
        user: demoUser,
        isDemoMode: true,
      );
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

    if (_supabaseService.isDemoMode) {
      // Simulate real delay
      await Future.delayed(const Duration(milliseconds: 300));
      return await _signInDemoMode(cleanEmail, cleanPassword);
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

    if (_supabaseService.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return await _signUpDemoMode(cleanEmail, cleanPassword, chosenUsername);
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

  /// Demo / Offline sign up implementation that persists user accounts locally.
  Future<bool> _signUpDemoMode(String email, String password, String username) async {
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
        isDemoMode: true,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Local signup error: $e');
      return false;
    }
  }

  /// Demo / Offline sign in implementation verifying against saved local accounts.
  Future<bool> _signInDemoMode(String email, String password) async {
    try {
      // Allow demo user credentials
      if (email == 'demo@mossy.app' || email == 'fern@mossy.app') {
        await _persistSession(demoUser);
        state = state.copyWith(user: demoUser, isLoading: false, isDemoMode: true);
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final storeStr = prefs.getString(_usersStoreKey) ?? '{}';
      final Map<String, dynamic> users = jsonDecode(storeStr);

      if (users.containsKey(email)) {
        final userData = users[email] as Map<String, dynamic>;
        if (userData['password'] == password) {
          final profile = UserProfile.fromJson(userData['profile'] as Map<String, dynamic>);
          await _persistSession(profile);
          state = state.copyWith(user: profile, isLoading: false, isDemoMode: true);
          return true;
        } else {
          state = state.copyWith(isLoading: false, errorMessage: 'Incorrect password.');
          return false;
        }
      }

      // If user not registered in local store:
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Account not found. Please sign up first or use Demo account.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Sign in error: $e');
      return false;
    }
  }

  /// Sends a password reset email via Supabase or simulated in Demo mode.
  Future<bool> resetPassword(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      state = state.copyWith(errorMessage: 'Please enter a valid email address.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    if (_supabaseService.isDemoMode) {
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

  /// Sign out and return to unauthenticated state.
  Future<void> signOut() async {
    _userActionOccurred = true;
    try {
      if (!_supabaseService.isDemoMode) {
        await _supabaseService.auth?.signOut();
      }
    } catch (e) {
      debugPrint('[Mossy] Sign out error: $e');
    } finally {
      await _clearPersistedSession();
      state = const AuthState(user: null, isLoading: false, isDemoMode: false);
    }
  }

  /// Switch to guest exploration mode.
  Future<void> continueAsGuest() async {
    _userActionOccurred = true;
    final guestProfile = UserProfile(
      id: 'guest-user',
      username: 'Guest Explorer',
      totalPoints: 0,
      explorerLevel: 1,
      createdAt: DateTime.now(),
    );
    await _persistSession(guestProfile);
    state = state.copyWith(
      user: guestProfile,
      isDemoMode: true,
      clearError: true,
      isLoading: false,
    );
  }

  /// Switch to demo user mode.
  Future<void> enterDemoMode() async {
    _userActionOccurred = true;
    await _persistSession(demoUser);
    state = state.copyWith(
      user: demoUser,
      isDemoMode: true,
      clearError: true,
      isLoading: false,
    );
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
        await _supabaseService.from('profiles')!.update({
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
  return AuthNotifier(supabaseService);
});
