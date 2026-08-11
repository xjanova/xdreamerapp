import '../models/json_ext.dart';

/// A release of the Android app, as described by `GET /api/mobile/app-version`.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.minSupportedVersion,
    required this.releaseNotes,
    required this.apkUrl,
    required this.apkSizeBytes,
    this.sha256,
    this.publishedAt,
    this.proxied = false,
  });

  final String version;

  /// Builds older than this must update before they can be used.
  final String minSupportedVersion;
  final String releaseNotes;

  /// Either GitHub's CDN URL, or a path on the API when the repo is private.
  final String apkUrl;
  final int apkSizeBytes;

  /// Published by the release workflow in `SHA256SUMS.txt`. Null when the
  /// workflow did not upload one.
  final String? sha256;
  final DateTime? publishedAt;
  final bool proxied;

  String get sizeLabel {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        version: json.str('latestVersion', '0.0.0'),
        minSupportedVersion: json.str('minSupportedVersion', '0.0.0'),
        releaseNotes: json.str('releaseNotes'),
        apkUrl: json.str('apkUrl'),
        apkSizeBytes: json.intVal('apkSizeBytes'),
        sha256: json.strOrNull('sha256'),
        publishedAt: json.date('publishedAt'),
        proxied: json.flag('proxied'),
      );
}

/// Compare two dotted version strings.
///
/// Returns -1 when [a] is older, 0 when equal, 1 when newer. Any pre-release
/// suffix (`1.2.0-beta.1`) is dropped before comparing, so a beta and its
/// release read as the same version — which is what we want: shipping
/// `1.2.0` must not tell a `1.2.0-beta.1` user they are up to date, but the
/// build number in the tag is what actually distinguishes them, and the app
/// only ever installs tagged releases.
int compareVersions(String a, String b) {
  List<int> parts(String value) => value
      .split('-')
      .first
      .split('.')
      .map((segment) => int.tryParse(segment.trim()) ?? 0)
      .toList();

  final left = parts(a);
  final right = parts(b);
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}
