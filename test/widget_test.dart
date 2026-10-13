import 'package:flutter_test/flutter_test.dart';
import 'package:bt6/main.dart';
import 'package:bt6/services/cloud_backend_service.dart';
import 'package:bt6/models/permission_model.dart';

void main() {
  group('BT6 - Kiểm thử Hệ thống Quản lý Tài liệu & Cloud Ecosystem', () {
    testWidgets('Ứng dụng khởi động giao diện thành công', (WidgetTester tester) async {
      await tester.pumpWidget(const CloudDocumentApp());
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề hiển thị
      expect(find.text('Quản Lý Tài Liệu (BT6)'), findsOneWidget);
    });

    test('Kiểm thử luồng phân quyền và chính sách bảo mật RLS giữa 3 tài khoản (Mục 06)', () async {
      final service = CloudBackendService();

      // 1. Kiểm tra khởi tạo 3 tài khoản kiểm thử
      final users = service.getAllUsers();
      expect(users.length, greaterThanOrEqualTo(3));

      // 2. Chuyển sang User A (Owner) và tạo tài liệu riêng tư
      await service.switchAccount(CloudBackendService.userA);
      final newDoc = await service.createDocument(
        title: 'Tài liệu UnitTest Bảo Mật',
        description: 'Kiểm tra RLS Policies tự động',
        subject: 'IT402',
        fileName: 'test.pdf',
        fileBytes: [1, 2, 3],
        fileSizeKb: 100,
        fileType: 'pdf',
        isPublic: false,
      );

      expect(newDoc.ownerId, equals(CloudBackendService.userA.id));

      // 3. User B và User C không thấy tài liệu riêng tư này (RLS SELECT)
      await service.switchAccount(CloudBackendService.userB);
      var docsB = service.getAccessibleDocuments();
      expect(docsB.any((d) => d.id == newDoc.id), isFalse);

      await service.switchAccount(CloudBackendService.userC);
      var docsC = service.getAccessibleDocuments();
      expect(docsC.any((d) => d.id == newDoc.id), isFalse);

      // 4. User A cấp quyền Editor cho User B
      await service.switchAccount(CloudBackendService.userA);
      await service.shareDocument(
        documentId: newDoc.id,
        targetUserEmail: CloudBackendService.userB.email,
        role: PermissionRole.editor,
      );

      // 5. User B bây giờ xem được và cập nhật thành công (RLS UPDATE)
      await service.switchAccount(CloudBackendService.userB);
      docsB = service.getAccessibleDocuments();
      expect(docsB.any((d) => d.id == newDoc.id), isTrue);

      await service.updateDocument(
        documentId: newDoc.id,
        title: 'Tiêu đề sau khi User B sửa',
        description: 'Sửa thành công',
        subject: 'IT402',
        isPublic: false,
      );

      // 6. User C cố gắng sửa -> RLS ném lỗi CloudSecurityException
      await service.switchAccount(CloudBackendService.userC);
      expect(
        () async => await service.updateDocument(
          documentId: newDoc.id,
          title: 'User C hack',
          description: 'Lỗi',
          subject: 'IT402',
          isPublic: false,
        ),
        throwsA(isA<CloudSecurityException>()),
      );

      // 7. User B cố gắng xóa tài liệu của User A -> RLS ném lỗi
      await service.switchAccount(CloudBackendService.userB);
      expect(
        () async => await service.deleteDocument(newDoc.id),
        throwsA(isA<CloudSecurityException>()),
      );

      // 8. User A xóa thành công tài liệu do chính mình tạo
      await service.switchAccount(CloudBackendService.userA);
      await service.deleteDocument(newDoc.id);
    });
  });
}
