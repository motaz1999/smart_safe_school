# Simplified Document Management System Plan

## 1. Current System Analysis

### 1.1 Overview
The current document management system in SmartSafeSchool allows:
- Teachers to send documents to students in their classes
- Students to view and download received documents

### 1.2 Components
- **DocumentService**: Handles document operations (upload, download, get sent/received documents)
- **DocumentsScreen**: Student interface for viewing documents
- **ClassesScreen**: Teacher interface for sending documents to class students
- **Database**: PostgreSQL tables for documents and student-document relationships
- **Storage**: Supabase storage with "documents" bucket

### 1.3 Database Schema
```sql
-- Documents table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER NOT NULL,
    sender_id UUID NOT NULL,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('admin', 'teacher')),
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL UNIQUE,
    file_name TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT DEFAULT 'application/pdf',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student documents table
CREATE TABLE student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    student_id UUID NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_id, student_id)
);
```

## 2. Issues and Limitations

### 2.1 Functional Issues
1. **Limited Document Management**: No ability for teachers to view/edit/delete sent documents
2. **No Document Organization**: No categories, tags, or filtering capabilities for students
3. **Missing Features**: No document expiration, versioning, or analytics

### 2.2 Technical Issues
1. **Inconsistent Error Handling**: Poor user feedback on failures
2. **No Search Capabilities**: Cannot search documents by title or content
3. **No Bulk Operations**: Cannot perform actions on multiple documents at once

### 2.3 UI/UX Issues
1. **Basic Interface**: Minimal visual design and user experience
2. **No Document Preview**: Cannot preview documents before downloading
3. **Limited Status Tracking**: No visibility into document engagement

## 3. Simplified System Architecture

### 3.1 Enhanced Document Model
```dart
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
  final int readCount; // New: Number of recipients who have read the document
}
```

### 3.2 Enhanced Student Document Model
```dart
class StudentDocument extends BaseModel {
  final String documentId;
  final String studentId;
  final bool isRead;
  final bool isFavorite; // New: Student can mark as favorite
  
  // Additional fields for UI
  final String documentTitle;
  final String senderName;
  final String filePath;
  final String fileName;
  final int? fileSize;
  final String? description;
}
```

### 3.3 User Roles and Permissions
1. **Students**:
   - View, download, and organize received documents
   - Mark as read/favorite
   - Search and filter documents

2. **Teachers**:
   - Send documents to classes/students
   - View/manage sent documents
   - Track document engagement

## 4. Database Schema Changes

### 4.1 Enhanced Tables
```sql
-- Enhanced documents table (minimal changes)
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER NOT NULL,
    sender_id UUID NOT NULL,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('admin', 'teacher')),
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL UNIQUE,
    file_name TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT DEFAULT 'application/pdf',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enhanced student documents table
CREATE TABLE student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    student_id UUID NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    is_favorite BOOLEAN DEFAULT FALSE, -- New: Favorite status
    read_at TIMESTAMP WITH TIME ZONE, -- New: When document was read
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_id, student_id)
);
```

### 4.2 New Functions
```sql
-- Function to get document statistics
CREATE OR REPLACE FUNCTION get_document_stats(p_document_id UUID)
RETURNS TABLE(
    total_recipients INTEGER,
    read_count INTEGER,
    favorite_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_recipients,
        COUNT(CASE WHEN sd.is_read THEN 1 END)::INTEGER as read_count,
        COUNT(CASE WHEN sd.is_favorite THEN 1 END)::INTEGER as favorite_count
    FROM student_documents sd
    WHERE sd.document_id = p_document_id;
END;
$$ LANGUAGE plpgsql;
```

## 5. Document Service Improvements

