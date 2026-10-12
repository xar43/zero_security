import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../config/api/api_services.dart';
import '../../../config/constants/url_constants.dart';
import '../../../config/local/local_storage_services.dart';
import '../helper/notification_services.dart';

class LocationController extends GetxController {
  RxMap<String, DailyLocationDataModel> dailyLocationMap = <String, DailyLocationDataModel>{}.obs;

  Timer? _hourlyTimer;
  RxBool isTracking = false.obs;
  String? currentSessionKey;

 

  String get _timestampKey => DateFormat('yyyy-MM-dd_HH:mm:ss').format(DateTime.now());

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Permission Denied', 'Location permission is required');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Permission Denied Permanently', 'Please enable location permission in app settings');
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<String> _getReadableAddress(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final readableAddress =
            "${placemark.name}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
        log("📍 Resolved Address: $readableAddress");
        return readableAddress;
      } else {
        log("⚠️ No placemarks found.");
        return 'Lat: ${position.latitude}, Lon: ${position.longitude}';
      }
    } catch (e) {
      log("❌ Reverse geocoding failed: $e");
      return 'Lat: ${position.latitude}, Lon: ${position.longitude}';
    }
  }

  Future<String> getCurrentLocation() async {
    bool hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return 'Permission not granted';

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high,
      );
      return await _getReadableAddress(position);
    } catch (e) {
      log("❌ Failed to get current position: $e");
      return 'Unable to get location';
    }
  }

  void startTracking() async {
    if (isTracking.value) {
      Get.snackbar('Already Tracking', 'Please stop the current session first.');
      return;
    }

    bool hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    // Get actual Position for lat/lng
    Position? startPosition;
    try {
      startPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      log('❌ Failed to get start position: $e');
    }

    String start = startPosition != null
        ? await _getReadableAddress(startPosition)
        : await getCurrentLocation();
    String sessionKey = _timestampKey;
    currentSessionKey = sessionKey;

    String now = DateFormat('hh:mm:ss a').format(DateTime.now());

    dailyLocationMap[sessionKey] = DailyLocationDataModel(
      startLocation: start,
      hourlyLocations: [],
      endLocation: '',
      startTime: now,
      endTime: '',
    );

    isTracking.value = true;

    // Backend par start location log karo
    _logLocationToBackend(
      latitude: startPosition?.latitude ?? 0.0,
      longitude: startPosition?.longitude ?? 0.0,
      address: start,
    );

    _hourlyTimer?.cancel();
    _hourlyTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (_) {}
      String loc = pos != null ? await _getReadableAddress(pos) : await getCurrentLocation();
      dailyLocationMap[sessionKey]?.hourlyLocations.add(loc);
      dailyLocationMap.refresh();
      log("⏱️ Tracked: $loc");

      // Backend par bhi log karo
      _logLocationToBackend(
        latitude: pos?.latitude ?? 0.0,
        longitude: pos?.longitude ?? 0.0,
        address: loc,
      );
    });

    await NotificationService.showTrackingNotification(
      title: 'Tracking Started', body: 'Tracking started at $start',
    );
  }

  /// Backend ko location JSON format mein bhejo (log_location API)
  Future<void> _logLocationToBackend({required double latitude, required double longitude, required String address}) async {
    final empId = LocalStorageServices.getEmployeeId();
    final company = LocalStorageServices.getCompany();
    if (empId == null || company == null) {
      debugPrint('⚠️ log_location skipped: empId/company null');
      return;
    }
    try {
      final api = ApiServices();
      await api.postRequest(
        UrlConstants.logLocationUrl,
        body: {
          "employee_id": empId,
          "company": company,
          "latitude": latitude,
          "longitude": longitude,
          "location": address,
        },
      );
      debugPrint('✅ Location logged to backend: $latitude, $longitude');
    } catch (e) {
      debugPrint('⚠️ log_location API failed: $e');
    }
  }

  void stopTracking() async {
    if (!isTracking.value) {
      Get.snackbar('Not Tracking', 'No active tracking session.');
      return;
    }

    _hourlyTimer?.cancel();
    _hourlyTimer = null;

    String end = await getCurrentLocation();
    String now = DateFormat('hh:mm:ss a').format(DateTime.now());

    if (currentSessionKey != null && dailyLocationMap.containsKey(currentSessionKey)) {
      final currentData = dailyLocationMap[currentSessionKey!]!;
      dailyLocationMap[currentSessionKey!] = DailyLocationDataModel(
        startLocation: currentData.startLocation,
        hourlyLocations: currentData.hourlyLocations,
        endLocation: end,
        startTime: currentData.startTime,
        endTime: now,
      );
      dailyLocationMap.refresh();
      log("🛑 Tracking stopped at: $end");
    }

    isTracking.value = false;
    currentSessionKey = null;
    await NotificationService.showTrackingNotification( 
      title: 'Tracking Stopped', body: 'Tracking stopped at $end');
  }

  @override
  void onClose() {
    _hourlyTimer?.cancel();
    super.onClose();
  }
}
class DailyLocationDataModel {
  final String startLocation;
  final List<String> hourlyLocations;
  final String endLocation;
  final String startTime;
  final String endTime;

  DailyLocationDataModel({
    required this.startLocation,
    required this.hourlyLocations,
    required this.endLocation,
    required this.startTime,
    required this.endTime,
  });
}
