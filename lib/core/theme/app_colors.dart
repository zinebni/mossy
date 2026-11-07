import 'package:flutter/material.dart';

/// Design system color palette for Mossy.
///
/// Features warm, earthy, nature-inspired tones:
/// - Sage green, cream, mint, lavender, peach, and butter yellow.
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color sageGreen = Color(0xFF829B79);
  static const Color lightSage = Color(0xFFA5B89D);
  static const Color deepSage = Color(0xFF5E7556);
  static const Color darkSage = Color(0xFF45583E);

  // Background & Surface
  static const Color cream = Color(0xFFF7F3E9);
  static const Color surfaceCream = Color(0xFFFAF7F0);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color subtleBackground = Color(0xFFF0EBE0);
  static const Color white = Color(0xFFFFFFFF);

  // Accent & Nature Pastel Colors
  static const Color mintGreen = Color(0xFFD9E8CF);
  static const Color lavender = Color(0xFFE9DDF5);
  static const Color peach = Color(0xFFF5D6C5);
  static const Color butterYellow = Color(0xFFEFCF79);
  static const Color natureEarth = Color(0xFF8C6D58);
  static const Color skyBlue = Color(0xFFCDE3E8);

  // Text & Typography Colors
  static const Color darkGreen = Color(0xFF2D3B2D); // Primary text
  static const Color secondaryText = Color(0xFF5A6B5A); // Subtitles / body
  static const Color mutedText = Color(0xFF8A9A8A); // Captions / placeholders
  static const Color inverseText = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE3DEC9);
  static const Color subtleBorder = Color(0xFFECE7D8);
  static const Color dividerColor = Color(0xFFE2DCCF);

  // Status & Feedback Colors
  static const Color error = Color(0xFFD9534F);
  static const Color errorLight = Color(0xFFFCEBEB);
  static const Color success = Color(0xFF5CB85C);
  static const Color successLight = Color(0xFFEDF7ED);
  static const Color warning = Color(0xFFF0AD4E);
  static const Color warningLight = Color(0xFFFFF8EC);
  static const Color info = Color(0xFF6B9AC4);
  static const Color infoLight = Color(0xFFEFF5FA);

  // Disabled States
  static const Color disabledBackground = Color(0xFFE5E2D8);
  static const Color disabledText = Color(0xFFA5ABA5);

  // Aliases for convenience
  static const Color creamBackground = cream;
  static const Color darkText = darkGreen;
  static const Color sageLight = Color(0xFFB8CEAF);
  static const Color sageDark = Color(0xFF45583E);
  static const Color mintLight = Color(0xFFEBF4E6);
  static const Color shadow = Color(0x1A2D3B2D); // 10% dark green
  static const Color surfaceCard = cardSurface;
  static const Color surfaceWhite = white;
  static const Color divider = dividerColor;
  static const Color butterYellowDark = Color(0xFFD4A832);
  static const Color peachDark = Color(0xFFD4A082);
  // Mascot-specific colors
  static const Color mascotBodyHighlight = Color(0xFF9DB894);
  static const Color mascotBodyShadow = Color(0xFF5E7556);
  static const Color mascotSprout = Color(0xFF5E7556);
  static const Color mascotSproutLight = Color(0xFF9DB894);
  static const Color mascotCheek = Color(0xFFF5B8A0);
  static const Color mascotEyeDark = Color(0xFF2D3B2D);
  // Difficulty accent colors
  static const Color easyAccent = mintGreen;
  static const Color mediumAccent = butterYellow;
  static const Color hardAccent = peach;
  // Border variants
  static const Color borderLight = Color(0xFFE8EDE5);
  // Mascot texture dot color
  static const Color mascotTexture = Color(0xFF4A6741);

  // Gradients
  static const LinearGradient sageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF829B79),
      Color(0xFF6E8665),
    ],
  );

  static const LinearGradient mintSageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD9E8CF),
      Color(0xFF829B79),
    ],
  );

  static const LinearGradient creamGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFDF8),
      Color(0xFFF7F3E9),
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD9E8CF),
      Color(0xFFE9DDF5),
      Color(0xFFF5D6C5),
    ],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5D6C5),
      Color(0xFFEFCF79),
    ],
  );

  static const LinearGradient lavenderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE9DDF5),
      Color(0xFFD9E8CF),
    ],
  );
}
