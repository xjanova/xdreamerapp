import 'package:dio/dio.dart';

/// What went wrong, in the terms a screen actually branches on.
enum ApiErrorKind {
  network,
  unauthorized,
  forbidden,
  notFound,
  insufficientCredits,
  rateLimited,
  serviceUnavailable,
  modelTuning,
  badRequest,
  server,
  cancelled,
  unknown,
}

/// The only error type that reaches the UI.
///
/// [message] is always a finished Thai sentence, safe to render as-is. Raw
/// `DioException`s, stack traces and server internals stop here — a customer
/// should never see `Exception: ` or a file path, and an attacker should never
/// learn the shape of the backend from an error bubble.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.kind = ApiErrorKind.unknown,
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String message;
  final ApiErrorKind kind;
  final int? statusCode;
  final int? retryAfterSeconds;

  bool get isAuthFailure => kind == ApiErrorKind.unauthorized;

  @override
  String toString() => message;

  /// Translate a transport or HTTP failure into something a person can act on.
  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) {
      return ApiException('เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
          kind: ApiErrorKind.network,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return ApiException(
          'ไม่สามารถเชื่อมต่อกับ X-DREAMER ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
          kind: ApiErrorKind.network,
        );
      case DioExceptionType.cancel:
        return ApiException('ยกเลิกแล้ว', kind: ApiErrorKind.cancelled);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final response = error.response;
    final status = response?.statusCode;
    final serverMessage = _serverMessage(response?.data);
    final retryAfter = int.tryParse(response?.headers.value('retry-after') ?? '');

    return switch (status) {
      400 => ApiException(
        serverMessage ?? 'ข้อมูลที่ส่งไปไม่ถูกต้อง',
        kind: ApiErrorKind.badRequest,
        statusCode: status,
      ),
      401 => ApiException(
        serverMessage ?? 'กรุณาเข้าสู่ระบบใหม่',
        kind: ApiErrorKind.unauthorized,
        statusCode: status,
      ),
      403 => ApiException(
        serverMessage ?? 'บัญชีนี้ไม่มีสิทธิ์ใช้งานส่วนนี้',
        kind: ApiErrorKind.forbidden,
        statusCode: status,
      ),
      404 => ApiException(
        serverMessage ?? 'ไม่พบข้อมูลที่ต้องการ',
        kind: ApiErrorKind.notFound,
        statusCode: status,
      ),
      // The generate endpoint returns 402 with an English "Insufficient
      // credits" — the one place the API is not already Thai.
      402 => ApiException(
        'เครดิตไม่พอสำหรับการสร้างนี้ กรุณาเติมเครดิตก่อน',
        kind: ApiErrorKind.insufficientCredits,
        statusCode: status,
      ),
      409 => ApiException(
        serverMessage ?? 'โมเดลนี้กำลังปรับแต่ง ยังใช้งานไม่ได้',
        kind: ApiErrorKind.modelTuning,
        statusCode: status,
      ),
      429 => ApiException(
        serverMessage ?? 'ทำรายการบ่อยเกินไป กรุณารอสักครู่',
        kind: ApiErrorKind.rateLimited,
        statusCode: status,
        retryAfterSeconds: retryAfter,
      ),
      503 => ApiException(
        'ระบบกำลังหนาแน่น กรุณาลองใหม่อีกสักครู่',
        kind: ApiErrorKind.serviceUnavailable,
        statusCode: status,
      ),
      _ => ApiException(
        // Deliberately generic: a 500's real message can name tables and
        // providers. The server logs it; the customer does not need it.
        'เกิดข้อผิดพลาดที่เซิร์ฟเวอร์ กรุณาลองใหม่',
        kind: ApiErrorKind.server,
        statusCode: status,
      ),
    };
  }

  /// Pull the API's own `{ "error": "..." }` copy when it is present and looks
  /// like something written for a customer.
  static String? _serverMessage(Object? data) {
    if (data is! Map) return null;
    final raw = data['error'];
    if (raw is! String) return null;

    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > 200) return null;

    // Internal English strings that leaked through the route handlers.
    const internal = {
      'Unauthorized': 'กรุณาเข้าสู่ระบบใหม่',
      'Not found': 'ไม่พบข้อมูลที่ต้องการ',
      'Invalid ID': 'ข้อมูลที่ส่งไปไม่ถูกต้อง',
      'Model not available': 'โมเดลนี้ยังใช้งานไม่ได้',
      'Generation not found': 'ไม่พบผลงานนี้',
      'Generation failed. Please try again.': 'สร้างผลงานไม่สำเร็จ กรุณาลองใหม่',
      'Service temporarily unavailable. Please try again later.':
          'ระบบกำลังหนาแน่น กรุณาลองใหม่อีกสักครู่',
    };
    return internal[trimmed] ?? trimmed;
  }
}
