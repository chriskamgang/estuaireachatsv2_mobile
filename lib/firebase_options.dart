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
        throw UnsupportedError('DefaultFirebaseOptions not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBHY9Bmu_OPBjT2nkERgEvhl09fgugJc0k',
    appId: '1:722472142130:android:a65296ad19d830c145832b',
    messagingSenderId: '722472142130',
    projectId: 'estuaireachats-cecd4',
    storageBucket: 'estuaireachats-cecd4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBGv7eLeHETb5X_p0gjCKTLfM3RAnB_FCE',
    appId: '1:722472142130:ios:ae313b1634e6a20645832b',
    messagingSenderId: '722472142130',
    projectId: 'estuaireachats-cecd4',
    storageBucket: 'estuaireachats-cecd4.firebasestorage.app',
    iosBundleId: 'com.estuaireachats.estuaireachats',
  );
}
