import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sos_battery/features/sos/presentation/pages/home_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // THÊM IMPORT NÀY
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
    _saveJobState(); // Lưu job ID khi mở trang (để reopen load lại)
  }

  void _listenToSOSStatus() {
    FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(widget.sosId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _status = data['status'] ?? 'open';
          _heroId = data['heroId'] ?? '';
        });
      }
    });
  }

  // Lưu job ID vào SharedPreferences khi trang SOS Request Sent mở (để reopen load lại)
  Future<void> _saveJobState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('active_sos_id', widget.sosId);
    print('Saved active SOS ID: ${widget.sosId}');
  }

  Future<void> _reportFake() async {
    await FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(widget.sosId)
        .update({
      'reported': true,
      'reportReason': 'Fake Hero/SOS',
      'reportTime': FieldValue.serverTimestamp(),
      'reportedBy': FirebaseAuth.instance.currentUser!.uid,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Report sent to admin. Thank you!'),
          backgroundColor: Colors.orange),
    );

    // THÊM DÒNG NÀY: Quay về HomePage sau khi report
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _confirmRescued() async {
    await FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(widget.sosId)
        .update({
      'status': 'completed_by_driver',
      'driverConfirmedTime': FieldValue.serverTimestamp(),
    });

    // Clear job ID khi confirm rescued (job hoàn thành)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_sos_id');
    print('Job confirmed by driver - cleared active_sos_id');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Rescue confirmed! Thank you!'),
          backgroundColor: Colors.green),
    );
    //start
    // THÊM DIALOG TIP HERO SAU CONFIRMED
    bool? wantToTip = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tip the Hero?'),
          content: const Text('Hero helped you, Tip for Hero happy ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, back to Home'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Tip now!'),
            ),
          ],
        );
      },
    );

    if (wantToTip == true) {
      // Mở TipScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TipScreen(heroId: _heroId),
        ),
      );
    } else {
      // Quay về HomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }
  //end

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
                    builder: (_) =>
                        ChatScreen(sosId: widget.sosId, driverId: uid),
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
          // Nut goi xe keo gan day
          // NÚT TÌM XE KÉO GẦN (hiện khi job open/accepted)
          if (_status == 'open' || _status == 'accepted')
            Positioned(
              bottom: 150,
              // left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  // Link Google Maps tìm "tow truck near me"
                  final Uri url = Uri.parse(
                      'https://www.google.com/maps/search/tow+truck+near+me');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Không mở được Maps'),
                          backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Call Tow Service near me',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          // End nut goi xe

          // CARD TRẠNG THÁI & NÚT
          Positioned(
            bottom: 30,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: _reportFake,
                    child: const Text('Report Fake',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _status == 'open'
                              ? 'Waiting for Hero...'
                              : _status == 'accepted'
                                  ? 'Hero is on the way!'
                                  : 'Job Completed!',
                          style: TextStyle(
                              color: _status == 'completed'
                                  ? Colors.green
                                  : Colors.yellow,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text('Reason: ${widget.reason}',
                            style: const TextStyle(color: Colors.white)),
                        Text(
                            'Time: ${widget.time.hour}:${widget.time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // NÚT CONFIRM RESCUED (luôn hiện cho đến khi Driver confirm hoặc tip)
                if (_status !=
                    'completed_by_driver') // Ẩn khi Driver đã confirm
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _confirmRescued,
                    child: const Text('Confirm Rescued',
                        style: TextStyle(color: Colors.white)),
                  ),

                const SizedBox(height: 10),

                // NÚT TIP HERO (hiện khi Hero complete job)
                if (_status == 'completed')
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _tipHero,
                    child: const Text('Tip the Hero',
                        style: TextStyle(color: Colors.white)),
                  ),

                const SizedBox(height: 10),

                // NÚT BACK TO HOME (tùy chọn, để Driver thoát nhanh)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                  child: const Text('Back to Home',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
