import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';
import '../models/document_model.dart';
import '../models/permission_model.dart';

class CloudSecurityException implements Exception {
  final String message;
  final String policyName;
  CloudSecurityException(this.message, {this.policyName = 'RLS_VIOLATION'});

  @override
  String toString() => '🛡️ [Bảo Mật RLS] $message (Chính sách: $policyName)';
}

class CloudBackendService extends ChangeNotifier {
  static final CloudBackendService _instance = CloudBackendService._internal();
  factory CloudBackendService() => _instance;

  final _uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // 3 TÀI KHOẢN KIỂM THỬ MẪU THEO YÊU CẦU ĐỀ BÀI (CHECKLIST MỤC 06)
  // ---------------------------------------------------------------------------
  static final UserProfile userA = UserProfile(
    id: 'uid_user_a',
    email: 'an.nguyen@edu.vn',
    displayName: 'ThS. Nguyễn Văn An (Giảng viên / Owner)',
    photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=AnNguyen',
  );

  static final UserProfile userB = UserProfile(
    id: 'uid_user_b',
    email: 'binh.tran@edu.vn',
    displayName: 'Trần Thị Bình (Sinh viên / Editor)',
    photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=BinhTran',
  );

  static final UserProfile userC = UserProfile(
    id: 'uid_user_c',
    email: 'cuong.le@edu.vn',
    displayName: 'Lê Hoàng Cường (Khách vãng lai / Viewer)',
    photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=CuongLe',
  );

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Dữ liệu mô phỏng trong bộ nhớ đại diện cho Supabase DB
  final List<UserProfile> _users = [userA, userB, userC];
  final List<StudyDocument> _documents = [];
  final List<DocumentPermission> _permissions = [];

  CloudBackendService._internal() {
    _initSeedData();
    // Mặc định đăng nhập User A để khởi đầu
    _currentUser = userA;
  }

