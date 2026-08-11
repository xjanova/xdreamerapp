import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/api_client.dart';
import '../core/net/token_store.dart';
import '../data/models/catalog.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/credits_repository.dart';
import '../data/repositories/gallery_repository.dart';
import '../data/repositories/generation_repository.dart';
import '../data/repositories/referral_repository.dart';

/// Fired by [ApiClient] when a refresh fails and the session is unrecoverable.
///
/// A plain notifier rather than a direct call into the auth controller: the
/// client is a dependency *of* the auth repository, so calling back into it
/// would close a loop through the provider graph.
class SessionLostSignal extends ChangeNotifier {
  void fire() => notifyListeners();
}

final sessionLostSignalProvider = Provider<SessionLostSignal>((ref) {
  final signal = SessionLostSignal();
  ref.onDispose(signal.dispose);
  return signal;
});

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final signal = ref.watch(sessionLostSignalProvider);
  return ApiClient(tokens: ref.watch(tokenStoreProvider), onSessionLost: signal.fire);
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      AuthRepository(client: ref.watch(apiClientProvider), tokens: ref.watch(tokenStoreProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);

final generationRepositoryProvider = Provider<GenerationRepository>(
  (ref) => GenerationRepository(ref.watch(apiClientProvider)),
);

final galleryRepositoryProvider = Provider<GalleryRepository>(
  (ref) => GalleryRepository(ref.watch(apiClientProvider)),
);

final creditsRepositoryProvider = Provider<CreditsRepository>(
  (ref) => CreditsRepository(ref.watch(apiClientProvider)),
);

final referralRepositoryProvider = Provider<ReferralRepository>(
  (ref) => ReferralRepository(ref.watch(apiClientProvider)),
);

// ── Catalog ───────────────────────────────────────────────────────────────
//
// `keepAlive` because these three lists change on the order of weeks, and
// refetching them every time the studio rebuilds would be a request per tab
// switch.

final modelsProvider = FutureProvider<List<AiModelInfo>>((ref) {
  ref.keepAlive();
  return ref.watch(catalogRepositoryProvider).models();
});

final stylesProvider = FutureProvider<List<StylePreset>>((ref) {
  ref.keepAlive();
  return ref.watch(catalogRepositoryProvider).styles();
});

final packagesProvider = FutureProvider<List<CreditPackage>>((ref) {
  ref.keepAlive();
  return ref.watch(catalogRepositoryProvider).packages();
});

final referralStatsProvider = FutureProvider(
  (ref) => ref.watch(referralRepositoryProvider).stats(),
);

final creditHistoryProvider = FutureProvider(
  (ref) => ref.watch(creditsRepositoryProvider).history(),
);
