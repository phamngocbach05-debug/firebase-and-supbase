// File cấu hình Firebase chính xác từ dự án Firebase Console của bạn
// Project: bth6-1a78a
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// [DefaultFirebaseOptions] cung cấp cấu hình Firebase kết nối với dự án bth6-1a78a
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

  // Cấu hình Firebase Web (Trực tiếp từ Firebase Console của bạn)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCMT32sfgvW1ZEt5TbhDTttJOv-j_zhROk',
    appId: '1:738756354127:web:39642428dce6f1093a0a3a',
    messagingSenderId: '738756354127',
    projectId: 'bth6-1a78a',
    authDomain: 'bth6-1a78a.firebaseapp.com',
    storageBucket: 'bth6-1a78a.firebasestorage.app',
    measurementId: 'G-LFRPMB7X6Q',
  );

  // Cấu hình Firebase Android kết nối cùng dự án bth6-1a78a
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMT32sfgvW1ZEt5TbhDTttJOv-j_zhROk',
    appId: '1:738756354127:android:39642428dce6f1093a0a3a',
    messagingSenderId: '738756354127',
    projectId: 'bth6-1a78a',
    storageBucket: 'bth6-1a78a.firebasestorage.app',
  );

  // Cấu hình Firebase Windows Desktop
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCMT32sfgvW1ZEt5TbhDTttJOv-j_zhROk',
    appId: '1:738756354127:web:39642428dce6f1093a0a3a',
    messagingSenderId: '738756354127',
    projectId: 'bth6-1a78a',
    authDomain: 'bth6-1a78a.firebaseapp.com',
    storageBucket: 'bth6-1a78a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMT32sfgvW1ZEt5TbhDTttJOv-j_zhROk',
    appId: '1:738756354127:ios:39642428dce6f1093a0a3a',
    messagingSenderId: '738756354127',
    projectId: 'bth6-1a78a',
    storageBucket: 'bth6-1a78a.firebasestorage.app',
    iosBundleId: 'com.quanlytailieu.bt6',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCMT32sfgvW1ZEt5TbhDTttJOv-j_zhROk',
    appId: '1:738756354127:ios:39642428dce6f1093a0a3a',
    messagingSenderId: '738756354127',
    projectId: 'bth6-1a78a',
    storageBucket: 'bth6-1a78a.firebasestorage.app',
    iosBundleId: 'com.quanlytailieu.bt6',
  );
}
