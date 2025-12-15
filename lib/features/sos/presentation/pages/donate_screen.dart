import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev; // <-- ĐÃ THÊM: Để debug lỗi

class DonateScreen extends StatelessWidget {
  // Thay link Stripe của bro (tạo tại https://dashboard.stripe.com/donations)
  // Đây là ví dụ placeholder, bạn cần thay bằng link thật của mình
  final String stripeLink = "https://donate.stripe.com/your_stripe_link_here"; 

  const DonateScreen({super.key}); // <-- ĐÃ THÊM: Constructor const

  Future<void> _donate(BuildContext context) async { // <-- ĐÃ SỬA: Thêm context
    final Uri uri = Uri.parse(stripeLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      dev.log("Không thể mở URL quyên góp: $stripeLink");
      ScaffoldMessenger.of(context).showSnackBar( // <-- ĐÃ THÊM: Thông báo lỗi
        const SnackBar(content: Text("Không thể mở trang quyên góp. Vui lòng thử lại sau."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate cho SOS Battery')),
      body: Center(
        child: Padding( // <-- ĐÃ THÊM: Padding cho nội dung
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Cảm ơn bạn đã ủng hộ SOS Battery! 100% tiền về đội ngũ Dallas', 
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _donate(context), // <-- ĐÃ SỬA: Truyền context
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(20)),
                child: const Text('DONATE VIA STRIPE', style: TextStyle(fontSize: 30)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
