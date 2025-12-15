import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as dev;
// Import màn hình ChatScreen để có thể mở từ đây
import 'chat_screen.dart'; 

class MapScreen extends StatefulWidget {
  final String reason;
  final String jobId; // <-- ĐÃ THÊM: ID của yêu cầu SOS
  final bool isHero;  // <-- ĐÃ THÊM: Cờ xác định vai trò người dùng

  // Cập nhật constructor để nhận 3 tham số
  const MapScreen({
    super.key,
    required this.reason,
    required this.jobId,
    required this.isHero,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  String _statusMessage = "Đang tìm vị trí hiện tại...";

  @override
  void initState() {
    super.initState();
    _liveLocateUser(); 
  }
  
  // ... (giữ nguyên các hàm _liveLocateUser, _updateCameraAndMarker, _getCurrentLocation nếu bạn có) ...

  // Hàm chuyển sang màn hình Chat
  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          jobId: widget.jobId, // Truyền ID job đã nhận
          isHero: widget.isHero, // Truyền cờ isHero đã nhận
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bản đồ cứu hộ Realtime"),
        backgroundColor: Colors.red,
        actions: [
          IconButton( // <-- ĐÃ THÊM NÚT MỞ CHAT
            icon: const Icon(Icons.chat),
            onPressed: _navigateToChat,
            tooltip: 'Mở Chat ẩn danh',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentPosition != null)
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 14,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                _updateCameraAndMarker();
              },
              markers: _markers,
              myLocationEnabled: true, 
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: SafeArea(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateCameraAndMarker, 
        child: const Icon(Icons.my_location),
        backgroundColor: Colors.red,
      ),
    );
  }
}
