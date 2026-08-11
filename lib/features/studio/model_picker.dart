import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/press.dart';
import '../../data/models/catalog.dart';

/// Pick a specific model, or hand the choice back to the app.
///
/// Models still in `tuning` are listed but not selectable — the platform shows
/// them so customers can see what is coming, and refuses the order so nobody
/// spends credits proving somebody else's GPU workflow.
Future<void> showModelPicker({
  required BuildContext context,
  required List<AiModelInfo> models,
  required StudioMode mode,
  required int? selectedId,
  required ValueChanged<int?> onSelect,
}) {
  final candidates = models.where((m) => m.servesMode(mode)).toList()
    ..sort((a, b) {
      if (a.canOrder != b.canOrder) return a.canOrder ? -1 : 1;
      if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
      return a.creditsPerUnit.compareTo(b.creditsPerUnit);
    });

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB8030612),
    isScrollControlled: true,
    builder: (sheetContext) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75),
          decoration: const BoxDecoration(
            color: Color(0xF70B1020),
            border: Border(top: BorderSide(color: XdrColors.hairlineStrong)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'เลือกโมเดล',
                      style: XdrType.thai(
                        size: 16,
                        weight: FontWeight.w500,
                        color: XdrColors.textPrimary,
                      ).copyWith(shadows: engraved),
                    ),
                    const Spacer(),
                    Text(
                      '${mode.labelTh} · ${candidates.length} โมเดล',
                      style: XdrType.thai(size: 11.5, color: XdrColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: candidates.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        child: Text(
                          'ยังไม่มีโมเดลที่เปิดใช้งานสำหรับโหมดนี้',
                          textAlign: TextAlign.center,
                          style: XdrType.thai(size: 13, color: XdrColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.fromLTRB(
                          14,
                          0,
                          14,
                          MediaQuery.paddingOf(sheetContext).bottom + 20,
                        ),
                        itemCount: candidates.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return _ModelTile(
                              title: 'เลือกให้อัตโนมัติ',
                              subtitle: 'ใช้โมเดลที่คุ้มที่สุดของโหมดนี้',
                              selected: selectedId == null,
                              onTap: () {
                                onSelect(null);
                                Navigator.of(sheetContext).pop();
                              },
                            );
                          }

                          final model = candidates[i - 1];
                          return _ModelTile(
                            title: model.name,
                            subtitle: '${model.providerName} · ${model.etaLabel}',
                            cost: model.creditsPerUnit,
                            selected: selectedId == model.id,
                            disabledReason: model.canOrder
                                ? null
                                : (model.tuningMessage ?? 'กำลังปรับแต่ง ยังใช้งานไม่ได้'),
                            onTap: model.canOrder
                                ? () {
                                    onSelect(model.id);
                                    Navigator.of(sheetContext).pop();
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.cost,
    this.disabledReason,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final int? cost;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final blocked = disabledReason != null;

    return Opacity(
      opacity: blocked ? 0.55 : 1,
      child: PressSink(
        radius: 15,
        onTap: onTap,
        child: MetalSurface(
          finish: selected ? MetalFinish.anodized : MetalFinish.keycap,
          radius: 15,
          borderColor: selected ? XdrColors.ice.withValues(alpha: 0.42) : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: XdrType.thai(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: selected ? Colors.white : XdrColors.textPrimary,
                      ).copyWith(shadows: engraved),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      disabledReason ?? subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: XdrType.thai(
                        size: 10.5,
                        color: blocked ? XdrColors.lilac : XdrColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (cost != null) ...[
                const SizedBox(width: 10),
                Text(
                  '$cost ✦',
                  style: XdrType.latin(
                    size: 12,
                    weight: FontWeight.w600,
                    color: selected ? Colors.white : XdrColors.ice,
                  ),
                ),
              ],
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_rounded, size: 17, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
