import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MossyBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const MossyBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = AppColors.mintGreen,
    this.textColor = AppColors.darkText,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  factory MossyBadge.easy() {
    return const MossyBadge(
      label: 'Easy',
      backgroundColor: AppColors.easyAccent,
      textColor: AppColors.darkText,
    );
  }

  factory MossyBadge.medium() {
    return const MossyBadge(
      label: 'Medium',
      backgroundColor: AppColors.mediumAccent,
      textColor: AppColors.darkText,
    );
  }

  factory MossyBadge.hard() {
    return const MossyBadge(
      label: 'Hard',
      backgroundColor: AppColors.hardAccent,
      textColor: AppColors.darkText,
    );
  }

  factory MossyBadge.points(int points) {
    return MossyBadge(
      label: '+$points pts',
      icon: Icons.star_rounded,
      backgroundColor: AppColors.butterYellow.withValues(alpha: 0.6),
      textColor: const Color(0xFF6B5310),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
