import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

/// Service quản lý background location cho Hero online / ETA realtime
class LocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Khởi động background service với location tracking
  static Future<void> init() async {
    final service = _service;
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Listen location updates – gửi lên Firebase realtime
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,  // meter
      ),
    ).listen((Position position) {
      print('📍 Background Location: ${position.latitude}, ${position.longitude}');
      print('Speed: ${position.speed}, Battery: ...');  // TODO: Thêm battery

      // TODO: Gửi location lên Firestore cho Hero online / ETA realtime
      // Ví dụ: FirebaseFirestore.instance.collection('hero_locations').doc(userId).set({
      //   'lat': position.latitude,
      //   'lng': position.longitude,
      //   'timestamp': FieldValue.serverTimestamp(),
      // });
    });

    // Gửi heartbeat mỗi 60 giây để giữ service alive
    Timer.periodic(const Duration(seconds: 60), (timer) {
      service.invoke('heartbeat', {'time': DateTime.now().toIso8601String()});
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  /// Bắt đầu service
  static void start() {
    _service.startService();
    print('✅ Background Location Service started');
  }

  /// Dừng service
  static void stop() {
    _service.invoke('stopService');
    print('❌ Background Location Service stopped');
  }

  /// Lấy location hiện tại 1 lần
  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}