import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/dashboard/presentation/providers/dashboard_provider.dart';

class PeriodToggle extends ConsumerWidget {
  const PeriodToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(dashboardPeriodProvider);

    return SegmentedButton<DashboardPeriod>(
      segments: const [
        ButtonSegment(
          value: DashboardPeriod.daily,
          label: Text('Day'),
        ),
        ButtonSegment(
          value: DashboardPeriod.weekly,
          label: Text('Week'),
        ),
        ButtonSegment(
          value: DashboardPeriod.monthly,
          label: Text('Month'),
        ),
      ],
      selected: {current},
      onSelectionChanged: (selection) {
        Haptics.selection();
        ref.read(dashboardPeriodProvider.notifier).set(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
