import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NotesController extends GetxController {
  final openNotes = <NoteModel>[].obs;
  final closedNotes = <NoteModel>[].obs;
  final filteredHistory = <NoteModel>[].obs;
  final filterStatusOpen = RxnBool();
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  NoteModel? editingNote;

  static const String _notesKey = "notes_data";

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_notesKey);

    if (jsonString == null) {
      openNotes.clear();
      closedNotes.clear();
      filteredHistory.clear();
      return;
    }

    final decoded = jsonDecode(jsonString) as List;

    final notes = decoded.map((e) {
      return NoteModel(
        id: e["id"],
        title: e["title"],
        createdAt: DateTime.parse(e["createdAt"]),
        updatedAt: DateTime.parse(e["updatedAt"]),
        isOpen: e["isOpen"],
        listName: e["listName"],
      );
    }).toList();

    openNotes.assignAll(notes.where((n) => n.isOpen).toList());
    closedNotes.assignAll(notes.where((n) => !n.isOpen).toList());

    filteredHistory.assignAll([...openNotes, ...closedNotes]);
  }


  Future<void> _saveAllNotes(List<NoteModel> notes) async {
    final prefs = await SharedPreferences.getInstance();

    final data = notes.map((n) {
      return {
        "id": n.id,
        "title": n.title,
        "createdAt": n.createdAt.toIso8601String(),
        "updatedAt": n.updatedAt.toIso8601String(),
        "isOpen": n.isOpen,
        "listName": n.listName,
      };
    }).toList();

    await prefs.setString(_notesKey, jsonEncode(data));
  }


  void applyFilter() {
    List<NoteModel> data = [...openNotes, ...closedNotes];

    if (startDate.value != null) {
      final start = DateTime(
        startDate.value!.year,
        startDate.value!.month,
        startDate.value!.day,
      );

      final endSource = endDate.value ?? startDate.value!;
      final end = DateTime(
        endSource.year,
        endSource.month,
        endSource.day,
        23,
        59,
        59,
        999,
      );

      data = data.where((n) {
        return !n.createdAt.isBefore(start) && !n.createdAt.isAfter(end);
      }).toList();
    }

    if (filterStatusOpen.value != null) {
      data = data.where((n) => n.isOpen == filterStatusOpen.value).toList();
    }

    filteredHistory.assignAll(data);
  }

  void clearFilters() {
    startDate.value = null;
    endDate.value = null;
    filterStatusOpen.value = null;
    filteredHistory.assignAll([...openNotes, ...closedNotes]);
  }


  Future<void> addNote(String text, bool isOpen, {String? listName}) async {
    if (text.trim().isEmpty) return;

    final allNotes = [...openNotes, ...closedNotes];

    final nextId = allNotes.isEmpty
        ? 1
        : (allNotes.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

    final now = DateTime.now();

    final note = NoteModel(
      id: nextId,
      title: text.trim(),
      createdAt: now,
      updatedAt: now,
      isOpen: isOpen,
      listName: listName,
    );

    allNotes.add(note);

    await _saveAllNotes(allNotes);
    await loadNotes();
  }

  Future<void> updateNote(String text, bool isOpen, {int? id, String? listName}) async {
    final noteId = id ?? editingNote?.id;
    if (noteId == null || text.trim().isEmpty) return;

    final allNotes = [...openNotes, ...closedNotes];

    final index = allNotes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final noteToUpdate = allNotes[index];
    final updatedNote = noteToUpdate.copyWith(
      title: text.trim(),
      isOpen: isOpen,
      updatedAt: DateTime.now(),
      listName: listName ?? noteToUpdate.listName,
    );

    allNotes[index] = updatedNote;

    await _saveAllNotes(allNotes);

    if (id == null) {
      editingNote = null;
    }
    await loadNotes();
  }

  Future<void> deleteNote(NoteModel note) async {
    final allNotes = [...openNotes, ...closedNotes];
    allNotes.removeWhere((n) => n.id == note.id);

    await _saveAllNotes(allNotes);
    await loadNotes();
  }
}
