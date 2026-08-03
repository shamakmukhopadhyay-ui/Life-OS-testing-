import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// The root widget of LifeOS.
///
/// This is intentionally thin: it only wires together the theme (§ theme)
/// and the router (§ navigation) via `MaterialApp.router`. It contains no
/// feature logic and no UI of its own — that separation is what lets us
/// change theming or routing strategy later without touching this file's
/// neighbors.
///
/// It's a [ConsumerWidget] (Riverpod's version of [StatelessWidget]) so it
/// can read the router provider.
class LifeOSApp extends ConsumerWidget {
  const LifeOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'LifeOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follows the OS light/dark setting by default. A manual override
      // toggle belongs in the Settings feature (already in scope per the
      // SRS) but hasn't been built yet — system default is correct until
      // then.
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
