import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../dimens.dart';
import '../theme.dart';
import '../utils.dart';

// ===========================================================================
// AppCard
// ===========================================================================
enum CardVariant { flat, elevated, hero }

/// One card recipe. border(1px) + consistent shadow. [ledgerLine] draws the
/// signature left-edge accent stripe (spec §3.3).
class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final CardVariant variant;
  final bool ledgerLine;
  final Color? ledgerColor;

  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.variant = CardVariant.flat,
    this.ledgerLine = false,
    this.ledgerColor,
  });

  BorderRadius get _radius {
    switch (variant) {
      case CardVariant.hero:
        return Radii.lgBr; // 20
      case CardVariant.elevated:
      case CardVariant.flat:
        return Radii.mdBr; // 16
    }
  }

  List<BoxShadow> _shadow(BuildContext context) {
    switch (variant) {
      case CardVariant.hero:
        return AppShadows.elevated(context);
      case CardVariant.elevated:
        return AppShadows.elevated(context);
      case CardVariant.flat:
        return AppShadows.card(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.cardBg,
          borderRadius: _radius,
          border: Border.all(color: p.cardBorder, width: 1),
          boxShadow: _shadow(context),
        ),
        child: ledgerLine
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: ledgerColor ?? p.primary),
                  if (child != null) Expanded(child: child!),
                ],
              )
            : child,
      ),
    );
  }
}

// ===========================================================================
// AppButton
// ===========================================================================
enum ButtonVariant { solid, ghost, danger, outline }

/// ONE button system. [variant] controls fill/shadow:
/// - solid: primary fill + colored glow shadow.
/// - ghost: translucent tint, NO shadow (kills the alpha-0.1 abuse).
/// - danger: error tint, NO shadow.
/// - outline: transparent fill + border, NO shadow.
class AppButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.solid,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(duration: const Duration(milliseconds: 120), vsync: this);
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
    final p = Theme.of(context).extension<AppPalette>()!;
    final enabled = widget.onPressed != null;

    Color fill;
    Color fg;
    Border? border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case ButtonVariant.solid:
        fill = _isPressed ? p.primaryHover : p.primary;
        fg = p.onPrimary;
        shadows = enabled
            ? [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null;
        border = null;
        break;
      case ButtonVariant.ghost:
        fill = p.primary.withValues(alpha: _isPressed ? 0.16 : 0.1);
        fg = p.primary;
        shadows = null; // no colored shadow on ghost
        border = null;
        break;
      case ButtonVariant.danger:
        fill = p.error.withValues(alpha: _isPressed ? 0.16 : 0.1);
        fg = p.error;
        shadows = null; // no colored shadow on danger
        border = null;
        break;
      case ButtonVariant.outline:
        fill = Colors.transparent;
        fg = p.textMain;
        shadows = null;
        border = Border.all(color: p.cardBorder, width: 1);
        break;
    }

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
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: Radii.mdBr, // 16
                border: border,
                boxShadow: shadows,
              ),
              child: Center(child: child),
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
            child: IconTheme(data: IconThemeData(color: fg), child: widget.child),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// AppInput
// ===========================================================================
class AppInput extends StatefulWidget {
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

  const AppInput({
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
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late TextEditingController _ctrl;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
      _ownsController = false;
    } else {
      _ctrl = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    }
  }

  @override
  void didUpdateWidget(AppInput old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && widget.controller != old.controller) {
      if (_ownsController) _ctrl.dispose();
      _ctrl = widget.controller!;
      _ownsController = false;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: Radii.smBr, // 12 (was 16)
        border: Border.all(color: p.cardBorder, width: 1),
        boxShadow: AppShadows.card(context),
      ),
      child: TextField(
        controller: _ctrl,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: AppTexts.body(context),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: p.textMuted),
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterText: '',
        ),
      ),
    );
  }
}

// ===========================================================================
// AppAvatar — single avatar recipe (spec §5)
// ===========================================================================
enum AvatarSize { sm, md, lg }

