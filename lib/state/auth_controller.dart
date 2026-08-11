import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/api_exception.dart';
import '../data/models/session.dart';
import 'gallery_controller.dart';
import 'providers.dart';
import 'studio_controller.dart';

/// Who is signed in, if anyone.
///
/// `null` data means "signed out" — a legitimate state, not an error. An
/// `AsyncError` here means the restore itself failed (no network on cold
/// start), which is different: the customer may still have a valid session and
/// should get a retry rather than a login form.
class AuthController extends AsyncNotifier<MobileSession?> {
  @override
  Future<MobileSession?> build() async {
    // A dead refresh token discovered mid-session drops straight to signed out.
    final signal = ref.watch(sessionLostSignalProvider);
    void onLost() {
      if (state.valueOrNull != null) state = const AsyncValue.data(null);
    }

    signal.addListener(onLost);
    ref.onDispose(() => signal.removeListener(onLost));

    return ref.watch(authRepositoryProvider).restore();
  }

  /// Sign in, without ever losing the fact that we already know the answer.
  ///
  /// Both the loading and the error state carry the previous value forward, so
  /// `hasValue` stays true throughout. The router keys the boot screen off
  /// `hasValue` — without `copyWithPrevious` here, tapping the login button
  /// would bounce the customer to a full-screen spinner, and a wrong password
  /// would bounce them there permanently instead of showing the error under the
  /// form.
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue<MobileSession?>.loading().copyWithPrevious(state);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = AsyncValue.data(session);
    } on ApiException catch (error, stack) {
      state = AsyncValue<MobileSession?>.error(error, stack).copyWithPrevious(state);
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);

    // Everything cached under the old identity has to go. The gallery
    // controllers are the ones that matter: they are a keyed family that
    // outlives the session, so without this the next account to sign in on this
    // phone would open ผลงานของฉัน and see the previous account's work.
    // Invalidating a family provider clears every instance of it.
    ref.invalidate(galleryControllerProvider);
    ref.invalidate(studioControllerProvider);
    ref.invalidate(referralStatsProvider);
    ref.invalidate(creditHistoryProvider);
  }

  /// Retry a failed cold-start restore without dropping to the login screen.
  Future<void> retryRestore() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).restore());
  }

  /// Pull a fresh balance — after a generation spends credits, after coming
  /// back from the xmanstudio checkout, on pull-to-refresh.
  Future<void> refreshCredits() async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final balance = await ref.read(creditsRepositoryProvider).balance();
      // The screen can be torn down mid-request.
      if (state.valueOrNull == null) return;
      state = AsyncValue.data(MobileSession(user: current.user, credits: balance));
    } on ApiException {
      // A stale balance is not worth an error banner over; the next successful
      // read corrects it.
    }
  }

  /// Apply a locally known delta immediately so the credit pill does not sit on
  /// a stale number for the length of a round trip.
  void applyCreditDelta(int delta) {
    final current = state.valueOrNull;
    if (current == null || delta == 0) return;

    final credits = current.credits;
    state = AsyncValue.data(
      MobileSession(
        user: current.user,
        credits: CreditBalance(
          balance: (credits.balance + delta).clamp(0, 1 << 31),
          totalBought: credits.totalBought,
          totalUsed: delta < 0 ? credits.totalUsed - delta : credits.totalUsed,
          totalBonus: credits.totalBonus,
        ),
      ),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, MobileSession?>(
  AuthController.new,
);

/// Convenience for widgets that only care about the balance.
final creditBalanceProvider = Provider<int>((ref) {
  return ref.watch(authControllerProvider).valueOrNull?.credits.balance ?? 0;
});
