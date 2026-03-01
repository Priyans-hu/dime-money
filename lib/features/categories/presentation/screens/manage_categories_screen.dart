import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/theme/color_tokens.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/categories/presentation/widgets/icon_picker.dart';
import 'package:dime_money/core/utils/sheet_padding.dart';
import 'package:dime_money/features/categories/presentation/widgets/color_picker.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: 72 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddCategory(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) => ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) newIndex--;
            final cat = categories[oldIndex];
            final updated = cat.copyWith(sortOrder: newIndex);
            await ref.read(categoryRepositoryProvider).update(updated);
          },
          itemBuilder: (context, index) {
            final cat = categories[index];
            final catColor = Color(cat.color);

            return ListTile(
              key: ValueKey(cat.id),
              leading: CircleAvatar(
                backgroundColor: catColor.withValues(alpha: 0.15),
                child: Icon(
                  IconData(cat.iconCodePoint,
                      fontFamily: cat.iconFontFamily),
                  color: catColor,
                ),
              ),
              title: Text(cat.name),
              subtitle: cat.isDefault
                  ? Text('Default',
                      style: Theme.of(context).textTheme.bodySmall)
                  : null,
              trailing: cat.isDefault
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          _confirmDelete(context, ref, cat),
                    ),
              onTap: () => _showEditCategory(context, ref, cat),
            );
          },
        ),
      ),
    );
  }

  void _showAddCategory(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    var selectedIcon = Icons.more_horiz;
    var selectedColor = AppColors.categoryPalette[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: sheetBottomPadding(context),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('New Category',
                    style: Theme.of(context).textTheme.titleLarge),
                const Gap(16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                ),
                const Gap(12),
                Text('Color',
                    style: Theme.of(context).textTheme.titleSmall),
                const Gap(8),
                ColorPicker(
                  selectedColor: selectedColor.toARGB32(),
                  onSelected: (c) =>
                      setSheetState(() => selectedColor = c),
                ),
                const Gap(12),
                Text('Icon',
                    style: Theme.of(context).textTheme.titleSmall),
                const Gap(8),
                IconPicker(
                  selectedCodePoint: selectedIcon.codePoint,
                  onSelected: (i) =>
                      setSheetState(() => selectedIcon = i),
                ),
                const Gap(16),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Haptics.medium();
                    await ref.read(categoryRepositoryProvider).insert(
                          name: name,
                          iconCodePoint: selectedIcon.codePoint,
                          color: selectedColor.toARGB32(),
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Add Category'),
                ),
                const Gap(8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCategory(
      BuildContext context, WidgetRef ref, Category cat) {
    final nameController = TextEditingController(text: cat.name);
    var selectedIcon =
        IconData(cat.iconCodePoint, fontFamily: cat.iconFontFamily);
    var selectedColor = Color(cat.color);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: sheetBottomPadding(context),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit Category',
                    style: Theme.of(context).textTheme.titleLarge),
                const Gap(16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const Gap(12),
                Text('Color',
                    style: Theme.of(context).textTheme.titleSmall),
                const Gap(8),
                ColorPicker(
                  selectedColor: selectedColor.toARGB32(),
                  onSelected: (c) =>
                      setSheetState(() => selectedColor = c),
                ),
                const Gap(12),
                Text('Icon',
                    style: Theme.of(context).textTheme.titleSmall),
                const Gap(8),
                IconPicker(
                  selectedCodePoint: selectedIcon.codePoint,
                  onSelected: (i) =>
                      setSheetState(() => selectedIcon = i),
                ),
                const Gap(16),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Haptics.medium();
                    await ref.read(categoryRepositoryProvider).update(
                          cat.copyWith(
                            name: name,
                            iconCodePoint: selectedIcon.codePoint,
                            iconFontFamily:
                                selectedIcon.fontFamily ?? 'MaterialIcons',
                            color: selectedColor.toARGB32(),
                          ),
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
                const Gap(8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Category cat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content:
            Text('Delete "${cat.name}"? Transactions won\'t be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Haptics.medium();
              await ref
                  .read(categoryRepositoryProvider)
                  .deleteById(cat.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

