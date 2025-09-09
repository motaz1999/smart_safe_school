# Document Sending UI Plan

## Overview
This document outlines the UI components needed for admins and teachers to send documents to students.

## Admin UI Components

### 1. Document Management Section
- Add a new section to the admin dashboard for document management
- Could be a new navigation item "Send Documents" or integrated into "Manage Students"

### 2. Send Document Screen
- AppBar with title "Send Document"
- File selection area
- Document metadata form (title, description)
- Student selection component
- Send button

### 3. File Selection Component
```
Card(
  child: Padding(
    padding: EdgeInsets.all(16.0),
    child: Column(
      children: [
        Icon(Icons.upload_file, size: 48, color: Colors.blue),
        SizedBox(height: 16),
        Text("Select PDF Document"),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectFile,
          child: Text("Choose File"),
        ),
        if (_selectedFile != null) ...[
          SizedBox(height: 16),
          Text(_selectedFile.name),
          Text("${_selectedFile.size} bytes"),
        ],
      ],
    ),
  ),
)
```

### 4. Document Metadata Form
```
Form(
  child: Column(
    children: [
      TextFormField(
        controller: _titleController,
        decoration: InputDecoration(labelText: "Document Title"),
        validator: (value) => value?.isEmpty ? "Title is required" : null,
      ),
      TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(labelText: "Description (Optional)"),
        maxLines: 3,
      ),
    ],
  ),
)
```

### 5. Student Selection Component
```
Card(
  child: Padding(
    padding: EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Students", style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: "Search Students",
            prefixIcon: Icon(Icons.search),
          ),
        ),
        SizedBox(height: 16),
        // List of students with checkboxes
        ListView.builder(
          shrinkWrap: true,
          itemCount: _filteredStudents.length,
          itemBuilder: (context, index) {
            final student = _filteredStudents[index];
            return CheckboxListTile(
              title: Text(student.name),
              subtitle: Text(student.className ?? ""),
              value: _selectedStudents.contains(student.id),
              onChanged: (bool? selected) {
                _toggleStudentSelection(student.id, selected ?? false);
              },
            );
          },
        ),
      ],
    ),
  ),
)
```

## Teacher UI Components

### 1. Document Management Section
- Add a new section to the teacher dashboard
- Could be a new navigation item "Send Documents" or integrated into "My Classes"

### 2. Send Document Screen
- Similar to admin version but with teacher-specific student filtering
- Only show students from classes taught by the teacher

### 3. Class-Based Student Selection
```
Card(
  child: Padding(
    padding: EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Classes", style: Theme.of(context).textTheme.titleMedium),
        // List of classes with checkboxes
        for (var classItem in _teacherClasses) ...[
          CheckboxListTile(
            title: Text(classItem.name),
            value: _selectedClasses.contains(classItem.id),
            onChanged: (bool? selected) {
              _toggleClassSelection(classItem.id, selected ?? false);
            },
          ),
        ],
        SizedBox(height: 16),
        Text("Select Students", style: Theme.of(context).textTheme.titleMedium),
        // List of students from selected classes
        for (var student in _studentsFromSelectedClasses) ...[
          CheckboxListTile(
            title: Text(student.name),
            subtitle: Text(student.className ?? ""),
            value: _selectedStudents.contains(student.id),
            onChanged: (bool? selected) {
              _toggleStudentSelection(student.id, selected ?? false);
            },
          ),
        ],
      ],
    ),
  ),
)
```

## Shared Components

### 1. Upload Progress Dialog
```
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text("Uploading Document"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(value: _uploadProgress),
          SizedBox(height: 16),
          Text("$_uploadProgressText%"),
        ],
      ),
    );
  },
);
```

### 2. Success Confirmation
```
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("Document sent successfully to ${_selectedStudents.length} students"),
    backgroundColor: Colors.green,
  ),
);
```

## Navigation Integration

### Admin Dashboard
- Add "Send Documents" to the sidebar navigation
- Place it under "Manage Students" or as a separate section

### Teacher Dashboard
- Add "Send Documents" to the main dashboard grid
- Or add it to the classes section

## Responsive Design Considerations
- Ensure the UI works well on both mobile and tablet screens
- Use appropriate layout for different screen sizes
- Consider modal sheets for student selection on smaller screens