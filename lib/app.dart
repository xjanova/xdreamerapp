import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/xdr_theme.dart';
import 'routing/app_router.dart';

class XDreamerApp extends ConsumerWidget {
  const XDreamerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'X-DREAMER',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: XdrTheme.build(),
      darkTheme: XdrTheme.build(),
      themeMode: ThemeMode.dark,
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // The design specifies 9.5px tab labels and 10px stat captions. At the
        // 2.0 scale Android allows, those layouts break outright — clamping at
        // 1.3 keeps large-text users readable without shredding the screen.
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
