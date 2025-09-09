import 'base_model.dart';

class StudentDocument extends BaseModel {
  final String documentId;
  final String studentId;
  final bool isRead;
  final bool isFavorite; // New field for favorite status
  final DateTime? readAt; // New field for when document was read

  // Additional fields for UI
  final String documentTitle;
  final String senderName;
  final String filePath;
  final String fileName;
  final int? fileSize;
  final String? description;
  final String? mimeType; // New field for file type

  StudentDocument({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.documentId,
    required this.studentId,
    required this.isRead,
    this.isFavorite = false, // Default to false
    this.readAt, // Optional field
    required this.documentTitle,
    required this.senderName,
    required this.filePath,
    required this.fileName,
    this.fileSize,
    this.description,
    this.mimeType, // New field
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
      isFavorite: json['is_favorite'] ?? false, // New field
      readAt: json['read_at'] != null // New field
          ? DateTime.parse(json['read_at'])
          : null,
      documentTitle: json['document_title'] ?? '',
      senderName: json['sender_name'] ?? '',
      filePath: json['file_path'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'],
      description: json['description'],
      mimeType: json['mime_type'], // New field
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'student_id': studentId,
      'is_read': isRead,
      'is_favorite': isFavorite, // New field
      'read_at': readAt?.toIso8601String(), // New field
      'document_title': documentTitle,
      'sender_name': senderName,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'description': description,
      'mime_type': mimeType, // New field
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}