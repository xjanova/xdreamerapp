import 'package:flutter/material.dart';

import '../../core/theme/xdr_colors.dart';

/// The X-DREAMER logo tile, with the violet bloom it always carries.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 30, this.radius = 9, this.glow = 18});

  final double size;
  final double radius;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: XdrColors.violet.withValues(alpha: 0.5),
            blurRadius: glow * 2,
            spreadRadius: -2,
          ),
          const BoxShadow(color: Color(0x17FFFFFF), spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset('assets/brand/logo.webp', fit: BoxFit.cover),
      ),
    );
  }
}

/// The circular identity ring on the top bar and profile header — a conic
/// brand sweep around the account's initial.
class AvatarRing extends StatelessWidget {
  const AvatarRing({
    super.key,
    required this.initial,
    this.size = 32,
    this.imageUrl,
    this.fontSize,
  });

  final String initial;
  final double size;
  final String? imageUrl;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: 3.14,
          endAngle: 3.14 + 6.283,
          colors: [XdrColors.emerald, XdrColors.cyan, XdrColors.violet, XdrColors.emerald],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: XdrColors.wellFill),
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? ClipOval(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initial(),
                ),
              )
            : _initial(),
      ),
    );
  }

  Widget _initial() => Center(
    child: Text(
      initial,
      style: TextStyle(
        fontSize: fontSize ?? size * 0.38,
        fontWeight: FontWeight.w800,
        color: XdrColors.ice,
        height: 1,
      ),
    ),
  );
}
