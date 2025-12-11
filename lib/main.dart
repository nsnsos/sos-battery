import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/location_service.dart';   // Import LocationService
import 'features/sos/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocationService.init();   // Khởi động background location
  runApp(const ProviderScope(child: SOSBatteryApp()));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocationService.init();
  LocationService.start();   // ← THÊM DÒNG NÀY
  runApp(const ProviderScope(child: SOSBatteryApp()));
}

class SOSBatteryApp extends StatelessWidget {
  const SOSBatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS-BATTERY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const HomePage(),
    );
  }
}