import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      default:
        throw UnsupportedError('This platform is not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDRSVCy1FRJo1WyKoe7tI7cTUpRThiD4SQ',
    appId: '1:83293203141:web:calmtrace25d65',
    messagingSenderId: '83293203141',
    projectId: 'calmtrace-25d65',
    authDomain: 'calmtrace-25d65.firebaseapp.com',
    storageBucket: 'calmtrace-25d65.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRSVCy1FRJo1WyKoe7tI7cTUpRThiD4SQ',
    appId: '1:83293203141:android:1958b26e2b422ef9741eac',
    messagingSenderId: '83293203141',
    projectId: 'calmtrace-25d65',
    storageBucket: 'calmtrace-25d65.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCBLYPefBP5Ki5ozIr4-WDMAYEZk4NzfXA',
    appId: '1:83293203141:ios:c06eb1b3cababb6f741eac',
    messagingSenderId: '83293203141',
    projectId: 'calmtrace-25d65',
    storageBucket: 'calmtrace-25d65.firebasestorage.app',
    iosBundleId: 'com.jeonghyeon.calmtrace',
  );
}
