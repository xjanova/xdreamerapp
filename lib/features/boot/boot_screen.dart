import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fiber_threads.dart';
import '../../core/widgets/motion.dart';
import '../../state/auth_controller.dart';
import '../shell/brand_mark.dart';

/// Held while the app works out whether the stored session is still good.
///
/// If that check fails on the network rather than on the credentials, this
/// screen offers a retry instead of dropping the customer at a login form —
/// they are probably still signed in, they are just on a bad connection.
class BootScreen extends ConsumerWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final failed = auth.hasError;

    return Scaffold(
      body: XdrBackdrop(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FloatBob(child: BrandMark(size: 84, radius: 24)),
                  const SizedBox(height: 18),
                  Text('X-DREAMER', style: XdrType.wordmark(size: 13).copyWith(shadows: engraved)),
                  const SizedBox(height: 26),
                  if (failed) ...[
                    ErrorPanel(
                      message: auth.error is Exception
                          ? '${auth.error}'
                          : 'เชื่อมต่อ X-DREAMER ไม่สำเร็จ',
                      onRetry: () => ref.read(authControllerProvider.notifier).retryRestore(),
                    ),
                  ] else
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: XdrColors.ice),
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
