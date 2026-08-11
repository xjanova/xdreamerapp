import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/net/api_exception.dart';
import '../../core/net/media_saver.dart';
import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../core/widgets/result_media.dart';
import '../../data/models/catalog.dart';
import '../../routing/app_router.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';
import '../../state/studio_controller.dart';

class ResultPanel extends ConsumerStatefulWidget {
  const ResultPanel({super.key, required this.state, required this.model});

  final StudioState state;
  final AiModelInfo? model;

  @override
  ConsumerState<ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends ConsumerState<ResultPanel> {
  /// One flag for every action that hits the network, so a double tap on
  /// "ดาวน์โหลด" cannot start two downloads.
  bool _busy = false;
  bool _favourited = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) showXdrToast(context, error.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? get _current => widget.state.selectedFrame;

  bool get _isVideo => widget.state.job?.isVideo ?? false;

  Future<void> _download() => _run(() async {
        final url = _current;
        if (url == null) return;
        final message = await MediaSaver.saveToGallery(url, isVideo: _isVideo);
        if (mounted) showXdrToast(context, message);
      });

  Future<void> _share() => _run(() async {
        final url = _current;
        if (url == null) return;
        await MediaSaver.share(url, isVideo: _isVideo, caption: widget.state.prompt.trim());
      });

  Future<void> _favourite() => _run(() async {
        final job = widget.state.job;
        if (job == null) return;
        await ref.read(galleryRepositoryProvider).favourite(job.id);
        if (!mounted) return;
        setState(() => _favourited = true);
        showXdrToast(context, 'บันทึกไว้ในผลงานที่ชื่นชอบแล้ว');
      });

  Future<void> _upscale() => _run(() async {
        final job = widget.state.job;
        if (job == null) return;
        final result = await ref.read(generationRepositoryProvider).upscale(generationId: job.id);
        await ref.read(authControllerProvider.notifier).refreshCredits();
        if (!mounted) return;
        showXdrToast(
          context,
          result.succeeded
              ? 'อัปสเกลเสร็จแล้ว ดูได้ที่ผลงานของฉัน'
              : 'ส่งงานอัปสเกลแล้ว จะปรากฏที่ผลงานของฉันเมื่อเสร็จ',
        );
      });

  @override
  Widget build(BuildContext context) {
    final job = widget.state.job;
    final frames = job?.frames ?? const <String>[];
    final aspect = widget.state.aspect;

    return XdrEnter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ผลลัพธ์ · ${frames.length} เฟรม'
                '${job?.durationLabel.isNotEmpty == true ? ' · ${job!.durationLabel}' : ''}',
                style: XdrType.thai(size: 13.5, color: XdrColors.textBody),
              ),
              const Spacer(),
              PressSink(
                radius: 8,
                depth: 1,
                onTap: ref.read(studioControllerProvider.notifier).clearResult,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('ล้าง', style: XdrType.thai(size: 11.5, color: XdrColors.ice)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Retention: results are swept on a schedule. Say so here, where the
          // customer can still act on it, rather than after the file is gone.
          if (job?.daysLeft != null && job!.daysLeft! <= 7) ...[
            _RetentionNotice(daysLeft: job.daysLeft!),
            const SizedBox(height: 10),
          ],

          BevelRing(
            radius: 20,
            thickness: 2,
            child: AspectRatio(
              aspectRatio: aspect.w / aspect.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ResultMedia(url: _current, isVideo: _isVideo),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: XdrColors.inkwell.withValues(alpha: 0.65),
                        border: Border.all(color: XdrColors.ice.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        () {
                          final (w, h) = aspect.sizeFor(widget.model);
                          return '$w × $h';
                        }(),
                        style: XdrType.label(size: 10, color: XdrColors.ice),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (frames.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 74,
              child: Row(
                children: [
                  for (final url in frames) ...[
                    Expanded(
                      child: PressSink(
                        radius: 11,
                        depth: 2,
                        onTap: () =>
                            ref.read(studioControllerProvider.notifier).selectFrame(url),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: url == _current
                                  ? XdrColors.ice
                                  : XdrColors.hairline,
                              width: url == _current ? 1.5 : 1,
                            ),
                            boxShadow: url == _current
                                ? [
                                    BoxShadow(
                                      color: XdrColors.ice.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                    )
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: RemoteArt(url: url),
                          ),
                        ),
                      ),
                    ),
                    if (url != frames.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              _ResultAction(
                icon: Icons.download_rounded,
                label: 'ดาวน์โหลด',
                busy: _busy,
                onTap: _download,
              ),
              _ResultAction(
                icon: _favourited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: 'บันทึก',
                tint: _favourited ? XdrColors.danger : null,
                busy: _busy,
                onTap: _favourited ? null : _favourite,
              ),
              _ResultAction(
                icon: Icons.ios_share_rounded,
                label: 'แชร์',
                busy: _busy,
                onTap: _share,
              ),
              _ResultAction(
                icon: Icons.open_in_full_rounded,
                label: 'อัปสเกล',
                busy: _busy,
                // Upscaling runs the image back through an edit model; there is
                // nothing to feed it for a video result.
                onTap: _isVideo ? null : _upscale,
              ),
              _ResultAction(
                icon: Icons.collections_outlined,
                label: 'ผลงาน',
                busy: false,
                onTap: () => context.go(Routes.works),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultAction extends StatelessWidget {
  const _ResultAction({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: PressSink(
            radius: 14,
            onTap: enabled ? onTap : null,
            child: MetalSurface(
              finish: MetalFinish.keycap,
              radius: 14,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
              child: Column(
                children: [
                  Icon(icon, size: 16, color: tint ?? XdrColors.ice),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: XdrType.thai(size: 9.5, color: XdrColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RetentionNotice extends StatelessWidget {
  const _RetentionNotice({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    return MetalSurface(
      radius: 12,
      dropShadows: false,
      borderColor: XdrColors.lilac.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 14, color: XdrColors.lilac),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              daysLeft <= 0
                  ? 'ไฟล์นี้กำลังจะถูกลบ กรุณาดาวน์โหลดเก็บไว้'
                  : 'เก็บไฟล์นี้ไว้อีก $daysLeft วัน — ดาวน์โหลดเก็บไว้ก่อนหมดอายุ',
              style: XdrType.thai(size: 11, color: XdrColors.lilac),
            ),
          ),
        ],
      ),
    );
  }
}
