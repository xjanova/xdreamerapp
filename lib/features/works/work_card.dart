import 'package:flutter/material.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/press.dart';
import '../../data/models/generation.dart';

/// One piece of work in a grid.
class WorkCard extends StatelessWidget {
  const WorkCard({
    super.key,
    required this.item,
    required this.height,
    this.onTap,
    this.onToggleFavourite,
    this.showFavouriteCount = false,
  });

  final Generation item;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavourite;
  final bool showFavouriteCount;

  String get _kindBadge => switch (item.type) {
    'video' => 'VIDEO',
    'edit' => '4K',
    _ => 'IMAGE',
  };

  @override
  Widget build(BuildContext context) {
    return PressSink(
      radius: 16,
      depth: 2,
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: XdrColors.hairline),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.mediaDeleted)
                const _DeletedPlaceholder()
              else
                RemoteArt(url: item.thumbnailUrl ?? item.resultUrl),

              // A failed row still appears in the gallery — say what happened
              // rather than showing a blank tile.
              if (!item.succeeded)
                Container(
                  color: XdrColors.inkwell.withValues(alpha: 0.72),
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      item.creditsRefunded ? 'ไม่สำเร็จ\nคืนเครดิตแล้ว' : 'ไม่สำเร็จ',
                      textAlign: TextAlign.center,
                      style: XdrType.thai(size: 11, color: XdrColors.danger),
                    ),
                  ),
                ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 22, 10, 9),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00030612), Color(0xE6030612)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.prompt ?? 'ไม่มีคำอธิบาย',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: XdrType.thai(size: 11, color: XdrColors.textBody),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: XdrColors.ice.withValues(alpha: 0.12),
                            ),
                            child: Text(
                              _kindBadge,
                              style: XdrType.label(size: 9, color: XdrColors.ice),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _relative(item.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: XdrType.thai(size: 9.5, color: XdrColors.textMuted),
                            ),
                          ),
                          if (showFavouriteCount)
                            Text(
                              '♥ ${item.favoritesCount}',
                              style: XdrType.latin(size: 10, color: XdrColors.danger),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (onToggleFavourite != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: PressSink(
                    radius: 999,
                    depth: 1.5,
                    onTap: onToggleFavourite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: XdrColors.inkwell.withValues(alpha: 0.55),
                      ),
                      child: Icon(
                        item.isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: item.isFavorited ? XdrColors.danger : Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relative(DateTime? at) {
    if (at == null) return '';
    final delta = DateTime.now().difference(at);
    if (delta.inMinutes < 1) return 'เมื่อครู่นี้';
    if (delta.inMinutes < 60) return '${delta.inMinutes} นาทีที่แล้ว';
    if (delta.inHours < 24) return '${delta.inHours} ชม.ที่แล้ว';
    if (delta.inDays < 30) return '${delta.inDays} วันที่แล้ว';
    return '${at.day}/${at.month}/${at.year + 543}'; // Buddhist era, as in the web app
  }
}

class _DeletedPlaceholder extends StatelessWidget {
  const _DeletedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: XdrColors.wellFill,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_delete_outlined, size: 20, color: XdrColors.textDim),
            const SizedBox(height: 6),
            Text('ไฟล์หมดอายุแล้ว', style: XdrType.thai(size: 10, color: XdrColors.textDim)),
          ],
        ),
      ),
    );
  }
}
