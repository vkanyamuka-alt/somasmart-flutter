import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/push/push_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

/// Root Application Widget for SomaSmart Flutter.
class SomaSmartApp extends ConsumerStatefulWidget {
  const SomaSmartApp({super.key});

  @override
  ConsumerState<SomaSmartApp> createState() => _SomaSmartAppState();
}

class _SomaSmartAppState extends ConsumerState<SomaSmartApp> {
  @override
  void initState() {
    super.initState();
    // Push notifications: token, foreground banner, tap-to-open. Does nothing
    // in builds without Firebase config, and never asks for permission here.
    unawaited(ref.read(pushControllerProvider).start());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      scaffoldMessengerKey: pushMessengerKey,
      routerConfig: router,
    );
  }
}
