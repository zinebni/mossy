import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography configuration for Mossy using Google Fonts.
///
/// Headings & Titles use 'Quicksand' (friendly, warm, rounded sans).
/// Body text, captions & labels use 'Nunito' (readable, rounded, legible).
class AppTypography {
  AppTypography._();

  // ---------------------------------------------------------
  // DISPLAY STYLES (Quicksand)
  // ---------------------------------------------------------
  static TextStyle get displayLarge => GoogleFonts.quicksand(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGreen,
        letterSpacing: -0.25,
        height: 1.12,
      );

  static TextStyle get displayMedium => GoogleFonts.quicksand(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGreen,
        letterSpacing: 0,
        height: 1.15,
      );

  static TextStyle get displaySmall => GoogleFonts.quicksand(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGreen,
        letterSpacing: 0,
        height: 1.2,
      );

  // ---------------------------------------------------------
  // HEADLINE STYLES (Quicksand)
  // ---------------------------------------------------------
  static TextStyle get headlineLarge => GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGreen,
        letterSpacing: 0,
        height: 1.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.quicksand(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGreen,
        letterSpacing: 0,
        height: 1.28,
      );

  static TextStyle get headlineSmall => GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGreen,
        letterSpacing: 0,
        height: 1.33,
      );

  // ---------------------------------------------------------
  // TITLE STYLES (Quicksand)
  // ---------------------------------------------------------
  static TextStyle get titleLarge => GoogleFonts.quicksand(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGreen,
        letterSpacing: 0,
        height: 1.35,
      );

  static TextStyle get titleMedium => GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGreen,
        letterSpacing: 0.15,
        height: 1.35,
      );

  static TextStyle get titleSmall => GoogleFonts.quicksand(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGreen,
        letterSpacing: 0.1,
        height: 1.4,
      );

  // ---------------------------------------------------------
  // BODY STYLES (Nunito)
  // ---------------------------------------------------------
  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.darkGreen,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryText,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryText,
        letterSpacing: 0.4,
        height: 1.4,
      );

  // ---------------------------------------------------------
  // LABEL STYLES (Nunito)
  // ---------------------------------------------------------
  static TextStyle get labelLarge => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGreen,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryText,
        letterSpacing: 0.5,
        height: 1.35,
      );

  static TextStyle get labelSmall => GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedText,
        letterSpacing: 0.5,
        height: 1.3,
      );

  /// Returns the complete TextTheme used by MaterialApp ThemeData.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
