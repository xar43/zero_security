import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageServices {
  static SharedPreferences? _preferences;

  static Future<SharedPreferences> get instance async => _preferences ??= await SharedPreferences.getInstance();

  static Future<bool> saveData<T>(String key, T value) async {
    if (_preferences?.containsKey(key.toString()) ?? false) {
      await deleteData(key);
    }
    if (T == String) {
      return await _preferences?.setString(key.toString(), value as String) ?? false;
    } else if (T == int) {
      return await _preferences?.setInt(key.toString(), value as int) ?? false;
    } else if (T == bool) {
      return await _preferences?.setBool(key.toString(), value as bool) ?? false;
    } else if (T == List<String>) {
      return await _preferences?.setStringList(key.toString(), value as List<String>) ?? false;
    } else {
      return await _preferences?.setString(key.toString(), jsonEncode(value).toString()) ?? false;
    }
  }

  static T? getData<T>(String key) {
    if (T == String) {
      return _preferences?.getString(key.toString()) as T?;
    } else if (T == int) {
      return _preferences?.getInt(key.toString()) as T?;
    } else if (T == bool) {
      return _preferences?.getBool(key.toString()) as T?;
    } else if (T == List<String>) {
      return _preferences?.getStringList(key.toString()) as T?;
    } else {
      final jsonString = _preferences?.getString(key.toString());
      if (jsonString != null) return jsonDecode(jsonString) as T?;
    }
    return null;
  }

  static List<T> getListData<T>(String key, {required T? Function(Map<String, dynamic> json) fromJson}) {
    final jsonString = _preferences?.getString(key.toString());
    if (jsonString != null) {
      return List<T>.from(jsonDecode(jsonString).map((e) => fromJson(e)).toList());
    }
    return [];
  }

  static Future<bool> clearAll() async {
    return await _preferences?.clear() ?? false;
  }

  static Future<bool> deleteData(String key) async {
    if (_preferences?.containsKey(key.toString()) ?? false) {
      return await _preferences?.remove(key.toString()) ?? false;
    }
    return false;
  }

  static String? getToken() => getData<String>(LocalStorageKeys.token.name);
  static String? getEmployeeId() => getData<String>(LocalStorageKeys.employeeId.name);
  static String? getCompany() => getData<String>(LocalStorageKeys.company.name);
}

enum LocalStorageKeys { token, employeeId, company }
