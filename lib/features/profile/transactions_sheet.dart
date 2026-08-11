import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../data/models/generation.dart';
import '../../state/providers.dart';
import '../shell/app_shell.dart';

/// Every credit movement on this account, newest first.
Future<void> showTransactionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB8030612),
    isScrollControlled: true,
    builder: (sheetContext) => const _TransactionsSheet(),
  );
}

class _TransactionsSheet extends ConsumerWidget {
  const _TransactionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(creditHistoryProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
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
              Text(
                'ประวัติธุรกรรม',
                style: XdrType.thai(
                  size: 16,
                  weight: FontWeight.w500,
                  color: XdrColors.textPrimary,
                ).copyWith(shadows: engraved),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: history.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: XdrColors.ice),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorPanel(
                      message: '$error',
                      onRetry: () => ref.invalidate(creditHistoryProvider),
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                          child: Text(
                            'ยังไม่มีรายการ',
                            textAlign: TextAlign.center,
                            style: XdrType.thai(size: 13, color: XdrColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            MediaQuery.paddingOf(context).bottom + 20,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(color: Color(0x0DFFFFFF)),
                          itemBuilder: (context, i) => _TransactionRow(item: items[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});

  final CreditTransaction item;

  static const _labels = {
    'purchase': 'ซื้อเครดิต',
    'usage': 'ใช้สร้างผลงาน',
    'refund': 'คืนเครดิต',
    'bonus': 'โบนัส',
    'admin_adjust': 'ปรับโดยผู้ดูแล',
  };

  @override
  Widget build(BuildContext context) {
    final positive = item.isCredit;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description ?? _labels[item.type] ?? item.type,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: XdrType.thai(size: 12.5, color: XdrColors.textBody),
                ),
                const SizedBox(height: 2),
                Text(
                  _stamp(item.createdAt),
                  style: XdrType.thai(size: 10.5, color: XdrColors.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${positive ? '+' : ''}${groupDigits(item.amount)} ✦',
                style: XdrType.latin(
                  size: 13,
                  weight: FontWeight.w700,
                  color: positive ? XdrColors.mint : XdrColors.textBody,
                ),
              ),
              Text(
                'คงเหลือ ${groupDigits(item.balanceAfter)}',
                style: XdrType.latin(size: 10, color: XdrColors.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _stamp(DateTime? at) {
    if (at == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year + 543} ${two(at.hour)}:${two(at.minute)}';
  }
}
