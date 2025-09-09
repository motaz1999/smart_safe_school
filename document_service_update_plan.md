# Document Service Update Plan

## Overview
This document outlines the changes needed to update the DocumentService to include actual file picker and upload functionality.

## Current Implementation Issues
The current DocumentService has a placeholder uploadFile method that doesn't actually upload files to Supabase storage.

## Updated DocumentService Implementation

### 1. Add Required Imports
```dart
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
```

### 2. Add File Picker Method
```dart
Future<PlatformFile?> pickFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      return result.files.first;
    }
    return null;
  } catch (e) {
    throw Exception('Failed to pick file: $e');
  }
}
```

### 3. Update uploadFile Method
Replace the placeholder method with actual implementation:
```dart
Future<String> uploadFile(PlatformFile file, String fileName) async {
  try {
    // Upload to Supabase storage
    final response = await _supabase.storage
        .from('documents')
        .upload(fileName, file.bytes!);
    
    return response;
  } catch (e) {
    throw Exception('Failed to upload file: $e');
  }
}
```

### 4. Update uploadDocument Method
The uploadDocument method should be updated to work with the new file upload process:
```dart
Future<Document> uploadDocument({
  required int schoolId,
  required String senderId,
  required String senderType,
  required String title,
  String? description,
  required String filePath,
  required String fileName,
  required int fileSize,
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
      'p_mime_type': 'application/pdf',
      'p_recipient_ids': recipientIds,
    });

    // Get the created document
    final documentResponse = await _supabase
        .from('documents')
        .select('*')
        .eq('id', response)
        .single();

    return Document.fromJson(documentResponse);
  } catch (e) {
    throw Exception('Failed to upload document: $e');
  }
}
```

## Implementation Steps

1. Add file_picker dependency to pubspec.yaml
2. Update DocumentService with the new methods
3. Test the file picker functionality
4. Test the file upload to Supabase storage
5. Verify the database record creation

## Error Handling
The updated service should handle various error scenarios:
- File picker cancellation
- Invalid file types
- File size limits
- Network upload failures
- Database operation failures

## Security Considerations
- Ensure only authenticated users can upload files
- Validate file types on both client and server
- Implement appropriate storage policies in Supabase
- Ensure files are only accessible to intended recipients