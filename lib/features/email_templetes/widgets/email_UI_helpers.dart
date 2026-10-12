import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/colors/app_colors.dart';

Widget emailHeader(BuildContext context, String title) => Row(
  children: [
    Expanded(
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.close, color: Colors.white),
      onPressed: () => Get.back(),
    ),
  ],
);

Widget inputBox({
  required TextEditingController controller,
  required String hint,
  double height = 45,
  int maxLines = 1,
  bool readOnly = false,
  Widget? suffixIcon,
}) =>
    SizedBox(
      height: height,
      width: double.infinity,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
    cursorColor: AppColors.kAppWhite,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: AppColors.kAppSecondary.withValues(alpha: .18),
          contentPadding: const EdgeInsets.all(12),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );


Widget gradientButton(String text, VoidCallback onTap) => Container(
  height: 46,
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(10),
  ),
  child: TextButton(
    onPressed: onTap,
    child: Text(text, style: const TextStyle(color: Colors.white)),
  ),
);
