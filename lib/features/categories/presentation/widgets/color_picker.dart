import 'package:flutter/material.dart';
import 'package:dime_money/core/theme/color_tokens.dart';
import 'package:dime_money/core/utils/haptics.dart';

class ColorPicker extends StatelessWidget {
  final int? selectedColor;
  final ValueChanged<Color> onSelected;

  const ColorPicker({
    super.key,
    this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppColors.categoryPalette.map((color) {
        final isSelected = color.toARGB32() == selectedColor;

        return GestureDetector(
          onTap: () {
            Haptics.selection();
            onSelected(color);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
