import 'package:get/get.dart';

class AppDrawerController extends GetxController {
  final _selectedIndex = "Dashboard".obs;
  final _notesExpanded = false.obs;

  String get selectedIndex => _selectedIndex.value;
  bool get notesExpanded => _notesExpanded.value;

  void setSelectedIndex(String index) => _selectedIndex.value = index;

  void toggleNotes() {
    _notesExpanded.value = !_notesExpanded.value;
  }

  void collapseNotes() {
    _notesExpanded.value = false;
  }
}
