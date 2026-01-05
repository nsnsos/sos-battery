import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/sos/presentation/pages/home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Flutter main started');

  // Khởi tạo Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully!');
  } catch (e, stack) {
    print('LỖI INIT FIREBASE: $e');
    print('Stack trace: $stack');
    // Nếu fail, app vẫn chạy nhưng auth không hoạt động
  }
  //khoi tao Background Service
  await initializeBackgroundService(); // Thêm dòng này
  // End khoi tao BS
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
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  bool _initialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _waitForFirebase();
  }

  Future<void> _waitForFirebase() async {
    try {
      // Đợi Firebase ready (nếu chưa init ở main)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await Future.delayed(
          const Duration(milliseconds: 500)); // delay nhỏ để đảm bảo
      setState(() {
        _initialized = true;
      });
      print('InitializationScreen: Firebase ready');
    } catch (e) {
      print('InitializationScreen error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Failed to initialize Firebase: $_errorMessage',
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.red)),
          );
        }

        if (snapshot.hasData) {
          print('User logged in: ${snapshot.data!.uid}');
          return const HomePage();
        }

        print('No user logged in, showing LoginPage');
        return const LoginPage();
      },
    );
  }
}
