# Document Feature Implementation Guide

## Overview
This guide provides step-by-step instructions for implementing the document upload feature that allows teachers to send PDF documents to students from their local PC or smartphone.

## Prerequisites
- Flutter development environment set up
- Supabase project configured
- Existing Smart Safe School application codebase

## Implementation Steps

### 1. Add Dependencies

#### 1.1 Update pubspec.yaml
Add the file_picker dependency to your pubspec.yaml file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... existing dependencies ...
  file_picker: ^5.2.8
```

#### 1.2 Run pub get
After updating pubspec.yaml, run:
```bash
flutter pub get
```

### 2. Update DocumentService

#### 2.1 Add Required Imports
Update `lib/services/document_service.dart` to include the necessary imports:

```dart
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
```

#### 2.2 Add File Picker Method
Add the following method to the DocumentService class:

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

#### 2.3 Update uploadFile Method
Replace the placeholder uploadFile method with the actual implementation:

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

### 3. Update Teacher UI

#### 3.1 Add Required Import
Add the file_picker import to `lib/screens/teacher/classes_screen.dart`:

```dart
import 'package:file_picker/file_picker.dart';
```

#### 3.2 Add State Variable
Add a new state variable to `_DocumentSendingDialogState`:

```dart
PlatformFile? _selectedFile;
```

#### 3.3 Add File Picker Button
Add the file picker button to the dialog content in `_DocumentSendingDialogState.build()`:

```dart
// Add after the description field and before the student selection section
const SizedBox(height: 16),
ElevatedButton(
  onPressed: _pickFile,
  child: Text(_selectedFile == null ? 'Select PDF File' : 'Change File'),
),
if (_selectedFile != null) ...[
  const SizedBox(height: 16),
  Text('Selected file: ${_selectedFile!.name}'),
  Text('Size: ${_selectedFile!.size} bytes'),
],
```

#### 3.4 Add File Picker Method
Add the `_pickFile` method to `_DocumentSendingDialogState`:

```dart
Future<void> _pickFile() async {
  final file = await widget.documentService.pickFile();
  if (file != null) {
    setState(() {
      _selectedFile = file;
    });
  }
}
```

#### 3.5 Update Validation
Update the validation in the `_sendDocument` method:

```dart
Future<void> _sendDocument() async {
  if (_titleController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a document title')),
    );
    return;
  }
  
  if (_selectedFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a PDF file')),
    );
    return;
  }
  
  if (_selectedStudentIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one student')),
    );
    return;
  }
  
  // ... rest of the method
}
```

#### 3.6 Update Document Upload Process
Update the document upload process in the `_sendDocument` method:

```dart
Future<void> _sendDocument() async {
  // ... validation code ...
  
  setState(() {
    _isSending = true;
  });
  
  try {
    // Upload the file to Supabase storage
    final fileName = '${DateTime.now().millisecondsSinceSinceEpoch}_${_selectedFile!.name}';
    final fileUrl = await widget.documentService.uploadFile(_selectedFile!, fileName);
    
    // Create the document record in the database
    final document = await widget.documentService.uploadDocument(
      schoolId: widget.schoolId,
      senderId: widget.senderId,
      senderType: 'teacher',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      filePath: fileUrl,
      fileName: _selectedFile!.name,
      fileSize: _selectedFile!.size,
      recipientIds: _selectedStudentIds,
    );
    
    if (mounted) {
      Navigator.of(context).pop({'success': true});
    }
  } catch (e) {
    if (mounted) {
      Navigator.of(context).pop({'error': e.toString()});
    }
  } finally {
    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }
  }
}
```

### 4. Implement Student Document Download

#### 4.1 Add Required Imports
Add the necessary imports to `lib/screens/student/documents_screen.dart`:

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show AnchorElement, Blob, Url;
```

#### 4.2 Add Download Method
Add the `_downloadDocument` method to `_DocumentsScreenState`:

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

#### 4.3 Update Download Button
Update the download button in the `_showDocumentDetails` method:

```dart
ElevatedButton(
  onPressed: () async {
    Navigator.of(context).pop();
    await _downloadDocument(document);
  },
  child: const Text('Download'),
),
```

### 5. Database Setup

#### 5.1 Run Database Commands
Execute the SQL commands from `document_management_sql_commands_corrected.sql` in your Supabase SQL editor:

1. Create documents and student_documents tables
2. Create database functions (create_document, get_student_documents, mark_document_as_read)
3. Set up storage bucket and policies

#### 5.2 Verify Storage Policies
Ensure the storage policies are correctly set up in Supabase to allow:
- Teachers and admins to upload documents
- Students to download documents sent to them

### 6. Testing

#### 6.1 Test File Selection
- Verify teachers can select PDF files from their device
- Verify teachers cannot select non-PDF files
- Verify file information is displayed correctly

#### 6.2 Test Document Upload
- Verify documents upload successfully
- Verify database records are created
- Verify students receive the documents

#### 6.3 Test Document Download
- Verify students can download documents
- Verify downloaded files open correctly
- Verify read status updates properly

#### 6.4 Test Error Handling
- Test network error scenarios
- Test file size limits
- Test authentication requirements

## Troubleshooting

### Common Issues

#### 1. File Picker Not Working
- Ensure file_picker dependency is added to pubspec.yaml
- Run `flutter pub get` after adding the dependency
- Check platform-specific setup for mobile devices

#### 2. Upload Failures
- Verify Supabase storage bucket exists
- Check storage policies are correctly configured
- Ensure user has proper permissions

#### 3. Download Failures
- Verify document exists in storage
- Check student has permission to access the document
- Ensure device has sufficient storage space

### Debugging Tips

#### 1. Enable Logging
Add print statements to track the flow of operations:
```dart
print('DEBUG: Selecting file...');
print('DEBUG: File selected: ${file?.name}');
print('DEBUG: Uploading file...');
print('DEBUG: File uploaded to: $fileUrl');
```

#### 2. Check Supabase Logs
Monitor Supabase logs for storage and database operations.

#### 3. Test with Small Files
Start with small PDF files to verify the workflow before testing with larger files.

## Security Considerations

### 1. File Validation
- Validate file types on both client and server
- Implement file size limits
- Sanitize file names

### 2. Access Control
- Ensure only authorized users can upload files
- Verify students can only access documents sent to them
- Implement proper authentication checks

### 3. Data Protection
- Store files securely in Supabase storage
- Use appropriate storage policies
- Regularly audit access logs

## Performance Optimization

### 1. File Size Limits
Implement reasonable file size limits to prevent storage issues.

### 2. Progress Indicators
Show upload/download progress for better user experience.

### 3. Caching
Consider caching frequently accessed documents for faster loading.

## Conclusion

With this implementation, teachers will be able to upload PDF documents from their local PC or smartphone and send them to students. Students will be able to download and view these documents. The feature includes proper error handling, security measures, and a good user experience across different devices.