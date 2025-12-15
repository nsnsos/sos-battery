import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev;

class TipScreen extends StatelessWidget {
  // Thay vì gán cứng, chúng ta nhận handles từ màn hình trước
  final String heroVenmoHandle; 
  final String heroCashAppHandle; 

  const TipScreen({
    super.key,
    required this.heroVenmoHandle,
    required this.heroCashAppHandle,
  });


  // Hàm chung để mở URL và xử lý lỗi
  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      dev.log("Không thể mở URL: $url");
      ScaffoldMessenger.of(context).showSnackBar( // <-- THÊM: SnackBar báo lỗi
        SnackBar(content: Text("Không thể mở ứng dụng. Vui lòng cài đặt ứng dụng hoặc kiểm tra handle."), backgroundColor: Colors.red),
      );
    }
  }

  // Mở Venmo (linh hoạt hơn, chỉ mở app để user nhập số tiền)
  void _tipVenmo(BuildContext context) {
    // Cấu trúc URL: venmo://paycharge?recipients=@handle
    // Hoặc thử cấu trúc cũ nếu cái trên lỗi: venmo://pay?recipients=handle
    String url = 'venmo://paycharge?recipients=$heroVenmoHandle';
    _launchURL(url, context);
  }

  // Mở Cash App (linh hoạt hơn, chỉ mở app để user nhập số tiền)
  void _tipCashApp(BuildContext context) {
     // Cấu trúc URL: cashapp://send?requestor_id=handle (handle có dấu $)
    String url = 'cashapp://send?requestor_id=$heroCashAppHandle';
    _launchURL(url, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tip Hero')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Tài khoản Hero:\nVenmo: $heroVenmoHandle\nCash App: $heroCashAppHandle",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              // Truyền context vào hàm
              onPressed: () => _tipVenmo(context), 
              child: const Text('Tip via Venmo (Mở ứng dụng)'),
            ),
            ElevatedButton(
              // Truyền context vào hàm
              onPressed: () => _tipCashApp(context),
              child: const Text('Tip via Cash App (Mở ứng dụng)'),
            ),
          ],
        ),
      ),
    );
  }
}
