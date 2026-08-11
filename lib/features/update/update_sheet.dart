import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/press.dart';
import '../../data/models/update_info.dart';
import '../../data/repositories/update_repository.dart';
import '../../state/update_controller.dart';

/// Open the updater. From the profile menu this is dismissible; a mandatory
/// update opens it with [dismissible] false and no way past it.
Future<void> showUpdateSheet(BuildContext context, WidgetRef ref, {bool? dismissible}) async {
  final status = await ref.read(updateStatusProvider.future);

  if (!context.mounted) return;

  if (status is! UpdateAvailable) {
    showXdrToast(context, 'ใช้เวอร์ชันล่าสุดอยู่แล้ว');
    return;
  }

  final canDismiss = dismissible ?? !status.mandatory;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xD1030612),
    isScrollControlled: true,
    isDismissible: canDismiss,
    enableDrag: canDismiss,
    builder: (sheetContext) => PopScope(
      canPop: canDismiss,
      child: _UpdateSheet(status: status, dismissible: canDismiss),
    ),
  );
}

class _UpdateSheet extends ConsumerStatefulWidget {
  const _UpdateSheet({required this.status, required this.dismissible});

  final UpdateAvailable status;
  final bool dismissible;

  @override
  ConsumerState<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends ConsumerState<_UpdateSheet> {
  StreamSubscription<DownloadProgress>? _download;
  DownloadProgress? _progress;
  String? _error;
  bool _done = false;

  UpdateInfo get _info => widget.status.info;

  @override
  void dispose() {
    // Closing the sheet cancels the transfer — the stream cancels its own
    // request, so no download outlives the screen that started it.
    _download?.cancel();
    super.dispose();
  }

  void _start() {
    if (_download != null) return; // guards a double tap on "อัปเดตเลย"

    setState(() {
      _error = null;
      _progress = const DownloadProgress(received: 0, total: 0);
    });

    _download = ref
        .read(updateRepositoryProvider)
        .downloadAndInstall(_info)
        .listen(
          (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _error = ApiException.from(error).message;
              _progress = null;
              _download = null;
            });
          },
          onDone: () {
            if (!mounted) return;
            // The system installer is now in front of the user; the sheet stays so
            // they can retry if they dismiss it.
            setState(() {
              _done = true;
              _download = null;
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final downloading = _progress != null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.paddingOf(context).bottom + 20),
          decoration: const BoxDecoration(
            color: Color(0xF70B1020),
            border: Border(top: BorderSide(color: XdrColors.hairlineStrong)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.dismissible)
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
              Row(
                children: [
                  const Icon(Icons.system_update_alt_rounded, size: 20, color: XdrColors.ice),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.status.mandatory ? 'ต้องอัปเดตก่อนใช้งาน' : 'มีเวอร์ชันใหม่',
                      style: XdrType.thai(
                        size: 16,
                        weight: FontWeight.w600,
                        color: XdrColors.textPrimary,
                      ).copyWith(shadows: engraved),
                    ),
                  ),
                  Text(
                    'v${_info.version}',
                    style: XdrType.latin(size: 12, weight: FontWeight.w600, color: XdrColors.ice),
                  ),
                ],
              ),
              if (_info.sizeLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'ขนาดไฟล์ ${_info.sizeLabel}'
                  '${_info.sha256 != null ? ' · ตรวจสอบความถูกต้องด้วย SHA-256' : ''}',
                  style: XdrType.thai(size: 11, color: XdrColors.textDim),
                ),
              ],

              if (_info.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.28),
                  child: MetalSurface(
                    finish: MetalFinish.sunk,
                    radius: 14,
                    padding: const EdgeInsets.all(13),
                    child: SingleChildScrollView(
                      child: Text(
                        _info.releaseNotes,
                        style: XdrType.body(size: 12, color: XdrColors.textBody),
                      ),
                    ),
                  ),
                ),
              ],

              if (_error != null) ...[const SizedBox(height: 14), ErrorPanel(message: _error!)],

              if (downloading) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progress!.total > 0 ? _progress!.fraction : null,
                          minHeight: 8,
                          backgroundColor: const Color(0x0FFFFFFF),
                          valueColor: const AlwaysStoppedAnimation(XdrColors.ice),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _progress!.total > 0 ? '${_progress!.percent}%' : 'กำลังเริ่ม…',
                      style: XdrType.latin(size: 12, weight: FontWeight.w600, color: XdrColors.ice),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'กำลังดาวน์โหลด — อย่าปิดหน้านี้',
                  style: XdrType.thai(size: 11, color: XdrColors.textDim),
                ),
              ],

              const SizedBox(height: 18),
              if (_done)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ดาวน์โหลดเสร็จแล้ว — ทำตามหน้าติดตั้งของ Android ต่อได้เลย\n'
                      'ถ้าไม่มีหน้าต่างขึ้น ให้อนุญาต “ติดตั้งแอปที่ไม่รู้จัก” ให้ X-DREAMER ก่อน',
                      style: XdrType.body(size: 12, color: XdrColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    GhostButton(label: 'เปิดตัวติดตั้งอีกครั้ง', fontSize: 13, onPressed: _start),
                  ],
                )
              else
                BrandButton(
                  label: 'อัปเดตเลย',
                  icon: Icons.download_rounded,
                  busy: downloading,
                  radius: 16,
                  fontSize: 14.5,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _start,
                ),

              if (widget.dismissible && !downloading) ...[
                const SizedBox(height: 10),
                Center(
                  child: PressSink(
                    radius: 10,
                    depth: 1,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        'ไว้ทีหลัง',
                        style: XdrType.thai(size: 12.5, color: XdrColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Watches for a mandatory update and puts the sheet up as soon as one appears.
///
/// Mounted once, inside the shell, so it cannot fire on the login screen where
/// there is nothing to block yet.
class MandatoryUpdateGate extends ConsumerStatefulWidget {
  const MandatoryUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MandatoryUpdateGate> createState() => _MandatoryUpdateGateState();
}

class _MandatoryUpdateGateState extends ConsumerState<MandatoryUpdateGate> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(updateStatusProvider, (_, next) {
      final status = next.valueOrNull;
      if (_shown || status is! UpdateAvailable || !status.mandatory) return;
      _shown = true;
      // After the frame: showing a sheet during build throws.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showUpdateSheet(context, ref, dismissible: false);
      });
    });

    return widget.child;
  }
}
