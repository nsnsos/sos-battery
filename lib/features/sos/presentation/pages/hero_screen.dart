import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // cho Timer
import 'package:shared_preferences/shared_preferences.dart'; // THÊM IMPORT NÀY
import 'package:sos_battery/features/sos/presentation/pages/hero_screen_accepted.dart'; // Accepted screen
import 'package:sos_battery/features/sos/presentation/pages/hero_profile_screen.dart'; // Profile

class HeroScreen extends ConsumerStatefulWidget {
  const HeroScreen({super.key});

  @override
  ConsumerState<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends ConsumerState<HeroScreen> {
  latlng.LatLng _heroPosition =
      latlng.LatLng(32.7767, -96.7970); // Default Arlington, Texas
  List<Map<String, dynamic>> _sosList = [];
  bool _isLoading = true;
  bool _isOnline = false; // trạng thái online/offline

  final MapController _mapController = MapController();

  Timer? _mcoinTimer;

  @override
  void initState() {
    super.initState();
    _getHeroLocation();
  }

  Future<void> _getHeroLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')));
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')));
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permission permanently denied')));
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _heroPosition = latlng.LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _mapController.move(_heroPosition, 13.0);
    } catch (e) {
      print('Location error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  void _listenToOpenSOS() {
    if (!_isOnline) return;

    FirebaseFirestore.instance
        .collection('sos_requests')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      List<Map<String, dynamic>> requests = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final GeoPoint? pos = data['location'] as GeoPoint?;
        if (pos == null) continue;

        double distance = Geolocator.distanceBetween(
              _heroPosition.latitude,
              _heroPosition.longitude,
              pos.latitude,
              pos.longitude,
            ) /
            1000;

        requests.add({
          'id': doc.id,
          'driverId': data['driverId'] as String? ?? 'unknown',
          'reason': data['reason'] as String? ?? 'Unknown Reason',
          'location': pos,
          'timestamp': data['timestamp'],
          'distance': distance,
        });
      }

      requests.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        _sosList = requests;
      });
    });
  }

  void _toggleOnline() {
    setState(() {
      _isOnline = !_isOnline;
    });
    if (_isOnline) {
      _listenToOpenSOS();
      _startMcoinCounter(); // bắt đầu đếm Mcoin
    } else {
      _stopMcoinCounter();
    }
  }

  void _startMcoinCounter() {
    _mcoinTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      FirebaseFirestore.instance.collection('heroes').doc(uid).update({
        'mcoin': FieldValue.increment(1),
        'totalPoints': FieldValue.increment(1),
        'onlineTime': FieldValue.increment(60),
      });
    });
  }

  void _stopMcoinCounter() {
    _mcoinTimer?.cancel();
  }

  Future<void> _saveJobState(String sosId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('active_job_id', sosId);
    print('Saved active job ID: $sosId'); // debug
  }

  void _acceptSOS(String sosId, String driverId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Accept SOS?'),
          content: const Text('This will lock the job for you. Ready to help?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, I\'m coming!',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('sos_requests')
          .doc(sosId)
          .update({
        'status': 'accepted',
        'heroId': FirebaseAuth.instance.currentUser!.uid,
        'acceptedTime': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job locked! Heading to location...'),
          backgroundColor: Colors.green,
        ),
      );

      // THÊM DÒNG NÀY: Lưu job ID để reopen app load lại
      await _saveJobState(sosId);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HeroScreenAccepted(sosId: sosId, driverId: driverId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Mode'),
        backgroundColor: Colors.green[800],
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (_) => _toggleOnline(),
            activeColor: Colors.white,
            activeTrackColor: Colors.green,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text('Online', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HeroProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _heroPosition,
                      initialZoom: 13.0,
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
                            point: _heroPosition,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.shield,
                              color: Colors.green,
                              size: 60,
                            ),
                          ),
                          ..._sosList.map((sos) {
                            GeoPoint pos = sos['location'];
                            return Marker(
                              point: latlng.LatLng(pos.latitude, pos.longitude),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 50,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _sosList.isEmpty
                      ? const Center(
                          child: Text(
                            'No SOS requests nearby\nGo online to help!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _sosList.length,
                          itemBuilder: (context, index) {
                            var sos = _sosList[index];
                            return Card(
                              color: Colors.grey[850],
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: ListTile(
                                leading: Icon(
                                  sos['reason'] == 'Dead Battery'
                                      ? Icons.battery_alert
                                      : sos['reason'] == 'Flat Tire'
                                          ? Icons.tire_repair
                                          : sos['reason'] == 'Out of Fuel'
                                              ? Icons.local_gas_station
                                              : Icons.help_outline,
                                  color: Colors.red,
                                  size: 40,
                                ),
                                title: Text(
                                  sos['reason'] ?? 'Unknown Reason',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Distance: ${sos['distance'].toStringAsFixed(1)} km',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () =>
                                      _acceptSOS(sos['id'], sos['driverId']),
                                  child: const Text('I\'m coming',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
