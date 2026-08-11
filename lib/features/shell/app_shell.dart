import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_motion.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/fiber_threads.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../data/models/catalog.dart';
import '../../routing/app_router.dart';
import '../../state/auth_controller.dart';
import '../../state/studio_controller.dart';
import '../update/update_sheet.dart';
import 'brand_mark.dart';

/// Height of the tab bar itself, above whatever gesture inset the device adds.
const kTabBarHeight = 64.0;

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final barInset = kTabBarHeight + media.padding.bottom;

    return Scaffold(
      body: MandatoryUpdateGate(
        child: XdrBackdrop(
        child: Stack(
          children: [
            Column(
              children: [
                const _TopBar(),
                Expanded(
                  // Screens read `MediaQuery.paddingOf(context).bottom` for
                  // their scroll padding, so content clears the tab bar while
                  // still scrolling underneath its blur.
                  child: MediaQuery(
                    data: media.copyWith(
                      padding: media.padding.copyWith(bottom: barInset),
                    ),
                    child: shell,
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _TabBar(shell: shell),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final credits = ref.watch(creditBalanceProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(14, MediaQuery.paddingOf(context).top + 10, 14, 8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xD9030612), Color(0x26030612)],
            ),
            border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
          ),
          child: Row(
            children: [
              const BrandMark(),
              const SizedBox(width: 9),
              Text('X-DREAMER', style: XdrType.wordmark(size: 11).copyWith(shadows: engraved)),
              const Spacer(),
              CreditPill(
                credits: credits,
                onTap: () => context.push(Routes.pricing),
              ),
              const SizedBox(width: 10),
              PressSink(
                radius: 16,
                depth: 1,
                onTap: () => context.go(Routes.profile),
                child: AvatarRing(
                  initial: session?.user.initial ?? '?',
                  imageUrl: session?.user.avatar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The credit balance, and the way to top it up.
class CreditPill extends StatelessWidget {
  const CreditPill({super.key, required this.credits, this.onTap});

  final int credits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      radius: 999,
      depth: 1.5,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: XdrColors.ice.withValues(alpha: 0.08),
          border: Border.all(color: XdrColors.ice.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 12, color: XdrColors.ice),
            const SizedBox(width: 5),
            Text(
              _grouped(credits),
              style: XdrType.latin(size: 11.5, weight: FontWeight.w600, color: XdrColors.ice),
            ),
          ],
        ),
      ),
    );
  }

  static String _grouped(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Formats a count the way every number in this app is formatted.
String groupDigits(int value) => CreditPill._grouped(value);

class _TabBar extends ConsumerWidget {
  const _TabBar({required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = <(IconData, String)>[
    (Icons.auto_fix_high_outlined, 'สตูดิโอ'),
    (Icons.grid_view_rounded, 'ผลงาน'),
    (Icons.hexagon_outlined, 'ชุมชน'),
    (Icons.person_outline_rounded, 'โปรไฟล์'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      // The FAB sits 24px proud of the bar, so the stack must not clip.
      height: kTabBarHeight + bottomInset + 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: kTabBarHeight + bottomInset,
                padding: EdgeInsets.only(bottom: bottomInset + 2),
                decoration: const BoxDecoration(
                  color: Color(0xE0030612),
                  border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++) ...[
                      Expanded(
                        child: _TabButton(
                          icon: _tabs[i].$1,
                          label: _tabs[i].$2,
                          selected: shell.currentIndex == i,
                          onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                        ),
                      ),
                      // The empty fifth column the FAB occupies.
                      if (i == 1) const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: kTabBarHeight + bottomInset - 34,
            child: _CreateFab(onTap: () => showCreateModeSheet(context, ref)),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = selected ? XdrColors.ice : XdrColors.textDim;

    return PressSink(
      radius: 12,
      depth: 1.5,
      onTap: onTap,
      child: SizedBox(
        height: kTabBarHeight - 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: colour,
              shadows: selected
                  ? [BoxShadow(color: XdrColors.ice.withValues(alpha: 0.6), blurRadius: 14)]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(label, style: XdrType.tabLabel(color: colour)),
          ],
        ),
      ),
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const PulseHalo(size: 82),
          PressSink(
            radius: 20,
            depth: 3,
            onTap: onTap,
            child: const MetalSurface(
              finish: MetalFinish.knob,
              radius: 20,
              child: SizedBox(
                width: 58,
                height: 58,
                child: Icon(Icons.auto_awesome, size: 23, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "สร้างผลงานใหม่" — pick a mode, land in the studio with it selected.
Future<void> showCreateModeSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB8030612),
    isScrollControlled: true,
    transitionAnimationController: null,
    builder: (sheetContext) => _CreateModeSheet(
      onPick: (mode) {
        ref.read(studioControllerProvider.notifier).setMode(mode);
        Navigator.of(sheetContext).pop();
        // `go` on the shell branch, not `push` — the studio is a tab, not a
        // page stacked on top of one.
        GoRouter.of(context).go(Routes.studio);
      },
    ),
  );
}

class _CreateModeSheet extends StatelessWidget {
  const _CreateModeSheet({required this.onPick});

  final ValueChanged<StudioMode> onPick;

  static const _icons = {
    StudioMode.textToImage: Icons.image_outlined,
    StudioMode.textToVideo: Icons.movie_creation_outlined,
    StudioMode.imageToVideo: Icons.animation_outlined,
    StudioMode.edit: Icons.edit_outlined,
    StudioMode.upscale: Icons.open_in_full_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14, 12, 14, MediaQuery.paddingOf(context).bottom + 20),
          decoration: const BoxDecoration(
            color: Color(0xF70B1020),
            border: Border(top: BorderSide(color: XdrColors.hairlineStrong)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'สร้างผลงานใหม่',
                style: XdrType.thai(size: 17, weight: FontWeight.w500, color: XdrColors.textPrimary)
                    .copyWith(shadows: engraved),
              ),
              const SizedBox(height: 3),
              Text('เลือกโหมดที่ต้องการ', style: XdrType.thai(size: 12, color: XdrColors.textMuted)),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: [
                  for (final mode in StudioMode.values)
                    XdrEnter(
                      delay: XdrMotion.sheet ~/ 4 * StudioMode.values.indexOf(mode),
                      child: PressSink(
                        radius: 16,
                        onTap: () => onPick(mode),
                        child: MetalSurface(
                          finish: MetalFinish.keycap,
                          radius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_icons[mode], size: 18, color: XdrColors.ice),
                              const SizedBox(height: 7),
                              Text(
                                mode.labelTh,
                                style: XdrType.thai(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: XdrColors.textPrimary,
                                ).copyWith(shadows: engraved),
                              ),
                              Text(
                                mode.labelEn,
                                style: XdrType.label(size: 9, color: XdrColors.textDim),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
