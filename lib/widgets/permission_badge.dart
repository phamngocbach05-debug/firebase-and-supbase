import 'package:flutter/material.dart';

class PermissionBadge extends StatelessWidget {
  final String role; // 'owner', 'editor', 'viewer', 'viewer_public', 'none'

  const PermissionBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'owner':
        label = 'Chủ sở hữu';
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF1B5E20);
        icon = Icons.verified_user;
        break;
      case 'admin':
        label = 'Quản trị viên';
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF4A148C);
        icon = Icons.admin_panel_settings;
        break;
      case 'editor':
        label = 'Được chỉnh sửa';
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        icon = Icons.edit_note;
        break;
      case 'viewer':
        label = 'Được chia sẻ xem';
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF0D47A1);
        icon = Icons.visibility;
        break;
      case 'viewer_public':
        label = 'Tài liệu công khai';
        bgColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF37474F);
        icon = Icons.public;
        break;
      default:
        label = 'Không có quyền';
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFB71C1C);
        icon = Icons.block;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
