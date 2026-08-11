import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with the instance loaded before the first frame.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

const _onboardingSeenKey = 'xdr.onboarded';

/// Whether this device has been through the onboarding carousel.
///
/// Non-sensitive, so plain SharedPreferences rather than the keystore — a user
/// who clears app data seeing the intro again is the correct outcome.
class OnboardingSeen extends Notifier<bool> {
  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_onboardingSeenKey) ?? false;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_onboardingSeenKey, true);
  }
}

final onboardingSeenProvider = NotifierProvider<OnboardingSeen, bool>(OnboardingSeen.new);
