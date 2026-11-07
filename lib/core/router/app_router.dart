import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/adventures/presentation/adventures_screen.dart';
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
    routes: [
      GoRoute(path: splashPath, builder: (_, __) => const SplashScreen()),
      GoRoute(path: onboardingPath, builder: (_, __) => const OnboardingScreen()),
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
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFD9E8CF),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark_rounded), label: 'Collection'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Adventures'),
          NavigationDestination(icon: Icon(Icons.eco_outlined), selectedIcon: Icon(Icons.eco_rounded), label: 'Garden'),
        ],
      ),
    );
  }
}
