import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_template_model.dart';

class EmailTemplateController {
  static const String _storageKey = "email_templates";

  /// GET ALL TEMPLATES
  static Future<List<EmailTemplateModel>> getTemplates() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_storageKey);

    if (data == null) return [];

    final List decodedList = jsonDecode(data);

    return decodedList.map((e) => EmailTemplateModel.fromJson(e)).toList();
  }

  /// SAVE LIST
  static Future<void> saveTemplates(List<EmailTemplateModel> templates) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = templates.map((e) => e.toJson()).toList();

    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// ADD NEW TEMPLATE
  static Future<void> addTemplate(EmailTemplateModel template) async {
    final templates = await getTemplates();
    templates.insert(0, template);
    await saveTemplates(templates);
  }

  /// UPDATE TEMPLATE
  static Future<void> updateTemplate(EmailTemplateModel updatedTemplate) async {
    final templates = await getTemplates();

    final index = templates.indexWhere((t) => t.id == updatedTemplate.id);

    if (index != -1) {
      templates[index] = updatedTemplate;
      await saveTemplates(templates);
    }
  }

  /// DELETE TEMPLATE
  static Future<void> deleteTemplate(String id) async {
    final templates = await getTemplates();
    templates.removeWhere((t) => t.id == id);
    await saveTemplates(templates);
  }

  /// CLEAR ALL (OPTIONAL)
  static Future<void> clearAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
