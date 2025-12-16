import 'package:flutter/material.dart';
// ... các imports khác ...
import 'roadside_screen.dart'; // <-- ĐÃ THÊM: Import RoadsideScreen

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  // ... (các biến trạng thái và hàm initState, dispose, etc. giữ nguyên) ...
  bool _isOnline = false;
  // ...

  // Hàm chuyển đến màn hình gọi Roadside
  void _navigateToRoadside() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoadsideScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero Mode')),
      body: Column(
        children: [
          // Hiển thị trạng thái Online/Offline
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: _isOnline,
                  onChanged: (value) => _toggleOnlineStatus(),
                  activeColor: Colors.green,
                ),
                Text(_isOnline ? 'Bạn đang Online' : 'Bạn đang Offline', style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          
          // --- NÚT GỌI ROADSIDE MỚI ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone_in_talk, color: Colors.white),
              label: const Text('GỌI ROADSIĐE CHÍNH HÃNG GIÚP USER', style: TextStyle(fontSize: 16, color: Colors.white)),
              onPressed: _navigateToRoadside,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50), // Làm cho nút rộng hết màn hình
              ),
            ),
          ),
          // --- KẾT THÚC THÊM ---

          if (_isOnline && _currentJobId.isEmpty)
            Expanded(
              // ... (phần ListView.builder hiển thị requests giữ nguyên) ...
              child: _nearbyRequests.isEmpty 
              ? const Center(child: Text("Đang chờ yêu cầu SOS gần đó...", style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: _nearbyRequests.length,
                  itemBuilder: (context, index) {
                    // ... (ListTile giữ nguyên) ...
                    var request = _nearbyRequests[index].data() as Map<String, dynamic>;
                    String jobId = _nearbyRequests[index].id;
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text("Yêu cầu SOS: ${request['reason'] ?? 'Không rõ'}"),
                      subtitle: Text("Trạng thái: ${request['status']}"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
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
