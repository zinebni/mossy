import 'package:flutter/material.dart';

/// Spacing system and padding constants for the Mossy app.
class AppSpacing {
  AppSpacing._();

  // Base Spacing Values
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // All-sides Padding Helpers
  static const EdgeInsets paddingZero = EdgeInsets.zero;
  static const EdgeInsets paddingAllXxs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingAllXxl = EdgeInsets.all(xxl);

  // Horizontal Padding Helpers
  static const EdgeInsets paddingHorizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets paddingHorizontalXxl = EdgeInsets.symmetric(horizontal: xxl);

  // Vertical Padding Helpers
  static const EdgeInsets paddingVerticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets paddingVerticalXxl = EdgeInsets.symmetric(vertical: xxl);

  // Contextual Semantic Paddings
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets screenPaddingWide = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: lg, vertical: 14.0);
  static const EdgeInsets buttonPaddingSm = EdgeInsets.symmetric(horizontal: md, vertical: 10.0);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: md, vertical: 14.0);
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(lg, md, lg, lg);

  // Horizontal Sized Box Gaps
  static const Widget gapW4 = SizedBox(width: xs);
  static const Widget gapW8 = SizedBox(width: sm);
  static const Widget gapW12 = SizedBox(width: 12.0);
  static const Widget gapW16 = SizedBox(width: md);
  static const Widget gapW24 = SizedBox(width: lg);
  static const Widget gapW32 = SizedBox(width: xl);
  static const Widget gapW48 = SizedBox(width: xxl);

  // Vertical Sized Box Gaps
  static const Widget gapH4 = SizedBox(height: xs);
  static const Widget gapH8 = SizedBox(height: sm);
  static const Widget gapH12 = SizedBox(height: 12.0);
  static const Widget gapH16 = SizedBox(height: md);
  static const Widget gapH24 = SizedBox(height: lg);
  static const Widget gapH32 = SizedBox(height: xl);
  static const Widget gapH48 = SizedBox(height: xxl);
  static const Widget gapH64 = SizedBox(height: xxxl);
}
