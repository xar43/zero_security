// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/colors/app_colors.dart';
import '../../../core/helper/app_helper.dart';
import '../../../core/utils/app_utils.dart';
import '../../home/widgets/app_drawer.dart';
import '../controller/note_controller.dart';
import '../models/note_model.dart';
import '../widgets/ui_helpers.dart';
import 'add_note.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final NotesController controller = Get.find<NotesController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<int> _selectedNoteIds = {};
  String? _activeListName;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedNoteIds.contains(id)) {
        _selectedNoteIds.remove(id);
      } else {
        _selectedNoteIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNoteIds.clear();
    });
  }

  Future<void> _groupNotesIntoList() async {
    if (_selectedNoteIds.isEmpty) return;
    
    final TextEditingController nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.kAppBackground,
        title: const Text('Create List', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter list name',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: AppColors.kAppSecondary.withValues(alpha: .18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      for (var id in _selectedNoteIds) {
        final note = controller.filteredHistory.firstWhere((n) => n.id == id);
        await controller.updateNote(note.title, note.isOpen, id: id, listName: name);
      }
      Get.snackbar("List Created", "${_selectedNoteIds.length} notes added to '$name'.");
    }
    _clearSelection();
  }

  Future<void> _toggleSelectedStatus() async {
    if (_selectedNoteIds.isEmpty) return;
    for (var id in _selectedNoteIds) {
      final note = controller.filteredHistory.firstWhere((n) => n.id == id);
      await controller.updateNote(note.title, !note.isOpen, id: id);
    }
    _clearSelection();
    await controller.loadNotes();
  }

  @override
  void initState() {
    super.initState();
    controller.loadNotes();
  }

  void _openAddEdit({NoteModel? note}) {
    controller.editingNote = note;
    showAddNoteSheet(context);
    controller.loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.kAppBackground,
      drawer: const AppDrawer(),
      appBar: _selectedNoteIds.isNotEmpty
          ? AppBar(
              title: Text("${_selectedNoteIds.length} Selected"),
              flexibleSpace: AppUtils.gradientFlexibleSpace(),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.create_new_folder),
                  tooltip: 'Create List',
                  onPressed: _groupNotesIntoList,
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Toggle Open/Close',
                  onPressed: _toggleSelectedStatus,
                ),
              ],
            )
          : AppBar(
              title: Text(_activeListName ?? "Notes"),
              flexibleSpace: AppUtils.gradientFlexibleSpace(),
              leading: _activeListName == null
                  ? AppHelper.buildDrawerButton(_scaffoldKey)
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _activeListName = null),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kAppSecondary,
        onPressed: () => _openAddEdit(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// FILTERS (same like history)
              _Filters(controller: controller),
              const SizedBox(height: 16),

              /// FOLDERS LIST
              if (_activeListName == null)
                Obx(() {
                  final uniqueLists = controller.filteredHistory
                      .where((n) => n.listName != null && n.listName!.isNotEmpty)
                      .map((n) => n.listName!)
                      .toSet()
                      .toList();
                  
                  if (uniqueLists.isEmpty) return const SizedBox.shrink();

                  return Container(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: uniqueLists.length,
                      itemBuilder: (context, index) {
                        final listName = uniqueLists[index];
                        return GestureDetector(
                          onTap: () => setState(() => _activeListName = listName),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.kAppSecondary.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder, color: Colors.amber, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  listName,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),

              /// NOTES LIST
              Expanded(
                child: Obx(() {
                  final displayNotes = _activeListName == null 
                      ? controller.filteredHistory.where((n) => n.listName == null || n.listName!.isEmpty).toList()
                      : controller.filteredHistory.where((n) => n.listName == _activeListName).toList();

                  if (displayNotes.isEmpty) {
                    return const Center(
                      child: Text(
                        "No notes found",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await controller.loadNotes();
                    },
                    child: ListView.builder(
                      itemCount: displayNotes.length,
                      itemBuilder: (_, index) {
                        final note = displayNotes[index];

                        return historyCard(
                          note,
                          onEdit: () => _openAddEdit(note: note),
                          isSelected: _selectedNoteIds.contains(note.id),
                          onSelect: (val) => _toggleSelection(note.id),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
      ).paddingAll(16),
    );
  }
}

class _Filters extends StatelessWidget {
  final NotesController controller;
  const _Filters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            /// DATE FILTER
            Expanded(
              child: Obx(
                    () => InkWell(
                  onTap: () async {
                    final start = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate:
                      controller.startDate.value ?? DateTime.now(),
                      helpText: "Select From Date",
                    );

                    if (start == null) return;

                    if (context.mounted) {
                      final end = await showDatePicker(
                      context: context,
                      firstDate: start,
                      lastDate: DateTime.now(),
                      initialDate: controller.endDate.value ?? start,
                      helpText: "Select To Date",
                      );
                    controller.startDate.value = start;
                    controller.endDate.value = end;
}

                    /// AUTO APPLY
                    controller.applyFilter();
                  },
                  child: _formLikeBox(_dateText()),
                ),
              ),
            ),
            const SizedBox(width: 8),

            /// STATUS FILTER
            Expanded(
              child: Obx(
                    () => DropdownButtonFormField<bool>(
                  value: controller.filterStatusOpen.value,
                  dropdownColor: AppColors.kAppBackground,
                  hint: const Text(
                    "Select Status",
                    style: TextStyle(color: Colors.white54),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text("Open")),
                    DropdownMenuItem(value: false, child: Text("Closed")),
                  ],
                  onChanged: (v) {
                    controller.filterStatusOpen.value = v;

                    /// AUTO APPLY
                    controller.applyFilter();
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.kAppSecondary.withOpacity(.18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// CLEAR FILTERS BUTTON (BEST DESIGN)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              controller.clearFilters();
              controller.applyFilter();
            },
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
            label: const Text(
              "Clear Filters",
              style: TextStyle(color: Colors.white70),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: AppColors.kAppSecondary.withOpacity(.6),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _dateText() {
    final s = controller.startDate.value;
    final e = controller.endDate.value;

    if (s == null && e == null) return "From date – To date";
    if (s != null && e == null) return "From ${_fmt(s)}";
    return "From ${_fmt(s!)} to ${_fmt(e!)}";
  }

  static String _fmt(DateTime d) => "${d.day}/${d.month}/${d.year}";

  static Widget _formLikeBox(String text) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      color: AppColors.kAppSecondary.withOpacity(.18),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white70),
    ),
  );
}
