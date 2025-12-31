import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sos_battery/features/auth/presentation/pages/login_page.dart'; // để logout
import 'package:sos_battery/features/sos/presentation/pages/hero_screen.dart'; // import HeroScreen
import 'package:sos_battery/features/sos/presentation/pages/chat_screen.dart'; // import ChatScreen
import 'package:sos_battery/features/sos/presentation/pages/tip_screen.dart'; // import TipScreen
import 'package:sos_battery/features/sos/presentation/pages/hero_profile_screen.dart'; // sửa đúng folder sos- import hero profile
import 'package:sos_battery/features/sos/presentation/pages/sos_request_sent_screen.dart';
import 'package:sos_battery/features/sos/presentation/pages/donate_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  latlng.LatLng _currentPosition =
      latlng.LatLng(32.7767, -96.7970); // Default Dallas, Texas
  latlng.LatLng _heroPosition =
      latlng.LatLng(32.7767, -96.7970); // Vị trí Hero realtime
  bool _isLoadingLocation = true;
  bool _sosSent = false;
  String _sosReason = '';
  DateTime _sosTime = DateTime.now();
  String _sosStatus = 'open'; // open / accepted / completed
  String _sosId = '';
  String _driverId = '';
  String _heroId = ''; // UID Hero khi accepted

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // Listener SOS của Driver (update status + id)
    FirebaseFirestore.instance
        .collection('sos_requests')
        .where('driverId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        setState(() {
          _sosStatus = data['status'] ?? 'open';
          _sosId = snapshot.docs.first.id;
          _driverId = data['driverId'] ?? '';
          _heroId = data['heroId'] ?? '';
        });
      }
    });

    // Listener vị trí Hero realtime (khi SOS accepted)
    FirebaseFirestore.instance
        .collection('sos_requests')
        .where('driverId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        String heroId = data['heroId'];
        _listenToHeroPosition(heroId);
      }
    });

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _listenToHeroPosition(String heroId) {
    FirebaseFirestore.instance
        .collection('heroes_online')
        .doc(heroId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        GeoPoint pos = doc['position'];
        setState(() {
          _heroPosition = latlng.LatLng(pos.latitude, pos.longitude);
        });
      }
    });
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

  // Hàm Log Out
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // Popup chọn lý do SOS → chuyển sang SOS Request Sent screen
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

  // Xác nhận + gửi SOS → chuyển sang SOS Request Sent screen
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
                  style: TextStyle(color: Colors.white)),
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

    if (confirm == true) {
      // Tạo document SOS mới trong Firestore
      DocumentReference ref =
          await FirebaseFirestore.instance.collection('sos_requests').add({
        'driverId': FirebaseAuth.instance.currentUser!.uid,
        'reason': reason,
        'location':
            GeoPoint(_currentPosition.latitude, _currentPosition.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'open',
      });

      setState(() {
        _sosSent = true;
        _sosReason = reason;
        _sosTime = DateTime.now();
        _sosStatus = 'open';
        _sosId = ref.id;
      });

      // Chuyển sang SOS Request Sent screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SOSRequestSentScreen(
            sosId: ref.id,
            reason: reason,
            time: DateTime.now(),
            sosPosition: _currentPosition,
          ),
        ),
      );
    }
  }

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
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 10),
                      ],
                    ),
                  ),
                  // Marker Hero (xe xanh di chuyển realtime khi SOS accepted)
                  Marker(
                    point: _heroPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Nut Profile o day
          Positioned(
            top: 50,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HeroProfileScreen()),
                );
              },
              child: const Icon(Icons.person, color: Colors.white),
              tooltip: 'My Profile',
            ),
          ),
          // Ket thuc nut Profile
          // Nut Donate o day.
          // NÚT DONATE CHO APP (góc trên trái)
          Positioned(
            top: 50,
            left: 80,
            child: FloatingActionButton(
              mini: true, // nhỏ gọn
              backgroundColor: Colors.blue,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DonateScreen()),
                );
              },
              child: const Icon(Icons.favorite, color: Colors.white),
              tooltip: 'Donate to support the app',
            ),
          ),
          //Ket thuc nut donate
          // NÚT LOG OUT ĐỎ GÓC TRÊN PHẢI
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 36,
              ),
              tooltip: 'Log Out',
              onPressed: _logout,
            ),
          ),

          // NÚT BECOME HERO XANH LÁ GÓC DƯỚI PHẢI
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
          if (!_sosSent)
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

          // MINI CHAT BUBBLE GÓC DƯỚI PHẢI (khi job accepted)
          if (_sosSent && _sosStatus == 'accepted')
            Positioned(
              bottom: 100,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(sosId: _sosId, driverId: _driverId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.chat, color: Colors.white, size: 30),
                ),
              ),
            ),

          // CARD THÔNG TIN SOS SAU KHI GỬI
          if (_sosSent)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'SOS Request Sent',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text('Reason: $_sosReason',
                          style: const TextStyle(color: Colors.white)),
                      Text(
                          'Time: ${_sosTime.hour}:${_sosTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                      const Text('Waiting for Hero...',
                          style: TextStyle(color: Colors.yellow)),
                    ],
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
                  padding: EdgeInsets.all(12),
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
