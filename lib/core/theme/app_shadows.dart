import 'package:flutter/material.dart';

/// Shadow definitions for the Mossy design system.
///
/// Uses tinted dark-green undertones instead of harsh black to complement
/// the organic, cream-based palette.
class AppShadows {
  AppShadows._();

  // Individual Shadows
  static const BoxShadow soft = BoxShadow(
    color: Color(0x0C2D3B2D),
    blurRadius: 10,
    offset: Offset(0, 3),
    spreadRadius: 0,
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x142D3B2D),
    blurRadius: 18,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  static const BoxShadow strong = BoxShadow(
    color: Color(0x222D3B2D),
    blurRadius: 28,
    offset: Offset(0, 10),
    spreadRadius: 1,
  );

  static const BoxShadow floating = BoxShadow(
    color: Color(0x1E2D3B2D),
    blurRadius: 36,
    offset: Offset(0, 14),
    spreadRadius: 2,
  );

  // Colored Ambient Card Shadows
  static const BoxShadow sageShadow = BoxShadow(
    color: Color(0x40829B79),
    blurRadius: 16,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  static const BoxShadow mintShadow = BoxShadow(
    color: Color(0x55D9E8CF),
    blurRadius: 14,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  static const BoxShadow lavenderShadow = BoxShadow(
    color: Color(0x50E9DDF5),
    blurRadius: 16,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  static const BoxShadow peachShadow = BoxShadow(
    color: Color(0x55F5D6C5),
    blurRadius: 16,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  static const BoxShadow yellowShadow = BoxShadow(
    color: Color(0x55EFCF79),
    blurRadius: 16,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  // Shadow Lists for easy use in BoxDecorations
  static const List<BoxShadow> softList = [soft];
  static const List<BoxShadow> mediumList = [medium];
  static const List<BoxShadow> strongList = [strong];
  static const List<BoxShadow> floatingList = [floating];

  static const List<BoxShadow> sageCardShadowList = [
    BoxShadow(
      color: Color(0x0A2D3B2D),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    sageShadow,
  ];

  static const List<BoxShadow> mintCardShadowList = [
    BoxShadow(
      color: Color(0x0A2D3B2D),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    mintShadow,
  ];

  static const List<BoxShadow> lavenderCardShadowList = [
    BoxShadow(
      color: Color(0x0A2D3B2D),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    lavenderShadow,
  ];

  static const List<BoxShadow> peachCardShadowList = [
    BoxShadow(
      color: Color(0x0A2D3B2D),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    peachShadow,
  ];

  static const List<BoxShadow> yellowCardShadowList = [
    BoxShadow(
      color: Color(0x0A2D3B2D),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    yellowShadow,
  ];
}
