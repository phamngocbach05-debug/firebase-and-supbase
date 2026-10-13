import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/cloud_backend_service.dart';

class AccountSwitcherSheet extends StatelessWidget {
  const AccountSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CloudBackendService();
    final currentUser = service.currentUser;

    final accounts = [
      {
        'user': CloudBackendService.userA,
        'roleDesc': 'Chủ sở hữu gốc (Owner của Bài giảng, Đề thi)',
        'color': Colors.blue.shade800,
        'badge': 'Tài khoản A (Owner)',
      },
      {
        'user': CloudBackendService.userB,
        'roleDesc': 'Được cấp quyền Editor (Bài giảng) & Viewer (Đề thi)',
        'color': Colors.orange.shade800,
        'badge': 'Tài khoản B (Editor)',
      },
      {
        'user': CloudBackendService.userC,
        'roleDesc': 'Không được cấp quyền riêng tư, chỉ xem tài liệu Public',
        'color': Colors.teal.shade800,
        'badge': 'Tài khoản C (Viewer/Khách)',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.switch_account, color: Color(0xFF1F4E79), size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Kiểm thử Phân quyền (3 Tài khoản)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F4E79),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Chuyển đổi tức thì giữa 3 tài khoản để kiểm tra ma trận phân quyền và chính sách bảo mật Row Level Security (RLS):',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ...accounts.map((item) {
              final user = item['user'] as UserProfile;
              final isCurrent = currentUser?.id == user.id;
              final color = item['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCurrent ? color.withAlpha(20) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent ? color : Colors.grey.shade300,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(50),
                    radius: 24,
                    child: Text(
                      user.displayName.substring(0, 1),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ĐANG ĐĂNG NHẬP',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['roleDesc'] as String,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  trailing: isCurrent
                      ? Icon(Icons.check_circle, color: color)
                      : OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: () {
                            service.switchAccount(user);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã chuyển sang tài khoản: ${user.displayName}'),
                                backgroundColor: color,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Chọn', style: TextStyle(fontSize: 12)),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
