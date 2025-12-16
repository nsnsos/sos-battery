import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
// Import các gói logic backend và các màn hình khác
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import 'map_screen.dart'; 
import 'hero_screen.dart'; 
import 'chat_screen.dart'; // <-- ĐÃ THÊM: Import màn hình Chat
import 'safety_report_screen.dart'; // <-- ĐÃ THÊM: Import màn hình Report
import 'tip_screen.dart'; // <-- ĐÃ THÊM: Import màn hình Tip
import 'donate_screen.dart';
import 'roadside_screen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Hàm hiển thị Popup chọn lý do SOS
  void _showReasonPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn lý do SOS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Phone dying'), onTap: () => _sendSOS('Phone dying')),
              ListTile(title: const Text('Car dead battery'), onTap: () => _sendSOS('Car dead battery')),
              ListTile(title: const Text('Flat tire'), onTap: () => _sendSOS('Flat tire')),
              ListTile(title: const Text('Out of gas'), onTap: () => _sendSOS('Out of gas')),
              ListTile(title: const Text('Keys locked'), onTap: () => _sendSOS('Keys locked')),
              ListTile(title: const Text('Other'), onTap: () => _sendSOS('Other')),
	      ListTile(title: const Text('Call Roadside service near you'),onTap: () 				{     Navigator.pop(context); // Đóng popup
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RoadsideScreen()));
                },
              ),

            ],
          ),
 	);
      },
    );
  }

  // Hàm xử lý logic khi gửi SOS (lấy vị trí, gửi lên Firestore)
  void _sendSOS(String reason) async {
    Navigator.pop(context); // đóng popup

    try {
      Position position = await _getCurrentLocation();
      dev.log('Đã lấy vị trí: ${position.latitude}, ${position.longitude} với lý do: $reason');

      // Gửi dữ liệu lên Cloud Firestore và lấy ID của job vừa tạo
      DocumentReference docRef = await FirebaseFirestore.instance.collection('jobs').add({ // Sử dụng 'jobs' collection
        'latitude': position.latitude,
        'longitude': position.longitude,
        'reason': reason, 
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      String jobId = docRef.id; // Lấy Job ID

      _confettiController.play(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Yêu cầu SOS đã được gửi thành công!"),
            backgroundColor: Colors.green),
      );

      // Chuyển sang MapScreen và truyền đầy đủ tham số (isHero: false vì đây là người dùng thường)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapScreen(
          reason: reason, 
          jobId: jobId, 
          isHero: false
        )),
      );

    } catch (e) {
      dev.log('Lỗi khi gửi SOS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lỗi: Không thể gửi yêu cầu SOS. $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  // Hàm lấy vị trí (sử dụng geolocator)
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Hàm chuyển sang màn hình Hero Mode
  void _navigateToHeroMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HeroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SOS Battery App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.two_wheeler, color: Colors.blue),
            onPressed: _navigateToHeroMode,
            tooltip: 'Chuyển sang chế độ Hero (Cứu hộ)',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column( // <-- Dùng Column để xếp chồng nút SOS và các nút test
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                ElevatedButton(
                  onPressed: _showReasonPopup, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(80),
                  ),
                  child: const Text(
                    'SOS',
                    style: TextStyle(fontSize: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40), 

                // --- CÁC NÚT THỬ NGHIỆM TẠM THỜI (Xóa khi hoàn tất phát triển) ---
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen(jobId: 'job_test_123', isHero: false))), 
                  child: const Text('Test Chat (User)'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SafetyReportScreen(jobId: 'job_test_123', isHero: false))),
                  child: const Text('Test Safety & Report'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TipScreen(heroVenmoHandle: '@mockhero', heroCashAppHandle: '\$mockhero'))),
                  child: const Text('Test Tip Hero'),
                ),
		ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DonateScreen())),
                  child: const Text('Test Donate Screen'),
                ),
                // --- KẾT THÚC CÁC NÚT THỬ NGHIỆM ---
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
              colors: const [Colors.red, Colors.white, Colors.blue],
            ),
          ),
        ],
      ),
    );
  }
}
