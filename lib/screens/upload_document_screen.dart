import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/cloud_backend_service.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _service = CloudBackendService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedSubject = 'IT402 - Phát triển Ứng dụng Di động';
  bool _isPublic = false;
  bool _isUploading = false;

  PlatformFile? _pickedFile;
  Uint8List? _pickedBytes;
  int? _pickedSize;

  final List<String> _subjects = [
    'IT402 - Phát triển Ứng dụng Di động',
    'CS205 - Cơ sở Dữ liệu Nâng cao',
    'CS301 - Kiến trúc Phần mềm',
    'CHUNG - Quy chế Học vụ',
    'Khác',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'pptx', 'ppt', 'zip', 'png', 'jpg', 'txt'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        final bytes = await file.readAsBytes();
        final size = await file.length();
        setState(() {
          _pickedFile = file;
          _pickedBytes = bytes;
          _pickedSize = size;
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn tệp: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleUpload() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề tài liệu.')),
      );
      return;
    }

    final fileName = _pickedFile?.name ?? '$title.pdf';
    final fileBytes = _pickedBytes ?? [0x25, 0x50, 0x44, 0x46]; // Default PDF bytes
    final fileSizeKb = (_pickedSize != null) ? (_pickedSize! / 1024) : 1024.0;
    final fileExt = _pickedFile?.extension ?? 'pdf';

    setState(() => _isUploading = true);

    try {
      await _service.createDocument(
        title: title,
        description: _descController.text.trim(),
        subject: _selectedSubject,
        fileName: fileName,
        fileBytes: fileBytes,
        fileSizeKb: fileSizeKb,
        fileType: fileExt,
        isPublic: _isPublic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tải lên Firebase Storage & lưu Supabase thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tải Lên Tài Liệu Mới'),
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
                    // Khối chọn File
                    const Text(
                      '1. Chọn tệp tin vật lý (Firebase Storage)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _isUploading ? null : _pickFile,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _pickedFile != null ? Colors.green : Colors.blue.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _pickedFile != null ? Colors.green.shade50 : Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _pickedFile != null ? Icons.check_circle : Icons.upload_file,
                                color: _pickedFile != null ? Colors.green : Colors.blue.shade800,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile != null
                                        ? _pickedFile!.name
                                        : 'Nhấn để chọn tệp từ thiết bị',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _pickedSize != null
                                        ? 'Dung lượng: ${(_pickedSize! / 1024).toStringAsFixed(1)} KB'
                                        : 'Hỗ trợ: PDF, DOCX, PPTX, ZIP, PNG, v.v.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F4E79),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isUploading ? null : _pickFile,
                              child: Text(_pickedFile != null ? 'Đổi tệp' : 'Chọn tệp'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Khối nhập thông tin Metadata (Supabase)
                    const Text(
                      '2. Thông tin siêu dữ liệu (Supabase Database)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề tài liệu *',
                        hintText: 'Nhập tiêu đề...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Môn học / Chuyên đề *',
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
                        hintText: 'Nhập thông tin ghi chú cho tài liệu...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cấu hình Riêng tư / Công khai
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tài liệu Công khai (Public)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        _isPublic
                            ? 'Mọi người dùng trong hệ thống đều có thể xem và tải tài liệu này.'
                            : 'Chỉ bạn (Chủ sở hữu) và những người được cấp quyền mới có thể truy cập.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _isPublic,
                      onChanged: (val) => setState(() => _isPublic = val),
                    ),
                    const SizedBox(height: 24),

                    // Nút xác nhận tải lên
                    if (_isUploading)
                      Column(
                        children: const [
                          LinearProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Đang tải file lên Firebase Storage và lưu Supabase...', style: TextStyle(fontSize: 13, color: Colors.blue)),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Tải lên & Lưu trữ Cloud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F4E79),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleUpload,
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
