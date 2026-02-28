import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:dime_money/core/providers/database_provider.dart';
import 'package:dime_money/core/providers/theme_provider.dart';
import 'package:dime_money/core/utils/csv_exporter.dart';
import 'package:dime_money/core/utils/csv_importer.dart';
import 'package:dime_money/core/utils/update_checker.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';
import 'package:dime_money/core/utils/seed_data.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final incomeEnabled = ref.watch(incomeEnabledProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final autoCheckUpdate = ref.watch(autoCheckUpdateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Accounts'),
            subtitle: const Text('Manage your accounts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/accounts'),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            subtitle: const Text('Manage expense categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Recurring'),
            subtitle: const Text('Auto-repeating transactions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/recurring'),
          ),
          const Divider(),
          _SectionHeader('Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.trending_up),
            title: const Text('Income tracking'),
            subtitle: const Text('Show income option in quick add'),
            value: incomeEnabled,
            onChanged: (_) =>
                ref.read(incomeEnabledProvider.notifier).toggle(),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency symbol'),
            subtitle: Text(currencySymbol),
            onTap: () => _showCurrencyPicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(themeMode)),
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const Divider(),
          _SectionHeader('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric lock'),
            subtitle: const Text('Require fingerprint/Face ID'),
            value: biometricEnabled,
            onChanged: (_) async {
              try {
                final success =
                    await ref.read(biometricEnabledProvider.notifier).toggle();
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric auth unavailable'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Auth failed: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(),
          _SectionHeader('Backup'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export CSV'),
            subtitle: const Text('Share your transaction data'),
            onTap: () async {
              try {
                final db = ref.read(databaseProvider);
                await CsvExporter(db).exportAndShare();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import CSV'),
            subtitle: const Text('Import from file'),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv'],
              );
              if (result == null || result.files.isEmpty) return;
              final path = result.files.single.path;
              if (path == null) return;

              try {
                final db = ref.read(databaseProvider);
                final count =
                    await CsvImporter(db).importFromFile(File(path));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Imported $count transactions')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
          ),
          const Divider(),
          _SectionHeader('Updates'),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Check for updates'),
            subtitle: const Text('Check GitHub for new releases'),
            onTap: () => _checkForUpdate(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.update),
            title: const Text('Auto-check updates'),
            subtitle: const Text('Check on app launch'),
            value: autoCheckUpdate,
            onChanged: (_) =>
                ref.read(autoCheckUpdateProvider.notifier).toggle(),
          ),
          const Divider(),
          _SectionHeader('Debug'),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Seed test data'),
            subtitle: const Text('Add dummy transactions & budgets'),
            onTap: () async {
              try {
                final db = ref.read(databaseProvider);
                final count = await seedDummyData(db);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seeded $count transactions'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seed failed: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(),
          const _VersionFooter(),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    const symbols = ['\$', '\u20AC', '\u00A3', '\u00A5', '\u20B9', '\u20A9', 'R\$', 'CHF'];
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: symbols
            .map((s) => ListTile(
                  title: Text(s),
                  onTap: () {
                    ref.read(currencySymbolProvider.notifier).set(s);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _checkForUpdate(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _UpdateCheckDialog(),
    );
  }
}

class _UpdateCheckDialog extends StatefulWidget {
  const _UpdateCheckDialog();

  @override
  State<_UpdateCheckDialog> createState() => _UpdateCheckDialogState();
}

class _UpdateCheckDialogState extends State<_UpdateCheckDialog> {
  UpdateInfo? _updateInfo;
  bool _checking = true;
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final info = await UpdateChecker.checkForUpdate();
      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _checking = false;
      });
    }
  }

  Future<void> _download() async {
    if (_updateInfo == null) return;
    setState(() => _downloading = true);
    try {
      await UpdateChecker.downloadAndInstall(
        _updateInfo!.apkDownloadUrl,
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
      setState(() {
        _error = 'Download failed: $e';
        _downloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return AlertDialog(
        title: const Text('Checking for updates'),
        content: const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    if (_updateInfo == null) {
      return AlertDialog(
        title: const Text('Up to date'),
        content: const Text('You are running the latest version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Update available — v${_updateInfo!.version}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_updateInfo!.releaseNotes.isNotEmpty) ...[
            Text(
              _updateInfo!.releaseNotes,
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
          child: Text(_downloading ? 'Downloading…' : 'Update'),
        ),
      ],
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? 'v${snapshot.data!.version} (build ${snapshot.data!.buildNumber})'
            : '';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            version,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
