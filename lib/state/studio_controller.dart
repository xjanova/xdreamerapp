import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/net/api_exception.dart';
import '../data/models/catalog.dart';
import '../data/models/generation.dart';
import 'auth_controller.dart';
import 'providers.dart';

enum StudioPhase { idle, generating, result }

/// The four output shapes the studio offers, with the proportions the little
/// preview rectangles are drawn at.
enum StudioAspect {
  square('1:1', 1, 1, 16, 16),
  portrait('3:4', 3, 4, 13, 17),
  story('9:16', 9, 16, 10, 18),
  wide('16:9', 16, 9, 20, 11);

  const StudioAspect(this.label, this.w, this.h, this.swatchW, this.swatchH);

  final String label;
  final int w;
  final int h;
  final double swatchW;
  final double swatchH;

  /// Pixel dimensions for this ratio, scaled to fit inside a model's limits and
  /// rounded to a multiple of 64 — every diffusion backend in the pool wants
  /// that, and sending 1023 gets silently rounded somewhere less predictable.
  (int width, int height) sizeFor(AiModelInfo? model) {
    final maxW = model?.maxWidth ?? 1024;
    final maxH = model?.maxHeight ?? 1024;
    final scale = [maxW / w, maxH / h].reduce((a, b) => a < b ? a : b);

    int snap(double value) {
      final rounded = (value / 64).floor() * 64;
      return rounded < 256 ? 256 : rounded;
    }

    return (snap(w * scale), snap(h * scale));
  }
}

class StudioState {
  const StudioState({
    this.mode = StudioMode.textToImage,
    this.prompt = '',
    this.styleId,
    this.aspect = StudioAspect.square,
    this.batch = 4,
    this.modelId,
    this.phase = StudioPhase.idle,
    this.job,
    this.selectedFrame,
    this.inputImage,
    this.inputImageName,
    this.submitting = false,
    this.error,
    this.startedAt,
  });

  final StudioMode mode;
  final String prompt;
  final int? styleId;
  final StudioAspect aspect;
  final int batch;

  /// null means "whatever the mode's default model is".
  final int? modelId;

  final StudioPhase phase;
  final Generation? job;
  final String? selectedFrame;

  /// A `data:` URL, because `/api/generate` takes base64 or a URL and the app
  /// has nowhere to host a file.
  final String? inputImage;
  final String? inputImageName;

  /// Guards the generate button against a double tap. Separate from [phase]
  /// because the request is in flight before the phase flips.
  final bool submitting;
  final String? error;
  final DateTime? startedAt;

  bool get hasInputImage => inputImage != null;

  StudioState copyWith({
    StudioMode? mode,
    String? prompt,
    int? Function()? styleId,
    StudioAspect? aspect,
    int? batch,
    int? Function()? modelId,
    StudioPhase? phase,
    Generation? Function()? job,
    String? Function()? selectedFrame,
    String? Function()? inputImage,
    String? Function()? inputImageName,
    bool? submitting,
    String? Function()? error,
    DateTime? Function()? startedAt,
  }) {
    return StudioState(
      mode: mode ?? this.mode,
      prompt: prompt ?? this.prompt,
      styleId: styleId == null ? this.styleId : styleId(),
      aspect: aspect ?? this.aspect,
      batch: batch ?? this.batch,
      modelId: modelId == null ? this.modelId : modelId(),
      phase: phase ?? this.phase,
      job: job == null ? this.job : job(),
      selectedFrame: selectedFrame == null ? this.selectedFrame : selectedFrame(),
      inputImage: inputImage == null ? this.inputImage : inputImage(),
      inputImageName: inputImageName == null ? this.inputImageName : inputImageName(),
      submitting: submitting ?? this.submitting,
      error: error == null ? this.error : error(),
      startedAt: startedAt == null ? this.startedAt : startedAt(),
    );
  }
}

class StudioController extends Notifier<StudioState> {
  StreamSubscription<Generation>? _watcher;
  CancelToken? _inFlight;

  @override
  StudioState build() {
    ref.onDispose(_stopWatching);
    return const StudioState();
  }

