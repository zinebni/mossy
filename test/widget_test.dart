import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mossy/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mossy/features/splash/presentation/splash_screen.dart';
import 'package:mossy/shared/widgets/mascot/mascot_expression.dart';
import 'package:mossy/shared/widgets/mascot/mascot_with_accessory.dart';
import 'package:mossy/shared/widgets/mascot/mossy_mascot.dart';

void main() {
  testWidgets('MossyMascot renders all expressions without error', (tester) async {
    for (final expr in MascotExpression.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MossyMascot(
              expression: expr,
              size: 140,
              animate: false,
            ),
          ),
        ),
      );
      expect(find.byType(MossyMascot), findsOneWidget);
    }
  });

  testWidgets('MascotWithAccessory renders with each accessory', (tester) async {
    for (final accessory in MascotAccessory.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MascotWithAccessory(
              expression: MascotExpression.happy,
              accessory: accessory,
              size: 160,
              animate: false,
            ),
          ),
        ),
      );
      expect(find.byType(MascotWithAccessory), findsOneWidget);
    }
  });

  testWidgets('OnboardingScreen renders initial slide and Next button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Verify first page title is present
    expect(find.text('Discover Plants Around You'), findsOneWidget);
    // Verify "Next" button and "Skip" button are present
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Unmount widget to clean up animation controllers
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('SplashScreen renders mascot and branding elements', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Mossy'), findsOneWidget);
    expect(find.text('Look closer. Discover more.'), findsOneWidget);
    expect(find.byType(MossyMascot), findsOneWidget);

    // Unmount widget to clean up navigation timer and animation controllers
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
  });
}
