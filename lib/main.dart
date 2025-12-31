import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/presentation/pages/login_page.dart';  // đường dẫn đúng
import 'features/sos/presentation/pages/home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully!');
  } catch (e, stack) {
    print('LỖI INIT FIREBASE: $e');
    print(stack);
  }

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.red)),
            );
          }

          if (snapshot.hasData) {
            return const HomePage();
          }

          return LoginPage();  // <-- xóa "const" ở đây
        },
      ),
    );
  }
}