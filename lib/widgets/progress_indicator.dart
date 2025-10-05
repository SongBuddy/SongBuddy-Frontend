// lib/widgets/progress_indicator.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ConnectionProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int completedSteps;

  const ConnectionProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.completedSteps,
  }) : assert(totalSteps > 0);

  @override
  Widget build(BuildContext context) {
    final double ratio = (completedSteps / totalSteps).clamp(0.0, 1.0);
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connections progress', style: textStyle?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text('$completedSteps of $totalSteps completed', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
