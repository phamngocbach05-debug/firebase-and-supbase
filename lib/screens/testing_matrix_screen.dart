import 'package:flutter/material.dart';
import '../services/cloud_backend_service.dart';
import '../models/permission_model.dart';

class TestStepResult {
  final int step;
  final String title;
  final String description;
  final String expected;
  final String actual;
  final bool isSuccess;

  TestStepResult({
    required this.step,
    required this.title,
    required this.description,
    required this.expected,
    required this.actual,
    required this.isSuccess,
  });
}

class TestingMatrixScreen extends StatefulWidget {
  const TestingMatrixScreen({super.key});

  @override
  State<TestingMatrixScreen> createState() => _TestingMatrixScreenState();
}

class _TestingMatrixScreenState extends State<TestingMatrixScreen> {
  final _service = CloudBackendService();
  bool _isRunning = false;
  final List<TestStepResult> _results = [];

  Future<void> _runAutomatedTests() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    final initialUser = _service.currentUser;

    try {
      // -----------------------------------------------------------------------
      // Bước 1: User A tạo một tài liệu hoàn toàn riêng tư (Private)
      // -----------------------------------------------------------------------
      await _service.switchAccount(CloudBackendService.userA);
      final testDoc = await _service.createDocument(
        title: '[TEST] Tài liệu Bí Mật Đồ Án Môn Học',
        description: 'Tài liệu mật thử nghiệm chính sách bảo mật RLS đa tài khoản.',
        subject: 'IT402 - Kiểm Thử RLS',
        fileName: 'tai_lieu_bi_mat.pdf',
        fileBytes: [1, 2, 3, 4],
        fileSizeKb: 512,
        fileType: 'pdf',
        isPublic: false,
      );

      _results.add(TestStepResult(
        step: 1,
        title: 'User A tạo tài liệu Riêng tư (Private)',
        description: 'Tài liệu được tải lên Firebase Storage và lưu vào Supabase với is_public = false.',
        expected: 'Tài liệu được tạo với owner_id = uid_user_a',
        actual: 'Thành công (ID: ${testDoc.id.substring(0, 8)}...)',
        isSuccess: testDoc.ownerId == CloudBackendService.userA.id && !testDoc.isPublic,
      ));
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 300));

      // -----------------------------------------------------------------------
      // Bước 2: Kiểm tra User B và User C không thấy tài liệu này (RLS SELECT)
      // -----------------------------------------------------------------------
      await _service.switchAccount(CloudBackendService.userB);
      final docsB = _service.getAccessibleDocuments();
      final canBSee = docsB.any((d) => d.id == testDoc.id);

      await _service.switchAccount(CloudBackendService.userC);
      final docsC = _service.getAccessibleDocuments();
      final canCSee = docsC.any((d) => d.id == testDoc.id);

      final rlsSelectPass = !canBSee && !canCSee;
      _results.add(TestStepResult(
        step: 2,
        title: 'Kiểm tra RLS SELECT (Tính riêng tư)',
        description: 'Chuyển sang User B và User C để truy vấn danh sách tài liệu từ cơ sở dữ liệu.',
        expected: 'User B & C hoàn toàn không thấy tài liệu này trong kết quả truy vấn.',
        actual: rlsSelectPass ? 'Chính xác: Cả User B và User C đều không thấy.' : 'Lỗi: Bị lộ dữ liệu!',
        isSuccess: rlsSelectPass,
      ));
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 300));

      // -----------------------------------------------------------------------
      // Bước 3: User A cấp quyền 'editor' cho User B
      // -----------------------------------------------------------------------
      await _service.switchAccount(CloudBackendService.userA);
      final perm = await _service.shareDocument(
        documentId: testDoc.id,
        targetUserEmail: CloudBackendService.userB.email,
        role: PermissionRole.editor,
      );

      _results.add(TestStepResult(
        step: 3,
        title: 'User A chia sẻ tài liệu cho User B với quyền Editor',
        description: 'Ghi bản ghi vào bảng permissions trên Supabase: user_id = uid_user_b, role = editor.',
        expected: 'Cấp quyền thành công cho binh.tran@edu.vn',
        actual: 'Thành công: Vai trò ${perm.role.name.toUpperCase()}',
        isSuccess: perm.userId == CloudBackendService.userB.id,
      ));
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 300));

      // -----------------------------------------------------------------------
      // Bước 4: User B truy cập -> Xem được tài liệu và Cập nhật tiêu đề (RLS UPDATE)
      // -----------------------------------------------------------------------
      await _service.switchAccount(CloudBackendService.userB);
      bool bUpdateSuccess = false;
      try {
        await _service.updateDocument(
          documentId: testDoc.id,
          title: '[TEST ĐÃ CẬP NHẬT BỞI USER B] Tài liệu Bí Mật',
          description: 'Nội dung cập nhật thành công từ phía Editor.',
          subject: testDoc.subject,
          isPublic: testDoc.isPublic,
        );
        bUpdateSuccess = true;
      } catch (e) {
        bUpdateSuccess = false;
      }

      _results.add(TestStepResult(
        step: 4,
        title: 'User B chỉnh sửa thông tin tài liệu (RLS UPDATE)',
        description: 'User B có quyền Editor thực hiện thay đổi tiêu đề tài liệu.',
        expected: 'Chính sách documents_update_policy cho phép User B cập nhật.',
        actual: bUpdateSuccess ? 'Thành công: Tiêu đề đã được cập nhật bởi Editor.' : 'Thất bại!',
        isSuccess: bUpdateSuccess,
      ));
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 300));

      // -----------------------------------------------------------------------
      // Bước 5: User C (Không có quyền) cố gắng chỉnh sửa -> RLS Phải Chặn
      // -----------------------------------------------------------------------
      await _service.switchAccount(CloudBackendService.userC);
      bool cBlockedSuccess = false;
      String blockedMessage = '';
      try {
        await _service.updateDocument(
          documentId: testDoc.id,
          title: '[HACK] Tài liệu bị User C sửa trộm',
          description: 'Cố tình sửa mà không có quyền',
          subject: testDoc.subject,
          isPublic: testDoc.isPublic,
        );
      } catch (e) {
        cBlockedSuccess = true;
        blockedMessage = e.toString();
      }

      _results.add(TestStepResult(
        step: 5,
        title: 'Chặn User C sửa tài liệu trái phép (RLS UPDATE Block)',
        description: 'User C (người ngoài) cố gắng gửi lệnh cập nhật lên bảng documents.',
        expected: 'Bị hệ thống RLS từ chối và ném ra ngoại lệ CloudSecurityException.',
        actual: cBlockedSuccess ? 'Bảo mật an toàn: $blockedMessage' : 'Lỗ hổng: User C sửa được!',
        isSuccess: cBlockedSuccess,
      ));
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 300));

      // -----------------------------------------------------------------------
      // Bước 6: User B (Editor) cố gắng xóa tài liệu của User A -> RLS Phải Chặn
      // -----------------------------------------------------------------------
      await _service.switchAccount(CloudBackendService.userB);
      bool deleteBlockedSuccess = false;
      try {
        await _service.deleteDocument(testDoc.id);
      } catch (e) {
        deleteBlockedSuccess = true;
      }

      _results.add(TestStepResult(
        step: 6,
        title: 'Chặn Editor xóa tài liệu của Owner (RLS DELETE Block)',
        description: 'User B chỉ có quyền Editor, không được quyền xóa tài liệu của người khác.',
        expected: 'Chính sách documents_delete_policy chỉ cho phép Owner xóa.',
        actual: deleteBlockedSuccess ? 'Bảo mật an toàn: Bị chặn xóa thành công.' : 'Lỗi: Editor xóa mất file!',
        isSuccess: deleteBlockedSuccess,
      ));
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 300));

      // -----------------------------------------------------------------------
      // Bước 7: User A thu hồi quyền của User B & Xóa dọn dẹp tài liệu test
      // -----------------------------------------------------------------------
      await _service.switchAccount(CloudBackendService.userA);
      await _service.revokePermission(perm.id);
      await _service.deleteDocument(testDoc.id);

      _results.add(TestStepResult(
        step: 7,
        title: 'User A thu hồi quyền & Xóa hoàn tất (Clean Up)',
        description: 'Xóa quyền trong bảng permissions và dọn dẹp tệp tin trên Firebase Storage.',
        expected: 'Thu hồi quyền và xóa tài liệu hoàn tất không để lại rác.',
        actual: 'Thành công: Dữ liệu kiểm thử đã được dọn dẹp sạch sẽ.',
        isSuccess: true,
      ));
      setState(() {});
    } catch (e) {
      _results.add(TestStepResult(
        step: 99,
        title: 'Lỗi kiểm thử bất thường',
        description: '$e',
        expected: 'Không có lỗi',
        actual: 'Gặp lỗi: $e',
        isSuccess: false,
      ));
    } finally {
      // Khôi phục lại tài khoản ban đầu
      if (initialUser != null) {
        await _service.switchAccount(initialUser);
      }
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passedCount = _results.where((r) => r.isSuccess).length;
    final totalCount = _results.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm Thử Phân Quyền (3 Tài Khoản)'),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ tóm tắt mục 06
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.rule, color: Color(0xFF1F4E79), size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Checklist Mục 06: Kiểm thử luồng phân quyền 3 tài khoản',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Xác minh tự động toàn vẹn dữ liệu và các chính sách bảo mật Row Level Security (RLS) của Supabase thông qua kịch bản tương tác thực tế giữa 3 người dùng: Giảng viên A (Owner), Sinh viên B (Editor) và Khách C (Viewer/Stranger).',
                          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton.icon(
                          icon: _isRunning
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.play_circle_fill),
                          label: Text(
                            _isRunning ? 'Đang chạy kiểm thử 7 bước...' : 'Chạy Kịch Bản Kiểm Thử Tự Động (Run Tests)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F4E79),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isRunning ? null : _runAutomatedTests,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Kết quả kiểm thử
                if (_results.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KẾT QUẢ KIỂM THỬ: $passedCount / $totalCount BƯỚC ĐẠT (PASS)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: passedCount == totalCount ? Colors.green.shade800 : Colors.red,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: passedCount == totalCount ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: passedCount == totalCount ? Colors.green : Colors.red),
                        ),
                        child: Text(
                          passedCount == totalCount ? '100% TUYỆT ĐỐI' : 'CHƯA ĐẠT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: passedCount == totalCount ? Colors.green.shade900 : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final r = _results[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: r.isSuccess ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: r.isSuccess ? Colors.green : Colors.red,
                                    child: Icon(r.isSuccess ? Icons.check : Icons.close, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Bước ${r.step}: ${r.title}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: r.isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      r.isSuccess ? 'PASS' : 'FAIL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: r.isSuccess ? Colors.green.shade800 : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(r.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kỳ vọng: ${r.expected}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Thực tế: ${r.actual}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: r.isSuccess ? Colors.green.shade800 : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
