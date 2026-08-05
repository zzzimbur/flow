// File generated from Firebase project settings (flowapp-25488).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLDQr52iwR0oiHx9sY3Ura4KC06nq25Ls',
    appId: '1:590191532624:android:9ef348230792a94dc84f55',
    messagingSenderId: '590191532624',
    projectId: 'flowapp-25488',
    storageBucket: 'flowapp-25488.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDiCaIt5wjyqq5lz19PdpHB1dNPAjaP6T4',
    appId: '1:590191532624:ios:7d650577b668430ec84f55',
    messagingSenderId: '590191532624',
    projectId: 'flowapp-25488',
    storageBucket: 'flowapp-25488.firebasestorage.app',
    iosClientId:
        '590191532624-gvs8p0c00g602t6kqh24et22qd6ohqt6.apps.googleusercontent.com',
    iosBundleId: 'com.prostozapaska.flow',
  );
}
