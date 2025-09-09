# Student Document Download Implementation Plan

## Overview
This document outlines the changes needed to implement document download functionality for students.

## Current Implementation Issues
The current student documents screen shows document details but doesn't actually implement the download functionality.

## Implementation Plan

### 1. Add Required Imports
Add the necessary imports to lib/screens/student/documents_screen.dart:
```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
```

### 2. Update Download Button
Update the download button in the _showDocumentDetails method:
```dart
ElevatedButton(
  onPressed: () async {
    Navigator.of(context).pop();
    await _downloadDocument(document);
  },
  child: const Text('Download'),
),
```

### 3. Add Download Method
Add the _downloadDocument method to _DocumentsScreenState:
```dart
Future<void> _downloadDocument(StudentDocument document) async {
  try {
    // Show loading indicator
    final snackBar = SnackBar(
      content: const Text('Downloading document...'),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    // Download the file from Supabase storage
    final response = await _supabase.storage
        .from('documents')
        .download(document.filePath);
    
    // Get the documents directory
    final directory = await getApplicationDocumentsDirectory();
    
    // Create the file path
    final filePath = '${directory.path}/${document.fileName}';
    
    // Write the file
    final file = File(filePath);
    await file.writeAsBytes(response);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document saved to $filePath')),
    );
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to download document: $e')),
    );
  }
}
```

### 4. Alternative Implementation for Web
For web platforms, a different approach is needed:
```dart
Future<void> _downloadDocument(StudentDocument document) async {
  try {
    // Show loading indicator
    final snackBar = SnackBar(
      content: const Text('Downloading document...'),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    // Download the file from Supabase storage
    final response = await _supabase.storage
        .from('documents')
        .download(document.filePath);
    
    // For web, we need to create a blob URL
    if (kIsWeb) {
      // Create a blob from the response
      final blob = html.Blob([response], 'application/pdf');
      final url = html.Url.createObjectUrl(blob);
      
      // Create a temporary anchor element to trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', document.fileName)
        ..click();
      
      // Clean up
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile/desktop, save to device storage
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${document.fileName}';
      final file = File(filePath);
      await file.writeAsBytes(response);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document saved to $filePath')),
      );
    }
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to download document: $e')),
    );
  }
}
```

## Security Considerations

### 1. Access Control
Ensure students can only download documents that were sent to them:
- The Supabase storage policies already restrict this
- The database queries only return documents for the specific student

### 2. File Validation
Validate that downloaded files are actually PDFs and not malicious files:
- Check file extension
- Check MIME type if possible
- Implement size limits

## Error Handling

### 1. Network Errors
Handle network connectivity issues during download:
- Show appropriate error messages
- Allow retry functionality

### 2. Storage Errors
Handle device storage issues:
- Check available storage space
- Handle permission errors

### 3. File System Errors
Handle file system access errors:
- Handle read/write permissions
- Handle file path issues

## UI/UX Improvements

### 1. Progress Indication
Show download progress for large files:
```dart
// This would require a more complex implementation with progress callbacks
```

### 2. Download History
Show previously downloaded documents:
- This would require storing download history locally
- Could use shared_preferences for simple implementation

### 3. Open With Feature
Allow opening documents with external apps:
- For mobile platforms, use platform-specific APIs
- For web, use browser capabilities

## Implementation Steps

1. Add necessary imports to student documents screen
2. Implement download method with error handling
3. Test download functionality on different platforms
4. Verify security restrictions are working
5. Test error scenarios

## Testing Scenarios

1. Student downloads a valid document
2. Student tries to download a document they didn't receive
3. Network error during download
4. Insufficient storage space on device
5. File permission errors
6. Large file downloads
7. Multiple simultaneous downloads
8. Cancelled downloads