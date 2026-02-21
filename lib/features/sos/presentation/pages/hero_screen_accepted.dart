import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _HeroScreenAcceptedState extends State<HeroScreenAccepted>
    with TickerProviderStateMixin {
  latlng.LatLng _heroPosition =
      latlng.LatLng(32.7767, -96.7970); // Vị trí Hero realtime
  GeoPoint _sosLocation = GeoPoint(32.7357, -97.1081); // Default SOS location
  late ConfettiController _confettiController;
  late AnimationController _animationController;

  bool _isLoadingComplete = false;
  bool _isLoadingReport = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadSOSData();
    _startLocationUpdates();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
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
    print('Complete Job button tapped!');
    print('Hero UID: ${FirebaseAuth.instance.currentUser?.uid ?? "NULL"}');
    setState(() => _isLoadingComplete = true);

    try {
      _confettiController.play();

      await FirebaseFirestore.instance
          .collection('sos_requests')
          .doc(widget.sosId)
          .update({
        'status': 'completed',
        'completedTime': FieldValue.serverTimestamp(),
      });

      final doc = await FirebaseFirestore.instance
          .collection('sos_requests')
          .doc(widget.sosId)
          .get();

      if (doc.exists && doc.data()!.containsKey('acceptedTime')) {
        Timestamp acceptedTime = doc['acceptedTime'];
        int durationSeconds =
            DateTime.now().difference(acceptedTime.toDate()).inSeconds;
        int hcoin = durationSeconds ~/ 60;

        String heroId = FirebaseAuth.instance.currentUser!.uid;

        await FirebaseFirestore.instance
            .collection('heroes')
            .doc(heroId)
            .update({
          'hcoin': FieldValue.increment(hcoin),
          'totalPoints': FieldValue.increment(hcoin),
          'rescueTime': FieldValue.increment(durationSeconds),
          'lastCompleteTime': FieldValue.serverTimestamp(),
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_job_id');
      print('Job completed - cleared active_job_id from prefs');

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Stack(
              children: [
                AlertDialog(
                  title: const Text('Job Completed! 🎉'),
                  content:
                      const Text('Thank you for helping! You earned Hcoin!'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        print(
                            'Navigating back to HeroScreen... Current route count: ${Navigator.of(context).canPop()}');
                        //
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HeroScreen()),
                          (route) => route
                              .isFirst, // Giữ lại route đầu tiên (màn hình chính), xóa hết ở giữa
                        );
                        //
                        //Navigator.of(context).pushReplacement(
                        //  MaterialPageRoute(builder: (_) => const HeroScreen()),
                        //);
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
    } catch (e) {
      print('Complete Job error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi complete job: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingComplete = false);
      }
    }
  }

  Future<void> _reportFake() async {
    print('Report Fake button tapped!');
    print('Hero UID: ${FirebaseAuth.instance.currentUser?.uid ?? "NULL"}');
    setState(() => _isLoadingReport = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await FirebaseFirestore.instance
          .collection('sos_requests')
          .doc(widget.sosId)
          .update({
        'reported': true,
        'reportReason': 'Fake SOS / Driver',
        'reportTime': FieldValue.serverTimestamp(),
        'reportedBy': user.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent to admin. Thank you!'),
            backgroundColor: Colors.orange,
          ),
        );
        print(
            'Navigating back to HeroScreen... Current route count: ${Navigator.of(context).canPop()}');
//
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HeroScreen()),
          (route) => route
              .isFirst, // Giữ lại route đầu tiên (màn hình chính), xóa hết ở giữa
        );
//
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(builder: (_) => const HeroScreen()),
        // );
      }
    } catch (e) {
      print('Report Fake error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi report fake: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingReport = false);
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Mode - Active Job'),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: Stack(
        children: [
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

          // MINI CHAT BUBBLE
          Positioned(
            bottom: 140 + MediaQuery.of(context).padding.bottom,
            right: 24,
            child: SafeArea(
              bottom: true, // Chỉ safe bottom để tránh che home indicator
              child: GestureDetector(
                onTap: () {
                  print('Chat bubble tapped!');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        sosId: widget.sosId,
                        driverId: widget.driverId,
                      ),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('sos_requests')
                          .doc(widget.sosId)
                          .collection('messages')
                          .where('read', isEqualTo: false)
                          .where('receiverId',
                              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int unreadCount =
                            snapshot.hasData ? snapshot.data!.docs.length : 0;
                        if (unreadCount == 0) return const SizedBox.shrink();

                        return Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 8),
                              ],
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + 0.08 * _animationController.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 5,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BOTTOM BUTTONS
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _isLoadingComplete ? null : _completeJob,
                  child: _isLoadingComplete
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Job',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HeroScreen()),
                    );
                  },
                  child: const Text(
                    'Back to Hero Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // REPORT FAKE BUTTON
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoadingReport ? null : _reportFake,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _isLoadingReport
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Report Fake',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
