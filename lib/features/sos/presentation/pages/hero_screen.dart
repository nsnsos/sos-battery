import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:background_locator_2/background_locator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'dart:developer' as dev;
// Import các màn hình cần chuyển đến
import 'chat_screen.dart'; 
import 'map_screen.dart'; 

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  bool _isOnline = false;
  Position? _currentPosition;
  final String _heroId = FirebaseAuth.instance.currentUser?.uid ?? "HERO_USER_ID_MOCK"; 
  String _currentJobId = ''; 
  final List<DocumentSnapshot> _nearbyRequests = []; // <-- ĐÃ THÊM: Danh sách requests gần đó

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }
  
  // ... (giữ nguyên các hàm _initNotifications, _goOnline, _updateHeroLocationInFirestore, _showNotification) ...

  // --- HÀM _startListeningToSosRequests ĐÃ CẬP NHẬT ---
  void _startListeningToSosRequests() {
    FirebaseFirestore.instance
        .collection('jobs') // Sử dụng collection 'jobs' theo cấu trúc của bạn
        // Lọc chỉ lấy các trạng thái Đang chờ hoặc Đã chấp nhận
        .where('status', whereIn: ['pending', 'accepted']) 
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _nearbyRequests.clear();
        _nearbyRequests.addAll(snapshot.docs);
        if (_nearbyRequests.isNotEmpty) {
           dev.log("Tìm thấy ${_nearbyRequests.length} yêu cầu SOS gần đó!");
           // showNotification("SOS Mới!", "Có yêu cầu cứu hộ gần vị trí của bạn.");
        }
      });
    });
  }
  // --- KẾT THÚC HÀM _startListeningToSosRequests ĐÃ CẬP NHẬT ---

  // ... (giữ nguyên hàm _acceptSOS, đảm bảo nó gọi đúng jobId khi nhận job) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero Mode')),
      body: Column( // <-- ĐÃ SỬA: Dùng Column thay vì Center/Stack để hiển thị danh sách
        children: [
          // Hiển thị trạng thái Online/Offline
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: _isOnline,
                  onChanged: (value) => _toggleOnlineStatus(), // <-- Cần hàm _toggleOnlineStatus()
                  activeColor: Colors.green,
                ),
                Text(_isOnline ? 'Bạn đang Online' : 'Bạn đang Offline', style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          
          if (_isOnline && _currentJobId.isEmpty)
            Expanded( // <-- ĐÃ SỬA: Dùng Expanded để danh sách cuộn được
              child: _nearbyRequests.isEmpty 
              ? const Center(child: Text("Đang chờ yêu cầu SOS gần đó...", style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: _nearbyRequests.length,
                  itemBuilder: (context, index) {
                    var request = _nearbyRequests[index].data() as Map<String, dynamic>;
                    String jobId = _nearbyRequests[index].id; // Lấy Job ID
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text("Yêu cầu SOS: ${request['reason'] ?? 'Không rõ'}"),
                      subtitle: Text("Trạng thái: ${request['status']}"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // Chuyển đến màn hình Map chi tiết (hoặc gọi _acceptSOS với jobId này)
                        // Ví dụ chuyển sang MapScreen:
                         Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(
                          reason: request['reason'] ?? 'Cứu hộ', 
                          jobId: jobId, 
                          isHero: true,
                        )));
                      },
                    );
                  },
                ),
            )
          else if (_currentJobId.isNotEmpty)
             Text('Đang trên đường đến Job $_currentJobId', style: const TextStyle(fontSize: 18, color: Colors.blue)),
        ],
      ),
    );
  }

  // Cần thêm hàm _toggleOnlineStatus() nếu bạn dùng Switch như trong mã nguồn mới này
  void _toggleOnlineStatus() {
    if (_isOnline) {
      // Logic go offline
      setState(() => _isOnline = false);
    } else {
      _goOnline(); // Gọi hàm go online đã viết
    }
  }
}
