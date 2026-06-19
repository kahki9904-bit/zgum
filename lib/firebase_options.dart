import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

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
    appId: '1:617839795124:android:6c6fe2ec80899adfadb0e1',
    messagingSenderId: '617839795124',
    projectId: 'zgum-6cc66',
    storageBucket: 'zgum-6cc66.firebasestorage.app',
  );

  // iOS 값은 GoogleService-Info.plist 받은 후 코덱스가 채울 것
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '617839795124',
    projectId: 'zgum-6cc66',
    storageBucket: 'zgum-6cc66.firebasestorage.app',
    iosBundleId: 'com.example.zgum',
  );
}
