import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fiber_threads.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../data/models/catalog.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';
import '../shell/app_shell.dart';

enum _Currency { thb, usd }

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> with WidgetsBindingObserver {
  _Currency _currency = _Currency.thb;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Checkout happens in the browser and lands back here. The webhook has
    // usually fired by then, so re-read the balance on return rather than
    // leaving a stale number on screen.
    if (state == AppLifecycleState.resumed) {
      ref.read(authControllerProvider.notifier).refreshCredits();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkout(CreditPackage package) async {
    final uri = AppConfig.checkoutUrl(package.slug);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      showXdrToast(context, 'เปิดหน้าชำระเงินไม่สำเร็จ กรุณาลองใหม่', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packages = ref.watch(packagesProvider);
    final models = ref.watch(modelsProvider).valueOrNull ?? const <AiModelInfo>[];

    return Scaffold(
      body: XdrBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _SheetHeader(title: 'เติมเครดิต'),
              Expanded(
                child: XdrEnter(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      0,
                      14,
                      MediaQuery.paddingOf(context).bottom + 26,
                    ),
                    children: [
                      SizedBox(
                        height: 118,
                        child: BevelRing(
                          radius: 20,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/showcase/pricing-hero.jpg',
                                fit: BoxFit.cover,
                                opacity: const AlwaysStoppedAnimation(0.30),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  child: Text(
                                    'จ่ายครั้งเดียว ใช้ได้ทุกโมเดล ไม่มีรายเดือน',
                                    textAlign: TextAlign.center,
                                    style: XdrType.thai(size: 13, color: XdrColors.textBody),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: _CurrencyToggle(
                          value: _currency,
                          onChanged: (c) => setState(() => _currency = c),
                        ),
                      ),
                      const SizedBox(height: 16),
                      packages.when(
                        loading: () => const Column(
                          children: [
                            SizedBox(height: 150, child: ShimmerTile(radius: 22)),
                            SizedBox(height: 11),
                            SizedBox(height: 150, child: ShimmerTile(radius: 22, index: 1)),
                          ],
                        ),
                        error: (error, _) => ErrorPanel(
                          message: '$error',
                          onRetry: () => ref.invalidate(packagesProvider),
                        ),
                        data: (list) => list.isEmpty
                            ? const EmptyState(
                                icon: Icons.sell_outlined,
                                title: 'ยังไม่มีแพ็กเกจเปิดขาย',
                                body: 'กรุณาลองใหม่ภายหลัง',
                              )
                            : Column(
                                children: [
                                  for (final package in list) ...[
                                    _TierCard(
                                      package: package,
                                      currency: _currency,
                                      onBuy: () => _checkout(package),
                                    ),
                                    const SizedBox(height: 11),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 10),
                      if (models.isNotEmpty) _PerGenerationTable(models: models),
                      const SizedBox(height: 14),
                      Text(
                        'ชำระเงินที่ xman4289.com — เครดิตจะเข้าบัญชีอัตโนมัติหลังชำระสำเร็จ',
                        textAlign: TextAlign.center,
                        style: XdrType.thai(size: 10.5, color: XdrColors.textDim),
                      ),
                    ],
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(title, style: XdrType.pageTitle(size: 22)),
        ],
      ),
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({required this.value, required this.onChanged});

  final _Currency value;
  final ValueChanged<_Currency> onChanged;

  @override
  Widget build(BuildContext context) {
    return MetalSurface(
      finish: MetalFinish.sunk,
      radius: 999,
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final currency in _Currency.values)
            PressSink(
              radius: 999,
              depth: 1.5,
              onTap: () => onChanged(currency),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: currency == value ? XdrColors.textRamp : null,
                ),
                child: Text(
                  currency == _Currency.thb ? 'THB' : 'USD',
                  style: XdrType.latin(
                    size: 12,
                    weight: FontWeight.w600,
                    color: currency == value ? XdrColors.inkwell : XdrColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.package, required this.currency, required this.onBuy});

  final CreditPackage package;
  final _Currency currency;
  final VoidCallback onBuy;

  String get _price => currency == _Currency.thb
      ? '฿${package.priceThb.toStringAsFixed(package.priceThb % 1 == 0 ? 0 : 2)}'
      : '\$${package.priceUsd.toStringAsFixed(package.priceUsd % 1 == 0 ? 0 : 2)}';

  @override
  Widget build(BuildContext context) {
    final popular = package.isFeatured;

    return MetalSurface(
      radius: 22,
      brushed: popular,
      borderColor: popular ? XdrColors.ice.withValues(alpha: 0.38) : null,
      glow: popular ? XdrColors.violet.withValues(alpha: 0.45) : null,
      faceOverride: popular
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                XdrColors.emerald.withValues(alpha: 0.14),
                XdrColors.violet.withValues(alpha: 0.24),
              ],
            )
          : null,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            package.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: XdrType.thai(
                              size: 15,
                              weight: FontWeight.w600,
                              color: XdrColors.textPrimary,
                            ).copyWith(shadows: engraved),
                          ),
                        ),
                        if (package.badge != null || popular) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: XdrColors.textRamp,
                            ),
                            child: Text(
                              package.badge ?? 'ยอดนิยม',
                              style: XdrType.latin(
                                size: 9.5,
                                weight: FontWeight.w700,
                                color: XdrColors.inkwell,
                                letterSpacing: 0.95,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (package.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        package.description!,
                        style: XdrType.thai(size: 11.5, color: XdrColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_price, style: XdrType.price()),
                  Text('ครั้งเดียว', style: XdrType.thai(size: 10, color: XdrColors.textDim)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                groupDigits(package.credits),
                style: XdrType.latin(size: 26, weight: FontWeight.w200, color: XdrColors.ice),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('เครดิต', style: XdrType.thai(size: 12, color: XdrColors.textBody)),
              ),
              if (package.bonusCredits > 0) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '+${groupDigits(package.bonusCredits)} โบนัส',
                    style: XdrType.thai(size: 11, color: XdrColors.mint),
                  ),
                ),
              ],
            ],
          ),
          if (package.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: XdrColors.hairline),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final feature in package.features)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Text(feature, style: XdrType.thai(size: 11, color: XdrColors.textBody)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (popular)
            BrandButton(
              label: 'เติมเลย',
              icon: Icons.auto_awesome,
              radius: 14,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(vertical: 13),
              onPressed: onBuy,
            )
          else
            GhostButton(
              label: 'เลือกแพ็กเกจนี้',
              fontSize: 13.5,
              radius: 14,
              padding: const EdgeInsets.symmetric(vertical: 13),
              onPressed: onBuy,
            ),
        ],
      ),
    );
  }
}