class AppAvatar extends StatelessWidget {
  final String name;
  final String hexColor;
  final AvatarSize size;
  /// When true, renders a small color dot instead of an initial avatar
  /// (used in compact finance lists).
  final bool dot;

  const AppAvatar({
    super.key,
    required this.name,
    required this.hexColor,
    this.size = AvatarSize.md,
    this.dot = false,
  });

  double get _dimension {
    switch (size) {
      case AvatarSize.sm:
        return 32;
      case AvatarSize.md:
        return 44;
      case AvatarSize.lg:
        return 64;
    }
  }

  double get _fontSize {
    switch (size) {
      case AvatarSize.sm:
        return 14;
      case AvatarSize.md:
        return 16;
      case AvatarSize.lg:
        return 22;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(hexColor);
    if (dot) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: _fontSize,
        ),
      ),
    );
  }
}

// ===========================================================================
// ScreenHeader — unified title + optional back (spec §5)
// ===========================================================================
class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  const ScreenHeader({super.key, required this.title, this.onBack, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.s24, Spacing.s8, Spacing.s24, Spacing.s8),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .extension<AppPalette>()!
                      .cardBg,
                  borderRadius: Radii.smBr,
                  border: Border.all(
                      color: Theme.of(context).extension<AppPalette>()!.cardBorder,
                      width: 1),
                ),
                child: Icon(PhosphorIcons.arrowLeft(),
                    color: Theme.of(context).extension<AppPalette>()!.textMain,
                    size: 20),
              ),
            ),
            const SizedBox(width: Spacing.s12),
          ],
          Expanded(
            child: Text(title, style: AppTexts.screenTitle(context)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ===========================================================================
// SectionHeader — eyebrow label + optional link (spec §5)
// ===========================================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: AppTexts.eyebrow(context)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!,
                    style: TextStyle(
                        color: p.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Icon(PhosphorIcons.caretRight(),
                    color: p.primary, size: 14),
              ],
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// SegmentedControl — reusable (replaces finance+stats duplication)
// ===========================================================================
class SegmentedControl extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const SegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: Radii.smBr, // 12
        border: Border.all(color: p.cardBorder, width: 1),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? p.primary : Colors.transparent,
                  borderRadius: Radii.xsBr, // 8
                  boxShadow: active && Theme.of(context).brightness == Brightness.light
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? p.onPrimary : p.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ===========================================================================
// EmptyState — unified (replaces history+stats duplication)
// ===========================================================================
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? cta;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.cta});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.s24),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: p.primary),
          ),
          const SizedBox(height: Spacing.s20),
          Text(title, style: AppTexts.sectionTitle(context)),
          if (subtitle != null) ...[
            const SizedBox(height: Spacing.s4),
            Text(subtitle!, style: AppTexts.caption(context)),
          ],
          if (cta != null) ...[
            const SizedBox(height: Spacing.s20),
            cta!,
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// AppSheet + AppDialog — wrappers (spec §5)
// ===========================================================================
class AppSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  const AppSheet({super.key, required this.child, this.title});

  /// Wrap any showModalBottomSheet content in this.
  static Widget decoration(BuildContext context, {Widget? child, String? title}) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        border: Border.all(color: p.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Spacing.s8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: p.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: Spacing.s12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
              child: Text(title.toUpperCase(), style: AppTexts.eyebrow(context)),
            ),
          ],
          const SizedBox(height: Spacing.s12),
          if (child != null) child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppSheet.decoration(context, child: child, title: title);
}

/// Standard dialog shape: radius xl(24) + border + navBg.
class AppDialog {
  static ShapeBorder shape(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.xl), // 24
      side: BorderSide(color: p.cardBorder, width: 1),
    );
  }

  static Color background(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!.cardBg;
}

// ===========================================================================
// CustomToast — minimal bottom-anchored snack (spec §5)
// ===========================================================================
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
    final p = Theme.of(context).extension<AppPalette>()!;
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
              color: p.textMain,
              borderRadius: BorderRadius.circular(Radii.sm), // 12 (was 14)
              boxShadow: AppShadows.dialog(context),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: p.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check,
                      size: 12, color: p.bgColor),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: p.bgColor,
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
