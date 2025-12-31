import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support SOS Battery'),
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Thank you for using SOS Battery!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your donation helps keep the app free for everyone in need. Every contribution counts!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            // Nut donate bat dau tu day
            // Nút Donate chung (customer choose amount)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              onPressed: () async {
                const String stripeLink =
                    'https://buy.stripe.com/test_3cIaEXB388PgBdw1B600'; // link test bro copy
                if (await canLaunchUrl(Uri.parse(stripeLink))) {
                  await launchUrl(Uri.parse(stripeLink),
                      mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot open donation link')),
                  );
                }
              },
              child: const Text('Donate Now (choose amount)',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            // End nut donate

            const Text(
              'All donations go toward maintaining and improving the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
