import 'dart:async';   // Cho Timer
import 'dart:ui';      // Cho DartPluginRegistrant

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
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
    DartPluginRegistrant.ensureInitialized();   // Đã có import dart:ui

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
      print('📍 Background Location: ${position.latitude}, ${position.longitude}');
      // TODO: Gửi lên Firestore cho Hero online
    });

    Timer.periodic(const Duration(seconds: 60), (timer) {
      print('❤️ Heartbeat - Service still alive');
      service.invoke('heartbeat');
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  static void start() {
    _service.startService();
    print('✅ Background Location Service started');
  }

  static void stop() {
    _service.invoke('stopService');
    print('❌ Background Location Service stopped');
  }
}