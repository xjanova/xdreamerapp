import 'json_ext.dart';

/// Where a GPU-backed job has got to.
///
/// Only present for models that run on a rented machine — those legitimately
/// take 10-25 minutes on a cold start, and the app has to say so or the
/// customer will assume it hung and pay for a second attempt.
class GpuProgress {
  const GpuProgress({
    required this.stage,
    required this.label,
    this.queuePosition,
    this.gpuModel,
    this.etaSeconds,
    this.etaLabel,
    this.etaBasis = 'baseline',
  });

  final String stage;

  /// Thai copy written by the server — render it, do not invent your own.
  final String label;
  final int? queuePosition;
  final String? gpuModel;
  final int? etaSeconds;
  final String? etaLabel;

  /// `baseline` means the server has no history for this model yet, so the ETA
  /// is a guess and the UI softens the wording.
  final String etaBasis;

  bool get isRoughEstimate => etaBasis == 'baseline';

  static GpuProgress? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return GpuProgress(
      stage: json.str('stage', 'queued'),
      label: json.str('label', 'อยู่ในคิว'),
      queuePosition: json.intOrNull('queuePosition'),
      gpuModel: json.strOrNull('gpuModel'),
      etaSeconds: json.intOrNull('etaSeconds'),
      etaLabel: json.strOrNull('etaLabel'),
      etaBasis: json.str('etaBasis', 'baseline'),
    );
  }
}

/// One row of `ai_generations`, in every shape the API returns it:
/// the POST result, the polled status, and a gallery item.
class Generation {
  const Generation({
    required this.id,
    required this.status,
    required this.type,
    this.prompt,
    this.resultUrl,
    this.resultUrls = const [],
    this.thumbnailUrl,
    this.creditsUsed = 0,
    this.creditsRefunded = false,
    this.processingMs,
    this.errorMessage,
    this.expiresAt,
    this.daysLeft,
    this.mediaDeleted = false,
    this.isFavorited = false,
    this.favoritesCount = 0,
    this.modelName,
    this.providerName,
    this.createdAt,
    this.gpu,
  });

  final int id;

  /// `pending` | `processing` | `completed` | `failed` | `cancelled`
  final String status;

  /// `image` | `video` | `edit`
  final String type;
  final String? prompt;
  final String? resultUrl;
  final List<String> resultUrls;
  final String? thumbnailUrl;
  final int creditsUsed;

  /// The server refunds automatically when a job fails; saying so plainly is
  /// the difference between "it broke" and "it broke and took my credits".
  final bool creditsRefunded;
  final int? processingMs;
  final String? errorMessage;
  final DateTime? expiresAt;
  final int? daysLeft;
  final bool mediaDeleted;
  final bool isFavorited;
  final int favoritesCount;
  final String? modelName;
  final String? providerName;
  final DateTime? createdAt;
  final GpuProgress? gpu;

  bool get isTerminal => status == 'completed' || status == 'failed' || status == 'cancelled';
  bool get isRunning => status == 'pending' || status == 'processing';
  bool get succeeded => status == 'completed';
  bool get isVideo => type == 'video';

  /// Every frame this job produced, newest API shape first.
  List<String> get frames {
    if (resultUrls.isNotEmpty) return resultUrls;
    final single = resultUrl;
    return single == null || single.isEmpty ? const [] : [single];
  }

  String get durationLabel {
    final ms = processingMs;
    if (ms == null || ms <= 0) return '';
    final seconds = ms / 1000;
    return seconds < 60
        ? '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s'
        : '${(seconds / 60).floor()}m ${(seconds % 60).round()}s';
  }

  factory Generation.fromJson(Map<String, dynamic> json) {
    final model = json.obj('model');
    return Generation(
      id: json.intVal('id'),
      status: json.str('status', 'pending'),
      type: json.str('type', 'image'),
      prompt: json.strOrNull('prompt'),
      resultUrl: json.strOrNull('resultUrl'),
      resultUrls: json.strList('resultUrls'),
      thumbnailUrl: json.strOrNull('thumbnailUrl'),
      creditsUsed: json.intVal('creditsUsed'),
      creditsRefunded: json.flag('creditsRefunded'),
      processingMs: json.intOrNull('processingMs'),
      errorMessage: json.strOrNull('errorMessage'),
      expiresAt: json.date('expiresAt'),
      daysLeft: json.intOrNull('daysLeft'),
      mediaDeleted: json.flag('mediaDeleted'),
      isFavorited: json.flag('isFavorited'),
      favoritesCount: json.intVal('favoritesCount'),
      modelName: model?.strOrNull('name'),
      providerName: model?.strOrNull('provider'),
      createdAt: json.date('createdAt'),
      gpu: GpuProgress.fromJson(json.obj('gpu')),
    );
  }

  Generation copyWith({bool? isFavorited, int? favoritesCount}) => Generation(
        id: id,
        status: status,
        type: type,
        prompt: prompt,
        resultUrl: resultUrl,
        resultUrls: resultUrls,
        thumbnailUrl: thumbnailUrl,
        creditsUsed: creditsUsed,
        creditsRefunded: creditsRefunded,
        processingMs: processingMs,
        errorMessage: errorMessage,
        expiresAt: expiresAt,
        daysLeft: daysLeft,
        mediaDeleted: mediaDeleted,
        isFavorited: isFavorited ?? this.isFavorited,
        favoritesCount: favoritesCount ?? this.favoritesCount,
        modelName: modelName,
        providerName: providerName,
        createdAt: createdAt,
        gpu: gpu,
      );
}

/// One page of `/api/gallery`.
class GalleryPage {
  const GalleryPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });

  final List<Generation> items;
  final int page;
  final int pages;
  final int total;

  bool get hasMore => page < pages;

  factory GalleryPage.fromJson(Map<String, dynamic> json) => GalleryPage(
        items: json.objList('data').map(Generation.fromJson).toList(),
        page: json.intVal('page', 1),
        pages: json.intVal('pages', 1),
        total: json.intVal('total'),
      );
}

/// A row of `ai_credit_transactions`.
class CreditTransaction {
  const CreditTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.createdAt,
  });

  final int id;

  /// `purchase` | `usage` | `refund` | `bonus` | `admin_adjust`
  final String type;
  final int amount;
  final int balanceAfter;
  final String? description;
  final DateTime? createdAt;

  bool get isCredit => amount > 0;

  factory CreditTransaction.fromJson(Map<String, dynamic> json) => CreditTransaction(
        id: json.intVal('id'),
        type: json.str('type'),
        amount: json.intVal('amount'),
        balanceAfter: json.intVal('balanceAfter'),
        description: json.strOrNull('description'),
        createdAt: json.date('createdAt'),
      );
}
