import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Battery Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/admin_login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng quan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Card tổng quan user
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                int totalUsers = snapshot.data!.docs.length;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Tổng User'),
                    subtitle: Text('$totalUsers user'),
                  ),
                );
              },
            ),

            // Card SOS active
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sos_requests')
                  .where('status', isEqualTo: 'open')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                int activeSOS = snapshot.data!.docs.length;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.emergency),
                    title: const Text('SOS Active'),
                    subtitle: Text('$activeSOS yêu cầu đang chờ Hero'),
                  ),
                );
              },
            ),

            // Thêm card khác sau (tổng coin, top Hero, donate...)
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.notifications),
              label: const Text('Broadcast / Promotion'),
              onPressed: () {
                // Chuyển sang trang Broadcast sau
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}