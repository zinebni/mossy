import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mossy/features/adventures/presentation/adventures_screen.dart';
import 'package:mossy/features/auth/presentation/auth_screen.dart';
import 'package:mossy/features/collection/presentation/collection_screen.dart';
import 'package:mossy/features/explore/presentation/explore_screen.dart';
import 'package:mossy/features/garden/presentation/garden_screen.dart';
import 'package:mossy/features/home/presentation/home_screen.dart';
import 'package:mossy/features/profile/presentation/profile_screen.dart';
import 'package:mossy/features/settings/presentation/settings_screen.dart';
import 'package:mossy/services/supabase_service.dart';
import 'package:mossy/shared/providers/app_providers.dart';
import 'package:mossy/shared/providers/auth_provider.dart';

/// Transparent 1x1 PNG image bytes for mock HTTP responses during image widget testing.
final List<int> _mockPngBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
];

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _mockPngBytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_mockPngBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Helper to wrap screens with a GoRouter for navigation support in tests
Widget _wrapWithRouter(Widget child) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => child),
        GoRoute(path: '/auth', builder: (_, __) => const Scaffold(body: Text('Auth Screen'))),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('Home Screen'))),
        GoRoute(path: '/map', builder: (_, __) => const Scaffold(body: Text('Map Screen'))),
        GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('Settings Screen'))),
      ],
    ),
  );
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('1. AuthNotifier & State Persistence Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes in demo mode with demo user when no session is persisted', () async {
      final notifier = AuthNotifier(SupabaseService.instance);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.username, equals('Fern Wanderer'));
      expect(notifier.state.isDemoMode, isTrue);
    });

    test('Validates email and password length on signup', () async {
      final notifier = AuthNotifier(SupabaseService.instance);

      final invalidEmailRes = await notifier.signUpWithEmail('invalid-email', 'password123');
      expect(invalidEmailRes, isFalse);
      expect(notifier.state.errorMessage, contains('valid email'));

      final shortPassRes = await notifier.signUpWithEmail('valid@mossy.test', '123');
      expect(shortPassRes, isFalse);
      expect(notifier.state.errorMessage, contains('at least 6 characters'));
    });

    test('Simulates creating a brand-new user account and persists active session', () async {
      final notifier = AuthNotifier(SupabaseService.instance);

      const email = 'flora.explorer@mossy.test';
      const password = 'Password123!';
      const username = 'FloraExplorer';

      final success = await notifier.signUpWithEmail(email, password, username: username);
      expect(success, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.username, equals(username));
      expect(notifier.state.user?.explorerLevel, equals(1));
      expect(notifier.state.user?.totalPoints, equals(0));

      // Verify account and session were written to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final usersStore = jsonDecode(prefs.getString('mossy_registered_users_store') ?? '{}');
      expect(usersStore.containsKey(email), isTrue);
      expect(usersStore[email]['password'], equals(password));

      final sessionProfile = jsonDecode(prefs.getString('mossy_active_session_profile') ?? '{}');
      expect(sessionProfile['username'], equals(username));
    });

    test('Simulates logging out and clearing active session', () async {
      final notifier = AuthNotifier(SupabaseService.instance);

      // Sign up a user first
      await notifier.signUpWithEmail('test@mossy.test', 'Password123!', username: 'TestUser');
      expect(notifier.state.isAuthenticated, isTrue);

      // Sign out
      await notifier.signOut();
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.user, isNull);

      // Verify active session was cleared from storage
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('mossy_active_session_profile'), isFalse);
    });

    test('Rejects sign in with wrong password', () async {
      final notifier = AuthNotifier(SupabaseService.instance);

      await notifier.signUpWithEmail('flora@mossy.test', 'SecretPass', username: 'Flora');
      await notifier.signOut();

      final loginFail = await notifier.signInWithEmail('flora@mossy.test', 'WrongPassword');
      expect(loginFail, isFalse);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.errorMessage, contains('Incorrect password'));
    });

    test('Simulates logging into the newly created account with correct credentials', () async {
      final notifier = AuthNotifier(SupabaseService.instance);

      const email = 'flora.login@mossy.test';
      const password = 'GreenPass#2026';
      const username = 'GreenThumbFlora';

      // 1. Create account
      await notifier.signUpWithEmail(email, password, username: username);
      // 2. Sign out
      await notifier.signOut();
      expect(notifier.state.isAuthenticated, isFalse);

      // 3. Sign back in
      final loginSuccess = await notifier.signInWithEmail(email, password);
      expect(loginSuccess, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.username, equals(username));

      // Verify session restored in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final sessionProfile = jsonDecode(prefs.getString('mossy_active_session_profile') ?? '{}');
      expect(sessionProfile['username'], equals(username));
    });

    test('Restores active session on app boot from SharedPreferences', () async {
      final initialNotifier = AuthNotifier(SupabaseService.instance);
      await initialNotifier.signUpWithEmail('persisted@mossy.test', 'Persist123', username: 'PersistentHero');

      // Now create a fresh notifier instance to simulate app restart
      final rebootNotifier = AuthNotifier(SupabaseService.instance);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(rebootNotifier.state.isAuthenticated, isTrue);
      expect(rebootNotifier.state.user?.username, equals('PersistentHero'));
    });

    test('Password reset simulation sends reset link to user email', () async {
      final notifier = AuthNotifier(SupabaseService.instance);
      final resetSuccess = await notifier.resetPassword('flora@mossy.test');
      expect(resetSuccess, isTrue);
      expect(notifier.state.successMessage, contains('flora@mossy.test'));
    });

    test('Guest mode enters as Guest Explorer', () async {
      final notifier = AuthNotifier(SupabaseService.instance);
      await notifier.continueAsGuest();
      expect(notifier.state.isGuest, isTrue);
      expect(notifier.state.user?.username, equals('Guest Explorer'));
    });
  });

  group('2. Auth UI Screen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('AuthScreen renders Sign In form by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithRouter(const AuthScreen(animateMascot: false)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Mossy Nature Journal'), findsOneWidget);
      expect(find.byKey(const Key('auth_tab_sign_in')), findsOneWidget);
      expect(find.byKey(const Key('auth_tab_sign_up')), findsOneWidget);
      expect(find.byKey(const Key('auth_email_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_password_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_signin_button')), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Switching to Create Account tab displays signup fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithRouter(const AuthScreen(animateMascot: false)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on Create Account tab
      await tester.tap(find.byKey(const Key('auth_tab_sign_up')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('auth_username_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_signup_email_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_signup_password_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_signup_button')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Submitting empty Sign In form triggers validation errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithRouter(const AuthScreen(animateMascot: false)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap signin button without typing
      await tester.tap(find.byKey(const Key('auth_signin_button')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Forgot password dialog opens and sends link', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithRouter(const AuthScreen(animateMascot: false)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Forgot Password
      await tester.tap(find.byKey(const Key('auth_forgot_password_button')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byKey(const Key('auth_reset_email_field')), findsOneWidget);

      // Enter email in dialog
      await tester.enterText(find.byKey(const Key('auth_reset_email_field')), 'reset@mossy.test');
      await tester.tap(find.byKey(const Key('auth_send_reset_button')));
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog closed
      expect(find.text('Reset Password'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('3. Project-wide Authenticated Session Diagnostic Check', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();

      // Create and authenticate brand new user
      await container.read(authProvider.notifier).signUpWithEmail(
            'endtoend@mossy.test',
            'SecurePass123',
            username: 'EndToEndBotanist',
          );
      await container.read(userProfileProvider.notifier).loadProfile();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('HomeScreen loads successfully under authenticated user session', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const HomeScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('EndToEndBotanist'), findsOneWidget);
      expect(find.text('Ready to explore?'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ExploreScreen loads successfully under authenticated session', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const ExploreScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.text('Take a Photo'), findsOneWidget);
      expect(find.text('From Gallery'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('CollectionScreen loads successfully under authenticated session', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const CollectionScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CollectionScreen), findsOneWidget);
      expect(find.text('My Collection'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('AdventuresScreen loads successfully under authenticated session', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const AdventuresScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdventuresScreen), findsOneWidget);
      expect(find.text('Adventures'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('GardenScreen loads successfully under authenticated session', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const GardenScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GardenScreen), findsOneWidget);
      expect(find.text('Your Garden'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ProfileScreen loads and displays authenticated user details', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const ProfileScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('EndToEndBotanist'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SettingsScreen loads with authenticated user account options', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const SettingsScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Switch Account'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
