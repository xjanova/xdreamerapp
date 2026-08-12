import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/metal_field.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../data/models/catalog.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';
import '../../state/studio_controller.dart';
import 'generating_panel.dart';
import 'model_picker.dart';
import 'result_panel.dart';

const _modeIcons = {
  StudioMode.textToImage: Icons.image_outlined,
  StudioMode.textToVideo: Icons.movie_creation_outlined,
  StudioMode.imageToVideo: Icons.animation_outlined,
  StudioMode.edit: Icons.edit_outlined,
  StudioMode.upscale: Icons.open_in_full_rounded,
};

class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  late final TextEditingController _prompt;

  @override
  void initState() {
    super.initState();
    // Seeded from the controller so a mode picked from the FAB sheet, or a
    // return from another tab, does not wipe what was typed.
    _prompt = TextEditingController(text: ref.read(studioControllerProvider).prompt)
      ..addListener(_onPromptChanged);
  }

  void _onPromptChanged() => ref.read(studioControllerProvider.notifier).setPrompt(_prompt.text);

  @override
  void dispose() {
    _prompt
      ..removeListener(_onPromptChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studioControllerProvider);
    final controller = ref.read(studioControllerProvider.notifier);
    final modelsAsync = ref.watch(modelsProvider);
    final models = modelsAsync.valueOrNull ?? const <AiModelInfo>[];
    final model = controller.resolveModel(models);
    final credits = ref.watch(creditBalanceProvider);

    return RefreshIndicator(
      color: XdrColors.ice,
      backgroundColor: XdrColors.wellFill,
      onRefresh: () async {
        ref.invalidate(modelsProvider);
        ref.invalidate(stylesProvider);
        await ref.read(authControllerProvider.notifier).refreshCredits();
      },
      child: XdrEnter(
        child: ListView(
          padding: EdgeInsets.fromLTRB(14, 14, 14, MediaQuery.paddingOf(context).bottom + 20),
          children: [
            _ModeRail(selected: state.mode, models: models, onSelect: controller.setMode),
            const SizedBox(height: 14),

            _PromptCard(
              controller: _prompt,
              state: state,
              onPickImage: controller.pickInputImage,
              onClearImage: controller.clearInputImage,
            ),
            const SizedBox(height: 14),

            _ModelRow(
              model: model,
              loading: modelsAsync.isLoading,
              cost: controller.costFor(model),
              onTap: models.isEmpty
                  ? null
                  : () => showModelPicker(
                      context: context,
                      models: models,
                      mode: state.mode,
                      selectedId: model?.id,
                      onSelect: controller.setModel,
                    ),
            ),
            const SizedBox(height: 14),

            const _StyleRail(),
            const SizedBox(height: 14),

            _AspectAndCount(state: state, controller: controller, model: model),
            const SizedBox(height: 16),

            if (state.error != null) ...[
              ErrorPanel(message: state.error!),
              const SizedBox(height: 14),
            ],

            switch (state.phase) {
              StudioPhase.generating => GeneratingPanel(
                state: state,
                model: model,
                onDetach: controller.detach,
              ),
              StudioPhase.result => ResultPanel(state: state, model: model),
              StudioPhase.idle => BrandButton(
                label: 'สร้างผลงาน · Generate',
                icon: Icons.auto_awesome,
                busy: state.submitting,
                onPressed: () => controller.generate(model: model, availableCredits: credits),
              ),
            },

            if (state.phase == StudioPhase.result) ...[
              const SizedBox(height: 14),
              BrandButton(
                label: 'สร้างอีกครั้ง · Generate',
                icon: Icons.auto_awesome,
                busy: state.submitting,
                onPressed: () => controller.regenerate(model: model, availableCredits: credits),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Mode rail ───────────────────────────────────────────────────────────────

class _ModeRail extends StatelessWidget {
  const _ModeRail({required this.selected, required this.models, required this.onSelect});

  final StudioMode selected;
  final List<AiModelInfo> models;
  final ValueChanged<StudioMode> onSelect;

  /// The cheapest orderable model for a mode — what the chip advertises.
  int? _priceFor(StudioMode mode) {
    final prices = models
        .where((m) => m.servesMode(mode) && m.canOrder)
        .map((m) => m.creditsPerUnit)
        .toList();
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Bleeds to the screen edges so the rail reads as scrollable.
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: StudioMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final mode = StudioMode.values[i];
          final active = mode == selected;
          final price = _priceFor(mode);

          return PressSink(
            radius: 14,
            onTap: () => onSelect(mode),
            child: MetalSurface(
              finish: active ? MetalFinish.anodized : MetalFinish.keycap,
              radius: 14,
              borderColor: active ? XdrColors.ice.withValues(alpha: 0.42) : null,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    _modeIcons[mode],
                    size: 15,
                    color: active ? Colors.white : XdrColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.labelTh,
                        style: XdrType.thai(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: active ? Colors.white : XdrColors.textMuted,
                        ).copyWith(shadows: engraved),
                      ),
                      Text(
                        price == null ? mode.labelEn : '${mode.labelEn} · $price ✦',
                        style: XdrType.label(
                          size: 9,
                          color: (active ? Colors.white : XdrColors.textDim).withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Prompt ──────────────────────────────────────────────────────────────────

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.controller,
    required this.state,
    required this.onPickImage,
    required this.onClearImage,
  });

  static const maxPromptLength = 2000;

  final TextEditingController controller;
  final StudioState state;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    return MetalSurface(
      radius: 20,
      brushed: true,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROMPT', style: XdrType.label(size: 10.5, color: XdrColors.ice)),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => Text(
                  '${value.text.length}/$maxPromptLength',
                  style: XdrType.latin(size: 10.5, color: XdrColors.textDim),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MetalField(
            controller: controller,
            maxLines: 5,
            minLines: 3,
            maxLength: maxPromptLength,
            hint: state.mode == StudioMode.upscale
                ? 'อธิบายเพิ่มเติมได้ (ไม่บังคับสำหรับอัปสเกล)'
                : 'แสงนีออนสีม่วงสาดผ่านสายฝนในซอยเยาวราช ยามค่ำคืน — cinematic wide shot, 85mm, volumetric light',
            textStyle: XdrType.thai(size: 14.5, height: 1.62, color: XdrColors.textBody),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              if (state.hasInputImage)
                Expanded(
                  child: PressSink(
                    radius: 11,
                    onTap: onClearImage,
                    child: MetalSurface(
                      finish: MetalFinish.keycap,
                      radius: 11,
                      dropShadows: false,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 14, color: XdrColors.mint),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              state.inputImageName ?? 'ภาพอ้างอิง',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: XdrType.thai(size: 11.5, color: XdrColors.textBody),
                            ),
                          ),
                          const Icon(Icons.close_rounded, size: 14, color: XdrColors.textDim),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: PressSink(
                    radius: 11,
                    onTap: onPickImage,
                    child: MetalSurface(
                      finish: MetalFinish.keycap,
                      radius: 11,
                      dropShadows: false,
                      borderColor: state.mode.needsInputImage
                          ? XdrColors.ice.withValues(alpha: 0.35)
                          : null,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 14,
                            color: XdrColors.ice,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            state.mode.needsInputImage ? 'เลือกภาพต้นฉบับ' : 'อ้างอิงภาพ',
                            style: XdrType.thai(size: 11.5, color: XdrColors.textBody),
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
    );
  }
}

// ── Model ───────────────────────────────────────────────────────────────────

class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.model,
    required this.loading,
    required this.cost,
    required this.onTap,
  });

  final AiModelInfo? model;
  final bool loading;
  final int cost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      radius: 18,
      onTap: onTap,
      child: MetalSurface(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            BevelRing(
              radius: 12,
              thickness: 1.5,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      XdrColors.emerald.withValues(alpha: 0.25),
                      XdrColors.violet.withValues(alpha: 0.30),
                    ],
                  ),
                ),
                child: const Icon(Icons.blur_on_rounded, size: 16, color: XdrColors.ice),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading ? 'กำลังโหลดโมเดล…' : (model?.name ?? 'ยังไม่มีโมเดลสำหรับโหมดนี้'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: XdrType.thai(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: XdrColors.textPrimary,
                    ).copyWith(shadows: engraved),
                  ),
                  if (model != null)
                    Text(
                      '${model!.providerName} · ${model!.etaLabel}',
                      style: XdrType.thai(size: 10.5, color: XdrColors.textMuted),
                    ),
                ],
              ),
            ),
            if (model != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: XdrColors.ice.withValues(alpha: 0.10),
                  border: Border.all(color: XdrColors.ice.withValues(alpha: 0.24)),
                ),
                child: Text(
                  '$cost ✦',
                  style: XdrType.latin(size: 11, weight: FontWeight.w600, color: XdrColors.ice),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, size: 18, color: XdrColors.textDim),
          ],
        ),
      ),
    );
  }
}