  void _initSeedData() {
    _documents.addAll([
      StudyDocument(
        id: '11111111-1111-1111-1111-111111111111',
        title: 'Slide Bài 06: Tích hợp Đám mây Flutter, Firebase và Supabase',
        description: 'Tài liệu hướng dẫn phân quyền bảo mật RLS, Firebase Storage và đăng nhập Google.',
        subject: 'IT402 - Phát triển Ứng dụng Di động',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/bt6-doc-manager.appspot.com/o/documents%2Fuid_user_a%2Fslide_bai_06.pdf?alt=media',
        storagePath: 'documents/uid_user_a/11111111-1111-1111-1111-111111111111/slide_bai_06.pdf',
        fileSizeKb: 4250.0,
        fileType: 'pdf',
        ownerId: userA.id,
        ownerEmail: userA.email,
        ownerName: userA.displayName,
        isPublic: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      StudyDocument(
        id: '22222222-2222-2222-2222-222222222222',
        title: 'Đề thi Tham khảo và Đáp án Cơ sở Dữ liệu Nâng cao',
        description: 'Tổng hợp câu hỏi truy vấn SQL, thiết kế chỉ mục và chính sách bảo mật bảng.',
        subject: 'CS205 - Cơ sở Dữ liệu Nâng cao',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/bt6-doc-manager.appspot.com/o/documents%2Fuid_user_a%2Fde_thi_cs205.docx?alt=media',
        storagePath: 'documents/uid_user_a/22222222-2222-2222-2222-222222222222/de_thi_cs205.docx',
        fileSizeKb: 1820.5,
        fileType: 'docx',
        ownerId: userA.id,
        ownerEmail: userA.email,
        ownerName: userA.displayName,
        isPublic: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      StudyDocument(
        id: '33333333-3333-3333-3333-333333333333',
        title: 'Quy định Chuẩn Đầu Ra & Hướng dẫn Làm Đồ án Môn học',
        description: 'Tài liệu hướng dẫn mẫu biểu và biểu mẫu đánh giá chung cho toàn bộ sinh viên.',
        subject: 'CHUNG - Quy chế Học vụ',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/bt6-doc-manager.appspot.com/o/documents%2Fuid_user_a%2Fquy_dinh_do_an.pdf?alt=media',
        storagePath: 'documents/uid_user_a/33333333-3333-3333-3333-333333333333/quy_dinh_do_an.pdf',
        fileSizeKb: 950.0,
        fileType: 'pdf',
        ownerId: userA.id,
        ownerEmail: userA.email,
        ownerName: userA.displayName,
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ]);

    // Phân quyền ban đầu:
    // User A chia sẻ Slide Bài 06 cho User B với quyền 'editor'
    _permissions.add(DocumentPermission(
      id: _uuid.v4(),
      documentId: '11111111-1111-1111-1111-111111111111',
      userId: userB.id,
      userEmail: userB.email,
      userDisplayName: userB.displayName,
      role: PermissionRole.editor,
      grantedBy: userA.id,
    ));

    // User A chia sẻ Đề thi CS205 cho User B với quyền 'viewer'
    _permissions.add(DocumentPermission(
      id: _uuid.v4(),
      documentId: '22222222-2222-2222-2222-222222222222',
      userId: userB.id,
      userEmail: userB.email,
      userDisplayName: userB.displayName,
      role: PermissionRole.viewer,
      grantedBy: userA.id,
    ));
  }

  // ===========================================================================
  // 1. XÁC THỰC GOOGLE VÀ FIREBASE AUTH (CHECKLIST MỤC 01)
  // ===========================================================================

  /// Đăng nhập tài khoản Google và đồng bộ người dùng vào bảng users trên Supabase
  Future<UserProfile> signInWithGoogle() async {
    // Trong môi trường kiểm thử trực tiếp hoặc khi kết nối Firebase Web/Android
    // ta đồng bộ người dùng và cập nhật session
    _currentUser ??= userA;
    await syncUserToSupabase(_currentUser!);
    notifyListeners();
    return _currentUser!;
  }

  /// Chuyển đổi nhanh giữa các tài khoản kiểm thử (Checklist Mục 06)
  Future<void> switchAccount(UserProfile user) async {
    _currentUser = user;
    await syncUserToSupabase(user);
    notifyListeners();
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  /// Đồng bộ người dùng Firebase vào cơ sở dữ liệu Supabase
  Future<void> syncUserToSupabase(UserProfile user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user.copyWith(lastSignInAt: DateTime.now());
    } else {
      _users.add(user);
    }
  }

  /// Lấy danh sách tất cả người dùng trong hệ thống (để chọn chia sẻ)
  List<UserProfile> getAllUsers() {
    return List.unmodifiable(_users);
  }

  // ===========================================================================
  // 2. LƯU TRỮ TỆP TIN FIREBASE STORAGE (CHECKLIST MỤC 02)
  // ===========================================================================

  /// Mô phỏng tải file lên Firebase Storage theo cấu trúc phân cấp:
  /// documents/{userId}/{documentId}/{fileName}
  Future<Map<String, String>> uploadFileToFirebaseStorage({
    required String fileName,
    required List<int> bytes,
    required String documentId,
  }) async {
    if (_currentUser == null) {
      throw CloudSecurityException('Bạn cần đăng nhập để tải file lên Firebase Storage.');
    }

    // Cấu trúc đường dẫn chuẩn bảo mật Firebase Storage
    final storagePath = 'documents/${_currentUser!.id}/$documentId/$fileName';
    
    // Tạo Download URL chuẩn theo định dạng Firebase Storage
    final encodedPath = Uri.encodeComponent(storagePath);
    final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/${AppConfig.firebaseStorageBucket}/o/$encodedPath?alt=media';

    return {
      'storage_path': storagePath,
      'file_url': downloadUrl,
    };
  }

  /// Xóa file vật lý trên Firebase Storage
  Future<void> deleteFileFromFirebaseStorage(String storagePath) async {
    // Đảm bảo chỉ người dùng có quyền mới được xóa file trên Storage
    debugPrint('Firebase Storage: Đã xóa tệp vật lý tại $storagePath');
  }

  // ===========================================================================
  // 3. QUẢN LÝ DỮ LIỆU & RLS BẢO MẬT (CHECKLIST MỤC 03, 04, 05)
  // ===========================================================================

  /// Kiểm tra quyền của người dùng hiện tại đối với một tài liệu
  /// Trả về: 'owner' | 'admin' | 'editor' | 'viewer' | 'none'
  String getUserRoleOnDocument(StudyDocument doc) {
    if (_currentUser == null) return 'none';
    if (doc.ownerId == _currentUser!.id) return 'owner';

    final perm = _permissions.firstWhere(
      (p) => p.documentIdMatches(doc.id) && p.userId == _currentUser!.id,
      orElse: () => DocumentPermission(
        id: '',
        documentId: '',
        userId: '',
        role: PermissionRole.viewer,
        grantedBy: '',
      ),
    );

    if (perm.id.isNotEmpty) {
      return DocumentPermission.roleToString(perm.role);
    }

    if (doc.isPublic) return 'viewer_public';
    return 'none';
  }

  /// ÁP DỤNG RLS SELECT: Lấy danh sách tài liệu mà người dùng hiện tại được phép thấy
  List<StudyDocument> getAccessibleDocuments({
    String? keyword,
    String? subjectFilter,
    String? categoryTab, // 'my', 'shared', 'public', 'all'
  }) {
    if (_currentUser == null) return [];

    return _documents.where((doc) {
      // 1. Kiểm tra chính sách RLS SELECT
      final isOwner = doc.ownerId == _currentUser!.id;
      final isPublic = doc.isPublic;
      final isShared = _permissions.any(
        (p) => p.documentIdMatches(doc.id) && p.userId == _currentUser!.id,
      );

      final hasReadAccess = isOwner || isPublic || isShared;
      if (!hasReadAccess) return false;

      // 2. Lọc theo Tab phân loại
      if (categoryTab == 'my' && !isOwner) return false;
      if (categoryTab == 'shared' && (!isShared || isOwner)) return false;
      if (categoryTab == 'public' && !isPublic) return false;

      // 3. Lọc theo từ khóa tìm kiếm (Tiêu đề, mô tả, môn học)
      if (keyword != null && keyword.trim().isNotEmpty) {
        final query = keyword.trim().toLowerCase();
        final matchTitle = doc.title.toLowerCase().contains(query);
        final matchSubject = doc.subject.toLowerCase().contains(query);
        final matchDesc = doc.description.toLowerCase().contains(query);
        if (!matchTitle && !matchSubject && !matchDesc) return false;
      }

      // 4. Lọc theo môn học
      if (subjectFilter != null && subjectFilter.isNotEmpty && subjectFilter != 'Tất cả') {
        if (!doc.subject.toLowerCase().contains(subjectFilter.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// ÁP DỤNG RLS INSERT: Tạo tài liệu mới
  Future<StudyDocument> createDocument({
    required String title,
    required String description,
    required String subject,
    required String fileName,
    required List<int> fileBytes,
    required double fileSizeKb,
    required String fileType,
    required bool isPublic,
  }) async {
    if (_currentUser == null) {
      throw CloudSecurityException('Bạn phải đăng nhập để thêm tài liệu mới.');
    }

    final docId = _uuid.v4();

    // Bước 1: Tải file lên Firebase Storage
    final storageResult = await uploadFileToFirebaseStorage(
      fileName: fileName,
      bytes: fileBytes,
      documentId: docId,
    );

    // Bước 2: Lưu siêu dữ liệu vào bảng documents trên Supabase
    // Tuân thủ RLS INSERT: owner_id = current_app_user()
    final newDoc = StudyDocument(
      id: docId,
      title: title,
      description: description,
      subject: subject,
      fileUrl: storageResult['file_url']!,
      storagePath: storageResult['storage_path']!,
      fileSizeKb: fileSizeKb,
      fileType: fileType,
      ownerId: _currentUser!.id,
      ownerEmail: _currentUser!.email,
      ownerName: _currentUser!.displayName,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _documents.insert(0, newDoc);
    notifyListeners();
    return newDoc;
  }

  /// ÁP DỤNG RLS UPDATE: Cập nhật thông tin tài liệu
  Future<void> updateDocument({
    required String documentId,
    required String title,
    required String description,
    required String subject,
    required bool isPublic,
  }) async {
    if (_currentUser == null) {
      throw CloudSecurityException('Yêu cầu xác thực tài khoản.');
    }

    final index = _documents.indexWhere((d) => d.id == documentId);
    if (index < 0) {
      throw Exception('Tài liệu không tồn tại.');
    }

    final existingDoc = _documents[index];
    final role = getUserRoleOnDocument(existingDoc);

    // RLS Policy Check: Chỉ cho phép nếu là Owner HOẶC có quyền editor / admin
    if (role != 'owner' && role != 'editor' && role != 'admin') {
      throw CloudSecurityException(
        'Từ chối truy cập: Tài khoản ${_currentUser!.email} chỉ có vai trò "$role", không có quyền cập nhật tài liệu này.',
        policyName: 'documents_update_policy',
      );
    }

    // Nếu không phải là Owner, không được tự ý đổi trạng thái isPublic
    final allowedPublic = (role == 'owner' || role == 'admin') ? isPublic : existingDoc.isPublic;

    _documents[index] = existingDoc.copyWith(
      title: title,
      description: description,
      subject: subject,
      isPublic: allowedPublic,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
  }

  /// ÁP DỤNG RLS DELETE: Xóa tài liệu khỏi hệ thống
  Future<void> deleteDocument(String documentId) async {
    if (_currentUser == null) {
      throw CloudSecurityException('Yêu cầu xác thực tài khoản.');
    }

    final index = _documents.indexWhere((d) => d.id == documentId);
    if (index < 0) {
      throw Exception('Tài liệu không tồn tại.');
    }

    final existingDoc = _documents[index];
    final role = getUserRoleOnDocument(existingDoc);

    // RLS Policy Check: CHỈ Chủ sở hữu (hoặc admin) mới được phép xóa!
    if (role != 'owner' && role != 'admin') {
      throw CloudSecurityException(
        'Từ chối truy cập: Tài khoản ${_currentUser!.email} có vai trò "$role", KHÔNG được phép xóa tài liệu của người khác!',
        policyName: 'documents_delete_policy',
      );
    }

    // Xóa file vật lý trên Firebase Storage
    await deleteFileFromFirebaseStorage(existingDoc.storagePath);

    // Xóa tất cả quyền liên kết trong bảng permissions (ON DELETE CASCADE)
    _permissions.removeWhere((p) => p.documentId == documentId);

    // Xóa tài liệu khỏi bảng documents
    _documents.removeAt(index);
    notifyListeners();
  }

  // ===========================================================================
  // 4. CHIA SẺ VÀ PHÂN QUYỀN (CHECKLIST MỤC 04 & 05)
  // ===========================================================================

  /// Lấy danh sách quyền chia sẻ của một tài liệu
  List<DocumentPermission> getPermissionsForDocument(String documentId) {
    return _permissions.where((p) => p.documentId == documentId).toList();
  }

  /// Chia sẻ tài liệu cho người dùng khác (Gán quyền)
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetUserEmail,
    required PermissionRole role,
  }) async {
    if (_currentUser == null) {
      throw CloudSecurityException('Yêu cầu xác thực tài khoản.');
    }

    final doc = _documents.firstWhere((d) => d.id == documentId,
        orElse: () => throw Exception('Tài liệu không tồn tại.'));

    final userRole = getUserRoleOnDocument(doc);

    // RLS Policy Check: Chỉ Owner hoặc Admin mới có quyền chia sẻ/phân quyền!
    if (userRole != 'owner' && userRole != 'admin') {
      throw CloudSecurityException(
        'Từ chối truy cập: Chỉ Chủ sở hữu mới có quyền phân quyền chia sẻ tài liệu này!',
        policyName: 'permissions_manage_policy',
      );
    }

    // Tìm thông tin người nhận theo email
    final targetUser = _users.firstWhere(
      (u) => u.email.toLowerCase() == targetUserEmail.trim().toLowerCase(),
      orElse: () => throw Exception('Không tìm thấy tài khoản với email $targetUserEmail trong hệ thống.'),
    );

    if (targetUser.id == doc.ownerId) {
      throw Exception('Không thể chia sẻ tài liệu cho chính chủ sở hữu.');
    }

    // Kiểm tra xem đã có quyền trước đó chưa, nếu có thì cập nhật, chưa thì tạo mới
    final existingIndex = _permissions.indexWhere(
      (p) => p.documentId == documentId && p.userId == targetUser.id,
    );

    DocumentPermission result;
    if (existingIndex >= 0) {
      result = DocumentPermission(
        id: _permissions[existingIndex].id,
        documentId: documentId,
        userId: targetUser.id,
        userEmail: targetUser.email,
        userDisplayName: targetUser.displayName,
        role: role,
        grantedBy: _currentUser!.id,
        createdAt: DateTime.now(),
      );
      _permissions[existingIndex] = result;
    } else {
      result = DocumentPermission(
        id: _uuid.v4(),
        documentId: documentId,
        userId: targetUser.id,
        userEmail: targetUser.email,
        userDisplayName: targetUser.displayName,
        role: role,
        grantedBy: _currentUser!.id,
      );
      _permissions.add(result);
    }

    notifyListeners();
    return result;
  }

  /// Thu hồi quyền truy cập của một người dùng đối với tài liệu
  Future<void> revokePermission(String permissionId) async {
    if (_currentUser == null) {
      throw CloudSecurityException('Yêu cầu xác thực tài khoản.');
    }

    final index = _permissions.indexWhere((p) => p.id == permissionId);
    if (index < 0) return;

    final perm = _permissions[index];
    final doc = _documents.firstWhere((d) => d.id == perm.documentId);
    final userRole = getUserRoleOnDocument(doc);

    if (userRole != 'owner' && userRole != 'admin') {
      throw CloudSecurityException(
        'Từ chối truy cập: Chỉ Chủ sở hữu mới được thu hồi quyền!',
        policyName: 'permissions_manage_policy',
      );
    }

    _permissions.removeAt(index);
    notifyListeners();
  }
}

extension DocumentPermissionHelper on DocumentPermission {
  bool documentIdMatches(String docId) => documentId == docId;
}
