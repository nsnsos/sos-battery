import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sos_battery/features/sos/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Email/Password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Phone
  String _phoneNumber = '';
  String _verificationId = '';
  bool _codeSent = false;
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Email Sign In / Sign Up
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
        await _showLegalDisclaimer();
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Authentication failed';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _showLegalDisclaimer();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed';
        _isLoading = false;
      });
    }
  }

  // Phone Auth
  Future<void> _verifyPhoneNumber() async {
    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        await _showLegalDisclaimer();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _errorMessage = e.message ?? 'Verification failed';
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
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
  }

  Future<void> _signInWithPhoneOTP() async {
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Invalid OTP';
        _isLoading = false;
      });
    }
  }

  // them cau thong bao o day.
  Future<void> _showLegalDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_disclaimer') ?? false;

    if (hasSeen) return; // Chỉ show 1 lần

    await showDialog(
      context: context,
      barrierDismissible: false, // Không cho đóng bằng bấm ngoài
      builder: (context) => AlertDialog(
        title: const Text('Important Legal Notice'),
        content: const Text(
          'SOS Battery is a voluntary roadside assistance app and does not replace emergency services.\n\n'
          'This application is NOT a substitute for dialing 911 or any local emergency number.\n\n'
          'In any situation involving immediate danger to life, serious injury, fire, medical emergency, or public safety threat, call 911 immediately.\n\n'
          'SOS Battery does not guarantee response time, availability of Heroes, or the outcome of any assistance request.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool('has_seen_disclaimer', true);
              Navigator.pop(context);
            },
            child: const Text('I Understand',
                style: TextStyle(color: Colors.blue)),
          ),
        ],
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
      ),
    );
  }
  // End cau thong bao.

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Dồn giữa theo chiều dọc
            crossAxisAlignment:
                CrossAxisAlignment.center, // Dồn giữa theo chiều ngang
            children: [
              // Logo (giữa)
              Image.asset(
                'assets/icons/iconsos.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              // Tiêu đề SOS Battery (giữa)
              const Text(
                'SOS Battery',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Tiêu đề phụ Roadside Help (giữa)
              Text(
                'Roadside Help',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),

              if (!_codeSent) ...[
                // Email + Password Section
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : () => _authWithEmail(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign In',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isLoading ? null : () => _authWithEmail(true),
                  child: const Text('Don\'t have an account? Sign Up',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 30),

                // Google Sign-In
                ElevatedButton.icon(
                  icon: const Icon(Icons.account_circle),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: 30),

                // Phone Sign-In
                const Text('OR',
                    style: TextStyle(color: Colors.grey, fontSize: 18)),
                const SizedBox(height: 20),
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialCountryCode: 'US',
                  style: const TextStyle(color: Colors.white),
                  onChanged: (phone) {
                    _phoneNumber = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPhoneNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                  child: const Text('Sign in with Phone',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ] else ...[
                // OTP Screen
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithPhoneOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                  child: const Text('Verify Code',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 40),
              const Text(
                'By continuing, you agree to our Terms & Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
