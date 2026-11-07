import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../services/supabase_service.dart';
import '../models/user_profile.dart';

/// Represents the current authentication state of the application.
class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final bool isDemoMode;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isDemoMode = true,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    bool? isDemoMode,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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

  static final UserProfile demoUser = UserProfile(
    id: 'demo-user',
    username: 'Fern Wanderer',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
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
      state = state.copyWith(user: demoUser, isDemoMode: true);
      return;
    }

    final client = _supabaseService.client;
    if (client == null) {
      state = state.copyWith(user: demoUser, isDemoMode: true);
      return;
    }

    // Listen to real Supabase auth state transitions
    _authSubscription = client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _loadUserProfile(session.user.id);
      } else {
        state = state.copyWith(clearUser: true, isDemoMode: false);
      }
    });

    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser.id);
    } else {
      state = state.copyWith(clearUser: true, isDemoMode: false);
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

  /// Sign in with email and password via Supabase.
  Future<bool> signInWithEmail(String email, String password) async {
    if (_supabaseService.isDemoMode) {
      state = state.copyWith(user: demoUser, isDemoMode: true);
      return true;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _supabaseService.auth?.signInWithPassword(
        email: email,
        password: password,
      );
      if (response?.user != null) {
        await _loadUserProfile(response!.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign up with email and password.
  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? username,
  }) async {
    if (_supabaseService.isDemoMode) {
      state = state.copyWith(user: demoUser, isDemoMode: true);
      return true;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _supabaseService.auth?.signUp(
        email: email,
        password: password,
        data: {'username': username ?? email.split('@').first},
      );
      if (response?.user != null) {
        await _loadUserProfile(response!.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign out and return to demo or unauthenticated state.
  Future<void> signOut() async {
    try {
      if (!_supabaseService.isDemoMode) {
        await _supabaseService.auth?.signOut();
      }
    } catch (e) {
      debugPrint('[Mossy] Sign out error: $e');
    } finally {
      state = const AuthState(user: null, isLoading: false, isDemoMode: false);
    }
  }

  /// Switch to demo guest mode.
  void enterDemoMode() {
    state = state.copyWith(
      user: demoUser,
      isDemoMode: true,
      clearError: true,
      isLoading: false,
    );
  }

  /// Update user profile details.
  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    if (state.user == null) return;

    final updated = state.user!.copyWith(
      username: username,
      avatarUrl: avatarUrl,
    );

    state = state.copyWith(user: updated);

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
