import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/colors/app_colors.dart';

abstract class AppUtils {
static Widget gradientFlexibleSpace() => Container(
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3, spreadRadius: 0)],
    ),
  );

  static String formatTimeToReadable(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 3) return timeStr; // fallback if format is invalid

      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);

      return '$hours Hr ${minutes.toString().padLeft(2, '0')} Min ${seconds.toString().padLeft(2, '0')} Sec';
    } catch (e) {
      return timeStr; // fallback in case of parsing error
    }
  }

  static String formatDateToReadable(String dateStr) {
    try {
      final date = DateTime.parse(dateStr); // Parses "2025-07-23"
      final formatter = DateFormat('EEE, d, y'); // Outputs: "Tue, 23, 2025"
      return formatter.format(date);
    } catch (e) {
      return dateStr; // fallback if parsing fails
    }
  }

  static String formatTimeToAmPm(String timeStr) {
    try {
      final time = DateFormat('HH:mm:ss').parse(timeStr); // Parses "10:00:00"
      return DateFormat('h:mm a').format(time); // Returns "10:00 AM"
    } catch (e) {
      return timeStr; // fallback if parsing fails
    }
  }
}
