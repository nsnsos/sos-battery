import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart' as latlng; // <--- THÊM DÒNG NÀY

import 'features/auth/presentation/pages/login_page.dart';
import 'features/sos/presentation/pages/home_page.dart'; // Không dùng trực tiếp nhưng giữ lại nếu cần
import 'features/sos/presentation/pages/hero_screen_accepted.dart';
import 'features/sos/presentation/pages/sos_request_sent_screen.dart'; // <--- THÊM DÒNG NÀY (quan trọng!)
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Test Shorebird patch from CI!');
  print('Flutter main started');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully!');
  } catch (e, stack) {
    print('LỖI INIT FIREBASE: $e');
    print('Stack trace: $stack');
  }

  // Load active job ID từ SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final activeJobId = prefs.getString('active_job_id');
  print('Loaded active job ID from prefs: $activeJobId');

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
    print('SOSBatteryApp build - activeJobId: $activeJobId');

    if (activeJobId != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('sos_requests')
            .doc(activeJobId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            print('Job not found or error - clearing active_job_id');
            SharedPreferences.getInstance()
                .then((prefs) => prefs.remove('active_job_id'));
            return MaterialApp(home: const LoginPage());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final currentUid = FirebaseAuth.instance.currentUser?.uid;

          // Nếu là HERO (có heroId trùng uid hiện tại)
          if (data.containsKey('heroId') && data['heroId'] == currentUid) {
            print('Resume Hero Mode');
            return MaterialApp(
              home: HeroScreenAccepted(
                sosId: activeJobId!,
                driverId: data['driverId'] ?? 'unknown',
              ),
            );
          }

          // Nếu là KHÁCH (dùng driverId như bro đang lưu khi tạo SOS)
          if (data['driverId'] == currentUid) {
            final status = data['status'] ?? 'open';

            // Nếu job đã hoàn thành hoặc hủy → clear và về login/home
            if (status == 'completed' ||
                status == 'completed_by_driver' ||
                status == 'cancelled') {
              print('Job completed/cancelled - clearing active_job_id');
              SharedPreferences.getInstance()
                  .then((prefs) => prefs.remove('active_job_id'));
              return MaterialApp(home: const LoginPage());
            }

            // Còn lại: open hoặc accepted → resume màn hình khách
            print('Resume SOS customer screen - status: $status');
            return MaterialApp(
              home: SOSRequestSentScreen(
                sosId: activeJobId!,
                reason: data['reason'] ?? 'Battery issue',
                time: DateTime.now(), // tạm dùng now, sau cải thiện nếu cần
                sosPosition: latlng.LatLng(
                  (data['location'] as GeoPoint).latitude,
                  (data['location'] as GeoPoint).longitude,
                ),
              ),
            );
          }

          // Các trường hợp khác (job của người khác) → clear prefs
          print('Job belongs to someone else - clearing prefs');
          SharedPreferences.getInstance()
              .then((prefs) => prefs.remove('active_job_id'));
          return MaterialApp(home: const LoginPage());
        },
      );
    }

    // Không có active job → bình thường vào Login
    return MaterialApp(
      title: 'SOS-BATTERY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
