import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/sos/presentation/pages/home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: SOSBatteryApp(),
    ),
  );
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

/// ⚡ Splash + Firebase Init + Auto-login
class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setState(() => _initialized = true);
    } catch (e, stack) {
      print('LỖI INIT FIREBASE: $e');
      print(stack);
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Failed to initialize Firebase',
            style: TextStyle(color: Colors.red[400], fontSize: 18),
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

    // ✅ Firebase đã init → kiểm tra auth
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
        }

        // User đã login
        if (snapshot.hasData) {
          return const HomePage();
        }

        // Chưa login
        return LoginPage();
      },
    );
  }
}