  void _stopWatching() {
    _watcher?.cancel();
    _watcher = null;
    if (_inFlight != null && !_inFlight!.isCancelled) {
      _inFlight!.cancel('studio disposed');
    }
    _inFlight = null;
  }

  // ── Settings ────────────────────────────────────────────────────────────

  void setMode(StudioMode mode) {
    if (mode == state.mode) return;
    state = state.copyWith(
      mode: mode,
      // The chosen model belongs to the old mode; let the new one pick its own.
      modelId: () => null,
      error: () => null,
      // Batching is meaningless for a single video render.
      batch: mode.producesVideo ? 1 : state.batch,
    );
  }

  void setPrompt(String value) => state = state.copyWith(prompt: value, error: () => null);

  void setStyle(int? id) => state = state.copyWith(styleId: () => id);

  void setAspect(StudioAspect aspect) => state = state.copyWith(aspect: aspect);

  void setBatch(int batch) => state = state.copyWith(batch: batch.clamp(1, 4));

  void setModel(int? id) => state = state.copyWith(modelId: () => id, error: () => null);

  void clearInputImage() =>
      state = state.copyWith(inputImage: () => null, inputImageName: () => null);

  /// Pick a reference image for edit / image→video.
  ///
  /// Capped at 1536px and 85% quality on the way in — the payload is base64 in
  /// a JSON body, so a 12MP phone photo would be a 16MB string.
  Future<void> pickInputImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1536,
        maxHeight: 1536,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      if (bytes.lengthInBytes > 8 * 1024 * 1024) {
        state = state.copyWith(error: () => 'ไฟล์ภาพใหญ่เกินไป กรุณาเลือกภาพที่เล็กกว่านี้');
        return;
      }

