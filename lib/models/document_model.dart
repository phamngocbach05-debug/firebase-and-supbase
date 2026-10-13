import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudyDocument {
  final String id;
  String title;
  String description;
  String subject;
  String fileUrl;
  String storagePath;
  double fileSizeKb;
  String fileType;
  final String ownerId;
  String? ownerEmail;
  String? ownerName;
  bool isPublic;
  final DateTime createdAt;
  DateTime updatedAt;

  StudyDocument({
    required this.id,
    required this.title,
    this.description = '',
    required this.subject,
    required this.fileUrl,
    required this.storagePath,
    this.fileSizeKb = 0,
    required this.fileType,
    required this.ownerId,
    this.ownerEmail,
    this.ownerName,
    this.isPublic = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory StudyDocument.fromJson(Map<String, dynamic> json) {
    return StudyDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      subject: json['subject'] as String? ?? 'Chung',
      fileUrl: json['file_url'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      fileSizeKb: (json['file_size_kb'] is num)
          ? (json['file_size_kb'] as num).toDouble()
          : 0.0,
      fileType: json['file_type'] as String? ?? 'pdf',
      ownerId: json['owner_id'] as String,
      ownerEmail: json['owner_email'] as String?,
      ownerName: json['owner_name'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'file_url': fileUrl,
      'storage_path': storagePath,
      'file_size_kb': fileSizeKb,
      'file_type': fileType,
      'owner_id': ownerId,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedFileSize {
    if (fileSizeKb >= 1024) {
      return '${(fileSizeKb / 1024).toStringAsFixed(2)} MB';
    }
    return '${fileSizeKb.toStringAsFixed(1)} KB';
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(updatedAt);
  }

  IconData get typeIcon {
    final lower = fileType.toLowerCase();
    if (lower.contains('pdf')) return Icons.picture_as_pdf;
    if (lower.contains('doc') || lower.contains('word')) return Icons.description;
    if (lower.contains('ppt') || lower.contains('presentation')) return Icons.slideshow;
    if (lower.contains('xls') || lower.contains('sheet')) return Icons.table_chart;
    if (lower.contains('zip') || lower.contains('rar')) return Icons.folder_zip;
    if (lower.contains('png') || lower.contains('jpg') || lower.contains('image')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  Color get typeColor {
    final lower = fileType.toLowerCase();
    if (lower.contains('pdf')) return Colors.red.shade700;
    if (lower.contains('doc') || lower.contains('word')) return Colors.blue.shade700;
    if (lower.contains('ppt') || lower.contains('presentation')) return Colors.amber.shade800;
    if (lower.contains('xls') || lower.contains('sheet')) return Colors.green.shade700;
    if (lower.contains('zip') || lower.contains('rar')) return Colors.purple.shade700;
    if (lower.contains('png') || lower.contains('jpg') || lower.contains('image')) {
      return Colors.teal.shade700;
    }
    return Colors.grey.shade700;
  }

  StudyDocument copyWith({
    String? title,
    String? description,
    String? subject,
    String? fileUrl,
    String? storagePath,
    double? fileSizeKb,
    String? fileType,
    bool? isPublic,
    DateTime? updatedAt,
  }) {
    return StudyDocument(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      fileSizeKb: fileSizeKb ?? this.fileSizeKb,
      fileType: fileType ?? this.fileType,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
      ownerName: ownerName,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
