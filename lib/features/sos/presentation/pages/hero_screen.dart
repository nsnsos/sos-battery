import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:background_locator_2/background_locator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- ĐÃ THÊM
import 'dart:developer' as dev;

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  bool _isOnline = false;
  Position? _currentPosition;
  String _currentJobId = ''; // <-- ĐÃ THÊM: Theo dõi ID job hiện tại

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notifications.initialize(initializationSettings);
  }

  Future<void> _goOnline() async {
    setState(() {
      _isOnline = true;
    });

    // Bắt đầu background location
    // CẦN CẤU HÌNH NATIVE CHO GÓI NÀY
    await BackgroundLocator.registerLocationUpdate(
      (Position position) {
        setState(() {
          _currentPosition = position;
        });
        // Gửi vị trí lên Firebase realtime để SOS thấy Hero gần
        _updateHeroLocationInFirestore(position); // <-- ĐÃ THÊM
      },
      settings: const LocationSettings( // Đã sửa thành const để dùng trong production
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    // Thông báo khi có SOS gần (giả lập)
    _showNotification("SOS gần bạn!", "Có người cần cứu pin xe – cách 2km");
    dev.log("Hero is online and location tracking started.");
  }
  
  // <-- HÀM MỚI: Cập nhật vị trí lên Firestore -->
  Future<void> _updateHeroLocationInFirestore(Position position) async {
    // Giả định bạn có ID người dùng (UID) sau khi đăng nhập
    String heroId = "HERO_USER_ID_MOCK"; 
    await FirebaseFirestore.instance.collection('heroes_online').doc(heroId).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'isOnline': true,
    }, SetOptions(merge: true));
  }
  // <-- END HÀM MỚI -->

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hero_channel', 'Hero Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, details);
  }

  void _acceptSOS() async {
    // Giả lập nhận JOB ID
    String jobId = "SOS_REQUEST_ID_MOCK"; 
    
    // <-- HÀM MỚI: Cập nhật trạng thái Job trên Firestore -->
    await FirebaseFirestore.instance.collection('sos_requests').doc(jobId).update({
      'status': 'accepted',
      'heroId': 'HERO_USER_ID_MOCK',
      'acceptedTimestamp': FieldValue.serverTimestamp(),
    });
    // <-- END HÀM MỚI -->

    setState(() {
      _currentJobId = jobId;
    });

    // Lock job + tính ETA realtime
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Job Locked!'),
        content: const Text('Bạn đã nhận job – ETA: 8 phút'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero Mode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isOnline ? 'Bạn đang Online' : 'Bạn đang Offline', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isOnline ? null : _goOnline,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(20)),
              child: const Text('GO ONLINE', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 40),
            if (_isOnline && _currentJobId.isEmpty) // Chỉ hiển thị nếu online và chưa nhận job
              Column(
                children: [
                  const Text('Có SOS gần bạn!', style: TextStyle(fontSize: 28, color: Colors.red)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _acceptSOS,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("I'M COMING", style: TextStyle(fontSize: 30)),
                  ),
                ],
              ),
            if (_currentJobId.isNotEmpty)
               Text('Đang trên đường đến Job $_currentJobId', style: const TextStyle(fontSize: 18, color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
