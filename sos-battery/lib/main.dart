import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'features/auth/presentation/pages/login_page.dart';
import 'features/sos/presentation/pages/hero_screen_accepted.dart';
import 'features/sos/presentation/pages/sos_request_sent_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase với cấu hình chuẩn từ Mac/FlutterFire
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('❌ LỖI INIT FIREBASE: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final activeJobId = prefs.getString('active_job_id');

  runApp(
    ProviderScope(
      child: SOSBatteryApp(activeJobId: activeJobId),
    ),
  );
}

class SOSBatteryApp extends StatelessWidget {
  final String? activeJobId;
  const SOSBatteryApp({super.key, this.activeJobId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS-BATTERY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      // Chỉ dùng 1 MaterialApp, điều hướng bằng logic ở home
      home: activeJobId == null 
          ? const LoginPage() 
          : JobResumeHandler(activeJobId: activeJobId!),
    );
  }
}

// Widget xử lý logic khôi phục phiên làm việc (Resume Job)
class JobResumeHandler extends StatelessWidget {
  final String activeJobId;
  const JobResumeHandler({super.key, required this.activeJobId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('sos_requests')
          .doc(activeJobId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          _clearActiveJob();
          return const LoginPage();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final status = data['status'] ?? 'open';

        // 1. Kiểm tra nếu Job đã kết thúc
        if (status == 'completed' || status == 'completed_by_driver' || status == 'cancelled') {
          _clearActiveJob();
          return const LoginPage();
        }

        // 2. Nếu là HERO (Người đi cứu hộ)
        if (data['heroId'] == currentUid) {
          return HeroScreenAccepted(
            sosId: activeJobId,
            driverId: data['driverId'] ?? 'unknown',
          );
        }

        // 3. Nếu là KHÁCH (Người cần cứu hộ)
        if (data['driverId'] == currentUid) {
          final geoPoint = data['location'] as GeoPoint?;
          return SOSRequestSentScreen(
            sosId: activeJobId,
            reason: data['reason'] ?? 'Battery issue',
            time: DateTime.now(),
            sosPosition: latlng.LatLng(
              geoPoint?.latitude ?? 0.0,
              geoPoint?.longitude ?? 0.0,
            ),
          );
        }

        // Trường hợp khác (không khớp UID)
        _clearActiveJob();
        return const LoginPage();
      },
    );
  }

  void _clearActiveJob() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_job_id');
  }
}
