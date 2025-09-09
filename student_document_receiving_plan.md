# Student Document Receiving Functionality Plan

## Overview
This document outlines the implementation plan for allowing students to view, download, and manage documents sent to them by admins and teachers.

## Feature Requirements
1. Students can view a list of documents sent to them
2. Students can see who sent each document and when
3. Students can download documents to their device
4. Students can mark documents as read
5. Students can see unread document count

## Implementation Plan

### 1. Student Document List Screen
- AppBar with title "My Documents"
- List of received documents with key information:
  - Document title
  - Sender name
  - Date sent
  - Read status
  - File size (optional)

### 2. Document List Item Component
```
Card(
  child: ListTile(
    leading: CircleAvatar(
      backgroundColor: _isRead ? Colors.green : Colors.orange,
      child: Icon(
        _isRead ? Icons.check : Icons.description,
        color: Colors.white,
      ),
    ),
    title: Text(document.title),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("From: ${document.senderName}"),
        Text("Sent: ${_formatDate(document.createdAt)}"),
        if (document.fileSize != null)
          Text("Size: ${_formatFileSize(document.fileSize)}"),
      ],
    ),
    trailing: Icon(Icons.arrow_forward_ios),
    onTap: () => _viewDocument(document),
  ),
)
```

### 3. Document Detail Screen
- Document title and description
- Sender information
- Date sent
- File name and size
- Download button
- Mark as read button (if not already read)

### 4. Document Detail Component
```
class DocumentDetailScreen extends StatelessWidget {
  final StudentDocument document;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.documentTitle),
        actions: [
          if (!document.isRead)
            IconButton(
              icon: Icon(Icons.check_circle),
              onPressed: () => _markAsRead(context, document),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.documentTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text("From: ${document.senderName}"),
                    Text("Sent: ${_formatDate(document.createdAt)}"),
                    if (document.fileSize != null)
                      Text("Size: ${_formatFileSize(document.fileSize)}"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (document.description != null) ...[
              Text(
                "Description",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Text(document.description!),
              SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () => _downloadDocument(context, document),
              icon: Icon(Icons.download),
              label: Text("Download Document"),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5. Document Download Functionality
```
Future<void> _downloadDocument(BuildContext context, StudentDocument document) async {
  try {
    // Show progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Downloading Document"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Please wait..."),
            ],
          ),
        );
      },
    );
    
    // Download file from Supabase storage
    final filePath = document.filePath;
    final response = await Supabase.instance.client.storage
        .from('documents')
        .download(filePath);
    
    // Save file to device
    final result = await FileSaver.instance.saveFile(
      name: document.fileName,
      bytes: response,
    );
    
    // Close progress dialog
    Navigator.of(context).pop();
    
    // Show success message
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Document downloaded successfully"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Mark as read if not already read
      if (!document.isRead) {
        await _markAsRead(context, document);
      }
    }
  } catch (e) {
    // Close progress dialog
    Navigator.of(context).pop();
    
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to download document: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### 6. Mark as Read Functionality
```
Future<void> _markAsRead(BuildContext context, StudentDocument document) async {
  try {
    await DocumentService.markAsRead(document.documentId, document.studentId);
    
    // Update local state
    setState(() {
      document.isRead = true;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Document marked as read"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to mark document as read: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## UI/UX Considerations

### 1. Unread Document Indicator
- Show unread document count in the navigation
- Highlight unread documents in the list

### 2. Filtering and Sorting
- Filter by read/unread status
- Sort by date sent (newest first by default)
- Search by document title or sender name

### 3. Empty State
```
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.description, size: 64, color: Colors.grey),
      SizedBox(height: 16),
      Text(
        "No documents received",
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      SizedBox(height: 8),
      Text(
        "Documents sent to you by admins and teachers will appear here",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  ),
)
```

### 4. Student Dashboard Integration
- Add "My Documents" card to student dashboard
- Show count of unread documents
- Quick access to document list

## Technical Considerations

### 1. Performance
- Implement pagination for large document lists
- Cache document metadata locally
- Lazy load document content

### 2. Security
- Ensure students can only access documents sent to them
- Validate document access before download
- Handle expired or deleted documents gracefully

### 3. Error Handling
- Network errors during download
- File not found errors
- Storage access errors
- Local storage errors