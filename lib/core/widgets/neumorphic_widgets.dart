import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/services.dart';
import '../theme.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

// Note: Standard BoxDecoration doesn't support inset shadows.
// We use flutter_inset_shadow package for the pressed/sunken effect.
// Since it's not in pubspec yet, I'll add it or implement a custom painter.
// Let's add it to pubspec first to be sure.

class NeuContainer extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;

  const NeuContainer({
    super.key,
    this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark,
            offset: const Offset(9, 9),
            blurRadius: 16,
          ),
          BoxShadow(
            color: isDark ? AppColors.darkShadowLight : AppColors.lightShadowLight,
            offset: const Offset(-9, -9),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

class NeuInput extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const NeuInput({
    super.key,
    required this.hintText,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Inset shadows
          BoxShadow(
            color: isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark,
            offset: const Offset(4, 4),
            blurRadius: 8,
            inset: true,
          ),
          BoxShadow(
            color: isDark ? AppColors.darkShadowLight : AppColors.lightShadowLight,
            offset: const Offset(-4, -4),
            blurRadius: 8,
            inset: true,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.5),
          ),
          prefixIcon: prefixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

class NeuButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Color? color;

  const NeuButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
    this.color,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null;

    return Listener(
      onPointerDown: isEnabled ? _onPointerDown : null,
      onPointerUp: isEnabled ? _onPointerUp : null,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color ?? (isDark ? AppColors.darkBg : AppColors.lightBg),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: !isEnabled
                ? [] // No shadow if disabled
                : _isPressed
                ? [
                    // Sunken effect when pressed
                    BoxShadow(
                      color: isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark,
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                      inset: true,
                    ),
                    BoxShadow(
                      color: isDark ? AppColors.darkShadowLight : AppColors.lightShadowLight,
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                      inset: true,
                    ),
                  ]
                : [
                    // Raised effect
                    BoxShadow(
                      color: isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark,
                      offset: const Offset(9, 9),
                      blurRadius: 16,
                    ),
                    BoxShadow(
                      color: isDark ? AppColors.darkShadowLight : AppColors.lightShadowLight,
                      offset: const Offset(-9, -9),
                      blurRadius: 16,
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
