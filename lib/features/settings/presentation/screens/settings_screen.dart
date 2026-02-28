import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dime_money/core/providers/database_provider.dart';
import 'package:dime_money/core/providers/theme_provider.dart';
import 'package:dime_money/core/utils/csv_exporter.dart';
import 'package:dime_money/core/utils/csv_importer.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final incomeEnabled = ref.watch(incomeEnabledProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);

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
            onChanged: (_) =>
                ref.read(biometricEnabledProvider.notifier).toggle(),
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
