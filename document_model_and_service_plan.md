# Document Model and Service Implementation Plan

## Document Model

### Document Class
```dart
class Document extends BaseModel {
  final String schoolId;      // UUID of the school
  final String senderId;      // UUID of the sender (from profiles.id)
  final String senderType;    // 'admin' or 'teacher'
  final String title;         // Document title
  final String? description;  // Optional description
  final String filePath;      // Path to file in Supabase storage
  final String fileName;      // Original file name
  final int? fileSize;        // Size in bytes
  final String mimeType;      // MIME type (default: 'application/pdf')
  
  // Additional fields for UI
  final String senderName;    // Name of the sender (for display)
  final int recipientCount;   // Number of students who received this document
}
```

### StudentDocument Class
```dart
class StudentDocument extends BaseModel {
  final String documentId;    // References documents.id
  final String studentId;     // References profiles.id
  final bool isRead;          // Whether the student has read the document
  
  // Additional fields for UI
  final String documentTitle; // Title of the document
  final String senderName;    // Name of the sender
}
```

## Document Service

### DocumentService Class
```dart
class DocumentService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Upload a document to Supabase storage and create database records
  Future<Document> uploadDocument({
    required String schoolId,
    required String senderId,
    required String senderType,
    required String title,
    String? description,
    required String filePath,
    required String fileName,
    required List<String> recipientIds, // List of student profile IDs
  }) async {
    // Implementation details:
    // 1. Upload file to Supabase storage
    // 2. Create document record in database
    // 3. Create student_document records for each recipient
  }
  
  // Get documents sent by a specific admin/teacher
  Future<List<Document>> getSentDocuments(String senderId) async {
    // Implementation details:
    // 1. Query documents table for documents sent by senderId
    // 2. Include recipient count information
  }
  
  // Get documents for a specific student
  Future<List<StudentDocument>> getReceivedDocuments(String studentId) async {
    // Implementation details:
    // 1. Query student_documents table for documents received by studentId
    // 2. Join with documents table to get document details
    // 3. Join with profiles table to get sender name
  }
  
  // Mark a document as read by a student
  Future<void> markAsRead(String documentId, String studentId) async {
    // Implementation details:
    // 1. Update student_documents record to set is_read = true
  }
  
  // Delete a document (only for sender)
  Future<void> deleteDocument(String documentId, String senderId) async {
    // Implementation details:
    // 1. Verify sender is the owner of the document
    // 2. Delete document from storage
    // 3. Delete document record (cascades to student_documents)
  }
}
```

## Implementation Considerations

1. **File Storage**: Use Supabase Storage with a dedicated bucket for documents
2. **Security**: Implement RLS policies to ensure only authorized users can access documents
3. **Error Handling**: Proper error handling for file upload failures, database errors, etc.
4. **Performance**: Consider pagination for large document lists
5. **File Validation**: Validate that uploaded files are PDFs (or other allowed formats)