import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/xdr_colors.dart';
import '../theme/xdr_type.dart';
import 'metal.dart';
import 'motion.dart';
import 'press.dart';

/// Text painted with the ice → lilac ramp. Used for the hero's emphasised line
/// and the "ยอดนิยม" badge.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = XdrColors.textRamp,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
      child: Text(text, style: style.copyWith(color: Colors.white), textAlign: textAlign),
    );
  }
}

/// The primary action: a brand-coloured knob with a sheen running across it.
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.padding = const EdgeInsets.symmetric(vertical: 17),
    this.radius = 18,
    this.fontSize = 15.5,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsets padding;
  final double radius;
  final double fontSize;

  /// Renders a spinner and refuses taps. Give this the same flag that guards
  /// the underlying request so a double-tap cannot fire it twice.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    final content = Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ] else if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: XdrType.thai(
                size: fontSize,
                weight: FontWeight.w700,
                color: Colors.white,
                shadows: const [Shadow(offset: Offset(0, 1), color: Color(0x73000000))],
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: PressSink(
        radius: radius,
        onTap: enabled ? onPressed : null,
        child: Sheen(
          radius: radius,
          child: MetalSurface(
            finish: MetalFinish.knob,
            radius: radius,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The quieter sibling — a raised key with a hairline edge.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 15),
    this.radius = 16,
    this.fontSize = 14,
    this.color = XdrColors.textBody,
  });

  final String label;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final double radius;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      radius: radius,
      onTap: onPressed,
      child: MetalSurface(
        finish: MetalFinish.keycap,
        radius: radius,
        borderColor: XdrColors.hairlineStrong,
        padding: padding,
        child: Center(
          child: Text(
            label,
            style: XdrType.thai(size: fontSize, color: color, weight: FontWeight.w500)
                .copyWith(shadows: engraved),
          ),
        ),
      ),
    );
  }
}

/// A remote image with the app's own placeholder and failure states — never a
/// grey box and never a broken-image glyph.
class RemoteArt extends StatelessWidget {
  const RemoteArt({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.radius = 0,
  });

  final String? url;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final art = (url == null || url!.isEmpty)
        ? const _ArtFallback()
        : CachedNetworkImage(
            imageUrl: url!,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 220),
            placeholder: (_, __) => const ShimmerTile(radius: 0),
            errorWidget: (_, __, ___) => const _ArtFallback(),
          );

    if (radius == 0) return art;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: art);
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: XdrColors.sunkFace),
      child: Center(
        child: Icon(Icons.auto_awesome_outlined, size: 22, color: XdrColors.textDim.withValues(alpha: 0.6)),
      ),
    );
  }
}

/// Screen-level empty state — a line of copy and a way out of it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.auto_awesome_outlined,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BevelRing(
              radius: 22,
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(gradient: XdrColors.plateFace),
                child: Icon(icon, color: XdrColors.ice, size: 26),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: XdrType.thai(size: 16, weight: FontWeight.w500, color: XdrColors.textPrimary),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: XdrType.body(size: 12.5, color: XdrColors.textMuted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              BrandButton(
                label: actionLabel!,
                onPressed: onAction,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
                radius: 14,
                fontSize: 13.5,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Failure panel used inline wherever a load can fail — states what happened in
/// Thai and offers the retry, rather than leaving a blank screen.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MetalSurface(
      radius: 16,
      borderColor: XdrColors.danger.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 17, color: XdrColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: XdrType.body(size: 12.5, color: XdrColors.danger),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            GhostButton(
              label: 'ลองใหม่',
              onPressed: onRetry,
              padding: const EdgeInsets.symmetric(vertical: 11),
              radius: 12,
              fontSize: 12.5,
            ),
          ],
        ],
      ),
    );
  }
}

/// A transient message. Kept on the app's own surface language rather than
/// Material's, and it never renders a raw exception.
void showXdrToast(BuildContext context, String message, {bool isError = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: MetalSurface(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          borderColor: isError ? XdrColors.danger.withValues(alpha: 0.4) : XdrColors.hairline,
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 17,
                color: isError ? XdrColors.danger : XdrColors.mint,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: XdrType.body(
                    size: 12.5,
                    color: isError ? XdrColors.danger : XdrColors.textBody,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
