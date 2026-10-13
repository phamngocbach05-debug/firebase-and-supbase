import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/permission_model.dart';
import '../models/user_profile.dart';
import '../services/cloud_backend_service.dart';

class ShareDocumentDialog extends StatefulWidget {
  final StudyDocument document;

  const ShareDocumentDialog({super.key, required this.document});

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final _service = CloudBackendService();
  final _emailController = TextEditingController();
  PermissionRole _selectedRole = PermissionRole.editor;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleShare([String? prefilledEmail]) async {
    final email = prefilledEmail ?? _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hoặc chọn email người nhận.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.shareDocument(
        documentId: widget.document.id,
        targetUserEmail: email,
        role: _selectedRole,
      );
      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cấp quyền ${_selectedRole.name.toUpperCase()} cho $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRevoke(String permissionId, String email) async {
    setState(() => _isLoading = true);
    try {
      await _service.revokePermission(permissionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thu hồi quyền của $email'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = _service.getPermissionsForDocument(widget.document.id);
    final allUsers = _service.getAllUsers();
    final otherUsers = allUsers.where((u) => u.id != widget.document.ownerId).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.share, color: Color(0xFF1F4E79), size: 26),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Phân Quyền Chia Sẻ Tài Liệu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tài liệu: ${widget.document.title}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 24),

              // Form nhập email & vai trò
              const Text('Cấp quyền mới:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email người nhận',
                        hintText: 'ví dụ: binh.tran@edu.vn',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<PermissionRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: PermissionRole.viewer,
                          child: Text('Viewer (Xem)', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: PermissionRole.editor,
                          child: Text('Editor (Sửa)', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: PermissionRole.admin,
                          child: Text('Admin', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F4E79),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: _isLoading ? null : () => _handleShare(),
                    child: const Text('Cấp'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gợi ý chọn nhanh tài khoản kiểm thử
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: otherUsers.map((user) {
                  return ActionChip(
                    avatar: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(user.displayName.substring(0, 1), style: const TextStyle(fontSize: 10)),
                    ),
                    label: Text(
                      '${user.displayName.split(' ').first} (${user.email})',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      _emailController.text = user.email;
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Text(
                'Danh sách người dùng đã được chia sẻ:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Danh sách permissions hiện có
              Expanded(
                child: permissions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'Chưa có người dùng nào được chia sẻ riêng.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: permissions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final perm = permissions[index];
                          final targetUser = allUsers.firstWhere(
                            (u) => u.id == perm.userId,
                            orElse: () => UserProfile(id: perm.userId, email: perm.userEmail ?? perm.userId, displayName: 'User'),
                          );

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              backgroundColor: perm.roleColor.withAlpha(38),
                              child: Icon(Icons.person, color: perm.roleColor, size: 20),
                            ),
                            title: Text(
                              targetUser.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${targetUser.email} • ${perm.roleLabel}',
                              style: TextStyle(fontSize: 12, color: perm.roleColor),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.red, size: 20),
                              tooltip: 'Thu hồi quyền truy cập (Revoke)',
                              onPressed: _isLoading ? null : () => _handleRevoke(perm.id, targetUser.email),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
