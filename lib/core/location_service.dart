// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:async'; // Cho Timer
import 'dart:ui'; // Cho DartPluginRegistrant
import 'package:flutter/foundation.dart'; // For kDebugMode

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> init() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        autoStartOnBoot: true,
        notificationChannelId: 'sos_battery_channel',
        initialNotificationTitle: 'SOS-BATTERY Hero Online',
        initialNotificationContent: 'Tracking location in background',
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized(); // Đã có import dart:ui

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "SOS-BATTERY Hero Online",
        content: "Tracking location...",
      );
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (kDebugMode) {
        var latitude = position.latitude;
        print('Background location: ${latitude}, ${position.longitude}');
      }
      // Forward location to the main isolate / uploader via the background service
      service.invoke('updateLocation', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    Timer.periodic(const Duration(seconds: 60), (timer) {
      service.invoke('heartbeat');
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  static void start() {
    _service.startService();
  }

  static void stop() {
    _service.invoke('stopService');
  }
}
