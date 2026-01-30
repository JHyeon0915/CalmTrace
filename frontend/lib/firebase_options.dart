import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('This platform is not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRSVCy1FRJo1WyKoe7tI7cTUpRThiD4SQ',
    appId: '1:83293203141:android:9a326d2c1e965729741eac',
    messagingSenderId: '83293203141',
    projectId: 'calmtrace-25d65',
    storageBucket: 'calmtrace-25d65.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCBLYPefBP5Ki5ozIr4-WDMAYEZk4NzfXA',
    appId: '1:83293203141:ios:3068b7e7e5c0657b741eac',
    messagingSenderId: '83293203141',
    projectId: 'calmtrace-25d65',
    storageBucket: 'calmtrace-25d65.appspot.com',
    iosBundleId: 'com.example.calmtrace',
  );
}
