import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';

class AnnouncementController {
  static const String _keyAnnouncements = "announcements_list";

  static Future<List<AnnouncementModel>> getAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyAnnouncements);

    if (data == null) return [];

    final decoded = jsonDecode(data) as List;
    return decoded.map((e) => AnnouncementModel.fromJson(e)).toList();
  }

  static Future<void> addAnnouncement(AnnouncementModel announcement) async {
    final list = await getAnnouncements();
    list.insert(0, announcement);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyAnnouncements,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> deleteAnnouncement(String id) async {
    final list = await getAnnouncements();
    list.removeWhere((e) => e.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyAnnouncements,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }
}
