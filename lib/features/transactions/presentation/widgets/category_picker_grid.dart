import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

class CategoryPickerGrid extends ConsumerWidget {
  final int? selectedId;
  final ValueChanged<Category> onSelected;

  /// If true, renders as a compact horizontal wrap instead of a full grid.
  final bool compact;

  const CategoryPickerGrid({
    super.key,
    this.selectedId,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (categories) =>
          compact ? _buildWrap(context, categories) : _buildGrid(context, categories),
    );
  }

  Widget _buildWrap(BuildContext context, List<Category> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat.id == selectedId;
        final catColor = Color(cat.color);

        return GestureDetector(
          onTap: () {
            Haptics.selection();
            onSelected(cat);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? catColor.withValues(alpha: 0.2)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh
                      .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: catColor, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconData(cat.iconCodePoint,
                      fontFamily: cat.iconFontFamily),
                  color: catColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? catColor
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(BuildContext context, List<Category> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = cat.id == selectedId;
        final catColor = Color(cat.color);

        return GestureDetector(
          onTap: () {
            Haptics.selection();
            onSelected(cat);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? catColor.withValues(alpha: 0.2)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh
                      .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: catColor, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconData(cat.iconCodePoint,
                      fontFamily: cat.iconFontFamily),
                  color: catColor,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  cat.name,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
