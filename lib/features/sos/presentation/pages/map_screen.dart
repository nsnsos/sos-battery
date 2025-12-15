import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:confetti/confetti.dart'; // <-- ĐÃ THÊM: Import Confetti
import 'dart:async';
import 'dart:developer' as dev;
import 'chat_screen.dart'; 
import 'safety_report_screen.dart'; 

class MapScreen extends StatefulWidget {
  final String reason;
  final String jobId; 
  final bool isHero;  

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
  late ConfettiController _confettiController; // <-- ĐÃ THÊM: Controller pháo hoa

  @override
  void initState() {
    super.initState();
    _liveLocateUser(); 
    _confettiController = ConfettiController(duration: const Duration(seconds: 3)); // <-- ĐÃ THÊM
  }
  
  @override
  void dispose() { // <-- ĐÃ THÊM: Dispose controller
    _confettiController.dispose();
    super.dispose();
  }

  // ... (giữ nguyên các hàm _liveLocateUser, _updateCameraAndMarker, _getCurrentLocation, _navigateToChat) ...
  // Các hàm này giữ nguyên như trước

  // HÀM _completeJob ĐÃ CẬP NHẬT để có pháo hoa
  void _completeJob() async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'status': 'completed', 
        'completedTimestamp': FieldValue.serverTimestamp(),
      });

      // KÍCH HOẠT PHÁO HOA TẠI ĐÂY
      _confettiController.play(); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dịch vụ đã hoàn tất! Cảm ơn bạn."), backgroundColor: Colors.green),
      );
      
      // Có thể chuyển về màn hình chính sau 3 giây pháo hoa nổ xong
      // Future.delayed(Duration(seconds: 3), () {
      //      Navigator.popUntil(context, (route) => route.isFirst);
      // });

    } catch (e) {
      dev.log("Lỗi hoàn tất dịch vụ: $e");
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: Không thể hoàn tất dịch vụ. $e"), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bản đồ cứu hộ Realtime"),
        backgroundColor: Colors.red,
        actions: [
          // ... (actions buttons giữ nguyên)
           IconButton( 
            icon: const Icon(Icons.chat),
            onPressed: _navigateToChat,
            tooltip: 'Mở Chat ẩn danh',
          ),
          IconButton( 
            icon: const Icon(Icons.report_problem, color: Colors.yellow),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyReportScreen(jobId: widget.jobId, isHero: widget.isHero)));
            },
            tooltip: 'Báo cáo sự cố/giả mạo',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentPosition != null)
            GoogleMap(
              // ... (phần GoogleMap giữ nguyên)
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
          
          // Thanh thông báo trạng thái
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container( /* ... code container ... */),
          ),

          // <-- ĐÃ THÊM: Widget Pháo hoa -->
          Align(
            alignment: Alignment.center, // Canh giữa màn hình (hoặc vị trí GPS)
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // Nổ tỏa ra xung quanh
              colors: const [Colors.green, Colors.blue, Colors.yellow],
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.3,
            ),
          ),
           // <-- KẾT THÚC THÊM -->
        ],
      ),
      // Nút Hoàn tất/My location
      floatingActionButton: widget.isHero == false
          ? FloatingActionButton.extended(
              onPressed: _completeJob, // Gọi hàm có pháo hoa
              label: const Text("XÁC NHẬN HOÀN TẤT"),
              icon: const Icon(Icons.check_circle),
              backgroundColor: Colors.green,
            )
          : FloatingActionButton( 
              onPressed: _updateCameraAndMarker, 
              child: const Icon(Icons.my_location),
              backgroundColor: Colors.red,
            ),
    );
  }
}
