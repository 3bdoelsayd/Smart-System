import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with across all platforms.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // إعدادات الويب المحدثة من الصورة
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBUEfN3YRyAV0zwnFb3mXG2hyl7msjGmfY',
    appId: '1:422930647459:web:41e9c2505447c4f38a3216',
    messagingSenderId: '422930647459',
    projectId: 'university-smart-system',
    authDomain: 'university-smart-system.firebaseapp.com',
    storageBucket: 'university-smart-system.firebasestorage.app',
    measurementId: 'G-BB6HH6QMG5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzJOlVHXLqiSPztqu7IGfIFTC38yLzGBU',
    appId: '1:422930647459:android:df52fadce1b445158a3216',
    messagingSenderId: '422930647459',
    projectId: 'university-smart-system',
    storageBucket: 'university-smart-system.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzJOlVHXLqiSPztqu7IGfIFTC38yLzGBU',
    appId: '1:422930647459:ios:df52fadce1b445158a3216',
    messagingSenderId: '422930647459',
    projectId: 'university-smart-system',
    storageBucket: 'university-smart-system.firebasestorage.app',
    iosBundleId: 'com.example.smartUniversity',
  );
}
