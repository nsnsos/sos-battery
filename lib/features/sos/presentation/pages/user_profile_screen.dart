import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  bool _wantsToReceiveTips = false; // Hero bật để nhận tip
  String _venmoUsername = '';
  String _cashAppUsername = '';
  String _applePayEmail = ''; // nếu dùng Apple Pay
  bool _isLoading = false;
  bool _isHero = false; // check role Hero (từ Firestore hoặc logic)

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _name = data['name'] ?? '';
        _phone = data['phone'] ?? '';
        _wantsToReceiveTips = data['wantsToReceiveTips'] ?? false;
        _venmoUsername = data['venmoUsername'] ?? '';
        _cashAppUsername = data['cashAppUsername'] ?? '';
        _applePayEmail = data['applePayEmail'] ?? '';
        _isHero = data['isHero'] ?? false; // lấy role Hero
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _name,
      'phone': _phone,
      'wantsToReceiveTips': _wantsToReceiveTips,
      if (_wantsToReceiveTips) ...{
        'venmoUsername': _venmoUsername,
        'cashAppUsername': _cashAppUsername,
        'applePayEmail': _applePayEmail,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                      'Update your info for better experience',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => _name = value,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      initialValue: _phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => _phone = value,
                    ),
                    const SizedBox(height: 30),

                    if (_isHero) ...[
                      SwitchListTile(
                        title: const Text('Register to receive tips from Drivers'),
                        subtitle: const Text('Enable to receive direct tips via Venmo/Cash App/Apple Pay'),
                        value: _wantsToReceiveTips,
                        onChanged: (value) => setState(() => _wantsToReceiveTips = value),
                      ),
                      const SizedBox(height: 20),

                      if (_wantsToReceiveTips) ...[
                        TextFormField(
                          initialValue: _venmoUsername,
                          decoration: const InputDecoration(labelText: 'Venmo Username', border: OutlineInputBorder()),
                          onChanged: (value) => _venmoUsername = value,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          initialValue: _cashAppUsername,
                          decoration: const InputDecoration(labelText: 'Cash App Username', border: OutlineInputBorder()),
                          onChanged: (value) => _cashAppUsername = value,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          initialValue: _applePayEmail,
                          decoration: const InputDecoration(labelText: 'Apple Pay Email (optional)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => _applePayEmail = value,
                        ),
                      ],
                    ],

                    const SizedBox(height: 40),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      ),
                      onPressed: _saveProfile,
                      child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}