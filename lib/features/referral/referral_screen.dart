import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/net/api_exception.dart';
import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fiber_threads.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/metal_field.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../data/models/referral.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';
import '../shell/app_shell.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeInput = TextEditingController();
  bool _copied = false;
  bool _redeeming = false;

  @override
  void dispose() {
    _codeInput.dispose();
    super.dispose();
  }

  String _link(String code) => '${AppConfig.registerUrl}?ref=$code';

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    // Revert after 1.6s, but only if this screen is still alive.
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _redeem() async {
    if (_redeeming) return;
    final code = _codeInput.text.trim();
    if (code.isEmpty) return;

    setState(() => _redeeming = true);
    try {
      await ref.read(referralRepositoryProvider).applyCode(code);
      if (!mounted) return;
      _codeInput.clear();
      showXdrToast(context, 'ใช้รหัสสำเร็จ เครดิตโบนัสเข้าบัญชีแล้ว');
      ref.invalidate(referralStatsProvider);
      await ref.read(authControllerProvider.notifier).refreshCredits();
    } on ApiException catch (error) {
      if (mounted) showXdrToast(context, error.message, isError: true);
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(referralStatsProvider);

    return Scaffold(
      body: XdrBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 14, 10),
                child: Row(
                  children: [
                    PressSink(
                      radius: 12,
                      depth: 1.5,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_rounded, size: 20, color: XdrColors.textBody),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('ชวนเพื่อน รับเครดิต', style: XdrType.pageTitle(size: 21)),
                  ],
                ),
              ),
              Expanded(
                child: stats.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator(color: XdrColors.ice)),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(14),
                    child: ErrorPanel(
                      message: '$error',
                      onRetry: () => ref.invalidate(referralStatsProvider),
                    ),
                  ),
                  data: (data) => _Body(
                    stats: data,
                    copied: _copied,
                    redeeming: _redeeming,
                    codeInput: _codeInput,
                    onCopy: () => _copy(data.code),
                    onShare: () => Share.share(
                      'มาสร้างภาพและวิดีโอด้วย AI กับ X-DREAMER — ใช้รหัส ${data.code} '
                      'แล้วรับเครดิตเริ่มต้นเพิ่ม\n${_link(data.code)}',
                    ),
                    onRedeem: _redeem,
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

class _Body extends StatelessWidget {
  const _Body({
    required this.stats,
    required this.copied,
    required this.redeeming,
    required this.codeInput,
    required this.onCopy,
    required this.onShare,
    required this.onRedeem,
  });

  final ReferralStats stats;
  final bool copied;
  final bool redeeming;
  final TextEditingController codeInput;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return XdrEnter(
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.paddingOf(context).bottom + 26),
        children: [
          SizedBox(
            height: 104,
            child: BevelRing(
              radius: 20,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/showcase/referral-art.jpg',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.34),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'เพื่อนได้เครดิตต้อนรับ คุณได้โบนัสเมื่อเพื่อนใช้รหัส '
                        'และได้ค่าคอมมิชชั่น ${stats.commissionRate}% ทุกครั้งที่เพื่อนเติมเครดิต',
                        textAlign: TextAlign.center,
                        style: XdrType.thai(size: 12, color: XdrColors.textBody, height: 1.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          MetalSurface(
            radius: 22,
            brushed: true,
            glow: XdrColors.violet.withValues(alpha: 0.45),
            borderColor: XdrColors.hairlineStrong,
            faceOverride: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                XdrColors.emerald.withValues(alpha: 0.16),
                XdrColors.violet.withValues(alpha: 0.24),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR CODE', style: XdrType.label(size: 10.5, color: XdrColors.ice)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          stats.code.isEmpty ? '—' : stats.code,
                          style: XdrType.latin(
                            size: 26,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 3.1,
                          ).copyWith(shadows: engraved),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PressSink(
                      radius: 12,
                      onTap: stats.code.isEmpty ? null : onCopy,
                      child: MetalSurface(
                        finish: MetalFinish.keycap,
                        radius: 12,
                        dropShadows: false,
                        borderColor: copied
                            ? XdrColors.mint.withValues(alpha: 0.5)
                            : XdrColors.hairlineStrong,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Text(
                          copied ? 'คัดลอกแล้ว' : 'คัดลอก',
                          style: XdrType.thai(
                            size: 12,
                            color: copied ? XdrColors.mint : XdrColors.textBody,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        label: 'แชร์ลิงก์',
                        fontSize: 12.5,
                        radius: 12,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        onPressed: stats.code.isEmpty ? null : onShare,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GhostButton(
                        label: 'QR code',
                        fontSize: 12.5,
                        radius: 12,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        onPressed: stats.code.isEmpty ? null : () => _showQr(context, stats.code),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MiniStat(value: stats.totalReferred, label: 'เพื่อนที่ชวน'),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MiniStat(value: stats.activeFriends, label: 'เติมเครดิตแล้ว'),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MiniStat(
                  value: stats.totalCommission,
                  label: 'เครดิตที่ได้',
                  colour: XdrColors.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          MetalSurface(
            radius: 18,
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('วิธีการทำงาน', style: XdrType.sectionLabel('วิธีการทำงาน')),
                const SizedBox(height: 12),
                const _Step(
                  index: 1,
                  title: 'แชร์โค้ดของคุณ',
                  body: 'ส่งลิงก์หรือ QR ให้เพื่อนผ่านแอปไหนก็ได้',
                  colours: [XdrColors.mint, XdrColors.ice],
                ),
                const _Step(
                  index: 2,
                  title: 'เพื่อนสมัครและใส่โค้ด',
                  body: 'เพื่อนรับเครดิตโบนัสทันที (เฉพาะบัญชีใหม่ที่ยังไม่เคยซื้อ)',
                  colours: [Color(0xFF67E8F9), XdrColors.ice],
                ),
                _Step(
                  index: 3,
                  title: 'คุณได้โบนัส + คอมมิชชั่น',
                  body:
                      'รับโบนัสทันทีที่เพื่อนใช้โค้ด และอีก ${stats.commissionRate}% '
                      'ของทุกยอดที่เพื่อนเติม',
                  colours: const [XdrColors.lilac, XdrColors.ice],
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          MetalSurface(
            radius: 18,
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('มีรหัสจากเพื่อน?', style: XdrType.sectionLabel('มีรหัสจากเพื่อน?')),
                const SizedBox(height: 4),
                Text(
                  'ใช้ได้เฉพาะบัญชีใหม่ภายใน 30 วัน และยังไม่เคยซื้อเครดิต',
                  style: XdrType.thai(size: 11, color: XdrColors.textDim),
                ),
                const SizedBox(height: 11),
                MetalField(
                  controller: codeInput,
                  hint: 'เช่น K7QM2XPA',
                  enabled: !redeeming,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onRedeem(),
                  maxLength: 16,
                ),
                const SizedBox(height: 11),
                GhostButton(
                  label: redeeming ? 'กำลังตรวจสอบ…' : 'ใช้รหัสนี้',
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: redeeming ? null : onRedeem,
                ),
              ],
            ),
          ),

          if (stats.friends.isNotEmpty) ...[
            const SizedBox(height: 14),
            MetalSurface(
              radius: 18,
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เพื่อนที่ชวนมา', style: XdrType.sectionLabel('เพื่อนที่ชวนมา')),
                  const SizedBox(height: 8),
                  for (final friend in stats.friends)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              friend.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: XdrType.thai(size: 12.5, color: XdrColors.textBody),
                            ),
                          ),
                          Text(
                            '+${groupDigits(friend.totalCommission + friend.bonusCredits)} ✦',
                            style: XdrType.latin(
                              size: 12,
                              weight: FontWeight.w600,
                              color: XdrColors.mint,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showQr(BuildContext context, String code) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: MetalSurface(
          radius: 22,
          brushed: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: QrImageView(
                  data: '${AppConfig.registerUrl}?ref=$code',
                  size: 190,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                code,
                style: XdrType.latin(
                  size: 18,
                  weight: FontWeight.w800,
                  color: XdrColors.ice,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ให้เพื่อนสแกนเพื่อสมัครพร้อมรหัสของคุณ',
                style: XdrType.thai(size: 11.5, color: XdrColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label, this.colour = XdrColors.ice});

  final int value;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return MetalSurface(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(groupDigits(value), style: XdrType.statValue(size: 20, color: colour)),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: XdrType.thai(size: 10, color: XdrColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.body,
    required this.colours,
    this.isLast = false,
  });

  final int index;
  final String title;
  final String body;
  final List<Color> colours;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(colors: colours),
              boxShadow: [BoxShadow(color: colours.first.withValues(alpha: 0.45), blurRadius: 22)],
            ),
            child: Text(
              '$index',
              style: XdrType.latin(size: 13, weight: FontWeight.w700, color: XdrColors.inkwell),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: XdrType.thai(
                    size: 13,
                    weight: FontWeight.w600,
                    color: XdrColors.textPrimary,
                  ).copyWith(shadows: engraved),
                ),
                const SizedBox(height: 2),
                Text(body, style: XdrType.body(size: 11.5, color: XdrColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
