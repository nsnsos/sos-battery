import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as dev;

class MapScreen extends StatefulWidget {
  final String reason;

  // Constructor nhận lý do SOS từ HomeScreen
  const MapScreen({super.key, required this.reason});

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
    _liveLocateUser(); // Bắt đầu theo dõi vị trí người dùng
  }

  // Hàm theo dõi vị trí người dùng theo thời gian thực (realtime)
  void _liveLocateUser() async {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Cập nhật vị trí khi di chuyển 10 mét
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _statusMessage = "Đã tìm thấy vị trí. Lý do SOS: ${widget.reason}";
          _updateCameraAndMarker();
        });
      },
      onError: (error) {
        dev.log("Lỗi theo dõi vị trí: $error");
        setState(() {
          _statusMessage = "Lỗi vị trí: $error";
        });
      },
    );
  }

  // Cập nhật vị trí camera và thêm marker trên bản đồ
  void _updateCameraAndMarker() async {
    if (_currentPosition == null) return;

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: _currentPosition!,
        zoom: 16, // Zoom gần hơn để thấy rõ vị trí
      ),
    ));

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
          infoWindow: InfoWindow(
            title: "Vị trí của bạn",
            snippet: "Lý do: ${widget.reason}",
          ),
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bản đồ cứu hộ Realtime"),
        backgroundColor: Colors.red,
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
              myLocationEnabled: true, // Hiển thị chấm tròn vị trí của tôi
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // Thanh thông báo trạng thái ở trên cùng
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
        onPressed: _updateCameraAndMarker, // Nút bấm để focus lại vào vị trí hiện tại
        child: const Icon(Icons.my_location),
        backgroundColor: Colors.red,
      ),
    );
  }
}
