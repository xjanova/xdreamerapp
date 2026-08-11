import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../core/net/media_saver.dart';
import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fiber_threads.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/press.dart';
import '../../core/widgets/result_media.dart';
import '../../data/models/generation.dart';

/// Full-screen view of one finished piece, with the things a customer wants to
/// do with it: keep it, share it, favourite it.
class WorkViewer extends ConsumerStatefulWidget {
  const WorkViewer({super.key, required this.item, this.onToggleFavourite});

  final Generation item;
  final VoidCallback? onToggleFavourite;

  static Future<void> open(
    BuildContext context, {
    required Generation item,
    VoidCallback? onToggleFavourite,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorkViewer(item: item, onToggleFavourite: onToggleFavourite),
      ),
    );
  }

  @override
  ConsumerState<WorkViewer> createState() => _WorkViewerState();
}

class _WorkViewerState extends ConsumerState<WorkViewer> {
  late String? _current = widget.item.frames.isEmpty ? null : widget.item.frames.first;
  bool _busy = false;

  /// Runs one network action at a time and owns every message it produces —
  /// the callers never touch `context` after an await, which is how a toast
  /// ends up on a disposed screen.
  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);

    String? message;
    String? failure;
    try {
      message = await action();
    } on ApiException catch (error) {
      failure = error.message;
    }

    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      showXdrToast(context, failure, isError: true);
    } else if (message != null) {
      showXdrToast(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final frames = item.frames;

    return Scaffold(
      body: XdrBackdrop(
        threads: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
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
                    const Spacer(),
                    if (item.daysLeft != null)
                      Text(
                        item.mediaDeleted ? 'ไฟล์หมดอายุแล้ว' : 'เหลืออีก ${item.daysLeft} วัน',
                        style: XdrType.thai(
                          size: 11,
                          color: item.mediaDeleted ? XdrColors.danger : XdrColors.textDim,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: item.mediaDeleted
                      ? EmptyState(
                          icon: Icons.auto_delete_outlined,
                          title: 'ไฟล์นี้ถูกลบตามนโยบายการเก็บข้อมูลแล้ว',
                          body:
                              'ระบบเก็บผลงานไว้ตามระยะเวลาที่กำหนด '
                              'ครั้งหน้าดาวน์โหลดเก็บไว้ก่อนหมดอายุได้เลย',
                        )
                      : Center(
                          child: BevelRing(
                            radius: 18,
                            child: ResultMedia(
                              url: _current,
                              isVideo: item.isVideo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                ),
              ),
              if (frames.length > 1)
                SizedBox(
                  height: 62,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    itemCount: frames.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => PressSink(
                      radius: 10,
                      depth: 2,
                      onTap: () => setState(() => _current = frames[i]),
                      child: SizedBox(
                        width: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: frames[i] == _current ? XdrColors.ice : XdrColors.hairline,
                              width: frames[i] == _current ? 1.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: RemoteArt(url: frames[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(14, 10, 14, MediaQuery.paddingOf(context).bottom + 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.prompt != null)
                      MetalSurface(
                        radius: 14,
                        padding: const EdgeInsets.all(13),
                        child: Text(
                          item.prompt!,
                          style: XdrType.body(size: 12.5, color: XdrColors.textBody),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GhostButton(
                            label: 'ดาวน์โหลด',
                            fontSize: 13,
                            onPressed: (item.mediaDeleted || _current == null)
                                ? null
                                : () => _run(
                                    () =>
                                        MediaSaver.saveToGallery(_current!, isVideo: item.isVideo),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GhostButton(
                            label: 'แชร์',
                            fontSize: 13,
                            onPressed: (item.mediaDeleted || _current == null)
                                ? null
                                : () => _run(() async {
                                    await MediaSaver.share(
                                      _current!,
                                      isVideo: item.isVideo,
                                      caption: item.prompt,
                                    );
                                    return null; // the share sheet is its own feedback
                                  }),
                          ),
                        ),
                        if (widget.onToggleFavourite != null) ...[
                          const SizedBox(width: 10),
                          PressSink(
                            radius: 16,
                            onTap: widget.onToggleFavourite,
                            child: MetalSurface(
                              finish: MetalFinish.keycap,
                              radius: 16,
                              padding: const EdgeInsets.all(15),
                              child: Icon(
                                item.isFavorited
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: item.isFavorited ? XdrColors.danger : XdrColors.textBody,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
