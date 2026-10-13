import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/cloud_backend_service.dart';
import '../widgets/permission_badge.dart';
import 'edit_document_screen.dart';
import 'share_document_dialog.dart';

class DocumentDetailScreen extends StatelessWidget {
  final StudyDocument document;

  const DocumentDetailScreen({super.key, required this.document});

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text('Bạn có chắc chắn muốn xóa "${document.title}" khỏi hệ thống? File trên Firebase Storage cũng sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = CloudBackendService();
        await service.deleteDocument(document.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài liệu thành công.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = CloudBackendService();
    final role = service.getUserRoleOnDocument(document);
    final canEdit = role == 'owner' || role == 'editor' || role == 'admin';
    final canShare = role == 'owner' || role == 'admin';
    final canDelete = role == 'owner' || role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Tài Liệu'),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        actions: [
          if (canShare)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Phân quyền chia sẻ',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ShareDocumentDialog(document: document),
                );
              },
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa tài liệu',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditDocumentScreen(document: document)),
                );
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa tài liệu',
              onPressed: () => _handleDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: document.typeColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(document.typeIcon, color: document.typeColor, size: 36),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      PermissionBadge(role: role),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Định dạng: ${document.fileType.toUpperCase()}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        _buildInfoRow('Môn học:', document.subject, Icons.school),
                        const SizedBox(height: 12),
                        _buildInfoRow('Người sở hữu:', '${document.ownerName ?? "N/A"} (${document.ownerEmail ?? document.ownerId})', Icons.person),
                        const SizedBox(height: 12),
                        _buildInfoRow('Dung lượng tệp:', document.formattedFileSize, Icons.storage),
                        const SizedBox(height: 12),
                        _buildInfoRow('Cập nhật lần cuối:', document.formattedDate, Icons.schedule),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Trạng thái bảo mật:',
                          document.isPublic ? 'Công khai (Mọi người có thể xem)' : 'Riêng tư (Chỉ chủ sở hữu & người được chia sẻ)',
                          document.isPublic ? Icons.public : Icons.lock,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mô tả nội dung
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mô Tả Nội Dung',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          document.description.isNotEmpty
                              ? document.description
                              : 'Chưa có mô tả chi tiết cho tài liệu này.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Chi tiết vị trí lưu trữ Cloud
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_done, color: Colors.teal, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Đường Dẫn Lưu Trữ Firebase Storage (Mục 02)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SelectableText(
                            document.storagePath,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Cấu trúc: documents/{userId}/{documentId}/{fileName}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Mở / Tải Về Tệp Tin Vật Lý', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F4E79),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đang tải file từ: ${document.fileUrl}'),
                                backgroundColor: Colors.blue.shade800,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1F4E79)),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }
}
