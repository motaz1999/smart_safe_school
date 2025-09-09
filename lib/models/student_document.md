# Student Document Model

```dart
import 'base_model.dart';

class StudentDocument extends BaseModel {
  final String documentId;
  final String studentId;
  final bool isRead;

  // Additional fields for UI
  final String documentTitle;
  final String senderName;
  final String filePath;
  final String fileName;
  final int? fileSize;

  StudentDocument({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.documentId,
    required this.studentId,
    required this.isRead,
    required this.documentTitle,
    required this.senderName,
    required this.filePath,
    required this.fileName,
    this.fileSize,
  });

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    return StudentDocument(
      id: json['id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      documentId: json['document_id'] ?? '',
      studentId: json['student_id'] ?? '',
      isRead: json['is_read'] ?? false,
      documentTitle: json['document_title'] ?? '',
      senderName: json['sender_name'] ?? '',
      filePath: json['file_path'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'],
    );
  }
}