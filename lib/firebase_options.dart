// Generated Firebase Options for SmartCart
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
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDmI6ntMIJGcVz9vhtA60Q8gbKLrg69iJk',
    appId: '1:725023630080:android:ec0af27c98f6d2ff6b89e5',
    messagingSenderId: '725023630080',
    projectId: 'smartcart-a4013',
    storageBucket: 'smartcart-a4013.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDmI6ntMIJGcVz9vhtA60Q8gbKLrg69iJk',
    appId: '1:725023630080:web:ec0af27c98f6d2ff6b89e5',
    messagingSenderId: '725023630080',
    projectId: 'smartcart-a4013',
    authDomain: 'smartcart-a4013.firebaseapp.com',
    storageBucket: 'smartcart-a4013.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDmI6ntMIJGcVz9vhtA60Q8gbKLrg69iJk',
    appId: '1:725023630080:ios:ec0af27c98f6d2ff6b89e5',
    messagingSenderId: '725023630080',
    projectId: 'smartcart-a4013',
    storageBucket: 'smartcart-a4013.firebasestorage.app',
    iosBundleId: 'com.example.ambarProductivity',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDmI6ntMIJGcVz9vhtA60Q8gbKLrg69iJk',
    appId: '1:725023630080:ios:ec0af27c98f6d2ff6b89e5',
    messagingSenderId: '725023630080',
    projectId: 'smartcart-a4013',
    storageBucket: 'smartcart-a4013.firebasestorage.app',
    iosBundleId: 'com.example.ambarProductivity',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDmI6ntMIJGcVz9vhtA60Q8gbKLrg69iJk',
    appId: '1:725023630080:web:ec0af27c98f6d2ff6b89e5',
    messagingSenderId: '725023630080',
    projectId: 'smartcart-a4013',
    authDomain: 'smartcart-a4013.firebaseapp.com',
    storageBucket: 'smartcart-a4013.firebasestorage.app',
  );
}
