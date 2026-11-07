import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'onboarding_illustration.dart';

/// Data model representing the content of an individual onboarding page.
class OnboardingPageData {
  final OnboardingStep step;
  final String title;
  final String description;

  const OnboardingPageData({
    required this.step,
    required this.title,
    required this.description,
  });
}

/// Reusable onboarding page widget that presents the top illustration area
/// and bottom educational copy with smooth entrance animations.
class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final illustrationHeight = totalHeight * 0.58;

        return Column(
          children: [
            // Top ~60% illustration area
            SizedBox(
              height: illustrationHeight,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OnboardingIllustration(step: data.step),
              ),
            ),

            // Bottom text content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 150.ms)
                        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOut),

                    const SizedBox(height: 14),

                    // Description
                    Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                        height: 1.45,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 250.ms)
                        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
