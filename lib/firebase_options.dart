import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDfspFfmBN0jE-1ZduudYJwGnzgcbJCVBA',
    appId: '1:617839795124:android:a1fcaa03a1a44114adb0e1',
    messagingSenderId: '617839795124',
    projectId: 'zgum-6cc66',
    storageBucket: 'zgum-6cc66.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDGI8sCcV1XDI8wDdahA3QXfo0H6ZKIRI0',
    appId: '1:617839795124:ios:2a0037d380b9382fadb0e1',
    messagingSenderId: '617839795124',
    projectId: 'zgum-6cc66',
    storageBucket: 'zgum-6cc66.firebasestorage.app',
    iosBundleId: 'com.zgum.app',
  );
}
