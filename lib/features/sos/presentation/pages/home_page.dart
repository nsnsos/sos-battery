import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
// Import các gói logic backend
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import 'map_screen.dart'; 
import 'hero_screen.dart'; // <-- ĐÃ THÊM: Import HeroScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ... (giữ nguyên các phần initState, dispose, _showSosConfirmation, _handleSosRequest, _getCurrentLocation, _sendSOS)
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
  
  // Hàm hiển thị Popup chọn lý do SOS (giữ nguyên)
  void _showReasonPopup() {
    // ... (logic popup giữ nguyên)
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
            ],
          ),
        );
      },
    );
  }

  void _sendSOS(String reason) async {
    Navigator.pop(context); 

    try {
      Position position = await _getCurrentLocation();
      dev.log('Đã lấy vị trí: ${position.latitude}, ${position.longitude} với lý do: $reason');

      await FirebaseFirestore.instance.collection('sos_requests').add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'reason': reason, 
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      _confettiController.play(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Yêu cầu SOS đã được gửi thành công!"),
            backgroundColor: Colors.green),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapScreen(reason: reason)),
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

  Future<Position> _getCurrentLocation() async {
     // ... (logic lấy vị trí giữ nguyên)
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

  // --- THÊM HÀM CHUYỂN MÀN HÌNH ---
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
      appBar: AppBar( // <-- ĐÃ THÊM APPBAR VÀ NÚT CHUYỂN MÀN HÌNH
        title: const Text("SOS Battery App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.two_wheeler, color: Colors.blue), // Icon xe máy/xe cộ
            onPressed: _navigateToHeroMode,
            tooltip: 'Chuyển sang chế độ Hero (Cứu hộ)',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
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

