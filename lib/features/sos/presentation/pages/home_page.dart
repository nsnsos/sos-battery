import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- THÊM DÒNG NÀY

import 'package:sos_battery/features/auth/presentation/pages/login_page.dart'; // để logout
import 'package:sos_battery/features/sos/presentation/pages/hero_screen.dart'; // Become Hero
import 'package:sos_battery/features/sos/presentation/pages/sos_request_sent_screen.dart'; // trang SOS Request Sent
import 'package:sos_battery/features/sos/presentation/pages/donate_screen.dart'; // Donate

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  latlng.LatLng _currentPosition =
      latlng.LatLng(32.7767, -96.7970); // Default Dallas
  bool _isLoadingLocation = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = latlng.LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> _showSOSReasonDialog() async {
    final String? selectedReason = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Reason for SOS',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),
                _reasonTile('Dead Battery', Icons.battery_alert),
                _reasonTile('Flat Tire', Icons.tire_repair),
                _reasonTile('Out of Fuel', Icons.local_gas_station),
                _reasonTile('Mechanical Breakdown', Icons.car_repair),
                _reasonTile('Accident', Icons.car_crash),
                _reasonTile('Locked Out', Icons.lock),
                _reasonTile('Other', Icons.help_outline),
              ],
            ),
          ),
        );
      },
    );

    if (selectedReason != null) {
      _confirmAndSendSOS(selectedReason);
    }
  }

  ListTile _reasonTile(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.red, size: 30),
      title: Text(title,
          style: const TextStyle(fontSize: 18, color: Colors.white)),
      onTap: () => Navigator.pop(context, title),
      tileColor: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

// Start here
  Future<void> _confirmAndSendSOS(String reason) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Send SOS?', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reason: $reason',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              Text(
                'Location: ${_currentPosition.latitude.toStringAsFixed(6)}, ${_currentPosition.longitude.toStringAsFixed(6)}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text('Rescue team will be notified.',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('SEND SOS', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return; // Nếu cancel thì thoát luôn

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      DocumentReference ref =
          await FirebaseFirestore.instance.collection('sos_requests').add({
        'driverId': user.uid,
        'reason': reason,
        'location':
            GeoPoint(_currentPosition.latitude, _currentPosition.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'open',
      });

      String sosId = ref.id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_job_id', sosId);
      print('SOS sent successfully! ID: $sosId');

      // Đóng loading
      if (context.mounted) Navigator.of(context).pop();

      // Navigate sang màn hình theo dõi
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SOSRequestSentScreen(
              sosId: sosId,
              reason: reason,
              time: DateTime.now(),
              sosPosition: _currentPosition,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error sending SOS: $e');

      // Đóng loading nếu đang mở
      if (context.mounted) Navigator.of(context).pop();

      // Show lỗi cho user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi SOS: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

// End
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MAP BACKGROUND
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sosbattery.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 60,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // NÚT DONATE (góc trên trái)
          Positioned(
            top: 50,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.blue,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DonateScreen()),
                );
              },
              child: const Icon(Icons.favorite, color: Colors.white, size: 24),
              tooltip: 'Donate to support the app',
            ),
          ),

          // NÚT LOG OUT (góc trên phải)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 36),
              tooltip: 'Log Out',
              onPressed: _logout,
            ),
          ),

          // NÚT BECOME HERO (góc dưới phải)
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HeroScreen()),
                );
              },
              backgroundColor: Colors.green[700],
              icon: const Icon(Icons.shield, color: Colors.white),
              label: const Text(
                'Become Hero',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              tooltip: 'Go online to help others',
            ),
          ),

          // NÚT SOS ĐỎ TO Ở GIỮA
          Center(
            child: GestureDetector(
              onTap: _showSOSReasonDialog,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.redAccent, Colors.red],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent,
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 40,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading vị trí
          if (_isLoadingLocation)
            const Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Getting your location...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
