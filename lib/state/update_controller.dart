import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/models/update_info.dart';
import '../data/repositories/update_repository.dart';

sealed class UpdateStatus {
  const UpdateStatus();
}

class UpToDate extends UpdateStatus {
  const UpToDate();
}

class UpdateAvailable extends UpdateStatus {
  const UpdateAvailable({required this.info, required this.mandatory});

  final UpdateInfo info;

  /// This build is below `minSupportedVersion` — the app blocks until it is
  /// installed. Reserved for releases that fix something that makes the old
  /// build actively wrong, not for every release.
  final bool mandatory;
}

final updateRepositoryProvider = Provider<UpdateRepository>((ref) => UpdateRepository());

/// The version string of the running build, for the profile footer.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// Checked once per app start, then cached.
///
/// Never surfaces an error: a failed version check is not something to put in
/// front of somebody who just wants to make a picture.
final updateStatusProvider = FutureProvider<UpdateStatus>((ref) async {
  ref.keepAlive();

  final latest = await ref.watch(updateRepositoryProvider).fetchLatest();
  if (latest == null) return const UpToDate();

  final current = await ref.watch(appVersionProvider.future);
  if (compareVersions(current, latest.version) >= 0) return const UpToDate();

  return UpdateAvailable(
    info: latest,
    mandatory: compareVersions(current, latest.minSupportedVersion) < 0,
  );
});
