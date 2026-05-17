import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummy_Key_For_Development_Only',
    appId: '1:123456789:android:abc123def456ghi789',
    messagingSenderId: '123456789',
    projectId: 'resto-queue-dev',
    storageBucket: 'resto-queue-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummy_Key_For_Development_Only',
    appId: '1:123456789:ios:abc123def456ghi789',
    messagingSenderId: '123456789',
    projectId: 'resto-queue-dev',
    storageBucket: 'resto-queue-dev.appspot.com',
    iosBundleId: 'com.resto.restoQueue',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummy_Key_For_Development_Only',
    appId: '1:123456789:web:abc123def456ghi789',
    messagingSenderId: '123456789',
    projectId: 'resto-queue-dev',
    storageBucket: 'resto-queue-dev.appspot.com',
  );
}
