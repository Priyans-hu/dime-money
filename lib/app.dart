import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/theme/app_theme.dart';
import 'package:dime_money/core/router/app_router.dart';
import 'package:dime_money/core/providers/theme_provider.dart';

class DimeMoneyApp extends ConsumerWidget {
  const DimeMoneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Dime Money',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
