import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xdreamer/core/net/api_exception.dart';
import 'package:xdreamer/data/models/catalog.dart';
import 'package:xdreamer/data/models/generation.dart';
import 'package:xdreamer/data/models/session.dart';
import 'package:xdreamer/data/models/update_info.dart';
import 'package:xdreamer/state/studio_controller.dart';

void main() {
  group('compareVersions', () {
    test('orders releases', () {
      expect(compareVersions('0.1.0', '0.2.0'), -1);
      expect(compareVersions('1.0.0', '0.9.9'), 1);
      expect(compareVersions('1.2.3', '1.2.3'), 0);
    });

    test('treats a missing segment as zero, so 1.2 == 1.2.0', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2', '1.2.1'), -1);
    });

    test('ignores a pre-release suffix', () {
      expect(compareVersions('1.0.0-beta.2', '1.0.0'), 0);
    });

    test('does not compare segments as strings — 10 is above 9', () {
      expect(compareVersions('0.10.0', '0.9.0'), 1);
    });
  });

  group('API payload parsing', () {
    test('survives a row with nulls and wrong types', () {
      final generation = Generation.fromJson({
        'id': '42', // string where the schema says int
        'status': null,
        'resultUrls': 'https://example.com/a.png', // single string, not a list
        'creditsUsed': 12.0,
        'model': null,
      });

      expect(generation.id, 42);
      expect(generation.status, 'pending');
      expect(generation.frames, ['https://example.com/a.png']);
      expect(generation.creditsUsed, 12);
      expect(generation.modelName, isNull);
    });

    test('reads Prisma Decimal prices, which arrive as strings', () {
      final package = CreditPackage.fromJson({
        'id': 2,
        'name': 'Creator',
        'slug': 'creator',
        'credits': 2500,
        'priceThb': '590.00',
        'priceUsd': '17.00',
        'bonusCredits': 250,
        'isFeatured': true,
        'features': ['4K upscale', 'คิวลัด'],
      });

      expect(package.priceThb, 590);
      expect(package.priceUsd, 17);
      expect(package.features, hasLength(2));
    });

    test('takes an avatar initial without slicing a Thai grapheme', () {
      final user = UserProfile.fromJson({'id': 1, 'name': 'กานต์', 'email': 'k@example.com'});
      expect(user.initial, 'ก');
      expect(user.handle, 'k');
    });

    test('assumes a model is orderable when the API predates canOrder', () {
      final model = AiModelInfo.fromJson({
        'id': 7,
        'name': 'Seedream',
        'category': 'image',
        'creditsPerUnit': 12,
        'provider': {'name': 'BytePlus', 'slug': 'byteplus'},
      });
      expect(model.canOrder, isTrue);
    });
  });

  group('StudioAspect.sizeFor', () {
    test('fits inside the model limits and snaps to a multiple of 64', () {
      const model = AiModelInfo(
        id: 1,
        name: 'test',
        category: 'image',
        creditsPerUnit: 1,
        providerName: 'p',
        providerSlug: 'p',
        canOrder: true,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      final (width, height) = StudioAspect.story.sizeFor(model); // 9:16
      expect(width % 64, 0);
      expect(height % 64, 0);
      expect(width, lessThanOrEqualTo(1024));
      expect(height, lessThanOrEqualTo(1024));
      expect(width, lessThan(height));
    });

    test('never returns a dimension small enough for a provider to reject', () {
      const tiny = AiModelInfo(
        id: 1,
        name: 'test',
        category: 'image',
        creditsPerUnit: 1,
        providerName: 'p',
        providerSlug: 'p',
        canOrder: true,
        maxWidth: 100,
        maxHeight: 100,
      );

      final (width, height) = StudioAspect.wide.sizeFor(tiny);
      expect(width, greaterThanOrEqualTo(256));
      expect(height, greaterThanOrEqualTo(256));
    });
  });

  group('ApiException', () {
    DioException http(int status, [Object? body]) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: body,
      ),
    );

    test('separates a dead session from a backend that is merely down', () {
      // The client signs out on the first and retries on the second, so these
      // must never collapse into one kind.
      expect(ApiException.from(http(401)).kind, ApiErrorKind.unauthorized);
      expect(ApiException.from(http(503)).kind, ApiErrorKind.serviceUnavailable);
      expect(ApiException.from(http(500)).kind, ApiErrorKind.server);
    });

    test('never shows a 500 body to the customer', () {
      final error = ApiException.from(
        http(500, {'error': 'Prisma error at ai_generations.user_id'}),
      );
      expect(error.message, isNot(contains('Prisma')));
      expect(error.message, isNot(contains('ai_generations')));
    });

    test('rewrites the API English that leaks through some routes', () {
      expect(
        ApiException.from(http(401, {'error': 'Unauthorized'})).message,
        'กรุณาเข้าสู่ระบบใหม่',
      );
      expect(ApiException.from(http(402)).kind, ApiErrorKind.insufficientCredits);
    });

    test('passes through the Thai copy the API already wrote', () {
      final error = ApiException.from(http(400, {'error': 'กรุณาระบุรหัสชวนเพื่อน'}));
      expect(error.message, 'กรุณาระบุรหัสชวนเพื่อน');
    });

    test('a dropped connection reads as a network problem, not a server fault', () {
      final error = ApiException.from(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(error.kind, ApiErrorKind.network);
    });
  });

  group('StudioMode', () {
    test('maps the five studio modes onto the three API types', () {
      expect(StudioMode.textToImage.apiType, 'image');
      expect(StudioMode.imageToVideo.apiType, 'video');
      expect(StudioMode.upscale.apiType, 'edit');
    });

    test('knows which modes cannot start without a source image', () {
      expect(StudioMode.textToImage.needsInputImage, isFalse);
      expect(StudioMode.edit.needsInputImage, isTrue);
      expect(StudioMode.imageToVideo.needsInputImage, isTrue);
    });
  });
}
