import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:background_locator_2/background_locator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'dart:developer' as dev;
// Import các màn hình cần chuyển đến
import 'chat_screen.dart'; 
import 'map_screen.dart'; 

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  bool _isOnline = false;
  Position? _currentPosition;
  // Giả định Hero ID lấy từ FirebaseAuth
  final String _heroId = FirebaseAuth.instance.currentUser?.uid ?? "HERO_USER_ID_MOCK"; 
  String _currentJobId = ''; 

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
    // Bắt đầu background location (cần cấu hình native)
    await BackgroundLocator.registerLocationUpdate(
      (Position position) {
        setState(() {
          _currentPosition = position;
        });
        _updateHeroLocationInFirestore(position); 
      },
      settings: const LocationSettings( 
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
    _showNotification("SOS gần bạn!", "Có người cần cứu pin xe – cách 2km");
    dev.log("Hero is online and location tracking started.");
  }
  
  Future<void> _updateHeroLocationInFirestore(Position position) async {
    await FirebaseFirestore.instance.collection('heroes_online').doc(_heroId).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'isOnline': true,
    }, SetOptions(merge: true));
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hero_channel', 'Hero Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, details);
  }

  // --- HÀM _acceptSOS ĐÃ CẬP NHẬT ---
  void _acceptSOS() async {
    // Giả lập nhận JOB ID từ một yêu cầu gần đó (ví dụ từ danh sách _nearbyRequests)
    String jobId = "SOS_REQUEST_ID_MOCK"; 
    
    // Cập nhật trạng thái Job trên Firestore
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'status': 'accepted',
      'heroId': _heroId,
      'acceptedTimestamp': FieldValue.serverTimestamp(),
    });
    
    setState(() {
      _currentJobId = jobId;
    });

    // Sau khi chấp nhận job, chuyển ngay sang màn hình Map và Chat
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Job Locked!'),
        content: const Text('Bạn đã nhận job – ETA: 8 phút. Chuyển sang màn hình bản đồ và chat.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              // Chuyển sang MapScreen và truyền tham số isHero: true
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen(
                  reason: "Hỗ trợ cứu hộ", 
                  jobId: jobId, 
                  isHero: true,
                )),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  // --- KẾT THÚC HÀM _acceptSOS ĐÃ CẬP NHẬT ---

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
            if (_isOnline && _currentJobId.isEmpty) 
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
