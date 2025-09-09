# File Picker Integration Plan

## Overview
This document outlines the steps needed to integrate file picker functionality so teachers can upload documents from their local PC or smartphone.

## Required Changes

### 1. Add file_picker dependency
Add the file_picker package to pubspec.yaml:
```yaml
dependencies:
  # ... existing dependencies ...
  file_picker: ^5.2.8
```

### 2. Update DocumentService
Modify the DocumentService to include file picker functionality:

```dart
// Add this import
import 'package:file_picker/file_picker.dart';

// Add this method to DocumentService class
Future<PlatformFile?> pickFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Required to get file data
    );
    
    if (result != null && result.files.isNotEmpty) {
      return result.files.first;
    }
    return null;
  } catch (e) {
    throw Exception('Failed to pick file: $e');
  }
}

// Update uploadFile method to actually upload to Supabase storage
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

### 3. Update Teacher Document Sending UI
Modify the _DocumentSendingDialog in lib/screens/teacher/classes_screen.dart:

```dart
// Add state variable
PlatformFile? _selectedFile;

// Add file picker button
ElevatedButton(
  onPressed: _pickFile,
  child: Text(_selectedFile == null ? 'Select PDF File' : 'Change File'),
),

// Add file info display
if (_selectedFile != null) ...[
  const SizedBox(height: 16),
  Text('Selected file: ${_selectedFile!.name}'),
  Text('Size: ${_selectedFile!.size} bytes'),
],

// Add _pickFile method
Future<void> _pickFile() async {
  final file = await widget.documentService.pickFile();
  if (file != null) {
    setState(() {
      _selectedFile = file;
    });
  }
}

// Update _sendDocument method to use the selected file
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
  
  setState(() {
    _isSending = true;
  });
  
  try {
    // Upload the file to Supabase storage
    final fileUrl = await widget.documentService.uploadFile(
      _selectedFile!, 
      '${DateTime.now().millisecondsSinceSinceEpoch}_${_selectedFile!.name}',
    );
    
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

### 4. Implement Document Download for Students
Add download functionality to the student documents screen:

```dart
// In DocumentsScreen, update the download button action:
ElevatedButton(
  onPressed: () async {
    Navigator.of(context).pop();
    try {
      // Download the file from Supabase storage
      final response = await _supabase.storage
          .from('documents')
          .download(document.filePath);
      
      // Save the file locally (this would need platform-specific implementation)
      // For now, just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document downloaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download document: $e')),
      );
    }
  },
  child: const Text('Download'),
),
```

## Testing Plan
1. Test file selection on both PC and mobile devices
2. Test PDF file validation
3. Test document upload to Supabase storage
4. Test document download by students
5. Test error handling for network issues and file size limits