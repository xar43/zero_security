import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/colors/app_colors.dart';
import '../controller/note_controller.dart';
import '../widgets/ui_helpers.dart';

void showAddNoteSheet(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add Note',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => const SizedBox(),
    transitionBuilder: (_, animation, _, _) {
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(animation),
        child: const AddNoteSheet(),
      );
    },
  );
}

class AddNoteSheet extends StatefulWidget {
  const AddNoteSheet({super.key});

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  late final TextEditingController textCtrl;
  late final TextEditingController listNameCtrl;
  late final RxnBool statusOpen;
  final RxBool isValid = false.obs;

  NotesController get controller => Get.find<NotesController>();
  bool get isEdit => controller.editingNote != null;

  @override
  void initState() {
    super.initState();

    textCtrl = TextEditingController(
      text: controller.editingNote?.title ?? "",
    );
    
    listNameCtrl = TextEditingController(
      text: controller.editingNote?.listName ?? "",
    );

    /// Default = Closed (false)
    statusOpen = RxnBool(controller.editingNote?.isOpen ?? false);

    textCtrl.addListener(_validate);
    _validate();
  }

  void _validate() {
    isValid.value = textCtrl.text.trim().isNotEmpty && statusOpen.value != null;
  }

  @override
  void dispose() {
    textCtrl.dispose();
    listNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayText =
        "TODAY   ${now.day}/${now.month}/${now.year} | ${TimeOfDay.now().format(context)}";

    final topOffset = MediaQuery.of(context).padding.top + 80;

    return Padding(
      padding: EdgeInsets.only(top: topOffset),
      child: Material(
        color: AppColors.kAppBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              notesHeader(context, isEdit ? "Update Details" : "Notes"),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.kAppSecondary.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  todayText,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.kAppSecondary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: "Add a note ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: "*",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),

                      inputBox(
                        controller: textCtrl,
                        hint: "Write your note here",
                        height: 120,
                        maxLines: 5,
                      ),

                      const SizedBox(height: 16),

                      const SizedBox(height: 16),
                      sectionLabel("List Name (Optional)"),
                      inputBox(
                        controller: listNameCtrl,
                        hint: "Enter list or folder name",
                      ),

                      const SizedBox(height: 16),

                      RichText(
                        text: const TextSpan(
                          text: "Status ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: "*",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),

                      Obx(
                            () => DropdownButtonFormField<bool>(
                          value: statusOpen.value, // default Closed
                          dropdownColor: AppColors.kAppBackground,
                          items: const [
                            DropdownMenuItem(
                              value: true,
                              child: Text("Open"),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text("Closed"),
                            ),
                          ],
                          onChanged: (v) {
                            statusOpen.value = v;
                            _validate();
                          },
                          decoration: _dropdownDecoration(),
                        ),
                      ),

                      const Spacer(),

                      /// SUBMIT
                      Obx(
                            () => IgnorePointer(
                          ignoring: !isValid.value,
                          child: Opacity(
                            opacity: isValid.value ? 1 : 0.5,
                            child: SizedBox(
                              width: double.infinity,
                              child: gradientButton(
                                "Submit",
                                    () async {
                                    final lst = listNameCtrl.text.trim();
                                    final listVal = lst.isEmpty ? null : lst;
                                    if (isEdit) {
                                      await controller.updateNote(
                                        textCtrl.text,
                                        statusOpen.value!,
                                        listName: listVal,
                                      );
                                    } else {
                                      await controller.addNote(
                                        textCtrl.text,
                                        statusOpen.value!,
                                        listName: listVal,
                                      );
                                    }

                                    textCtrl.clear();
                                    listNameCtrl.clear();

                                  /// Reset default to Closed
                                  statusOpen.value = false;

                                  _validate();
                                  Get.back();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: AppColors.kAppSecondary.withValues(alpha: .18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}
