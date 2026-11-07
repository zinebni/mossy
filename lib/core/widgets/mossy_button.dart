import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum _MossyButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
}

/// A custom Mossy button with soft press animation, generous touch targets,
/// loading states, and icon support.
class MossyButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final _MossyButtonVariant _variant;

  const MossyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50.0,
    this.borderRadius = AppConstants.buttonRadius,
    this.padding,
  }) : _variant = _MossyButtonVariant.primary;

  const MossyButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50.0,
    this.borderRadius = AppConstants.buttonRadius,
    this.padding,
  }) : _variant = _MossyButtonVariant.primary;

  const MossyButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50.0,
    this.borderRadius = AppConstants.buttonRadius,
    this.padding,
  }) : _variant = _MossyButtonVariant.secondary;

  const MossyButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50.0,
    this.borderRadius = AppConstants.buttonRadius,
    this.padding,
  }) : _variant = _MossyButtonVariant.outline;

  const MossyButton.text({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 44.0,
    this.borderRadius = AppConstants.buttonRadius,
    this.padding,
  }) : _variant = _MossyButtonVariant.text;

  const MossyButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50.0,
    this.borderRadius = AppConstants.buttonRadius,
    this.padding,
  }) : _variant = _MossyButtonVariant.danger;

  @override
  State<MossyButton> createState() => _MossyButtonState();
}

class _MossyButtonState extends State<MossyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _onTapDown(TapDownDetails details) {
    if (_isEnabled) {
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isEnabled) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (_isEnabled) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Style configurations based on variant
    Color backgroundColor;
    Color foregroundColor;
    Border? border;

    switch (widget._variant) {
      case _MossyButtonVariant.primary:
        backgroundColor =
            _isEnabled ? AppColors.sageGreen : AppColors.disabledBackground;
        foregroundColor =
            _isEnabled ? AppColors.white : AppColors.disabledText;
        border = null;
        break;
      case _MossyButtonVariant.secondary:
        backgroundColor =
            _isEnabled ? AppColors.mintGreen : AppColors.disabledBackground;
        foregroundColor =
            _isEnabled ? AppColors.darkGreen : AppColors.disabledText;
        border = null;
        break;
      case _MossyButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor =
            _isEnabled ? AppColors.sageGreen : AppColors.disabledText;
        border = Border.all(
          color: _isEnabled ? AppColors.sageGreen : AppColors.disabledBackground,
          width: 1.5,
        );
        break;
      case _MossyButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor =
            _isEnabled ? AppColors.sageGreen : AppColors.disabledText;
        border = null;
        break;
      case _MossyButtonVariant.danger:
        backgroundColor =
            _isEnabled ? AppColors.error : AppColors.disabledBackground;
        foregroundColor =
            _isEnabled ? AppColors.white : AppColors.disabledText;
        border = null;
        break;
    }

    Widget content;

    if (widget.isLoading) {
      content = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else {
      content = Row(
        mainAxisSize:
            widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            IconTheme(
              data: IconThemeData(color: foregroundColor, size: 20),
              child: widget.icon!,
            ),
            AppSpacing.gapW8,
          ],
          Text(
            widget.text,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              letterSpacing: 0.2,
            ),
          ),
          if (widget.trailingIcon != null) ...[
            AppSpacing.gapW8,
            IconTheme(
              data: IconThemeData(color: foregroundColor, size: 20),
              child: widget.trailingIcon!,
            ),
          ],
        ],
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: AppConstants.fastAnimation,
          width: widget.isFullWidth ? double.infinity : widget.width,
          height: widget.height,
          padding: widget.padding ??
              (widget._variant == _MossyButtonVariant.text
                  ? const EdgeInsets.symmetric(horizontal: 16)
                  : AppSpacing.buttonPadding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: border,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isEnabled ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: widget._variant == _MossyButtonVariant.primary
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppColors.sageGreen.withValues(alpha: 0.15),
              highlightColor: Colors.transparent,
              child: Center(
                widthFactor: widget.isFullWidth ? null : 1.0,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
