# Document Management System Redesign Plan

## 1. Current System Analysis

### 1.1 Overview
The current document management system in SmartSafeSchool allows:
- Teachers to send documents to students in their classes
- Admins to send documents to all students
- Students to view and download received documents

### 1.2 Components
- **DocumentService**: Handles document operations (upload, download, get sent/received documents)
- **DocumentsScreen**: Student interface for viewing documents
- **ClassesScreen**: Teacher interface for sending documents to class students
- **AdminDashboard**: Admin interface for sending documents to all students
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
1. **Incomplete Admin Implementation**: Admin document sending doesn't actually upload files
2. **Limited Document Management**: No ability to view/edit/delete sent documents
3. **No Document Organization**: No categories, tags, or filtering capabilities
4. **Missing Features**: No document expiration, versioning, or analytics

### 2.2 Technical Issues
1. **Inconsistent File Picker Integration**: Only implemented for teachers
2. **Limited Error Handling**: Poor user feedback on failures
3. **No Search Capabilities**: Cannot search documents by title, content, or metadata
4. **No Bulk Operations**: Cannot perform actions on multiple documents at once

### 2.3 UI/UX Issues
1. **Basic Interface**: Minimal visual design and user experience
2. **No Document Preview**: Cannot preview documents before downloading
3. **Limited Status Tracking**: No visibility into document engagement
4. **No Mobile Optimization**: Interface not optimized for mobile devices

## 3. New System Architecture

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
  final String? category; // New: Document category/type
  final DateTime? expiresAt; // New: Document expiration date
  final int priority; // New: Priority level (1-5)
  final List<String> tags; // New: Document tags
  final int version; // New: Document version for tracking changes
  
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
  final bool isArchived; // New: Student can archive documents
  
  // Additional fields for UI
  final String documentTitle;
  final String senderName;
  final String filePath;
  final String fileName;
  final int? fileSize;
  final String? description;
  final String? category; // New: Document category
  final DateTime? expiresAt; // New: Document expiration date
}
```

### 3.3 User Roles and Permissions
1. **Students**:
   - View, download, and organize received documents
   - Mark as read/favorite/archived
   - Search and filter documents
   - Bulk operations on documents

2. **Teachers**:
   - All student capabilities plus
   - Send documents to classes/students
   - View/manage sent documents
   - Track document engagement
   - Use document templates

3. **Admins**:
   - All teacher capabilities plus
   - Send documents to all/specific groups
   - System-wide document management
   - Document analytics and reporting
   - Document retention policies

## 4. Database Schema Changes

### 4.1 Enhanced Documents Table
```sql
-- Enhanced documents table
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
    category TEXT, -- New: Document category
    expires_at TIMESTAMP WITH TIME ZONE, -- New: Expiration date
    priority INTEGER DEFAULT 3 CHECK (priority >= 1 AND priority <= 5), -- New: Priority level
    tags TEXT[], -- New: Document tags
    version INTEGER DEFAULT 1, -- New: Document version
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
    is_archived BOOLEAN DEFAULT FALSE, -- New: Archive status
    read_at TIMESTAMP WITH TIME ZONE, -- New: When document was read
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_id, student_id)
);

-- Document categories table
CREATE TABLE document_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT, -- For UI display
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, name)
);

