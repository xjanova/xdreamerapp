import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/theme/xdr_theme.dart';
import 'state/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The backdrop is drawn edge to edge and the tab bar handles its own safe
  // area, so both system bars are transparent and the app paints under them.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(XdrTheme.systemOverlay);

  // Portrait only: every screen in the handoff is specified at 412×812 dp, and
  // the studio's three-panel column has nowhere sensible to go in landscape.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Loaded before the first frame so the router can decide between onboarding
  // and login without a flash of the wrong screen.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const XDreamerApp(),
    ),
  );
}
