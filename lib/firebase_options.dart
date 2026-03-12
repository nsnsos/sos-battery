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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDJJosCpnLCva4bWThjHCVlT1k6XluBEy0',
    appId: '1:183082399206:web:90098dcb3f057daa9c9227',
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    authDomain: 'sos-battery-dfa5e.firebaseapp.com',
    storageBucket: 'sos-battery-dfa5e.firebasestorage.app',
    measurementId: 'G-BNPCP09QDE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDC0sfg8ASLJpNYQZgMPipVbhgRvdfmMJg',
    appId: '1:183082399206:android:f589f7a92cb2584a9c9227',
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    storageBucket: 'sos-battery-dfa5e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCEeV6qjE7rMntKiKEsp2rkSdWNHF2rFW4',
    appId: '1:183082399206:ios:fe7a5ccd344c46549c9227',
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    storageBucket: 'sos-battery-dfa5e.firebasestorage.app',
    androidClientId: '183082399206-91sggpe0i81ddtpsigq9uoajm61imcl8.apps.googleusercontent.com',
    iosClientId: '183082399206-t5v5sfb87aoh7peab4s0flhjnms6cchb.apps.googleusercontent.com',
    iosBundleId: 'com.sosbattery.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDi1Fnpq9SeDgoKl1fA2Fgffo58s0Ct-mM',
    appId: '1:183082399206:ios:acd9f03d758254e09c9227',
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    storageBucket: 'sos-battery-dfa5e.firebasestorage.app',
    androidClientId: '183082399206-91sggpe0i81ddtpsigq9uoajm61imcl8.apps.googleusercontent.com',
    iosClientId: '183082399206-0n5sd3i5jsmnhqcefg6dk6nn0tfer011.apps.googleusercontent.com',
    iosBundleId: 'com.sosbattery.sosBattery',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDJJosCpnLCva4bWThjHCVlT1k6XluBEy0',
    appId: '1:183082399206:web:847422174d31ad1f9c9227',
    messagingSenderId: '183082399206',
    projectId: 'sos-battery-dfa5e',
    authDomain: 'sos-battery-dfa5e.firebaseapp.com',
    storageBucket: 'sos-battery-dfa5e.firebasestorage.app',
    measurementId: 'G-FMRTEKH9DS',
  );

}