-- Document activities table (for analytics)
CREATE TABLE document_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    student_id UUID,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('view', 'download', 'favorite', 'archive', 'unread')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4.2 New Functions
```sql
-- Function to get document statistics
CREATE OR REPLACE FUNCTION get_document_stats(p_document_id UUID)
RETURNS TABLE(
    total_recipients INTEGER,
    read_count INTEGER,
    favorite_count INTEGER,
    archived_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_recipients,
        COUNT(CASE WHEN sd.is_read THEN 1 END)::INTEGER as read_count,
        COUNT(CASE WHEN sd.is_favorite THEN 1 END)::INTEGER as favorite_count,
        COUNT(CASE WHEN sd.is_archived THEN 1 END)::INTEGER as archived_count
    FROM student_documents sd
    WHERE sd.document_id = p_document_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's document activity
CREATE OR REPLACE FUNCTION get_user_document_activity(p_user_id UUID)
RETURNS TABLE(
    total_received INTEGER,
    total_read INTEGER,
    total_favorite INTEGER,
    total_archived INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_received,
        COUNT(CASE WHEN sd.is_read THEN 1 END)::INTEGER as total_read,
        COUNT(CASE WHEN sd.is_favorite THEN 1 END)::INTEGER as total_favorite,
        COUNT(CASE WHEN sd.is_archived THEN 1 END)::INTEGER as total_archived
    FROM student_documents sd
    WHERE sd.student_id = p_user_id;
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
    String? category,
    DateTime? expiresAt,
    int priority = 3,
    List<String>? tags,
    required List<String> recipientIds,
  }) async {
    try {
      // Call the enhanced database function to create document and student_document records
      final response = await _supabase.rpc('create_document_enhanced', params: {
        'p_school_id': schoolId,
        'p_sender_id': senderId,
        'p_sender_type': senderType,
        'p_title': title,
        'p_description': description,
        'p_file_path': filePath,
        'p_file_name': fileName,
        'p_file_size': fileSize,
        'p_mime_type': mimeType,
        'p_category': category,
        'p_expires_at': expiresAt?.toIso8601String(),
        'p_priority': priority,
        'p_tags': tags ?? [],
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
    String? category,
    bool? isRead,
    bool? isFavorite,
    bool? isArchived,
    String? searchQuery,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      // Build query with filters
      var query = _supabase.rpc('get_student_documents_enhanced', params: {
        'p_student_id': studentId,
      });
      
      // Apply additional filters if needed
      // This would be implemented in the database function or as additional query parameters
      
      final response = await query;
      
      return (response as List)
          .map((json) => StudentDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw DocumentException('Failed to get received documents: $e');
    }
  }
  
  // Update document metadata
  Future<Document> updateDocument(Document document) async {
    try {
      final response = await _supabase
          .from('documents')
          .update(document.toJson())
          .eq('id', document.id)
          .select()
          .single();
      
      return Document.fromJson(response);
    } catch (e) {
      throw DocumentException('Failed to update document: $e');
    }
  }
  
  // Delete document (with cascade delete of student_documents)
  Future<void> deleteDocument(String documentId) async {
    try {
      await _supabase
          .from('documents')
          .delete()
          .eq('id', documentId);
    } catch (e) {
      throw DocumentException('Failed to delete document: $e');
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
  
  // Archive/unarchive document
  Future<void> toggleArchive(String documentId, String studentId) async {
    try {
      await _supabase.rpc('toggle_document_archive', params: {
        'p_document_id': documentId,
        'p_student_id': studentId,
      });
    } catch (e) {
      throw DocumentException('Failed to toggle archive: $e');
    }
  }
  
  // Get document categories for school
  Future<List<DocumentCategory>> getDocumentCategories(int schoolId) async {
    try {
      final response = await _supabase
          .from('document_categories')
          .select('*')
          .eq('school_id', schoolId)
          .order('name');
      
      return response.map((json) => DocumentCategory.fromJson(json)).toList();
    } catch (e) {
      throw DocumentException('Failed to get document categories: $e');
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
   - Archived

2. **Enhanced Document Cards**:
   - Category badges
   - Priority indicators
   - Expiration warnings
   - Engagement metrics (read by X/Y students)

3. **Search and Filter**:
   - Search by title, description, sender
   - Filter by category, date range, priority
   - Sort by date, priority, title

4. **Document Preview**:
   - PDF preview within app
   - Image preview for image documents
   - Metadata display

5. **Bulk Operations**:
   - Select multiple documents
   - Mark as read/unread
   - Add/remove from favorites
   - Archive/unarchive

### 6.2 Teacher Document Management
1. **Dedicated Document Dashboard**:
   - Overview of sent documents
   - Engagement analytics
   - Quick send functionality

2. **Enhanced Send Dialog**:
   - Document templates
   - Category selection
   - Priority setting
   - Expiration date
   - Tags management

3. **Document Tracking**:
   - Read status per student
   - Favorite/archive status
   - Download counts

4. **Document Templates**:
   - Save frequently used documents as templates
   - Quick access to templates
   - Template management

### 6.3 Admin Document Management
1. **School-Wide Document Management**:
   - Send to all students
   - Send to specific classes/grades
   - Send to custom groups

2. **Document Analytics**:
   - School-wide engagement metrics
   - Category usage statistics
   - User activity reports

3. **System Management**:
   - Document category management
   - Document retention policies
   - Storage usage monitoring

## 7. Implementation Plan

### 7.1 Phase 1: Backend and Database (Weeks 1-2)
1. **Database Schema Updates**:
   - Add new columns to existing tables
   - Create new tables (document_categories, document_activities)
   - Create new functions (get_document_stats, etc.)

2. **Database Migration**:
   - Write migration scripts
   - Test migration on staging environment
   - Apply to production

3. **API Endpoints**:
   - Update existing RPC functions
   - Create new RPC functions
   - Test all database operations

### 7.2 Phase 2: Document Service (Weeks 2-3)
1. **Service Enhancement**:
   - Implement new methods in DocumentService
   - Add error handling and logging
   - Write unit tests

2. **Model Updates**:
   - Update Document and StudentDocument models
   - Add new models (DocumentCategory, etc.)
   - Ensure backward compatibility

3. **Integration Testing**:
   - Test all service methods
   - Verify database interactions
   - Performance testing

### 7.3 Phase 3: UI Implementation (Weeks 3-5)
1. **Student Interface**:
   - Redesign DocumentsScreen
   - Implement tabbed interface
   - Add search and filter functionality
   - Implement document preview

2. **Teacher Interface**:
   - Create document management dashboard
   - Enhance send document dialog
   - Implement document tracking features

3. **Admin Interface**:
   - Enhance admin document sending
   - Add document analytics
   - Implement system management features

### 7.4 Phase 4: Testing and Deployment (Week 6)
1. **Testing**:
   - Unit testing for all new code
   - Integration testing
   - User acceptance testing
   - Performance testing

2. **Deployment**:
   - Deploy to staging environment
   - Conduct final testing
   - Deploy to production
   - Monitor for issues

### 7.5 Timeline Summary
- **Week 1-2**: Backend and database changes
- **Week 2-3**: Document service enhancements
- **Week 3-5**: UI/UX implementation
- **Week 6**: Testing and deployment

## 8. Risk Mitigation

### 8.1 Technical Risks
1. **Database Migration Issues**:
   - Solution: Thorough testing in staging environment
   - Rollback plan: Database backup and restore procedures

2. **Performance Degradation**:
   - Solution: Query optimization and indexing
   - Monitoring: Performance metrics and alerts

3. **Data Loss**:
   - Solution: Comprehensive backup strategy
   - Validation: Data integrity checks after migration

### 8.2 User Adoption Risks
1. **Resistance to Change**:
   - Solution: User training and documentation
   - Gradual rollout: Phased feature releases

2. **Learning Curve**:
   - Solution: Intuitive UI design
   - Support: Help documentation and tooltips

## 9. Success Metrics

### 9.1 Technical Metrics
- Document load times < 2 seconds
- 99.9% uptime for document services
- < 1% error rate in document operations

### 9.2 User Engagement Metrics
- 20% increase in document engagement
- 50% reduction in support tickets related to documents
- 90% user satisfaction rating

### 9.3 Business Metrics
- 30% increase in document sharing frequency
- Improved communication efficiency
- Enhanced user retention