/// What a single generation costs, straight from `ai_models.credits_per_unit`.
class _PerGenerationTable extends StatelessWidget {
  const _PerGenerationTable({required this.models});

  final List<AiModelInfo> models;

  @override
  Widget build(BuildContext context) {
    final shown = models.where((m) => m.canOrder).toList()
      ..sort((a, b) => a.creditsPerUnit.compareTo(b.creditsPerUnit));
    final rows = shown.take(8).toList();

    return MetalSurface(
      radius: 18,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ราคาต่อการสร้าง', style: XdrType.sectionLabel('ราคาต่อการสร้าง')),
          const SizedBox(height: 10),
          for (final model in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      model.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: XdrType.thai(size: 12.5, color: XdrColors.textBody),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(switch (model.category) {
                    'video' => 'วิดีโอ',
                    'edit' => 'แก้ไข',
                    _ => 'ภาพ',
                  }, style: XdrType.thai(size: 10.5, color: XdrColors.textDim)),
                  const SizedBox(width: 12),
                  Text(
                    '${model.creditsPerUnit} ✦',
                    style: XdrType.latin(size: 12, weight: FontWeight.w600, color: XdrColors.ice),
                  ),
                ],
              ),
            ),
          if (shown.length > rows.length) ...[
            const SizedBox(height: 6),
            Text(
              'และอีก ${shown.length - rows.length} โมเดล — ดูราคาทั้งหมดได้ในตัวเลือกโมเดลที่สตูดิโอ',
              style: XdrType.thai(size: 10.5, color: XdrColors.textDim),
            ),
          ],
        ],
      ),
    );
  }
}
