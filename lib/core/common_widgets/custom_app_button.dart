import 'package:flutter/material.dart';
import 'package:toggle_timer/config/colors/app_colors.dart';
import 'package:toggle_timer/config/typography/app_typography.dart';

class CustomAppButton extends StatefulWidget {
  const CustomAppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.borderRadius = 100,
    this.isLoading = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final double borderRadius;
  final bool isLoading;

  @override
  State<CustomAppButton> createState() => _CustomAppButtonState();
}

class _CustomAppButtonState extends State<CustomAppButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (details) {
      if (!widget.isLoading) {
        setState(() => _scale = 0.95);
      }
    },
    onTapUp: (details) {
      if (!widget.isLoading) {
        setState(() => _scale = 1.0);
        widget.onPressed?.call();
      }
    },
    onTapCancel: () => setState(() => _scale = 1.0),
    child: Transform.scale(
      scale: _scale,
      child: AnimatedContainer(
        height: 57,
        width: 364,
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: AppColors.primaryGradient,
        ),
        child: widget.isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.kAppBlack),
                  ),
                ),
              )
            : Center(
                child: Text(widget.text, style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppBlack)),
              ),
      ),
    ),
  );
}
