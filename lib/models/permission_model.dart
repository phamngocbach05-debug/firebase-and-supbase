import 'package:flutter/material.dart';

enum PermissionRole { viewer, editor, admin }

class DocumentPermission {
  final String id;
  final String documentId;
  final String userId;
  String? userEmail;
  String? userDisplayName;
  PermissionRole role;
  final String grantedBy;
  final DateTime createdAt;

  DocumentPermission({
    required this.id,
    required this.documentId,
    required this.userId,
    this.userEmail,
    this.userDisplayName,
    required this.role,
    required this.grantedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static PermissionRole roleFromString(String str) {
    switch (str.toLowerCase()) {
      case 'editor':
        return PermissionRole.editor;
      case 'admin':
        return PermissionRole.admin;
      case 'viewer':
      default:
        return PermissionRole.viewer;
    }
  }

  static String roleToString(PermissionRole role) {
    switch (role) {
      case PermissionRole.editor:
        return 'editor';
      case PermissionRole.admin:
        return 'admin';
      case PermissionRole.viewer:
        return 'viewer';
    }
  }

  factory DocumentPermission.fromJson(Map<String, dynamic> json) {
    return DocumentPermission(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      userId: json['user_id'] as String,
      userEmail: json['user_email'] as String?,
      userDisplayName: json['user_display_name'] as String?,
      role: roleFromString(json['role'] as String? ?? 'viewer'),
      grantedBy: json['granted_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'role': roleToString(role),
      'granted_by': grantedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get roleLabel {
    switch (role) {
      case PermissionRole.viewer:
        return 'Chỉ xem (Viewer)';
      case PermissionRole.editor:
        return 'Chỉnh sửa (Editor)';
      case PermissionRole.admin:
        return 'Quản trị (Admin)';
    }
  }

  String get roleDescription {
    switch (role) {
      case PermissionRole.viewer:
        return 'Được xem và tải file, không được sửa hay xóa.';
      case PermissionRole.editor:
        return 'Được cập nhật thông tin tài liệu, không được xóa.';
      case PermissionRole.admin:
        return 'Toàn quyền chỉnh sửa, chia sẻ và xóa tài liệu.';
    }
  }

  Color get roleColor {
    switch (role) {
      case PermissionRole.viewer:
        return Colors.blue.shade700;
      case PermissionRole.editor:
        return Colors.orange.shade800;
      case PermissionRole.admin:
        return Colors.purple.shade700;
    }
  }
}
