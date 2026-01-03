import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sos_battery/features/auth/presentation/pages/login_page.dart';
import 'package:sos_battery/features/sos/presentation/pages/hero_screen.dart';
import 'package:sos_battery/features/sos/presentation/pages/chat_screen.dart';
import 'package:sos_battery/features/sos/presentation/pages/hero_profile_screen.dart';
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
      latlng.LatLng(32.7767, -96.7970); // Dallas default
  latlng.LatLng _heroPosition =
      latlng.LatLng(32.7767, -96.7970);

  bool _isLoadingLocation = true;
  bool _sosSent = false;
  String _sosReason = '';
  DateTime _sosTime = DateTime.now();
  String _sosStatus = 'open';
  String _sosId = '';
  String _driverId = '';
  String _heroId = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // iOS-safe: chạy sau khi UI render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAfterUI();
    });
  }

  Future<void> _initAfterUI() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    _driverId = user.uid;

    await _getCurrentLocation();
    _listenToSOS(user.uid);
  }

  void _listenToSOS(String uid) {
    FirebaseFirestore.instance
        .collection('sos_requests')
        .where('driverId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        setState(() {
          _sosStatus = data['status'] ?? 'open';
          _sosId = doc.id;
          _heroId = data['heroId'] ?? '';
        });

        if (_sosStatus == 'accepted' && _heroId.isNotEmpty) {
          _listenToHeroPosition(_heroId);
        }
      }
    });
  }

  void _listenToHeroPosition(String heroId) {
    FirebaseFirestore.instance
        .collection('heroes_online')
        .doc(heroId)
        .snapshots()
        .listen((doc) {
      if (!mounted || !doc.exists) return;
      final pos = doc['position'];
      setState(() {
        _heroPosition =
            latlng.LatLng(pos.latitude, pos.longitude);
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition =
            latlng.LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
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
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sosbattery.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.location_pin,
                        color: Colors.red, size: 60),
                  ),
                  Marker(
                    point: _heroPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.directions_car,
                        color: Colors.green, size: 60),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 50,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HeroProfileScreen()),
              ),
              child: const Icon(Icons.person),
            ),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon:
                  const Icon(Icons.logout, color: Colors.red, size: 36),
              onPressed: _logout,
            ),
          ),

          if (!_sosSent)
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

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
                    style:
                        TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
