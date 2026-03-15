import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// MidnightCard — minimal white card with subtle shadow
// ---------------------------------------------------------------------------
class MidnightCard extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const MidnightCard({
    super.key,
    this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MidnightButton — clean solid button with press animation
// ---------------------------------------------------------------------------
class MidnightButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Color? color;

  const MidnightButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.width,
    this.height,
    this.color,
  });

  @override
  State<MidnightButton> createState() => _MidnightButtonState();
}

class _MidnightButtonState extends State<MidnightButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    setState(() => _isPressed = true);
    _ctrl.forward();
    HapticFeedback.lightImpact();
  }

  void _up(PointerUpEvent _) {
    setState(() => _isPressed = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bg = widget.color ?? MidnightColors.primary;

    return Listener(
      onPointerDown: enabled ? _down : null,
      onPointerUp: enabled ? _up : null,
      onPointerCancel: enabled
          ? (_) {
              setState(() => _isPressed = false);
              _ctrl.reverse();
            }
          : null,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: _isPressed
                    ? (widget.color != null
                        ? widget.color!.withValues(alpha: 0.85)
                        : AppColors.primaryDark)
                    : bg,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: bg.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Center(child: child),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MidnightInput — clean text field, white background
// ---------------------------------------------------------------------------
class MidnightInput extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;

  const MidnightInput({
    super.key,
    required this.hintText,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl =
        controller ?? TextEditingController(text: initialValue);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        maxLength: maxLength,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterText: '',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomToast — minimal bottom-anchored snack
// ---------------------------------------------------------------------------
class CustomToast extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback? onDismiss;

  const CustomToast({
    super.key,
    required this.message,
    this.onDismiss,
    this.duration = const Duration(milliseconds: 3000),
  });

  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => CustomToast(
        message: message,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<CustomToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 280), vsync: this);
    _slide = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
    Future.delayed(widget.duration, () {
      if (mounted) _ctrl.reverse().then((_) => widget.onDismiss?.call());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => SlideTransition(
            position: _slide,
            child: FadeTransition(opacity: _fade, child: child),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 12, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
