import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase app.
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
      throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnnyDjlyUMfKFf6xmLi3sN2fkKpjZNbhA',
    appId: '1:220629323801:android:8afd3b56df48c12fc01a88',
    messagingSenderId: '220629323801',
    projectId: 'kennetvillanescv',
    storageBucket: 'kennetvillanescv.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCnnyDjlyUMfKFf6xmLi3sN2fkKpjZNbhA',
    appId: '1:220629323801:ios:8afd3b56df48c12fc01a88',
    messagingSenderId: '220629323801',
    projectId: 'kennetvillanescv',
    storageBucket: 'kennetvillanescv.firebasestorage.app',
    iosClientId: '220629323801-vd8reeqrfoae58b73n00a0mlm8nc694h.apps.googleusercontent.com',
    iosBundleId: 'com.familytracker.familyTracker',
  );
}