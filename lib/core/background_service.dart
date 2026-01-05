import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'sos_battery_channel',
      initialNotificationTitle: 'SOS Battery Running',
      initialNotificationContent: 'Keeping connection for rescue job...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "SOS Battery",
      content: "Maintaining connection for active rescue job...",
    );
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Listen job active (khi app background)
  FirebaseFirestore.instance
      .collection('sos_requests')
      .where('heroId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'accepted')
      .snapshots()
      .listen((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      print('Active job found in background - keeping connection');
      // Có thể send local notification nếu cần
      // service.invoke('showNotification', {'title': 'Active Job', 'content': 'Reopen app to continue!'});
    }
  });

  // Keep alive timer
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "SOS Battery",
          content: "Keeping connection for rescue...",
        );
      }
    }
  });
}
