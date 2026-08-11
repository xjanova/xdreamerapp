import 'package:flutter/material.dart';

import '../theme/xdr_colors.dart';
import '../theme/xdr_type.dart';
import 'metal.dart';

/// A text input milled into the plate.
///
/// Focus lifts an ice-coloured rim; an error turns the rim red and prints the
/// reason underneath. Both states are on the channel itself rather than on a
/// Material `InputDecorator`, which would draw its own underline through the
/// machined edge.
class MetalField extends StatefulWidget {
  const MetalField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.trailing,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofillHints,
    this.enabled = true,
    this.textStyle,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final TextStyle? textStyle;

  @override
  State<MetalField> createState() => _MetalFieldState();
}

class _MetalFieldState extends State<MetalField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final rim = hasError
        ? XdrColors.danger.withValues(alpha: 0.45)
        : _focus.hasFocus
            ? XdrColors.cyan.withValues(alpha: 0.35)
            : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(widget.label!.toUpperCase(), style: XdrType.label(size: 11)),
              const Spacer(),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 7),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              if (_focus.hasFocus && !hasError)
                BoxShadow(color: XdrColors.cyan.withValues(alpha: 0.09), blurRadius: 0, spreadRadius: 3),
            ],
          ),
          child: MetalSurface(
            finish: MetalFinish.sunk,
            radius: 13,
            borderColor: rim,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              maxLines: widget.obscure ? 1 : widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              autofillHints: widget.autofillHints,
              cursorColor: XdrColors.ice,
              cursorWidth: 2,
              style: widget.textStyle ??
                  XdrType.thai(
                    size: 14,
                    color: XdrColors.textPrimary,
                    letterSpacing: widget.obscure ? 3.1 : null,
                  ),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                hintText: widget.hint,
                hintStyle: XdrType.thai(size: 14, color: XdrColors.textDim),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(widget.error!, style: XdrType.thai(size: 11, color: XdrColors.danger)),
        ],
      ],
    );
  }
}
