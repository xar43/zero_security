import 'package:flutter/material.dart';

import '../../../config/colors/app_colors.dart';
import '../models/note_model.dart';

Widget notesHeader(BuildContext context, String title) => Row(
  children: [
    Expanded(
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
    ),
    IconButton(
      icon: const Icon(Icons.close, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
  ],
);

Widget sectionLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: const TextStyle(color: Colors.white70)),
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

Widget historyCard(
    NoteModel note, {
      required VoidCallback onEdit,
      bool? isSelected,
      ValueChanged<bool?>? onSelect,
    }) =>
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
    color: AppColors.kAppSecondary.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isSelected != null && onSelect != null)
                Checkbox(
                  value: isSelected,
                  onChanged: onSelect,
                  activeColor: AppColors.kAppSecondary,
                  side: const BorderSide(color: Colors.white54),
                ),
              Expanded(
                child: Text(
                  note.title,
                  style:
                  const TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.white54,
                ),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                note.isOpen ? "OPEN" : "CLOSED",
                style: TextStyle(
                  color: note.isOpen
                      ? AppColors.kAppSecondary
                      : Colors.redAccent,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                "${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}",
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );

