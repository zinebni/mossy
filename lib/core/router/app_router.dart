import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../features/adventures/presentation/adventures_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/collection/presentation/collection_screen.dart';
import '../../features/discovery_map/presentation/discovery_map_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/garden/presentation/garden_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splashPath = '/splash';
  static const String onboardingPath = '/onboarding';
  static const String authPath = '/auth';
  static const String homePath = '/home';
  static const String explorePath = '/explore';
  static const String collectionPath = '/collection';
  static const String adventuresPath = '/adventures';
  static const String gardenPath = '/garden';
  static const String profilePath = '/profile';
  static const String settingsPath = '/settings';
  static const String mapPath = '/map';

  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    redirect: (context, state) async {
      final path = state.uri.path;
      final isAuthPath = path == authPath;
      final isOnboardingPath = path == onboardingPath;
      final isSplashPath = path == splashPath;

      final supabaseService = SupabaseService.instance;
      bool hasActiveSession = false;

      if (!supabaseService.isDemoMode && supabaseService.isInitialized) {
        hasActiveSession = supabaseService.auth?.currentUser != null;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final isLoggedOut = prefs.getBool('mossy_explicitly_logged_out') ?? false;
        final sessionJson = prefs.getString('mossy_active_session_profile');
        if (!isLoggedOut && sessionJson != null && sessionJson.isNotEmpty) {
          try {
            final data = jsonDecode(sessionJson) as Map<String, dynamic>;
            final id = data['id'] as String?;
            hasActiveSession = id != null && id.isNotEmpty && id != 'guest-user' && id != 'demo-user';
          } catch (_) {
            hasActiveSession = false;
          }
        }
      }

      // If user is unauthenticated and attempting to access protected screens
      if (!hasActiveSession) {
        if (!isAuthPath && !isOnboardingPath && !isSplashPath) {
          return authPath;
        }
        return null;
      }

      // If user is authenticated and navigating to auth
      if (hasActiveSession && isAuthPath) {
        return homePath;
      }

      return null;
    },
    routes: [
      GoRoute(path: splashPath, builder: (_, __) => const SplashScreen()),
      GoRoute(path: onboardingPath, builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: authPath,
        builder: (_, state) => AuthScreen(
          initialIsSignUp: state.uri.queryParameters['signup'] == 'true',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _MainScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: homePath, builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: explorePath, builder: (_, __) => const ExploreScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: collectionPath, builder: (_, __) => const CollectionScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: adventuresPath, builder: (_, __) => const AdventuresScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: gardenPath, builder: (_, __) => const GardenScreen())]),
        ],
      ),
      GoRoute(path: profilePath, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: settingsPath, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: mapPath, builder: (_, __) => const DiscoveryMapScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}

class _MainScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _MainScaffold({required this.shell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeLabel = l10n?.home ?? 'Home';
    final exploreLabel = l10n?.explore ?? 'Explore';
    final collectionLabel = l10n?.collection ?? 'Collection';
    final adventuresLabel = l10n?.adventures ?? 'Adventures';
    final gardenLabel = l10n?.garden ?? 'Garden';

    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && shell.currentIndex != 0) {
          shell.goBranch(0);
        }
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD9E8CF),
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: homeLabel),
            NavigationDestination(icon: const Icon(Icons.search_outlined), selectedIcon: const Icon(Icons.search_rounded), label: exploreLabel),
            NavigationDestination(icon: const Icon(Icons.collections_bookmark_outlined), selectedIcon: const Icon(Icons.collections_bookmark_rounded), label: collectionLabel),
            NavigationDestination(icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore_rounded), label: adventuresLabel),
            NavigationDestination(icon: const Icon(Icons.eco_outlined), selectedIcon: const Icon(Icons.eco_rounded), label: gardenLabel),
          ],
        ),
      ),
    );
  }
}
