import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/motion.dart';
import '../../routing/app_router.dart';
import '../../state/prefs.dart';
import '../shell/brand_mark.dart';

class _Slide {
  const _Slide({
    required this.art,
    required this.headline,
    required this.accent,
    required this.sub,
  });

  final String art;
  final String headline;

  /// The second line — lighter, italic, gradient-masked.
  final String accent;
  final String sub;
}

const _slides = <_Slide>[
  _Slide(
    art: 'assets/showcase/hero-reel.jpg',
    headline: 'ทอความฝันจาก',
    accent: 'เส้นใยแห่งความคิด',
    sub:
        'Weave your dreams from threads of thought.\n'
        '9 providers · 40+ models · image, video, edit, upscale.',
  ),
  _Slide(
    art: 'assets/showcase/city.jpg',
    headline: 'ห้าโหมด',
    accent: 'ในสตูดิโอเดียว',
    sub:
        'ภาพ · วิดีโอ · ภาพ→วิดีโอ · แก้ไข · อัปสเกล 4K\n'
        'เลือกโมเดลที่เหมาะกับงาน ระบบจัดคิวและสลับผู้ให้บริการให้เอง',
  ),
  _Slide(
    art: 'assets/showcase/pricing-hero.jpg',
    headline: 'จ่ายเท่าที่ใช้',
    accent: 'ไม่มีรายเดือน',
    sub:
        'เติมเครดิตครั้งเดียว ใช้ได้กับทุกโมเดล\n'
        'ใช้บัญชีเดียวกับ xman4289.com ผลงานอยู่ที่เดิมทุกเครื่อง',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _toLogin({bool register = false}) async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();

    if (register) {
      // There is no signup endpoint on the AI side — `users` belongs to
      // xmanstudio, so registration happens there and the customer comes back
      // to sign in.
      await launchUrl(AppConfig.registerUrl, mode: LaunchMode.externalApplication);
    }
    if (!mounted) return;
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The artwork crossfades under the copy rather than sliding with it —
          // the panel stays put and only the world behind it changes.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            child: Image.asset(
              _slides[_index].art,
              key: ValueKey(_index),
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.55),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x59030612), Color(0xBF030612), XdrColors.base],
                  stops: [0.0, 0.45, 0.88],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _SlideBody(slide: _slides[i], isFirst: i == 0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 34),
                  child: Column(
                    children: [
                      _PagerDots(count: _slides.length, active: _index),
                      const SizedBox(height: 18),
                      BrandButton(
                        label: 'เริ่มสร้างฟรี · Start free',
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        radius: 16,
                        fontSize: 15,
                        onPressed: () => _toLogin(register: true),
                      ),
                      const SizedBox(height: 10),
                      GhostButton(label: 'มีบัญชีแล้ว · Sign in', onPressed: _toLogin),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideBody extends StatelessWidget {
  const _SlideBody({required this.slide, required this.isFirst});

  final _Slide slide;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirst) ...[
            const FloatBob(child: BrandMark(size: 96, radius: 26, glow: 30)),
            const SizedBox(height: 16),
          ],
          Text('X-DREAMER', style: XdrType.wordmark(size: 15).copyWith(shadows: engraved)),
          const SizedBox(height: 14),
          Text(slide.headline, style: XdrType.hero),
          GradientText(slide.accent, style: XdrType.heroAccent),
          const SizedBox(height: 12),
          Text(
            slide.sub,
            style: XdrType.body(size: 13, color: XdrColors.textBody.withValues(alpha: 0.66)),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _PagerDots extends StatelessWidget {
  const _PagerDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 22 : 7,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: i == active
                  ? const LinearGradient(colors: [XdrColors.cyan, XdrColors.violet])
                  : null,
              color: i == active ? null : Colors.white.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }
}
