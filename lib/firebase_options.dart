import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDC0sfg8ASLJpNYQZgMPipVbhgRvdfmMJg',
    appId: '1:183082399206:web:90098dcb3f057daa9c9227', // nếu dùng web
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    authDomain: 'sos-battery.firebaseapp.com',
    storageBucket: 'sos-battery.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDC0sfg8ASLJpNYQZgMPipVbhgRvdfmMJg',
    appId: '1:183082399206:android:f589f7a92cb2584a9c9227',
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    storageBucket: 'sos-battery.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDC0sfg8ASLJpNYQZgMPipVbhgRvdfmMJg',
    appId:
        '1:183082399206:ios:fe7a5ccd344c46549c9227', // <<< BẮT BUỘC PHẢI LÀ iOS APP ID
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    storageBucket: 'sos-battery.appspot.com',
    iosBundleId: 'com.sosbattery.app',
  );
}
