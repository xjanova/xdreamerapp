import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../routing/app_router.dart';
import '../../state/auth_controller.dart';
import '../../state/gallery_controller.dart';
import '../../state/update_controller.dart';
import '../shell/app_shell.dart';
import '../shell/brand_mark.dart';
import '../update/update_sheet.dart';
import 'transactions_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final user = session?.user;
    final credits = session?.credits;
    final works = ref.watch(
      galleryControllerProvider((filter: GalleryFilter.all, sort: GallerySort.newest)),
    );
    final favourites = ref.watch(
      galleryControllerProvider((filter: GalleryFilter.favourites, sort: GallerySort.newest)),
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (user == null || credits == null) {
      return const Center(child: CircularProgressIndicator(color: XdrColors.ice));
    }

    final granted = credits.totalBought + credits.totalBonus;
    final usedFraction = granted == 0 ? 0.0 : (credits.totalUsed / granted).clamp(0.0, 1.0);

    return RefreshIndicator(
      color: XdrColors.ice,
      backgroundColor: XdrColors.wellFill,
      onRefresh: () => ref.read(authControllerProvider.notifier).refreshCredits(),
      child: XdrEnter(
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomInset + 20),
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/showcase/profile-banner.jpg',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.75),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x26030612), XdrColors.base],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -42),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AvatarRing(
                          initial: user.initial,
                          imageUrl: user.avatar,
                          size: 78,
                          fontSize: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: XdrType.thai(
                                    size: 18,
                                    weight: FontWeight.w500,
                                    color: XdrColors.textPrimary,
                                  ).copyWith(shadows: engraved),
                                ),
                                Text(
                                  '@${user.handle}',
                                  style: XdrType.thai(size: 11.5, color: XdrColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PressSink(
                          radius: 999,
                          depth: 2,
                          // Profile details live in xmanstudio, which owns the
                          // users table — editing them here would be writing to
                          // somebody else's schema.
                          onTap: () => launchUrl(
                            Uri.parse('${AppConfig.xmanBaseUrl}/account'),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: MetalSurface(
                            finish: MetalFinish.keycap,
                            radius: 999,
                            dropShadows: false,
                            borderColor: XdrColors.ice.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            child: Text(
                              'แก้ไข',
                              style: XdrType.thai(size: 11.5, color: XdrColors.ice),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'CREDITS',
                            value: credits.balance,
                            colour: XdrColors.ice,
                            caption: 'คงเหลือ',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'WORKS',
                            value: works.total,
                            colour: XdrColors.emerald,
                            caption: 'ผลงานทั้งหมด',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'USED',
                            value: credits.totalUsed,
                            colour: XdrColors.cyan,
                            caption: 'เครดิตที่ใช้ไป',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'BONUS',
                            value: credits.totalBonus,
                            colour: XdrColors.violet,
                            caption: 'โบนัสที่ได้รับ',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    MetalSurface(
                      radius: 18,
                      brushed: true,
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'เครดิตที่ใช้ไปแล้ว',
                                style: XdrType.thai(size: 12.5, color: XdrColors.textBody),
                              ),
                              const Spacer(),
                              Text(
                                // Lifetime, not "this month": the API exposes
                                // running totals, not a monthly window, and a
                                // made-up monthly figure would be a lie.
                                '${groupDigits(credits.totalUsed)} / ${groupDigits(granted)}',
                                style: XdrType.latin(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: XdrColors.ice,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Stack(
                              children: [
                                Container(height: 8, color: const Color(0x0FFFFFFF)),
                                LayoutBuilder(
                                  builder: (context, constraints) => Container(
                                    height: 8,
                                    width: constraints.maxWidth * usedFraction,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          XdrColors.emerald,
                                          XdrColors.cyan,
                                          XdrColors.violet,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: XdrColors.cyan.withValues(alpha: 0.7),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 13),
                          GhostButton(
                            label: 'เติมเครดิต · Top up',
                            fontSize: 13,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: () => context.push(Routes.pricing),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    MetalSurface(
                      radius: 20,
                      child: Column(
                        children: [
                          _MenuRow(
                            icon: Icons.auto_awesome,
                            label: 'แพ็กเกจเครดิต',
                            hint: 'เติมเครดิต',
                            onTap: () => context.push(Routes.pricing),
                          ),
                          _MenuRow(
                            icon: Icons.card_giftcard_rounded,
                            label: 'ชวนเพื่อน · Referral',
                            hint: 'รับเครดิตโบนัส',
                            onTap: () => context.push(Routes.referral),
                          ),
                          _MenuRow(
                            icon: Icons.favorite_border_rounded,
                            label: 'ผลงานที่บันทึกไว้',
                            hint: favourites.loading ? '' : '${favourites.total}',
                            onTap: () => context.go(Routes.works),
                          ),
                          _MenuRow(
                            icon: Icons.receipt_long_outlined,
                            label: 'ประวัติธุรกรรม',
                            onTap: () => showTransactionsSheet(context),
                          ),
                          const _UpdateMenuRow(),
                          _MenuRow(
                            icon: Icons.logout_rounded,
                            label: 'ออกจากระบบ',
                            tint: XdrColors.danger,
                            showChevron: false,
                            isLast: true,
                            onTap: () => _confirmSignOut(context, ref),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final version = ref.watch(appVersionProvider).valueOrNull;
                          return Text(
                            version == null ? '' : 'X-DREAMER v$version',
                            style: XdrType.label(size: 9.5, color: XdrColors.textDim),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: MetalSurface(
          radius: 20,
          brushed: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ออกจากระบบ?',
                style: XdrType.thai(
                  size: 16,
                  weight: FontWeight.w600,
                  color: XdrColors.textPrimary,
                ).copyWith(shadows: engraved),
              ),
              const SizedBox(height: 6),
              Text(
                'ผลงานและเครดิตยังอยู่ครบ เข้าสู่ระบบใหม่เมื่อไหร่ก็ได้',
                style: XdrType.body(size: 12.5, color: XdrColors.textMuted),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'ยกเลิก',
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GhostButton(
                      label: 'ออกจากระบบ',
                      fontSize: 13,
                      color: XdrColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.colour,
    required this.caption,
  });

  final String label;
  final int value;
  final Color colour;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return MetalSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: XdrType.label(size: 10, color: XdrColors.textMuted)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(groupDigits(value), style: XdrType.statValue(color: colour)),
          ),
          const SizedBox(height: 2),
          Text(caption, style: XdrType.thai(size: 10.5, color: XdrColors.textDim)),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.hint,
    this.onTap,
    this.tint,
    this.showChevron = true,
    this.isLast = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final Color? tint;
  final bool showChevron;
  final bool isLast;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      radius: 0,
      depth: 1.5,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tint ?? XdrColors.ice),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: XdrType.thai(size: 13.5, color: tint ?? XdrColors.textBody),
              ),
            ),
            if (trailing != null) trailing!,
            if (hint != null && hint!.isNotEmpty)
              Text(hint!, style: XdrType.thai(size: 11, color: XdrColors.textDim)),
            if (showChevron) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: XdrColors.textDim),
            ],
          ],
        ),
      ),
    );
  }
}

/// "ตรวจสอบอัปเดต", with a dot when one is waiting.
class _UpdateMenuRow extends ConsumerWidget {
  const _UpdateMenuRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updateStatusProvider);
    final available = status.valueOrNull;
    final hasUpdate = available is UpdateAvailable;

    return _MenuRow(
      icon: Icons.system_update_alt_rounded,
      label: 'ตรวจสอบอัปเดต',
      hint: hasUpdate ? 'v${available.info.version}' : null,
      trailing: hasUpdate
          ? Container(
              margin: const EdgeInsets.only(right: 8),
              width: 7,
              height: 7,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: XdrColors.mint),
            )
          : null,
      onTap: () => showUpdateSheet(context, ref),
    );
  }
}
