import 'base_model.dart';

class Document extends BaseModel {
  final int schoolId;
  final String senderId;
  final String senderType;
  final String title;
  final String? description;
  final String filePath;
  final String fileName;
  final int? fileSize;
  final String mimeType;

  // Additional fields for UI
  final String senderName;
  final int recipientCount;
  final int readCount; // New field for tracking read count
  final int favoriteCount; // New field for tracking favorite count

  Document({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.schoolId,
    required this.senderId,
    required this.senderType,
    required this.title,
    this.description,
    required this.filePath,
    required this.fileName,
    this.fileSize,
    required this.mimeType,
    required this.senderName,
    required this.recipientCount,
    this.readCount = 0, // Default to 0
    this.favoriteCount = 0, // Default to 0
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      schoolId: json['school_id'] ?? 0,
      senderId: json['sender_id'] ?? '',
      senderType: json['sender_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      filePath: json['file_path'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'],
      mimeType: json['mime_type'] ?? 'application/pdf',
      senderName: json['sender_name'] ?? '',
      recipientCount: json['recipient_count'] ?? 0,
      readCount: json['read_count'] ?? 0, // New field
      favoriteCount: json['favorite_count'] ?? 0, // New field
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'sender_id': senderId,
      'sender_type': senderType,
      'title': title,
      'description': description,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'sender_name': senderName,
      'recipient_count': recipientCount,
      'read_count': readCount, // New field
      'favorite_count': favoriteCount, // New field
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}