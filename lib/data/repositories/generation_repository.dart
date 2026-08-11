import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/net/api_client.dart';
import '../models/generation.dart';

/// Everything that creates or watches a job.
class GenerationRepository {
  GenerationRepository(this._client);

  final ApiClient _client;

  /// `POST /api/generate`.
  ///
  /// This blocks for synchronous providers — an image can take 40s, so it gets
  /// its own longer receive timeout. Asynchronous and GPU-backed providers
  /// return a `pending` row immediately and are followed with [status].
  Future<Generation> create({
    required int modelId,
    required String type,
    required String prompt,
    int? styleId,
    String? negativePrompt,
    String? inputImage,
    Map<String, Object?> params = const {},
    CancelToken? cancelToken,
  }) async {
    final data = await _client.postJson(
      '/api/generate',
      cancelToken: cancelToken,
      receiveTimeout: const Duration(minutes: 3),
      body: {
        'modelId': modelId,
        'type': type,
        'prompt': prompt,
        if (styleId != null) 'styleId': styleId,
        if (negativePrompt != null && negativePrompt.isNotEmpty) 'negativePrompt': negativePrompt,
        if (inputImage != null) 'inputImage': inputImage,
        if (params.isNotEmpty) 'params': params,
      },
    );
    return Generation.fromJson(data);
  }

  /// `GET /api/generate/:id` — one poll.
  Future<Generation> status(int id, {CancelToken? cancelToken}) async {
    final data = await _client.getJson('/api/generate/$id', cancelToken: cancelToken);
    return Generation.fromJson(data);
  }

  /// `POST /api/upscale` — re-runs an existing result through an upscale model.
  Future<Generation> upscale({required int generationId, int? modelId, CancelToken? cancelToken}) async {
    final data = await _client.postJson(
      '/api/upscale',
      cancelToken: cancelToken,
      receiveTimeout: const Duration(minutes: 3),
      body: {
        'generationId': generationId,
        if (modelId != null) 'modelId': modelId,
      },
    );
    return Generation.fromJson(data);
  }

  /// Poll a running job until it reaches a terminal state.
  ///
  /// The interval backs off: a fast image is usually done inside three polls,
  /// while a rented-GPU video can legitimately run for twenty minutes and does
  /// not deserve a request every second for all of it.
  ///
  /// Cancel the subscription to stop — the stream closes its `CancelToken` and
  /// no in-flight request outlives the screen.
  Stream<Generation> watch(int id) {
    late StreamController<Generation> controller;
    final cancelToken = CancelToken();
    var stopped = false;

    Future<void> loop() async {
      var attempt = 0;
      while (!stopped) {
        await Future<void>.delayed(_intervalFor(attempt));
        if (stopped) return;

        try {
          final generation = await status(id, cancelToken: cancelToken);
          if (stopped) return;
          controller.add(generation);
          if (generation.isTerminal) {
            await controller.close();
            return;
          }
        } catch (error) {
          if (stopped) return;
          controller.addError(error);
          await controller.close();
          return;
        }
        attempt++;
      }
    }

    controller = StreamController<Generation>(
      onListen: loop,
      onCancel: () {
        stopped = true;
        if (!cancelToken.isCancelled) cancelToken.cancel('screen closed');
      },
    );

    return controller.stream;
  }

  static Duration _intervalFor(int attempt) {
    if (attempt < 6) return const Duration(milliseconds: 1500); // first ~9s
    if (attempt < 20) return const Duration(seconds: 3); // out to ~50s
    if (attempt < 60) return const Duration(seconds: 6); // out to ~5min
    return const Duration(seconds: 12); // long GPU renders
  }
}
