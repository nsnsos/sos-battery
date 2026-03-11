import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Chỉ init Firebase một lần
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDJJosCpnLCva4bWThjHCVlT1k6XluBEy0",
      authDomain: "sos-battery-dfa5e.firebaseapp.com",
      projectId: "sos-battery-dfa5e",
      storageBucket: "sos-battery-dfa5e.firebasestorage.app",
      messagingSenderId: "183082399206",
      appId: "1:183082399206:web:90098dcb3f057daa9c9227",
      measurementId: "G-BNPCP09QDE",
    ),
  );

  print('Firebase initialized for Admin Web'); // Debug (mở F12 để xem)

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Battery Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(backgroundColor: Colors.red),
      ),
      home: const AdminLoginPage(),
    );
  }
}
