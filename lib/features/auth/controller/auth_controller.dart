import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:toggle_timer/config/api/api_services.dart';
import 'package:toggle_timer/config/constants/url_constants.dart';
import 'package:toggle_timer/config/local/local_storage_services.dart';
import 'package:toggle_timer/core/utils/app_log.dart';
import 'package:toggle_timer/core/utils/app_prompts.dart';
import 'package:toggle_timer/features/auth/models/login_model.dart';

class AuthController extends GetxController {
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  final _apiServices = ApiServices();

  Future<bool> login(LoginRequestModel request) async {
    try {
      _isLoading.value = true;
      final json = await _apiServices.postRequest(UrlConstants.loginUrl, body: request.toJson());
      if (json != null) {
        debugPrint('🔐 LOGIN RAW RESPONSE: $json');

        // Token save karo
        final token = json['token'] as String?;
        if (token != null) {
          await LocalStorageServices.saveData<String>(LocalStorageKeys.token.name, token);
          debugPrint('✅ Token saved: $token');
        }

        // details se employee_id aur company nikalo
        final details = json['details'] as Map<String, dynamic>?;
        debugPrint('👤 details field: $details');

        final empId = details?['employee_id'] as String?;
        final company = details?['company'] as String?;

        debugPrint('👤 employeeId: $empId');
        debugPrint('🏢 company: $company');

        if (empId != null) {
          await LocalStorageServices.saveData<String>(LocalStorageKeys.employeeId.name, empId);
          debugPrint('✅ employeeId saved!');
        } else {
          debugPrint('⚠️ employeeId is NULL in response!');
        }

        if (company != null) {
          await LocalStorageServices.saveData<String>(LocalStorageKeys.company.name, company);
          debugPrint('✅ company saved!');
        } else {
          debugPrint('⚠️ company is NULL in response!');
        }

        return true;
      }
    } catch (e) {
      debugPrint('❌ LOGIN ERROR: $e');
      AppPrompts.showError(message: e.toString());
      AppLog.errorLog("login", e.toString());
    } finally {
      _isLoading.value = false;
    }
    return false;
  }
}
