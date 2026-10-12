import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sent_mail_model.dart';

class SentMailController {
  static const String _storageKey = "sent_mails";

  static Future<List<SentMailModel>> getSentMails() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data == null) return [];

    final List decoded = jsonDecode(data);

    return decoded.map((e) => SentMailModel.fromJson(e)).toList();
  }

  static Future<void> saveSentMails(List<SentMailModel> mails) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = mails.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  static Future<void> addSentMail(SentMailModel mail) async {
    final mails = await getSentMails();
    mails.insert(0, mail);
    await saveSentMails(mails);
  }

  static Future<void> deleteSentMail(String id) async {
    final mails = await getSentMails();
    mails.removeWhere((m) => m.id == id);
    await saveSentMails(mails);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
