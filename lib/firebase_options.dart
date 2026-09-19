// File generated for provider_app.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase apps.
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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCgxOpnhAXYuEx_UZhWAZmHY-h_RrjOj7U',
    appId: '1:709570383359:web:b3f81ab88fdd180fce6bca',
    messagingSenderId: '709570383359',
    projectId: 'marketplace-push-notific-4371c',
    authDomain: 'marketplace-push-notific-4371c.firebaseapp.com',
    storageBucket: 'marketplace-push-notific-4371c.firebasestorage.app',
    measurementId: 'G-P65LLMSBGR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAg-ZgpfFWNHyflBRfzFnN7b34wNn0K8sM',
    appId: '1:709570383359:android:6ee2405f948d3e96ce6bca',
    messagingSenderId: '709570383359',
    projectId: 'marketplace-push-notific-4371c',
    storageBucket: 'marketplace-push-notific-4371c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8j5aEsywCHY4Xg5KiVXKXUWYHbo67Wbs',
    appId: '1:709570383359:ios:109996b839b4cb75ce6bca',
    messagingSenderId: '709570383359',
    projectId: 'marketplace-push-notific-4371c',
    storageBucket: 'marketplace-push-notific-4371c.firebasestorage.app',
    iosBundleId: 'com.example.provider_app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD8j5aEsywCHY4Xg5KiVXKXUWYHbo67Wbs',
    appId: '1:709570383359:ios:109996b839b4cb75ce6bca',
    messagingSenderId: '709570383359',
    projectId: 'marketplace-push-notific-4371c',
    storageBucket: 'marketplace-push-notific-4371c.firebasestorage.app',
    iosBundleId: 'com.example.provider_app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgxOpnhAXYuEx_UZhWAZmHY-h_RrjOj7U',
    appId: '1:709570383359:web:288683a2dd6386abce6bca',
    messagingSenderId: '709570383359',
    projectId: 'marketplace-push-notific-4371c',
    authDomain: 'marketplace-push-notific-4371c.firebaseapp.com',
    storageBucket: 'marketplace-push-notific-4371c.firebasestorage.app',
    measurementId: 'G-TN7YP9D4Y0',
  );
}
