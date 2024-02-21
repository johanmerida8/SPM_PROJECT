// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyDrAc1qVLr0KYPBfeQdNNAC5FdYE-zZjWg',
    appId: '1:726368023189:web:758d9db503d7d058f2a19c',
    messagingSenderId: '726368023189',
    projectId: 'chat-app2023-5c2c0',
    authDomain: 'chat-app2023-5c2c0.firebaseapp.com',
    storageBucket: 'chat-app2023-5c2c0.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAfU4u0gaSeZNbyrGVVG4Dv-nQ55qCAFrk',
    appId: '1:726368023189:android:e975f340eb2d52f3f2a19c',
    messagingSenderId: '726368023189',
    projectId: 'chat-app2023-5c2c0',
    storageBucket: 'chat-app2023-5c2c0.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCCQPodMjWYfLHJgj4BAdSQA_MXC3DBMkk',
    appId: '1:726368023189:ios:e0462f282bd1338ef2a19c',
    messagingSenderId: '726368023189',
    projectId: 'chat-app2023-5c2c0',
    storageBucket: 'chat-app2023-5c2c0.appspot.com',
    iosBundleId: 'com.example.chatApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCCQPodMjWYfLHJgj4BAdSQA_MXC3DBMkk',
    appId: '1:726368023189:ios:109003c545126767f2a19c',
    messagingSenderId: '726368023189',
    projectId: 'chat-app2023-5c2c0',
    storageBucket: 'chat-app2023-5c2c0.appspot.com',
    iosBundleId: 'com.example.chatApp.RunnerTests',
  );
}
