import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/theme/app_theme.dart';
import 'package:dime_money/core/router/app_router.dart' show appRouter, rootNavigatorKey;
import 'package:dime_money/core/providers/theme_provider.dart';
import 'package:dime_money/core/utils/update_checker.dart';
import 'package:dime_money/core/utils/quick_action_handler.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';
import 'package:dime_money/shared/widgets/lock_gate.dart';

class DimeMoneyApp extends ConsumerStatefulWidget {
  final bool checkForUpdate;

  const DimeMoneyApp({super.key, this.checkForUpdate = false});

  @override
  ConsumerState<DimeMoneyApp> createState() => _DimeMoneyAppState();
}

class _DimeMoneyAppState extends ConsumerState<DimeMoneyApp> {
  bool _shortcutsInitialized = false;

  @override
  void initState() {
    super.initState();
    QuickActionHandler.init();
    if (widget.checkForUpdate) {
      _silentUpdateCheck();
    }
  }

  Future<void> _silentUpdateCheck() async {
    final info = await UpdateChecker.checkForUpdate();
    if (info == null || !mounted) return;

    // Wait for first frame so we have a valid navigator context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (_) => _AutoUpdateDialog(info: info),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Update quick action shortcuts when income toggle changes
    final incomeEnabled = ref.watch(incomeEnabledProvider);
    ref.listen<bool>(incomeEnabledProvider, (previous, value) {
      QuickActionHandler.updateShortcuts(value);
    });

    if (!_shortcutsInitialized) {
      _shortcutsInitialized = true;
      QuickActionHandler.updateShortcuts(incomeEnabled);
    }

    return LockGate(
      child: MaterialApp.router(
        title: 'Dime Money',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}

class _AutoUpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _AutoUpdateDialog({required this.info});

  @override
  State<_AutoUpdateDialog> createState() => _AutoUpdateDialogState();
}

class _AutoUpdateDialogState extends State<_AutoUpdateDialog> {
  bool _downloading = false;
  double _progress = 0;

  Future<void> _download() async {
    if (!widget.info.hasApk) {
      await UpdateChecker.openReleasePage();
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _downloading = true);
    try {
      await UpdateChecker.downloadAndInstall(
        widget.info.apkDownloadUrl!,
        (received, total) {
          if (!mounted) return;
          setState(() {
            _progress = total > 0 ? received / total : 0;
          });
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update available — v${widget.info.version}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.info.releaseNotes.isNotEmpty) ...[
            Text(
              widget.info.releaseNotes,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          if (_downloading)
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: _downloading ? null : _download,
          child: Text(_downloading
              ? 'Downloading…'
              : widget.info.hasApk
                  ? 'Update'
                  : 'View on GitHub'),
        ),
      ],
    );
  }
}
