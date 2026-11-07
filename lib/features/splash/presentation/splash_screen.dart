import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../../shared/widgets/mascot/mossy_mascot.dart';

/// Animated Splash Screen for Mossy.
/// Features floating botanical particles, an unfurling vine,
/// an elastic-bouncing Mossy mascot, app branding, and auto-navigation
/// based on SharedPreferences onboarding state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _vineController;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // Growing vine animation controller
    _vineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // Schedule navigation after 3 seconds
    _navTimer = Timer(const Duration(milliseconds: 3000), _proceedToNextScreen);
  }

  @override
  void dispose() {
    _vineController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  Future<void> _proceedToNextScreen() async {
    _navTimer?.cancel();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool hasCompletedOnboarding =
        prefs.getBool('onboarding_completed') ?? false;

    if (!mounted) return;

    if (hasCompletedOnboarding) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _proceedToNextScreen, // Allow tap-to-skip
      child: Scaffold(
        backgroundColor: AppColors.creamBackground,
        body: Stack(
          children: [
            // 1. Subtle floating botanical elements around the edges
            const Positioned.fill(
              child: _FloatingBotanicals(),
            ),

            // 2. Growing bottom vine animation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 120,
              child: AnimatedBuilder(
                animation: _vineController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GrowingVinePainter(
                      progress: _vineController.value,
                    ),
                  );
                },
              ),
            ),

            // 3. Central Brand Composition (Mascot, Title, Tagline)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mossy mascot entrance: starts small and bounces into center
                  Animate(
                    effects: [
                      FadeEffect(duration: 500.ms, curve: Curves.easeOut),
                      ScaleEffect(
                        begin: const Offset(0.2, 0.2),
                        end: const Offset(1.0, 1.0),
                        duration: 900.ms,
                        curve: Curves.elasticOut,
                      ),
                    ],
                    child: MossyMascot(
                      expression: MascotExpression.happy,
                      size: 170.0,
                      animate: true,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Title: "Mossy"
                  Text(
                    'Mossy',
                    style: GoogleFonts.fraunces(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                      letterSpacing: -1.0,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.25, end: 0, duration: 600.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 8),

                  // Tagline: "Look closer. Discover more."
                  Text(
                    'Look closer. Discover more.',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.4,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 750.ms)
                      .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

                  const SizedBox(height: 36),

                  // Subtle nature loading dot indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.sageGreen,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(
                            delay: (index * 200).ms,
                            onPlay: (c) => c.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1.3, 1.3),
                            duration: 600.ms,
                          );
                    }),
                  )
                      .animate()
                      .fadeIn(delay: 1000.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// GROWING VINE CUSTOM PAINTER
// ==========================================

class _GrowingVinePainter extends CustomPainter {
  final double progress;

  const _GrowingVinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final w = size.width;
    final h = size.height;

    // Vine stem
    final vinePaint = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = AppColors.mintGreen
      ..style = PaintingStyle.fill;

    final leafOutline = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Unfurling path from left to right along bottom
    final path = Path();
    path.moveTo(0, h * 0.85);
    path.quadraticBezierTo(w * 0.25, h * 0.45, w * 0.5, h * 0.75);
    path.quadraticBezierTo(w * 0.75, h * 1.05, w, h * 0.65);

    // Extract current progress of vine
    for (final metric in path.computeMetrics()) {
      final currentLength = metric.length * progress;
      final extract = metric.extractPath(0, currentLength);
      canvas.drawPath(extract, vinePaint);

      // Draw sprouting leaves at milestones along the path
      final leafPoints = [0.2, 0.4, 0.6, 0.8];
      for (int i = 0; i < leafPoints.length; i++) {
        final t = leafPoints[i];
        if (progress >= t) {
          final tangent = metric.getTangentForOffset(metric.length * t);
          if (tangent != null) {
            final leafGrowth = ((progress - t) / 0.2).clamp(0.0, 1.0);
            final leafSize = 12.0 * leafGrowth;

            canvas.save();
            canvas.translate(tangent.position.dx, tangent.position.dy);
            final flip = (i % 2 == 0) ? -1.0 : 1.0;
            canvas.rotate(tangent.angle + (flip * 0.8));

            final leaf = Path();
            leaf.moveTo(0, 0);
            leaf.quadraticBezierTo(-leafSize * 0.5, -leafSize * 0.6, 0, -leafSize);
            leaf.quadraticBezierTo(leafSize * 0.5, -leafSize * 0.6, 0, 0);
            leaf.close();

            canvas.drawPath(leaf, leafPaint);
            canvas.drawPath(leaf, leafOutline);
            canvas.restore();
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GrowingVinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ==========================================
// FLOATING BOTANICAL PARTICLES
// ==========================================

class _FloatingBotanicals extends StatelessWidget {
  const _FloatingBotanicals();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Top Left Leaf
            Positioned(
              left: w * 0.08,
              top: h * 0.12,
              child: _BotanicalLeaf(
                color: AppColors.mintGreen,
                size: 26,
                rotation: -0.4,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: 12, duration: 3000.ms)
                  .rotate(begin: -0.05, end: 0.05, duration: 3200.ms),
            ),

            // Top Right Spore Dot
            Positioned(
              right: w * 0.12,
              top: h * 0.15,
              child: _SporeDot(color: AppColors.butterYellow, size: 14)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -10, duration: 2500.ms),
            ),

            // Mid Left Lavender Dot
            Positioned(
              left: w * 0.14,
              top: h * 0.42,
              child: _SporeDot(color: AppColors.lavender, size: 12)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: 8, duration: 2700.ms),
            ),

            // Mid Right Leaf
            Positioned(
              right: w * 0.08,
              top: h * 0.38,
              child: _BotanicalLeaf(
                color: AppColors.peach,
                size: 22,
                rotation: 0.6,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -12, duration: 2800.ms)
                  .rotate(begin: 0.05, end: -0.05, duration: 3000.ms),
            ),

            // Bottom Left Spore
            Positioned(
              left: w * 0.16,
              bottom: h * 0.22,
              child: _SporeDot(color: AppColors.mintGreen, size: 16)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -8, duration: 2200.ms),
            ),

            // Bottom Right Leaf
            Positioned(
              right: w * 0.15,
              bottom: h * 0.24,
              child: _BotanicalLeaf(
                color: AppColors.sageGreen.withValues(alpha: 0.5),
                size: 24,
                rotation: -0.3,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: 10, duration: 3100.ms),
            ),
          ],
        );
      },
    );
  }
}

class _BotanicalLeaf extends StatelessWidget {
  final Color color;
  final double size;
  final double rotation;

  const _BotanicalLeaf({
    required this.color,
    required this.size,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size(size, size * 1.5),
        painter: _LeafPainter(color: color),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color color;

  _LeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.quadraticBezierTo(-size.width * 0.2, size.height * 0.4, size.width / 2, 0);
    path.quadraticBezierTo(size.width * 1.2, size.height * 0.4, size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SporeDot extends StatelessWidget {
  final Color color;
  final double size;

  const _SporeDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