      final mime = picked.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      state = state.copyWith(
        inputImage: () => 'data:$mime;base64,${base64Encode(bytes)}',
        inputImageName: () => picked.name,
        error: () => null,
      );
    } catch (_) {
      state = state.copyWith(error: () => 'เปิดคลังภาพไม่สำเร็จ กรุณาลองใหม่');
    }
  }

  // ── Model resolution ────────────────────────────────────────────────────

  /// The model this run will use: the explicit choice, else the cheapest
  /// orderable model that serves the current mode.
  AiModelInfo? resolveModel(List<AiModelInfo> models) {
    if (models.isEmpty) return null;

    final chosen = state.modelId;
    if (chosen != null) {
      for (final model in models) {
        if (model.id == chosen) return model;
      }
    }

    final candidates = models.where((m) => m.servesMode(state.mode) && m.canOrder).toList()
      ..sort((a, b) {
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        return a.creditsPerUnit.compareTo(b.creditsPerUnit);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  int costFor(AiModelInfo? model) => (model?.creditsPerUnit ?? 0) * state.batch;

  // ── Running a job ───────────────────────────────────────────────────────

  Future<void> generate({required AiModelInfo? model, required int availableCredits}) async {
    // Rapid repeated taps: the first one owns the request, the rest are noise.
    if (state.submitting || state.phase == StudioPhase.generating) return;

    if (model == null) {
      state = state.copyWith(error: () => 'ยังไม่มีโมเดลที่ใช้ได้สำหรับโหมดนี้');
      return;
    }
    if (!model.canOrder) {
      state = state.copyWith(
        error: () => model.tuningMessage ?? 'โมเดลนี้กำลังปรับแต่ง ยังใช้งานไม่ได้',
      );
      return;
    }
    if (state.mode != StudioMode.upscale && state.prompt.trim().isEmpty) {
      state = state.copyWith(error: () => 'กรุณาใส่คำอธิบายภาพที่ต้องการก่อน');
      return;
    }
    if (state.mode.needsInputImage && !state.hasInputImage) {
      state = state.copyWith(error: () => 'โหมดนี้ต้องเลือกภาพต้นฉบับก่อน');
      return;
    }

    final cost = costFor(model);
    if (cost > availableCredits) {
      state = state.copyWith(
        error: () => 'เครดิตไม่พอ ต้องใช้ $cost ✦ แต่เหลือ $availableCredits ✦',
      );
      return;
    }

    _stopWatching();
    final cancelToken = CancelToken();
    _inFlight = cancelToken;

    state = state.copyWith(
      submitting: true,
      phase: StudioPhase.generating,
      error: () => null,
      job: () => null,
      selectedFrame: () => null,
      startedAt: () => DateTime.now(),
    );

    final (width, height) = state.aspect.sizeFor(model);

    try {
      final job = await ref
          .read(generationRepositoryProvider)
          .create(
            modelId: model.id,
            type: state.mode.apiType,
            prompt: state.prompt.trim(),
            styleId: state.styleId,
            inputImage: state.inputImage,
            cancelToken: cancelToken,
            params: {
              'width': width,
              'height': height,
              'aspectRatio': state.aspect.label,
              'numOutputs': state.batch,
              if (state.mode.producesVideo) 'duration': model.maxDuration ?? 5,
              if (state.mode == StudioMode.upscale) 'mode': 'upscale',
            },
          );

      // The controller outlives the screen, but not the provider container.
      if (_inFlight != cancelToken) return;

      // Credits are already spent server-side; reflect it now rather than after
      // the next poll, then reconcile with the real balance when it settles.
      ref.read(authControllerProvider.notifier).applyCreditDelta(-job.creditsUsed);

      _adopt(job);
      if (!job.isTerminal) _watch(job.id);
    } on ApiException catch (error) {
      if (_inFlight != cancelToken) return;
      state = state.copyWith(
        submitting: false,
        phase: StudioPhase.idle,
        startedAt: () => null,
        error: () => error.message,
      );
      if (error.kind == ApiErrorKind.insufficientCredits) {
        await ref.read(authControllerProvider.notifier).refreshCredits();
      }
    }
  }

  void _watch(int id) {
    _watcher = ref
        .read(generationRepositoryProvider)
        .watch(id)
        .listen(
          _adopt,
          onError: (Object error) {
            state = state.copyWith(
              submitting: false,
              error: () => ApiException.from(error).message,
            );
          },
        );
  }

  void _adopt(Generation job) {
    final finished = job.isTerminal;

    state = state.copyWith(
      submitting: false,
      job: () => job,
      phase: finished && job.succeeded ? StudioPhase.result : state.phase,
      selectedFrame: () => job.frames.isEmpty ? null : job.frames.first,
      error: () => finished && !job.succeeded
          ? (job.creditsRefunded
                ? 'สร้างไม่สำเร็จ ระบบคืนเครดิตให้แล้ว'
                : 'สร้างไม่สำเร็จ กรุณาลองใหม่')
          : null,
    );

    if (finished) {
      _stopWatching();
      // Balance moved (spend, or a refund on failure) — get the real number.
      ref.read(authControllerProvider.notifier).refreshCredits();
      if (!job.succeeded) {
        state = state.copyWith(phase: StudioPhase.idle, startedAt: () => null);
      }
    }
  }

  void selectFrame(String url) => state = state.copyWith(selectedFrame: () => url);

  /// Stop watching and go back to the form.
  ///
  /// Note this is **not** a cancel: the platform has no endpoint that stops a
  /// job once it has been handed to a provider, and the credits are already
  /// spent. The work keeps running and lands in ผลงานของฉัน — the UI says so
  /// rather than implying a refund that will not arrive.
  void detach() {
    _stopWatching();
    state = state.copyWith(phase: StudioPhase.idle, submitting: false, startedAt: () => null);
  }

  /// "ล้าง" on the result header — clear the output, keep the settings.
  void clearResult() {
    _stopWatching();
    state = state.copyWith(
      phase: StudioPhase.idle,
      job: () => null,
      selectedFrame: () => null,
      error: () => null,
      startedAt: () => null,
    );
  }

  void dismissError() => state = state.copyWith(error: () => null);

  /// Re-run with exactly the same settings.
  Future<void> regenerate({required AiModelInfo? model, required int availableCredits}) {
    clearResult();
    return generate(model: model, availableCredits: availableCredits);
  }
}

final studioControllerProvider = NotifierProvider<StudioController, StudioState>(
  StudioController.new,
);
