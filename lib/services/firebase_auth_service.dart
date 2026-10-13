import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// DỊCH VỤ XÁC THỰC FIREBASE VÀ GOOGLE SIGN-IN (CHECKLIST MỤC 01)
/// Chịu trách nhiệm:
/// 1. Tương tác với Firebase Authentication SDK
/// 2. Điều phối luồng đăng nhập Google OAuth 2.0
/// 3. Đồng bộ danh tính người dùng vào bảng `users` trên Supabase
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lấy người dùng Firebase hiện tại (nếu có)
  User? get currentFirebaseUser => _auth.currentUser;

  /// Luồng theo dõi trạng thái đăng nhập Firebase realtime
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Thực hiện đăng nhập bằng tài khoản Google qua Firebase Auth (Yêu cầu 01)
  Future<UserProfile?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Trên nền tảng Web: Sử dụng GoogleAuthProvider popup
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.addScope('email');
        authProvider.addScope('profile');

        final UserCredential userCredential = await _auth.signInWithPopup(authProvider);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          final userProfile = UserProfile(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? 'Người dùng Google',
            photoUrl: firebaseUser.photoURL ?? '',
          );

          // Đồng bộ tài khoản sang Supabase (Yêu cầu 01 kết nối Yêu cầu 03)
          await SupabaseService().syncUserProfile(userProfile);
          return userProfile;
        }
      } else {
        // Trên Android / iOS / Desktop: Sử dụng GoogleSignIn SDK
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
        final String? idToken = googleUser.authentication.idToken;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          final userProfile = UserProfile(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? googleUser.displayName ?? 'Người dùng Google',
            photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl ?? '',
          );

          // Đồng bộ tài khoản sang Supabase
          await SupabaseService().syncUserProfile(userProfile);
          return userProfile;
        }
      }
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
      rethrow;
    }
    return null;
  }

  /// Đăng xuất khỏi Firebase và Google
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        GoogleSignIn.instance.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error signing out from Firebase: $e');
    }
  }
}
