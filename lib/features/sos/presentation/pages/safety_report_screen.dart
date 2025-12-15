import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- ĐÃ THÊM: Để lấy ID người báo cáo
import 'dart:developer' as dev;

class SafetyReportScreen extends StatelessWidget {
  final String jobId;
  final bool isHero; // <-- ĐÃ THÊM: Cờ xác định vai trò người báo cáo

  const SafetyReportScreen({super.key, required this.jobId, required this.isHero});

  void _reportFake(BuildContext context) async { // <-- ĐÃ SỬA: Thêm BuildContext và async
    try {
      // Xác định người gửi báo cáo
      final User? user = FirebaseAuth.instance.currentUser;
      final String reporterRole = isHero ? 'Hero' : 'User';

      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'fake_reported',
        'reportedByUserId': user?.uid ?? 'anonymous', // <-- ĐÃ THÊM: ID người báo cáo
        'reportedByRole': reporterRole,              // <-- ĐÃ THÊM: Vai trò
        'reportTimestamp': FieldValue.serverTimestamp(),
      });

      dev.log("Job $jobId đã được báo cáo giả mạo thành công.");

      // Hiển thị thông báo thành công cho người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Đã gửi báo cáo thành công!"),
            backgroundColor: Colors.green),
      );
      
      // Trở về màn hình trước
      Navigator.pop(context);

    } catch (e) {
      dev.log("Lỗi khi báo cáo giả mạo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lỗi: Không thể gửi báo cáo. $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  // Hàm mô phỏng cảnh báo an toàn (không cần sửa nhiều)
  void _triggerSafetyAlert(BuildContext context) {
    // Trong ứng dụng thật, bạn sẽ tích hợp gọi 911 tại đây
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cảnh Báo An Toàn'),
        content: const Text('Đã gửi cảnh báo đến cơ quan chức năng!'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('An Toàn & Report')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              // Truyền context vào hàm xử lý
              onPressed: () => _triggerSafetyAlert(context), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
              child: const Text('⚠️ CẢNH BÁO AN TOÀN', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              // Truyền context vào hàm xử lý
              onPressed: () => _reportFake(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Report Fake SOS', style: TextStyle(fontSize: 30)),
            ),
          ],
        ),
      ),
    );
  }
}
