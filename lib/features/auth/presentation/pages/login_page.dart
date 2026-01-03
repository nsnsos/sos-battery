import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:sos_battery/features/sos/presentation/pages/home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  String _phoneNumber = '';
  String _verificationId = '';
  bool _codeSent = false;

  bool _isLoading = false;
  String? _errorMessage;

  // 🔴 iOS bắt buộc có clientId – Android không cần
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '1-183082399206-ios-fe7a5ccd344c46549c9227.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
  }

  // ================= EMAIL AUTH =================
  Future<void> _authWithEmail(bool isSignUp) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Authentication failed';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= GOOGLE SIGN IN =================
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      _goHome();
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed';
        _isLoading = false;
      });
    }
  }

  // ================= PHONE AUTH =================
  Future<void> _verifyPhoneNumber() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          _goHome();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _errorMessage = e.message ?? 'Verification failed';
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? _) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Phone sign-in is not available';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithPhoneOTP() async {
    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Invalid OTP';
        _isLoading = false;
      });
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Text(
                'SOS Battery',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 60),
              if (!_codeSent) ...[
                _input(controller: _emailController, label: 'Email'),
                const SizedBox(height: 20),
                _input(
                    controller: _passwordController,
                    label: 'Password',
                    obscure: true),
                const SizedBox(height: 20),
                _primaryButton(
                    text: 'Sign In', onTap: () => _authWithEmail(false)),
                TextButton(
                  onPressed: () => _authWithEmail(true),
                  child: const Text('Create account',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.account_circle),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                ),
                const SizedBox(height: 30),
                IntlPhoneField(
                  initialCountryCode: 'US',
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Phone Number'),
                  onChanged: (phone) => _phoneNumber = phone.completeNumber,
                ),
                const SizedBox(height: 20),
                _primaryButton(
                    text: 'Sign in with Phone', onTap: _verifyPhoneNumber),
              ] else ...[
                _input(controller: _otpController, label: 'OTP'),
                const SizedBox(height: 20),
                _primaryButton(text: 'Verify Code', onTap: _signInWithPhoneOTP),
              ],
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({required String text, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        minimumSize: const Size(double.infinity, 55),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget _input(
      {required TextEditingController controller,
      required String label,
      bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