// ── Styles ──────────────────────────────────────────────────────────────────

class _StyleRail extends ConsumerWidget {
  const _StyleRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styles = ref.watch(stylesProvider);
    final selected = ref.watch(studioControllerProvider.select((s) => s.styleId));
    final controller = ref.read(studioControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STYLE PRESET', style: XdrType.label(size: 10.5)),
        const SizedBox(height: 9),
        SizedBox(
          height: 34,
          child: styles.when(
            loading: () => const Row(
              children: [
                SizedBox(width: 96, child: ShimmerTile(radius: 999)),
                SizedBox(width: 8),
                SizedBox(width: 80, child: ShimmerTile(radius: 999, index: 1)),
              ],
            ),
            error: (_, __) =>
                Text('โหลดสไตล์ไม่สำเร็จ', style: XdrType.thai(size: 12, color: XdrColors.textDim)),
            data: (list) => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, i) {
                // Index 0 is "ไม่ใช้สไตล์" — the API treats a null styleId as
                // "append nothing", and the customer needs a way back to it.
                final style = i == 0 ? null : list[i - 1];
                final active = selected == style?.id;

                return _StylePill(
                  label: style?.name ?? 'ไม่ใช้สไตล์',
                  active: active,
                  onTap: () => controller.setStyle(style?.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StylePill extends StatelessWidget {
  const _StylePill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      radius: 999,
      depth: 2,
      onTap: onTap,
      child: MetalSurface(
        finish: active ? MetalFinish.anodized : MetalFinish.keycap,
        radius: 999,
        dropShadows: false,
        borderColor: active ? XdrColors.ice.withValues(alpha: 0.40) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Center(
          child: Text(
            label,
            style: XdrType.thai(
              size: 12,
              weight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? XdrColors.ice : XdrColors.textMuted,
            ).copyWith(shadows: engraved),
          ),
        ),
      ),
    );
  }
}

// ── Aspect + batch ──────────────────────────────────────────────────────────

/// Clip lengths offered, before the model's own ceiling is applied.
const _videoDurations = [5, 10, 15, 20];

class _AspectAndCount extends StatelessWidget {
  const _AspectAndCount({required this.state, required this.controller, required this.model});

  final StudioState state;
  final StudioController controller;
  final AiModelInfo? model;

  @override
  Widget build(BuildContext context) {
    // A video render produces one clip; offering "×4" would quietly quadruple
    // the price for something the providers do not batch. The slot is worth
    // more as the clip length, which is the choice a video actually has.
    final isVideo = state.mode.producesVideo;

    final maxDuration = model?.maxDuration ?? 10;
    final durations = _videoDurations.where((d) => d <= maxDuration).toList();
    final durationChoices = durations.isEmpty ? [_videoDurations.first] : durations;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: MetalSurface(
            radius: 18,
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASPECT', style: XdrType.label(size: 9.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final aspect in StudioAspect.values) ...[
                      Expanded(
                        child: _AspectChoice(
                          aspect: aspect,
                          active: state.aspect == aspect,
                          onTap: () => controller.setAspect(aspect),
                        ),
                      ),
                      if (aspect != StudioAspect.values.last) const SizedBox(width: 5),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: MetalSurface(
            radius: 18,
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isVideo ? 'LENGTH' : 'BATCH', style: XdrType.label(size: 9.5)),
                const SizedBox(height: 10),
                if (isVideo)
                  Row(
                    children: [
                      for (final seconds in durationChoices) ...[
                        Expanded(
                          child: _CountChoice(
                            label: '${seconds}s',
                            active: state.duration == seconds,
                            onTap: () =>
                                controller.setDuration(seconds, maxDuration: model?.maxDuration),
                          ),
                        ),
                        if (seconds != durationChoices.last) const SizedBox(width: 5),
                      ],
                    ],
                  )
                else
                  Row(
                    children: [
                      for (var n = 1; n <= 4; n++) ...[
                        Expanded(
                          child: _CountChoice(
                            label: '$n',
                            active: state.batch == n,
                            onTap: () => controller.setBatch(n),
                          ),
                        ),
                        if (n < 4) const SizedBox(width: 5),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AspectChoice extends StatelessWidget {
  const _AspectChoice({required this.aspect, required this.active, required this.onTap});

  final StudioAspect aspect;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = active ? XdrColors.ice : XdrColors.textDim;

    return PressSink(
      radius: 11,
      depth: 2,
      onTap: onTap,
      child: MetalSurface(
        finish: active ? MetalFinish.sunk : MetalFinish.keycap,
        radius: 11,
        dropShadows: false,
        borderColor: active ? XdrColors.ice.withValues(alpha: 0.40) : null,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            SizedBox(
              height: 19,
              child: Center(
                child: Container(
                  width: aspect.swatchW,
                  height: aspect.swatchH,
                  decoration: BoxDecoration(
                    border: Border.all(color: tint, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(aspect.label, style: XdrType.latin(size: 9, color: tint)),
          ],
        ),
      ),
    );
  }
}

/// One cell of the batch-count or clip-length group.
class _CountChoice extends StatelessWidget {
  const _CountChoice({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      radius: 11,
      depth: 2,
      onTap: onTap,
      child: MetalSurface(
        finish: active ? MetalFinish.sunk : MetalFinish.keycap,
        radius: 11,
        dropShadows: false,
        borderColor: active ? XdrColors.ice.withValues(alpha: 0.40) : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            label,
            style: XdrType.latin(
              size: 13,
              weight: FontWeight.w600,
              color: active ? XdrColors.ice : XdrColors.textMuted,
            ).copyWith(shadows: engraved),
          ),
        ),
      ),
    );
  }
}
