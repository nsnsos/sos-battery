import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HeroProfileScreen extends StatefulWidget {
  const HeroProfileScreen({super.key});

  @override
  State<HeroProfileScreen> createState() => _HeroProfileScreenState();
}

class _HeroProfileScreenState extends State<HeroProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _venmoUsername = '';
  String _cashAppUsername = '';
  String _applePayEmail = '';
  String _zelleEmail = '';
  bool _wantsToReceiveTips = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _paymentOptions = [
    {
      'name': 'Venmo',
      'icon': Icons.payment,
      'color': Colors.blue,
      'field': 'venmoUsername'
    },
    {
      'name': 'Cash App',
      'icon': Icons.money,
      'color': Colors.green,
      'field': 'cashAppUsername'
    },
    {
      'name': 'Apple Pay',
      'icon': Icons.apple,
      'color': Colors.black,
      'field': 'applePayEmail'
    },
    {
      'name': 'Zelle',
      'icon': Icons.send,
      'color': Colors.purple,
      'field': 'zelleEmail'
    },
  ];

  List<String> _selectedMethods = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('heroes').doc(uid).get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _name = data['name'] ?? '';
        _phone = data['phone'] ?? '';
        _wantsToReceiveTips = data['wantsToReceiveTips'] ?? false;
        _venmoUsername = data['venmoUsername'] ?? '';
        _cashAppUsername = data['cashAppUsername'] ?? '';
        _applePayEmail = data['applePayEmail'] ?? '';
        _zelleEmail = data['zelleEmail'] ?? '';
        _selectedMethods = _paymentOptions
            .where((option) =>
                data[option['field']] != null && data[option['field']] != '')
            .map((option) => option['field'] as String)
            .toList();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String uid = FirebaseAuth.instance.currentUser!.uid;
    Map<String, dynamic> updateData = {
      'name': _name,
      'phone': _phone,
      'wantsToReceiveTips': _wantsToReceiveTips,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_wantsToReceiveTips) {
      updateData.addAll({
        'venmoUsername': _venmoUsername,
        'cashAppUsername': _cashAppUsername,
        'applePayEmail': _applePayEmail,
        'zelleEmail': _zelleEmail,
      });
    }

    await FirebaseFirestore.instance
        .collection('heroes')
        .doc(uid)
        .set(updateData, SetOptions(merge: true));

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Profile updated!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Profile'),
        backgroundColor: Colors.green[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Info',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(
                          labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => _name = value,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      initialValue: _phone,
                      decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => _phone = value,
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'Register to Receive Tips (optional)',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _paymentOptions.map((option) {
                        bool isSelected =
                            _selectedMethods.contains(option['field']);
                        return FilterChip(
                          label: Text(option['name']),
                          avatar: Icon(option['icon'],
                              color:
                                  isSelected ? Colors.white : option['color']),
                          selected: isSelected,
                          backgroundColor: Colors.grey[800],
                          selectedColor: option['color'],
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMethods.add(option['field']);
                              } else {
                                _selectedMethods.remove(option['field']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Field nhập username cho từng phương thức đã chọn
                    ..._selectedMethods.map((field) {
                      String label = field == 'venmoUsername'
                          ? 'Venmo Username'
                          : field == 'cashAppUsername'
                              ? 'Cash App Username'
                              : field == 'applePayEmail'
                                  ? 'Apple Pay Email'
                                  : 'Zelle Email';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TextFormField(
                          decoration: InputDecoration(
                              labelText: label,
                              border: const OutlineInputBorder()),
                          onChanged: (value) {
                            if (field == 'venmoUsername')
                              _venmoUsername = value;
                            if (field == 'cashAppUsername')
                              _cashAppUsername = value;
                            if (field == 'applePayEmail')
                              _applePayEmail = value;
                            if (field == 'zelleEmail') _zelleEmail = value;
                          },
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                      ),
                      onPressed: _saveProfile,
                      child: const Text('Save Profile',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),

                    // Hiển thị MCoin & HCoin (tinh gọn, góc trên)
                    //them phan test o day
                    // Phần hiển thị MCoin & HCoin (tinh gọn, góc trên - thêm vào cuối Column)
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.timer,
                                  color: Colors.blue, size: 30),
                              const SizedBox(height: 5),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('heroes')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text('Loading...',
                                        style: TextStyle(color: Colors.white));
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}',
                                        style:
                                            const TextStyle(color: Colors.red));
                                  }
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return const Text('No stats yet',
                                        style: TextStyle(color: Colors.grey));
                                  }

                                  var data = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  int mcoin = data['mcoin'] ?? 0;
                                  return Text('MCoin: $mcoin',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold));
                                },
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.volunteer_activism,
                                  color: Colors.green, size: 30),
                              const SizedBox(height: 5),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('heroes')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text('Loading...',
                                        style: TextStyle(color: Colors.white));
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}',
                                        style:
                                            const TextStyle(color: Colors.red));
                                  }
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return const Text('No stats yet',
                                        style: TextStyle(color: Colors.grey));
                                  }

                                  var data = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  int hcoin = data['hcoin'] ?? 0;
                                  return Text('HCoin: $hcoin',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

// Chi tiết stats (ẩn, mở rộng khi cần - thêm vào cuối Column)
                    const SizedBox(height: 40),
                    ExpansionTile(
                      title: const Text('View Detailed Hero Stats',
                          style: TextStyle(color: Colors.white)),
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('heroes')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white)),
                              );
                            }

                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                    'Error loading stats: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.red)),
                              );
                            }

                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                    'No stats yet - Go online to earn MCoin!',
                                    style: TextStyle(color: Colors.grey)),
                              );
                            }

                            var data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            int totalPoints = data['totalPoints'] ?? 0;
                            int level = data['level'] ?? 1;
                            int streak = data['streak'] ?? 0;
                            List<dynamic> badges = data['badges'] ?? [];

                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone Number: $_phone',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  Text('Total Points: $totalPoints',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  Text('Level: $level',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  Text('Streak: $streak days',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  const SizedBox(height: 10),
                                  Text('Badges: ${badges.join(', ')}',
                                      style: const TextStyle(
                                          color: Colors.yellow, fontSize: 16)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    // ket thuc phan test streambuilder
                  ],
                ),
              ),
            ),
    );
  }
}
