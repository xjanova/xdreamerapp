import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/motion.dart';
import '../../data/models/catalog.dart';
import '../../data/models/generation.dart';
import '../../state/studio_controller.dart';

/// What the studio shows while a job is running.
///
/// The platform reports no percentage for provider-backed jobs, so the ring is
/// an **elapsed-against-expected estimate** and is capped at 95% until the job
/// actually reports `completed`. Showing 100% on a spinning ring is the one
/// thing a progress indicator must never do.
///
/// GPU-backed jobs do report a real stage and ETA; when they do, that copy
/// takes over — it comes from the server and is more truthful than any local
/// guess.
class GeneratingPanel extends StatefulWidget {
  const GeneratingPanel({
    super.key,
    required this.state,
    required this.model,
    required this.onDetach,
  });

  final StudioState state;
  final AiModelInfo? model;
  final VoidCallback onDetach;

  @override
  State<GeneratingPanel> createState() => _GeneratingPanelState();
}

class _GeneratingPanelState extends State<GeneratingPanel> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Ticker rather than Timer.periodic: it is muted automatically when this
    // route is covered, and it dies with the State.
    _ticker = createTicker((_) {
      final startedAt = widget.state.startedAt;
      if (startedAt == null) return;
      final next = DateTime.now().difference(startedAt);
      // Four updates a second is plenty for a number that counts seconds.
      if ((next.inMilliseconds ~/ 250) != (_elapsed.inMilliseconds ~/ 250)) {
        setState(() => _elapsed = next);
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Seconds this kind of job usually takes, used only when the server has
  /// nothing better to offer.
  int get _expectedSeconds {
    final gpuEta = widget.state.job?.gpu?.etaSeconds;
    if (gpuEta != null && gpuEta > 0) return gpuEta;

    return switch (widget.model?.category) {
      'video' => 60,
      'edit' => 15,
      _ => 15,
    };
  }

  @override
  Widget build(BuildContext context) {
    final gpu = widget.state.job?.gpu;
    final fraction = (_elapsed.inMilliseconds / (_expectedSeconds * 1000)).clamp(0.0, 0.95);
    final percent = (fraction * 100).round();

    return XdrEnter(
      child: Column(
        children: [
          MetalSurface(
            radius: 22,
            brushed: true,
            glow: XdrColors.violet.withValues(alpha: 0.35),
            borderColor: XdrColors.violet.withValues(alpha: 0.28),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    SpinRing(
                      size: 52,
                      child: Text(
                        '$percent%',
                        style: XdrType.latin(
                          size: 12,
                          weight: FontWeight.w700,
                          color: XdrColors.ice,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gpu?.label ?? 'กำลังทอความฝัน…',
                            style: XdrType.thai(
                              size: 14,
                              color: XdrColors.textPrimary,
                            ).copyWith(shadows: engraved),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle(gpu),
                            style: XdrType.thai(size: 11, color: XdrColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < widget.state.batch.clamp(1, 4); i++) ShimmerTile(index: i),
                  ],
                ),
                const SizedBox(height: 14),
                GhostButton(
                  label: 'ทำงานเบื้องหลัง',
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  radius: 12,
                  onPressed: widget.onDetach,
                ),
                const SizedBox(height: 8),
                Text(
                  // Honest: there is no endpoint that stops a job once a
                  // provider has it, and the credits are already spent. Saying
                  // "ยกเลิก" here would promise a refund that never arrives.
                  'งานจะทำต่อจนเสร็จ และไปโผล่ที่ “ผลงานของฉัน”',
                  textAlign: TextAlign.center,
                  style: XdrType.thai(size: 10.5, color: XdrColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(GpuProgress? gpu) {
    final model = widget.model?.name ?? 'โมเดล';
    final seconds = _elapsed.inSeconds;

    if (gpu != null) {
      final parts = <String>[model];
      if (gpu.queuePosition != null && gpu.queuePosition! > 0) {
        parts.add('คิวที่ ${gpu.queuePosition}');
      }
      if (gpu.etaLabel != null) {
        parts.add(gpu.isRoughEstimate ? 'ประมาณ ${gpu.etaLabel}' : 'เหลือ ~${gpu.etaLabel}');
      }
      if (gpu.gpuModel != null) parts.add(gpu.gpuModel!);
      return parts.join(' · ');
    }

    final frames = widget.state.batch;
    return 'กำลังสร้าง $frames ภาพ · $model · ผ่านไป ${seconds}s';
  }
}
