import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev; // <-- ĐÃ THÊM: Để debug lỗi

class RoadsideScreen extends StatelessWidget {
  final String hotline = "tel:+18887627623"; // hotline AAA hoặc đội van bro
  
  const RoadsideScreen({super.key}); // <-- ĐÃ THÊM: Constructor const

  Future<void> _callRoadside(BuildContext context) async { // <-- ĐÃ SỬA: Thêm context
    final Uri uri = Uri.parse(hotline);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      dev.log("Không thể thực hiện cuộc gọi: $hotline");
      ScaffoldMessenger.of(context).showSnackBar( // <-- ĐÃ THÊM: Thông báo lỗi
        const SnackBar(content: Text("Không thể thực hiện cuộc gọi. Vui lòng kiểm tra quyền hoặc số hotline."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Roadside Chính Hãng')),
      body: Center(
        child: Padding( // <-- ĐÃ THÊM: Padding cho nội dung
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Gọi đội xe van chính hãng thay pin, jump start ngay!', 
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _callRoadside(context), // <-- ĐÃ SỬA: Truyền context
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(20)),
                child: const Text('GỌI ĐỘI XE VAN', style: TextStyle(fontSize: 30)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
