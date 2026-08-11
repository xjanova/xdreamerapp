import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';
import '../../core/net/api_exception.dart';
import '../models/update_info.dart';

class DownloadProgress {
  const DownloadProgress({required this.received, required this.total});

  final int received;
  final int total;

  double get fraction => total <= 0 ? 0 : (received / total).clamp(0.0, 1.0);
  int get percent => (fraction * 100).round();
}

/// Fetching, verifying and launching a new build of the app.
class UpdateRepository {
  UpdateRepository();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 10),
    ),
  );

  /// Ask the backend what the newest release is.
  ///
  /// Returns null both when there is no release and when the check fails —
  /// a version check is not something to interrupt anyone about.
  Future<UpdateInfo?> fetchLatest() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConfig.apiBaseUrl}/api/mobile/app-version',
      );
      final update = response.data?['update'];
      if (update is! Map) return null;

      final info = UpdateInfo.fromJson(Map<String, dynamic>.from(update));
      return info.apkUrl.isEmpty ? null : info;
    } catch (_) {
      return null;
    }
  }

  /// Download the APK and hand it to Android's installer.
  ///
  /// Emits progress; completes when the system install prompt has been opened.
  /// The caller must keep the subscription alive for the whole download — the
  /// stream cancels the request if it is dropped.
  Stream<DownloadProgress> downloadAndInstall(UpdateInfo info) async* {
    if (!Platform.isAndroid) {
      throw ApiException('การอัปเดตในแอปรองรับเฉพาะ Android');
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/xdreamer-${info.version}.apk');
    // A half-finished download from a previous attempt would fail the digest
    // check in a confusing way.
    if (await file.exists()) await file.delete();

    final cancelToken = CancelToken();
    final progress = StreamController<DownloadProgress>();

    unawaited(
      _dio
          .download(
            info.apkUrl.startsWith('http') ? info.apkUrl : '${AppConfig.apiBaseUrl}${info.apkUrl}',
            file.path,
            cancelToken: cancelToken,
            options: Options(headers: const {'Accept': 'application/vnd.android.package-archive'}),
            onReceiveProgress: (received, total) => progress.add(
              DownloadProgress(
                received: received,
                // The proxied route may not know the length up front; fall back
                // to the size the release reported.
                total: total > 0 ? total : info.apkSizeBytes,
              ),
            ),
          )
          .then<void>((_) => progress.close())
          .catchError((Object error) {
            progress.addError(ApiException.from(error));
            return progress.close();
          }),
    );

    try {
      yield* progress.stream;
    } finally {
      if (!cancelToken.isCancelled) cancelToken.cancel('update cancelled');
    }

    // ── Integrity ───────────────────────────────────────────────────────
    //
    // Android refuses to install an APK signed with a different key than the
    // installed app, so a swapped binary cannot silently replace X-DREAMER.
    // The digest check is still worth doing: it catches a truncated download
    // and refuses a tampered file before the installer is ever opened.
    final expected = info.sha256;
    if (expected != null && expected.isNotEmpty) {
      final actual = await sha256OfFile(file);
      if (actual != expected.toLowerCase()) {
        await file.delete();
        throw ApiException('ไฟล์ติดตั้งไม่ตรงกับต้นฉบับ ยกเลิกการติดตั้งเพื่อความปลอดภัย');
      }
    }

    final result = await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) {
      throw ApiException(
        'เปิดตัวติดตั้งไม่สำเร็จ — ตรวจสอบว่าอนุญาตให้ X-DREAMER ติดตั้งแอปจากแหล่งนี้แล้ว',
      );
    }
  }
}

/// Lowercase hex SHA-256 of a file, streamed so a 40MB APK is never held in
/// memory twice.
///
/// The format has to match `sha256sum` byte for byte — that is what the release
/// workflow writes into SHA256SUMS.txt and what the install is checked against.
/// Top-level and public so that rule is testable.
Future<String> sha256OfFile(File file) async {
  final output = AccumulatorSink<Digest>();
  final input = sha256.startChunkedConversion(output);
  await for (final chunk in file.openRead()) {
    input.add(chunk);
  }
  input.close();
  final digest = output.events.single;
  output.close();
  return digest.toString();
}