### 5.1 Enhanced DocumentService Class
```dart
class DocumentService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  bool _bucketVerified = false;
  
  // Enhanced file picker with support for multiple file types
  Future<PlatformFile?> pickFile({List<String>? allowedExtensions}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions ?? ['pdf', 'doc', 'docx', 'jpg', 'png'],
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      throw DocumentException('Failed to pick file: $e');
    }
  }
  
  // Enhanced upload document with additional metadata
  Future<Document> uploadDocument({
    required int schoolId,
    required String senderId,
    required String senderType,
    required String title,
    String? description,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required List<String> recipientIds,
  }) async {
    try {
      // Call the database function to create document and student_document records
      final response = await _supabase.rpc('create_document', params: {
        'p_school_id': schoolId,
        'p_sender_id': senderId,
        'p_sender_type': senderType,
        'p_title': title,
        'p_description': description,
        'p_file_path': filePath,
        'p_file_name': fileName,
        'p_file_size': fileSize,
        'p_mime_type': mimeType,
        'p_recipient_ids': recipientIds,
      });
      
      // Get the created document
      final documentResponse = await _supabase
          .from('documents')
          .select('*, student_documents(count)')
          .eq('id', response)
          .single();
      
      return Document.fromJson(documentResponse);
    } catch (e) {
      throw DocumentException('Failed to upload document: $e');
    }
  }
  
  // Get documents sent by a specific user with enhanced information
  Future<List<Document>> getSentDocuments(String senderId) async {
    try {
      final response = await _supabase
          .from('documents')
          .select('*, student_documents(count, is_read, is_favorite)')
          .eq('sender_id', senderId)
          .order('created_at', ascending: false);
      
      return response.map((json) {
        // Calculate statistics from the join
        final studentDocs = json['student_documents'] as List;
        final recipientCount = studentDocs.length;
        final readCount = studentDocs.where((doc) => doc['is_read'] == true).length;
        final favoriteCount = studentDocs.where((doc) => doc['is_favorite'] == true).length;
        
        json['recipient_count'] = recipientCount;
        json['read_count'] = readCount;
        json['favorite_count'] = favoriteCount;
        
        return Document.fromJson(json);
      }).toList();
    } catch (e) {
      throw DocumentException('Failed to get sent documents: $e');
    }
  }
  
  // Enhanced get received documents with filtering and sorting
  Future<List<StudentDocument>> getReceivedDocuments({
    required String studentId,
    bool? isRead,
    bool? isFavorite,
    String? searchQuery,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      // Build query with filters
      var query = _supabase.rpc('get_student_documents', params: {
        'p_student_id': studentId,
      });
      
      final response = await query;
      
      return (response as List)
          .map((json) => StudentDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw DocumentException('Failed to get received documents: $e');
    }
  }
  
  // Mark document as favorite
  Future<void> toggleFavorite(String documentId, String studentId) async {
    try {
      await _supabase.rpc('toggle_document_favorite', params: {
        'p_document_id': documentId,
        'p_student_id': studentId,
      });
    } catch (e) {
      throw DocumentException('Failed to toggle favorite: $e');
    }
  }
  
  // Search documents
  Future<List<StudentDocument>> searchDocuments({
    required String studentId,
    required String query,
  }) async {
    try {
      final response = await _supabase.rpc('search_student_documents', params: {
        'p_student_id': studentId,
        'p_search_query': query,
      });
      
      return (response as List)
          .map((json) => StudentDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw DocumentException('Failed to search documents: $e');
    }
  }
}
```

## 6. UI/UX Improvements

### 6.1 Student Document Screen Enhancements
1. **Tabbed Interface**:
   - All Documents
   - Unread
   - Favorites

2. **Enhanced Document Cards**:
   - Engagement metrics (read by X/Y students)
   - Favorite indicator

3. **Search and Filter**:
   - Search by title, description, sender
   - Filter by read/unread status

4. **Document Preview**:
   - PDF preview within app
   - Image preview for image documents

### 6.2 Teacher Document Management
1. **Enhanced Send Dialog**:
   - Better file picker integration
   - Student selection improvements

2. **Document Tracking**:
   - Read status per student
   - Favorite status

## 7. Implementation Plan

### 7.1 Phase 1: Backend and Database (Week 1)
1. **Database Schema Updates**:
   - Add new columns to student_documents table
   - Create new functions (get_document_stats, etc.)

2. **Database Migration**:
   - Write migration scripts
   - Test migration on staging environment
   - Apply to production

### 7.2 Phase 2: Document Service (Week 2)
1. **Service Enhancement**:
   - Implement new methods in DocumentService
   - Add error handling and logging
   - Write unit tests

2. **Model Updates**:
   - Update Document and StudentDocument models
   - Ensure backward compatibility

### 7.3 Phase 3: UI Implementation (Week 3)
1. **Student Interface**:
   - Redesign DocumentsScreen
   - Implement tabbed interface
   - Add search and filter functionality
   - Implement document preview

2. **Teacher Interface**:
   - Enhance send document dialog
   - Implement document tracking features

### 7.4 Phase 4: Testing and Deployment (Week 4)
1. **Testing**:
   - Unit testing for all new code
   - Integration testing
   - User acceptance testing

2. **Deployment**:
   - Deploy to staging environment
   - Conduct final testing
   - Deploy to production
   - Monitor for issues

### 7.5 Timeline Summary
- **Week 1**: Backend and database changes
- **Week 2**: Document service enhancements
- **Week 3**: UI/UX implementation
- **Week 4**: Testing and deployment

## 8. Key Improvements

### 8.1 For Students
- **Better Organization**: Tabbed interface for easier navigation
- **Search Functionality**: Find documents quickly
- **Document Preview**: View documents without downloading
- **Favorites**: Mark important documents for quick access

### 8.2 For Teachers
- **Document Tracking**: See which students have read documents
- **Improved Send Interface**: Better file selection and student selection
- **Sent Document Management**: View previously sent documents

### 8.3 Technical Improvements
- **Better Error Handling**: More informative error messages
- **Enhanced Security**: Improved access controls
- **Performance**: Optimized database queries
- **Maintainability**: Cleaner code structure

## 9. Success Metrics

### 9.1 User Engagement
- 15% increase in document interactions
- 30% reduction in support tickets related to documents
- 85% user satisfaction rating

### 9.2 Technical Performance
- Document load times under 2 seconds
- 99.5% system uptime
- Less than 2% error rate

### 9.3 Business Impact
- 20% increase in document sharing frequency
- Improved communication efficiency
- Enhanced user retention