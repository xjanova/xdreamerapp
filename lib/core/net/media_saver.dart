import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'api_exception.dart';

/// Getting a finished result off the platform and onto the phone.
///
/// Results live behind signed S3/R2 URLs and expire — `daysLeft` on every
/// generation exists precisely so the app can nudge a download before the file
/// is swept. These two actions are what make that possible.
abstract final class MediaSaver {
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 3),
    ),
  );

  static Future<File> _download(String url, {required bool isVideo}) async {
    final directory = await getTemporaryDirectory();
    final extension = isVideo ? 'mp4' : _imageExtension(url);
    final path = '${directory.path}/xdreamer-${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      await _dio.download(url, path);
    } catch (error) {
      throw ApiException.from(error);
    }
    return File(path);
  }

  static String _imageExtension(String url) {
    final lower = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  /// Save to the device gallery. Returns the Thai line to show on success.
  static Future<String> saveToGallery(String url, {required bool isVideo}) async {
    if (!await Gal.hasAccess()) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw ApiException('ต้องอนุญาตให้เข้าถึงคลังภาพก่อนจึงจะบันทึกได้');
      }
    }

    final file = await _download(url, isVideo: isVideo);
    try {
      if (isVideo) {
        await Gal.putVideo(file.path, album: 'X-DREAMER');
      } else {
        await Gal.putImage(file.path, album: 'X-DREAMER');
      }
      return isVideo ? 'บันทึกวิดีโอลงคลังแล้ว' : 'บันทึกภาพลงคลังแล้ว';
    } on GalException catch (error) {
      throw ApiException(switch (error.type) {
        GalExceptionType.accessDenied => 'ต้องอนุญาตให้เข้าถึงคลังภาพก่อนจึงจะบันทึกได้',
        GalExceptionType.notEnoughSpace => 'พื้นที่เก็บข้อมูลไม่พอ',
        _ => 'บันทึกไม่สำเร็จ กรุณาลองใหม่',
      });
    } finally {
      // The gallery copy is the one that matters; the temp file is not.
      if (await file.exists()) await file.delete();
    }
  }

  /// Hand the file to the system share sheet.
  static Future<void> share(String url, {required bool isVideo, String? caption}) async {
    final file = await _download(url, isVideo: isVideo);
    await Share.shareXFiles([XFile(file.path)], text: caption);
    // Left in the cache on purpose — the receiving app may still be reading it
    // when this returns, and the OS clears the temp directory itself.
  }
}
