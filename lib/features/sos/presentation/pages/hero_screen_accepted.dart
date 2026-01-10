import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart'; // THÊM IMPORT NÀY
import 'dart:async';
import 'chat_screen.dart'; // chat realtime
import 'package:sos_battery/features/sos/presentation/pages/hero_screen.dart'; // quay lại list SOS

class HeroScreenAccepted extends StatefulWidget {
  final String sosId;
  final String driverId;

  const HeroScreenAccepted({
    super.key,
    required this.sosId,
    required this.driverId,
  });

  @override
  State<HeroScreenAccepted> createState() => _HeroScreenAcceptedState();
}

class _HeroScreenAcceptedState extends State<HeroScreenAccepted> {
  latlng.LatLng _heroPosition =
      latlng.LatLng(32.7767, -96.7970); // Vị trí Hero realtime
  GeoPoint _sosLocation = GeoPoint(32.7357, -97.1081); // Default SOS location
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadSOSData();
    _startLocationUpdates();
  }

  Future<void> _loadSOSData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('sos_requests')
          .doc(widget.sosId)
          .get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _sosLocation =
              data['location'] as GeoPoint? ?? GeoPoint(32.7357, -97.1081);
        });
      }
    } catch (e) {
      print('Load SOS error: $e');
    }
  }

  void _startLocationUpdates() {
    // Update vị trí Hero realtime (mỗi 10s)
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _heroPosition = latlng.LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
        print('Location update error: $e');
      }
    });
  }

  void _completeJob() async {
    // Bùng pháo hoa
    _confettiController.play();

    // Update status job thành completed
    await FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(widget.sosId)
        .update({
      'status': 'completed',
      'completedTime': FieldValue.serverTimestamp(),
    });

    // Tính và cộng Hcoin cho hero
    final doc = await FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(widget.sosId)
        .get();

    if (doc.exists && doc.data()!.containsKey('acceptedTime')) {
      Timestamp acceptedTime = doc['acceptedTime'];
      int durationSeconds =
          DateTime.now().difference(acceptedTime.toDate()).inSeconds;
      int hcoin = durationSeconds ~/ 60; // 1 phút = 1 Hcoin

      String heroId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('heroes').doc(heroId).update({
        'hcoin': FieldValue.increment(hcoin),
        'totalPoints': FieldValue.increment(hcoin),
        'rescueTime': FieldValue.increment(durationSeconds),
        'lastCompleteTime': FieldValue.serverTimestamp(),
      });
    }

    // ===> THÊM PHẦN CLEAR ACTIVE_JOB_ID ĐỂ KHÔNG RESUME LẠI JOB CŨ <===
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_job_id');
    print('Job completed - cleared active_job_id from prefs');

    // Show dialog chúc mừng + pháo hoa
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Stack(
            children: [
              AlertDialog(
                title: const Text('Job Completed! 🎉'),
                content: const Text('Thank you for helping! You earned Hcoin!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Đóng dialog
                      // Sau khi đóng dialog mới chuyển màn hình
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HeroScreen()),
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [Colors.red, Colors.white, Colors.blue],
                numberOfParticles: 150,
                maxBlastForce: 20,
                minBlastForce: 5,
                emissionFrequency: 0.05,
                gravity: 0.1,
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Mode - Active Job'),
        backgroundColor: Colors.green[800],
      ),
      body: Stack(
        children: [
          // MAP NAVIGATION
          FlutterMap(
            options: MapOptions(
              initialCenter: _heroPosition,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sosbattery.app',
              ),
              MarkerLayer(
                markers: [
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
                  Marker(
                    point: latlng.LatLng(
                        _sosLocation.latitude, _sosLocation.longitude),
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 60,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // MINI CHAT BUBBLE GÓC DƯỚI PHẢI
          Positioned(
            bottom: 100,
            right: 30,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                        sosId: widget.sosId, driverId: widget.driverId),
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

          // NÚT COMPLETE JOB
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _completeJob,
              child: const Text('Complete Job',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
          // NÚT REPORT FAKE (luôn hiện, góc phải trên, Hero report SOS fake)
          Positioned(
            top: 60,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('sos_requests')
                    .doc(widget.sosId)
                    .update({
                  'reported': true,
                  'reportReason': 'Fake SOS / Driver',
                  'reportTime': FieldValue.serverTimestamp(),
                  'reportedBy':
                      FirebaseAuth.instance.currentUser!.uid, // Hero report
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Report sent to admin. Thank you!'),
                      backgroundColor: Colors.orange),
                );

                // Tự động quay về HeroScreen (list SOS open)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HeroScreen()),
                );
              },
              child: const Text('Report Fake',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
          //End nut Fake Report
        ],
      ),
    );
  }
}
