import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTestPage extends StatefulWidget {
  const MapTestPage({super.key});

  @override
  State<MapTestPage> createState() => _MapTestPageState();
}

class _MapTestPageState extends State<MapTestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TEST GOOGLE MAP API')),
      body: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(10.7769, 106.7009),  // TP.HCM để test
          zoom: 15,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
}