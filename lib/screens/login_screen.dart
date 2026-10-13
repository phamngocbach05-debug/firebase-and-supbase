import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/cloud_backend_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin(UserProfile user) async {
    setState(() => _isLoading = true);
    try {
      final service = CloudBackendService();
      await service.switchAccount(user);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng nhập: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Biểu tượng ứng dụng & Hệ sinh thái Cloud
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F4E79).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_sync,
                        size: 56,
                        color: Color(0xFF1F4E79),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Hệ Thống Quản Lý Tài Liệu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F4E79),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tích hợp Firebase Auth, Storage & Supabase RLS (BT6)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // Badges thông tin công nghệ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTechBadge('Firebase Auth', Colors.amber.shade800, Icons.verified_user),
                        const SizedBox(width: 8),
                        _buildTechBadge('Storage', Colors.orange.shade800, Icons.cloud_upload),
                        const SizedBox(width: 8),
                        _buildTechBadge('Supabase RLS', Colors.teal.shade800, Icons.security),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      // Nút Đăng nhập Google tiêu chuẩn
                      ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        label: const Text(
                          'Đăng nhập với Google',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _handleLogin(CloudBackendService.userA),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'HOẶC CHỌN TÀI KHOẢN KIỂM THỬ (MỤC 06)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Danh sách 3 tài khoản kiểm thử theo đề bài
                      _buildQuickLoginTile(
                        user: CloudBackendService.userA,
                        title: 'Tài khoản A (Owner)',
                        sub: 'an.nguyen@edu.vn • Có sẵn tài liệu riêng tư & cấp quyền',
                        color: Colors.blue.shade800,
                      ),
                      const SizedBox(height: 10),
                      _buildQuickLoginTile(
                        user: CloudBackendService.userB,
                        title: 'Tài khoản B (Editor)',
                        sub: 'binh.tran@edu.vn • Được cấp quyền sửa Bài giảng',
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(height: 10),
                      _buildQuickLoginTile(
                        user: CloudBackendService.userC,
                        title: 'Tài khoản C (Viewer/Khách)',
                        sub: 'cuong.le@edu.vn • Không có quyền xem tài liệu riêng tư',
                        color: Colors.teal.shade800,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickLoginTile({
    required UserProfile user,
    required String title,
    required String sub,
    required Color color,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () => _handleLogin(user),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(38),
            radius: 18,
            child: Text(
              user.displayName.substring(0, 1),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withAlpha(38),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.email.split('@').first,
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
