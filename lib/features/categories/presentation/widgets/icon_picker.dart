import 'package:flutter/material.dart';
import 'package:dime_money/core/utils/haptics.dart';

const curatedIcons = [
  Icons.restaurant,
  Icons.local_cafe,
  Icons.shopping_bag,
  Icons.shopping_cart,
  Icons.directions_car,
  Icons.directions_bus,
  Icons.flight,
  Icons.train,
  Icons.local_gas_station,
  Icons.home,
  Icons.apartment,
  Icons.receipt_long,
  Icons.bolt,
  Icons.water_drop,
  Icons.phone_android,
  Icons.wifi,
  Icons.movie,
  Icons.sports_esports,
  Icons.music_note,
  Icons.fitness_center,
  Icons.favorite,
  Icons.medical_services,
  Icons.school,
  Icons.menu_book,
  Icons.work,
  Icons.business_center,
  Icons.attach_money,
  Icons.savings,
  Icons.card_giftcard,
  Icons.pets,
  Icons.child_care,
  Icons.checkroom,
  Icons.dry_cleaning,
  Icons.cut,
  Icons.park,
  Icons.beach_access,
  Icons.spa,
  Icons.local_grocery_store,
  Icons.more_horiz,
  Icons.star,
];

class IconPicker extends StatelessWidget {
  final int? selectedCodePoint;
  final ValueChanged<IconData> onSelected;

  const IconPicker({
    super.key,
    this.selectedCodePoint,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: curatedIcons.length,
      itemBuilder: (context, index) {
        final icon = curatedIcons[index];
        final isSelected = icon.codePoint == selectedCodePoint;

        return GestureDetector(
          onTap: () {
            Haptics.selection();
            onSelected(icon);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
