import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart'; // chat realtime
import 'tip_screen.dart'; // import TipScreen

class SOSRequestSentScreen extends StatefulWidget {
  final String sosId;
  final String reason;
  final DateTime time;
  final latlng.LatLng sosPosition;

  const SOSRequestSentScreen({
    super.key,
    required this.sosId,
    required this.reason,
    required this.time,
    required this.sosPosition,
  });

  @override
  State<SOSRequestSentScreen> createState() => _SOSRequestSentScreenState();
}

class _SOSRequestSentScreenState extends State<SOSRequestSentScreen> {
  String _status = 'open';
  String _heroId = ''; // UID Hero khi accepted
  Offset _chatBubbleOffset = const Offset(300, 600); // vị trí mini chat bubble

  @override
  void initState() {
    super.initState();
    _listenToSOSStatus();
  }

  void _listenToSOSStatus() {
    FirebaseFirestore.instance.collection('sos_requests').doc(widget.sosId).snapshots().listen((doc) {
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _status = data['status'] ?? 'open';
          _heroId = data['heroId'] ?? '';
        });
      }
    });
  }

  Future<void> _reportFake() async {
    await FirebaseFirestore.instance.collection('sos_requests').doc(widget.sosId).update({
      'reported': true,
      'reportReason': 'Fake Hero/SOS',
      'reportTime': FieldValue.serverTimestamp(),
      'reportedBy': FirebaseAuth.instance.currentUser!.uid,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report sent to admin. Thank you!'), backgroundColor: Colors.orange),
    );
  }

  Future<void> _confirmRescued() async {
    await FirebaseFirestore.instance.collection('sos_requests').doc(widget.sosId).update({
      'status': 'completed_by_driver',
      'driverConfirmedTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rescue confirmed! Thank you!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _tipHero() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TipScreen(heroId: _heroId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Request Sent'),
        backgroundColor: Colors.red[800],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.sosPosition,
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
                    point: widget.sosPosition,
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

          // MINI CHAT BUBBLE (drag được)
          Positioned(
            left: _chatBubbleOffset.dx,
            top: _chatBubbleOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _chatBubbleOffset += details.delta;
                });
              },
              onTap: () {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login to chat')),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(sosId: widget.sosId, driverId: uid),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: const Icon(Icons.chat, color: Colors.white, size: 30),
              ),
            ),
          ),

          // CARD TRẠNG THÁI & NÚT
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // NÚT REPORT FAKE (luôn hiện, góc phải trên)
                Align(
                  alignment: Alignment.topRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: _reportFake,
                    child: const Text('Report Fake', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _status == 'open' ? 'Waiting for Hero...' : _status == 'accepted' ? 'Hero is on the way!' : 'Job Completed!',
                          style: TextStyle(color: _status == 'completed' ? Colors.green : Colors.yellow, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text('Reason: ${widget.reason}', style: const TextStyle(color: Colors.white)),
                        Text('Time: ${widget.time.hour}:${widget.time.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // NÚT XÁC NHẬN ĐÃ ĐƯỢC CỨU
                if (_status == 'accepted')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _confirmRescued,
                    child: const Text('Confirm Rescued', style: TextStyle(color: Colors.white)),
                  ),

                const SizedBox(height: 10),

                // NÚT TIP HERO
                if (_status == 'completed')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _tipHero,
                    child: const Text('Tip the Hero', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}