# Document Upload Functionality Plan

## Overview
This document outlines the implementation plan for allowing admins and teachers to upload and send PDF documents to students.

## Feature Requirements
1. Admins and teachers can select PDF files from their device
2. Users can add a title and optional description to the document
3. Users can select one or more students to send the document to
4. The system validates that the file is a PDF
5. The system uploads the file to Supabase storage
6. The system creates appropriate database records

## Implementation Plan

### 1. File Selection Component
- Use Flutter's file picker to allow users to select PDF files
- Validate file type and size
- Display selected file information (name, size)

### 2. Document Metadata Form
- Title field (required)
- Description field (optional)
- Student selection component

### 3. Student Selection Component
- For admins: List all students in their school
- For teachers: List students in their classes
- Allow multiple selection
- Search/filter functionality

### 4. Upload Process
1. Validate form inputs
2. Validate selected file (PDF format, reasonable size)
3. Show upload progress
4. Upload file to Supabase storage
5. Create document record in database
6. Create student_document records for each recipient
7. Show success/error message

### 5. Admin Implementation
- Add "Send Document" option to admin dashboard
- Possibly in the "Manage Students" section
- Modal or separate screen for document upload

### 6. Teacher Implementation
- Add "Send Document" option to teacher dashboard
- Possibly in the "Classes" section
- Modal or separate screen for document upload

## Technical Considerations

### File Validation
```dart
bool isValidPdfFile(File file) {
  // Check file extension
  // Check MIME type if possible
  // Check file size (implement reasonable limit)
}
```

### Upload Process
```dart
Future<Document> uploadDocument({
  required File file,
  required String title,
  String? description,
  required List<String> recipientIds,
}) async {
  // 1. Validate file
  // 2. Upload to Supabase storage
  // 3. Create database records
  // 4. Return created document
}
```

### Error Handling
- File too large
- Invalid file format
- Network/upload errors
- Database errors
- Partial success scenarios (some students failed to receive)

## UI/UX Considerations

### Upload Flow
1. Click "Send Document" button
2. File selection dialog
3. Document metadata form
4. Student selection
5. Review and confirm
6. Upload progress
7. Success confirmation

### User Feedback
- Clear error messages
- Upload progress indicator
- Success confirmation with option to send more documents
- Ability to cancel upload