import 'package:flutter/material.dart';

import '../../../config/colors/app_colors.dart';
import '../../../config/typography/app_typography.dart';

class TimeWithColon extends StatelessWidget {
  final String value;
  final String label;
  final bool showColon;

  const TimeWithColon(
      this.value,
      this.label, {
        super.key,
        required this.showColon,
      });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(
            value,
            style:
            AppTypography.style18SemiBold.copyWith(color: Colors.white),
          ),
          if (showColon)
            Text(
              " :",
              style: AppTypography.style18SemiBold
                  .copyWith(color: Colors.white),
            ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: AppTypography.style10Regular.copyWith(color: Colors.white70),
      ),
    ],
  );
}

class StatusChip extends StatelessWidget {
  final String text;
  final bool active;

  const StatusChip(this.text, this.active, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: active
          ? AppColors.kAppSecondary
          : Colors.black.withOpacity(.3),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Text(
      text,
      style: AppTypography.style12SemiBold.copyWith(
        color: active ? Colors.black : Colors.white,
      ),
    ),
  );
}

class YAxisLabel extends StatelessWidget {
  final String text;
  const YAxisLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Text(
      text,
      style: AppTypography.style10Regular.copyWith(color: Colors.white70),
    ),
  );
}

class ActivityBarGroup extends StatelessWidget {
  final double darkValue;
  final double brightValue;
  final String label;

  const ActivityBarGroup(this.darkValue, this.brightValue, this.label,
      {super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Bar(height: darkValue * 3, color: const Color(0xFF14532D)),
          const SizedBox(width: 4),
          Bar(height: brightValue * 3, color: AppColors.kAppSecondary),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: 44,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.style10Regular
              .copyWith(color: Colors.white70),
        ),
      ),
    ],
  );
}

class Bar extends StatelessWidget {
  final double height;
  final Color color;

  const Bar({super.key, required this.height, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}
