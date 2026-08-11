import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/boot/boot_screen.dart';
import '../features/community/community_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/pricing/pricing_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/referral/referral_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/studio/studio_screen.dart';
import '../features/works/works_screen.dart';
import '../state/auth_controller.dart';
import '../state/prefs.dart';

abstract final class Routes {
  static const boot = '/';
  static const onboard = '/onboard';
  static const login = '/login';
  static const studio = '/studio';
  static const works = '/works';
  static const community = '/community';
  static const profile = '/profile';
  static const pricing = '/pricing';
  static const referral = '/referral';
}

/// Bridges a Riverpod provider to go_router's `refreshListenable`.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.boot,
    refreshListenable: refresh,
    redirect: (context, routerState) {
      final auth = ref.read(authControllerProvider);
      final path = routerState.matchedLocation;

      // Still restoring, or retrying after a failed restore: hold on the boot
      // screen rather than bouncing the customer to a login form they may not
      // need.
      if (auth.isLoading) return path == Routes.boot ? null : Routes.boot;

      if (auth.hasError) return path == Routes.boot ? null : Routes.boot;

      final signedIn = auth.valueOrNull != null;
      final atEntry = path == Routes.boot || path == Routes.onboard || path == Routes.login;

      if (!signedIn) {
        if (!atEntry) return Routes.login;
        if (path == Routes.boot) {
          return ref.read(onboardingSeenProvider) ? Routes.login : Routes.onboard;
        }
        return null;
      }

      return atEntry ? Routes.studio : null;
    },
    routes: [
      GoRoute(path: Routes.boot, builder: (_, __) => const BootScreen()),
      GoRoute(path: Routes.onboard, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),

      // The four tabs keep their own navigation state and scroll position, so
      // coming back to ผลงาน does not reload it from page one.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.studio, builder: (_, __) => const StudioScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.works, builder: (_, __) => const WorksScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.community, builder: (_, __) => const CommunityScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen())],
          ),
        ],
      ),

      // Reached from the profile menu and the credit pill — deliberately not in
      // the tab bar.
      GoRoute(path: Routes.pricing, builder: (_, __) => const PricingScreen()),
      GoRoute(path: Routes.referral, builder: (_, __) => const ReferralScreen()),
    ],
  );
});
