import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/cloud_backend_service.dart';

class EditDocumentScreen extends StatefulWidget {
  final StudyDocument document;

  const EditDocumentScreen({super.key, required this.document});

  @override
  State<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  final _service = CloudBackendService();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _selectedSubject;
  late bool _isPublic;
  bool _isLoading = false;

  final List<String> _subjects = [
    'IT402 - Phát triển Ứng dụng Di động',
    'CS205 - Cơ sở Dữ liệu Nâng cao',
    'CS301 - Kiến trúc Phần mềm',
    'CHUNG - Quy chế Học vụ',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _descController = TextEditingController(text: widget.document.description);
    _selectedSubject = _subjects.contains(widget.document.subject)
        ? widget.document.subject
        : _subjects.first;
    _isPublic = widget.document.isPublic;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiêu đề không được để trống.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.updateDocument(
        documentId: widget.document.id,
        title: title,
        description: _descController.text.trim(),
        subject: _selectedSubject,
        isPublic: _isPublic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin tài liệu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _service.getUserRoleOnDocument(widget.document);
    final isOwner = role == 'owner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập Nhật Tài Liệu'),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit, color: Color(0xFF1F4E79)),
                        const SizedBox(width: 8),
                        Text(
                          'Vai trò của bạn: ${role.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isOwner ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề tài liệu *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Môn học *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      items: _subjects
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSubject = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả tóm tắt nội dung',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isOwner)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tài liệu Công khai (Public)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Chỉ Chủ sở hữu mới được thay đổi tính công khai của tài liệu.'),
                        value: _isPublic,
                        onChanged: (val) => setState(() => _isPublic = val),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bạn là Editor: được sửa tiêu đề & mô tả, nhưng không thể đổi chế độ Công khai / Riêng tư.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu Thay Đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F4E79),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleUpdate,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
