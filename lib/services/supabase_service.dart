import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/document_model.dart';
import '../models/permission_model.dart';

/// DỊCH VỤ CƠ SỞ DỮ LIỆU QUAN HỆ SUPABASE (CHECKLIST MỤC 03)
/// Chịu trách nhiệm:
/// 1. Kết nối và thực thi các thao tác trên 3 bảng: users, documents, permissions
/// 2. Lưu trữ siêu dữ liệu tài liệu kết nối với Firebase Storage (Yêu cầu 02)
/// 3. Quản lý danh tính người dùng đồng bộ từ Firebase Auth (Yêu cầu 01)
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 1. THAO TÁC TRÊN BẢNG users (NGƯỜI DÙNG)
  // ---------------------------------------------------------------------------

  /// Đồng bộ hồ sơ người dùng từ Firebase Authentication sang bảng users
  Future<void> syncUserProfile(UserProfile user) async {
    try {
      final client = _client;
      if (client != null) {
        await client.from('users').upsert({
          'id': user.id, // Firebase UID
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoUrl,
          'last_sign_in_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Supabase: Đã đồng bộ hồ sơ user ${user.email}');
      }
    } catch (e) {
      debugPrint('Supabase syncUserProfile warning: $e');
    }
  }

  /// Lấy danh sách tất cả người dùng từ bảng users để chọn chia sẻ
  Future<List<UserProfile>> fetchAllUsers() async {
    try {
      final client = _client;
      if (client != null) {
        final List<dynamic> response = await client.from('users').select();
        return response.map((data) => UserProfile.fromJson(data as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Supabase fetchAllUsers warning: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // 2. THAO TÁC TRÊN BẢNG documents (TÀI LIỆU) - KẾT NỐI FIREBASE STORAGE
  // ---------------------------------------------------------------------------

  /// Lưu thông tin siêu dữ liệu tài liệu kèm file_url từ Firebase Storage
  Future<void> insertDocument(StudyDocument document) async {
    try {
      final client = _client;
      if (client != null) {
        await client.from('documents').insert(document.toJson());
        debugPrint('Supabase: Đã lưu siêu dữ liệu tài liệu ${document.id}');
      }
    } catch (e) {
      debugPrint('Supabase insertDocument warning: $e');
    }
  }

  /// Cập nhật thông tin tài liệu
  Future<void> updateDocument(String documentId, Map<String, dynamic> updates) async {
    try {
      final client = _client;
      if (client != null) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        await client.from('documents').update(updates).eq('id', documentId);
        debugPrint('Supabase: Đã cập nhật tài liệu $documentId');
      }
    } catch (e) {
      debugPrint('Supabase updateDocument warning: $e');
    }
  }

  /// Xóa tài liệu khỏi bảng documents (Kích hoạt CASCADE xóa quyền)
  Future<void> deleteDocument(String documentId) async {
    try {
      final client = _client;
      if (client != null) {
        await client.from('documents').delete().eq('id', documentId);
        debugPrint('Supabase: Đã xóa tài liệu $documentId');
      }
    } catch (e) {
      debugPrint('Supabase deleteDocument warning: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 3. THAO TÁC TRÊN BẢNG permissions (QUYỀN CHIA SẺ)
  // ---------------------------------------------------------------------------

  /// Cấp quyền chia sẻ tài liệu cho người dùng
  Future<void> insertOrUpdatePermission(DocumentPermission permission) async {
    try {
      final client = _client;
      if (client != null) {
        await client.from('permissions').upsert(permission.toJson());
        debugPrint('Supabase: Đã cấp quyền ${permission.role} cho user ${permission.userId}');
      }
    } catch (e) {
      debugPrint('Supabase insertOrUpdatePermission warning: $e');
    }
  }

  /// Thu hồi quyền chia sẻ
  Future<void> deletePermission(String permissionId) async {
    try {
      final client = _client;
      if (client != null) {
        await client.from('permissions').delete().eq('id', permissionId);
        debugPrint('Supabase: Đã thu hồi quyền $permissionId');
      }
    } catch (e) {
      debugPrint('Supabase deletePermission warning: $e');
    }
  }
}
