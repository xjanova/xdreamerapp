import 'json_ext.dart';

/// A generation mode as the studio presents it.
///
/// The API has three `type` values (`image`, `video`, `edit`). The studio shows
/// five, because "image → video" and "upscale" are different jobs to a customer
/// even though they ride the same endpoint. [apiType] is what goes on the wire.
enum StudioMode {
  textToImage('t2i', 'ภาพ', 'TEXT → IMAGE', 'image'),
  textToVideo('t2v', 'วิดีโอ', 'TEXT → VIDEO', 'video'),
  imageToVideo('i2v', 'ภาพ → วิดีโอ', 'IMAGE → VIDEO', 'video'),
  edit('edit', 'แก้ไขภาพ', 'EDIT / INPAINT', 'edit'),
  upscale('up', 'อัปสเกล', 'UPSCALE 4K', 'edit');

  const StudioMode(this.id, this.labelTh, this.labelEn, this.apiType);

  final String id;
  final String labelTh;
  final String labelEn;
  final String apiType;

  /// Modes that cannot start without a source image.
  bool get needsInputImage =>
      this == StudioMode.imageToVideo || this == StudioMode.edit || this == StudioMode.upscale;

  bool get producesVideo => apiType == 'video';

  static StudioMode fromId(String id) =>
      StudioMode.values.firstWhere((m) => m.id == id, orElse: () => StudioMode.textToImage);
}

/// A row of `ai_models`, joined with its provider.
class AiModelInfo {
  const AiModelInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.creditsPerUnit,
    required this.providerName,
    required this.providerSlug,
    required this.canOrder,
    this.subcategory,
    this.description,
    this.thumbnail,
    this.maxWidth,
    this.maxHeight,
    this.maxDuration,
    this.isFeatured = false,
    this.readiness = 'ready',
    this.tuningMessage,
  });

  final int id;
  final String name;

  /// `image` | `video` | `edit` — matches `GenerationType` on the server.
  final String category;
  final String? subcategory;
  final String? description;
  final String? thumbnail;
  final int creditsPerUnit;
  final String providerName;
  final String providerSlug;
  final int? maxWidth;
  final int? maxHeight;
  final int? maxDuration;
  final bool isFeatured;

  /// `tuning` models are listed but not orderable by a customer — the studio
  /// shows [tuningMessage] instead of letting them spend credits on it.
  final String readiness;
  final String? tuningMessage;
  final bool canOrder;

  bool get isTuning => readiness == 'tuning';

  /// Rough wait, shown next to the model name. Derived rather than stored — the
  /// API has no ETA field for non-GPU jobs.
  String get etaLabel => switch (category) {
    'video' => '~40-60 วิ',
    'edit' => '~10-15 วิ',
    _ => '~8-15 วิ',
  };

  factory AiModelInfo.fromJson(Map<String, dynamic> json) {
    final provider = json.obj('provider') ?? const {};
    return AiModelInfo(
      id: json.intVal('id'),
      name: json.str('name', 'โมเดล'),
      category: json.str('category', 'image'),
      subcategory: json.strOrNull('subcategory'),
      description: json.strOrNull('description'),
      thumbnail: json.strOrNull('thumbnail'),
      creditsPerUnit: json.intVal('creditsPerUnit'),
      providerName: provider.str('name', '—'),
      providerSlug: provider.str('slug'),
      maxWidth: json.intOrNull('maxWidth'),
      maxHeight: json.intOrNull('maxHeight'),
      maxDuration: json.intOrNull('maxDuration'),
      isFeatured: json.flag('isFeatured'),
      readiness: json.str('readiness', 'ready'),
      tuningMessage: json.strOrNull('tuningMessage'),
      // Absent on older builds of the API — assume orderable rather than
      // hiding every model behind a field that might not be deployed yet.
      canOrder: json.containsKey('canOrder') ? json.flag('canOrder', true) : true,
    );
  }

  /// Which studio modes this model can serve.
  bool servesMode(StudioMode mode) {
    if (mode == StudioMode.upscale) {
      final haystack = '$name ${subcategory ?? ''}'.toLowerCase();
      return haystack.contains('upscale') ||
          haystack.contains('esrgan') ||
          haystack.contains('enhance');
    }
    return category == mode.apiType;
  }
}

/// A row of `ai_styles` — appended to the prompt server-side via `styleId`.
class StylePreset {
  const StylePreset({required this.id, required this.name, this.thumbnail});

  final int id;
  final String name;
  final String? thumbnail;

  factory StylePreset.fromJson(Map<String, dynamic> json) => StylePreset(
    id: json.intVal('id'),
    name: json.str('name'),
    thumbnail: json.strOrNull('thumbnail'),
  );
}

/// A row of `ai_credit_packages`. Prices arrive as Prisma `Decimal` strings.
class CreditPackage {
  const CreditPackage({
    required this.id,
    required this.name,
    required this.slug,
    required this.credits,
    required this.priceThb,
    required this.priceUsd,
    this.description,
    this.bonusCredits = 0,
    this.badge,
    this.isFeatured = false,
    this.features = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
  final int credits;
  final double priceThb;
  final double priceUsd;
  final int bonusCredits;
  final String? badge;

  /// The "ยอดนิยม" tier — rendered as a brand-tinted plate rather than a plain
  /// one, with the filled CTA.
  final bool isFeatured;
  final List<String> features;

  factory CreditPackage.fromJson(Map<String, dynamic> json) => CreditPackage(
    id: json.intVal('id'),
    name: json.str('name'),
    slug: json.str('slug'),
    description: json.strOrNull('description'),
    credits: json.intVal('credits'),
    priceThb: json.dbl('priceThb'),
    priceUsd: json.dbl('priceUsd'),
    bonusCredits: json.intVal('bonusCredits'),
    badge: json.strOrNull('badge'),
    isFeatured: json.flag('isFeatured'),
    features: json.strList('features'),
  );
}
