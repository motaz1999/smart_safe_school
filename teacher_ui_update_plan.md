# Teacher UI Update Plan

## Overview
This document outlines the changes needed to update the teacher's document sending UI to include file picker functionality.

## Current Implementation Issues
The current _DocumentSendingDialog in lib/screens/teacher/classes_screen.dart has a placeholder implementation that simulates file upload instead of actually allowing teachers to select and upload files.

## Updated UI Implementation

### 1. Add Required Imports
```dart
import 'package:file_picker/file_picker.dart';
```

### 2. Add State Variable
Add a new state variable to _DocumentSendingDialogState:
```dart
PlatformFile? _selectedFile;
```

### 3. Add File Picker Button
Add a file picker button to the dialog content:
```dart
// Add after the description field
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

### 4. Add File Picker Method
Add the _pickFile method to _DocumentSendingDialogState:
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

### 5. Update Validation
Update the validation in _sendDocument method:
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

### 6. Update Document Upload Process
Update the document upload process in _sendDocument method:
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

## UI/UX Improvements

### 1. File Type Validation
The file picker should only allow PDF files to be selected.

### 2. File Size Limits
Consider implementing file size limits and showing appropriate error messages.

### 3. Progress Indication
Show upload progress to the user during file upload.

### 4. Error Handling
Provide clear error messages for different failure scenarios.

## Implementation Steps

1. Add file_picker dependency to pubspec.yaml
2. Update _DocumentSendingDialog with file picker functionality
3. Test file selection on different devices
4. Test document upload process
5. Verify error handling

## Testing Scenarios

1. Teacher selects a valid PDF file
2. Teacher cancels file selection
3. Teacher selects a non-PDF file (should be prevented)
4. Teacher selects a file that's too large
5. Network error during file upload
6. Database error during document creation
7. Successful document upload and distribution to students