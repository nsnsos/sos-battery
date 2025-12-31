import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TipScreen extends StatefulWidget {
  final String heroId; // UID Hero để lấy profile từ Firestore

  const TipScreen({super.key, required this.heroId});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  String? _selectedMethod; // phương thức Hero đã đăng ký
  String _venmoUsername = '';
  String _cashAppUsername = '';
  String _applePayEmail = '';
  String _zelleEmail = '';
  final TextEditingController _amountController = TextEditingController(text: '10');
  final TextEditingController _noteController = TextEditingController(text: 'Thanks for the rescue!');

  // Danh sách phương thức tip (icon + tên + field)
  final List<Map<String, dynamic>> _paymentOptions = [
    {'name': 'Venmo', 'icon': Icons.payment, 'color': Colors.blue, 'field': 'venmoUsername', 'linkPrefix': 'https://venmo.com/'},
    {'name': 'Zelle', 'icon': Icons.send, 'color': Colors.purple, 'field': 'zelleEmail', 'linkPrefix': 'https://zellepay.com/'},
    {'name': 'Apple Pay', 'icon': Icons.apple, 'color': Colors.black, 'field': 'applePayEmail', 'linkPrefix': 'https://pay.apple.com/'},
    {'name': 'Cash App', 'icon': Icons.money, 'color': Colors.green, 'field': 'cashAppUsername', 'linkPrefix': 'https://cash.app/'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHeroPaymentMethods();
  }

  Future<void> _loadHeroPaymentMethods() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('heroes').doc(widget.heroId).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _venmoUsername = data['venmoUsername'] ?? '';
          _cashAppUsername = data['cashAppUsername'] ?? '';
          _applePayEmail = data['applePayEmail'] ?? '';
          _zelleEmail = data['zelleEmail'] ?? '';

          // Tự động chọn phương thức đầu tiên có data
          _selectedMethod = _venmoUsername.isNotEmpty ? 'venmoUsername' :
                            _cashAppUsername.isNotEmpty ? 'cashAppUsername' :
                            _applePayEmail.isNotEmpty ? 'applePayEmail' :
                            _zelleEmail.isNotEmpty ? 'zelleEmail' : null;
        });
      }
    } catch (e) {
      print('Load hero payment error: $e');
    }
  }

  Future<void> _sendTip() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hero has not registered any payment method')),
      );
      return;
    }

    String amount = _amountController.text.trim();
    String note = _noteController.text.trim();

    if (amount.isEmpty || double.tryParse(amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Lấy identifier từ biến state
    String identifier = _selectedMethod == 'venmoUsername' ? _venmoUsername :
                        _selectedMethod == 'cashAppUsername' ? _cashAppUsername :
                        _selectedMethod == 'applePayEmail' ? _applePayEmail :
                        _zelleEmail;

    // Tìm linkPrefix từ paymentOptions
    String linkPrefix = _paymentOptions.firstWhere((opt) => opt['field'] == _selectedMethod)['linkPrefix'];

    String tipLink = '$linkPrefix$identifier?txn=pay&amount=$amount&note=${Uri.encodeComponent(note)}';

    if (await canLaunchUrl(Uri.parse(tipLink))) {
      await launchUrl(Uri.parse(tipLink), mode: LaunchMode.externalApplication);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tip sent! Thank you!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open payment app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tip the Hero'),
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
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'Thank you for the help!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose a payment method and tip the Hero!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Chọn phương thức tip (icon)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _paymentOptions.map((option) {
                bool isSelected = _selectedMethod == option['field'];
                return FilterChip(
                  label: Text(option['name']),
                  avatar: Icon(option['icon'], color: isSelected ? Colors.white : option['color']),
                  selected: isSelected,
                  backgroundColor: Colors.grey[800],
                  selectedColor: option['color'],
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMethod = selected ? option['field'] : null;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // Amount + Note
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (\$)',
                hintText: 'e.g. 5, 10, 20, 50...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800], // xóa const để tránh lỗi
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Thanks for the rescue!',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800], // xóa const
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              onPressed: _sendTip,
              child: const Text('Tip Now', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Powered by Venmo, Zelle, Apple Pay, Cash App',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}