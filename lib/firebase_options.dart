import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDC0sfg8ASLJpNYQZgMPipVbhgRvdfmMJg',
    appId: '1:183082399206:android:f589f7a92cb2584a9c9227',
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    storageBucket: '', // Nếu project có Cloud Storage thì điền, không thì để rỗng ""
  );
}