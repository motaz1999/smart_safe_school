import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../../services/teacher_service.dart';
import '../../services/document_service.dart';
import './grades_screen.dart';

class ClassesScreen extends StatefulWidget {
  final AcademicYear academicYear;
  final Semester semester;
  
  const ClassesScreen({
    super.key,
    required this.academicYear,
    required this.semester,
  });

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final TeacherService _teacherService = TeacherService();
  final DocumentService _documentService = DocumentService();
  
  List<TeacherClassSubject> _classes = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load classes from the teacher service
      final classes = await _teacherService.getTeacherClassesAndSubjects();
      
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSafeSchool'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Sign out the user
              Provider.of<AuthProvider>(context, listen: false).signOut();
              // Navigate back to login screen
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            color: Colors.white,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadClasses,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClasses,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildClassesList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Academic Year: ${widget.academicYear.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Semester: ${widget.semester.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage your classes',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Classes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (_classes.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No classes found for this academic year/semester'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadClasses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else
          for (final classItem in _classes)
            _buildClassCard(classItem),
      ],
    );
  }

  Widget _buildClassCard(TeacherClassSubject classData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          '${classData.className} - ${classData.subjectName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${classData.studentCount} students'),
            Text('${classData.subjectCode}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _showClassDetails(classData);
        },
      ),
    );
  }

  void _showClassDetails(TeacherClassSubject classData) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${classData.className} - ${classData.subjectName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Students: ${classData.studentCount}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Subject Code: ${classData.subjectCode}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showSendDocumentDialog(classData);
                      },
                      child: const Text('Send Document'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to grades screen for this class
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TeacherGradesScreen(
                              classSubject: classData,
                              academicYear: widget.academicYear,
                              semester: widget.semester,
                            ),
                          ),
                        );
                      },
                      child: const Text('Enter Grades'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSendDocumentDialog(TeacherClassSubject classData) async {
    // Get students in this class
    List<UserProfile> students = [];
    try {
      students = await _teacherService.getStudentsInClass(
        classData.classId,
        classData.subjectId,
      );
      
      // Check if students list is empty
      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students found in this class')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
      return;
    }

    // Get current user profile
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Show document sending dialog
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return _DocumentSendingDialog(
          classData: classData,
          students: students,
          documentService: _documentService,
          senderId: currentUser.id,
          schoolId: currentUser.schoolId,
        );
      },
    );

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document sent successfully')),
      );
    } else if (result != null && result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send document: ${result['error']}')),
      );
    }
  }
}

class _DocumentSendingDialog extends StatefulWidget {
  final TeacherClassSubject classData;
  final List<UserProfile> students;
  final DocumentService documentService;
  final String senderId;
  final int schoolId;

  const _DocumentSendingDialog({
    required this.classData,
    required this.students,
    required this.documentService,
    required this.senderId,
    required this.schoolId,
  });

  @override
  State<_DocumentSendingDialog> createState() => _DocumentSendingDialogState();
}

class _DocumentSendingDialogState extends State<_DocumentSendingDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  PlatformFile? _selectedFile;
  List<String> _selectedStudentIds = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Initially select all students
    _selectedStudentIds = widget.students.map((s) => s.id).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedStudentIds.length == widget.students.length) {
        _selectedStudentIds.clear();
      } else {
        _selectedStudentIds = widget.students.map((s) => s.id).toList();
      }
    });
  }

  
    Future<void> _pickFile() async {
      print('DEBUG: _pickFile called');
      try {
        final file = await widget.documentService.pickFile();
        print('DEBUG: _pickFile got result: ${file != null ? 'got file' : 'no file'}');
        if (file != null) {
          setState(() {
            _selectedFile = file;
          });
          print('DEBUG: _pickFile updated state with file: ${file.name}');
        } else {
          print('DEBUG: _pickFile no file selected');
        }
      } catch (e) {
        print('ERROR: _pickFile failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick file: $e')),
          );
        }
      }
    }
  
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
      // Ensure the documents bucket exists and policies are set up
      try {
        await widget.documentService.ensureDocumentsBucketExists();
        await widget.documentService.setupBucketPolicies();
      } catch (bucketError) {
        // Handle bucket errors gracefully
        print('Warning: Could not ensure documents bucket exists: $bucketError');
        // Continue with upload even if bucket setup fails
      }
      
      // Upload the file to Supabase storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';
      final filePath = await widget.documentService.uploadFile(_selectedFile!, fileName);
      print('Uploaded file with path: $filePath');

      // Create the document record in the database
      final mimeType = lookupMimeType(_selectedFile!.name) ?? 'application/octet-stream';
      final document = await widget.documentService.uploadDocument(
        schoolId: widget.schoolId,
        senderId: widget.senderId,
        senderType: 'teacher',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        filePath: filePath, // This is now correctly formatted
        fileName: _selectedFile!.name,
        fileSize: _selectedFile!.size,
        mimeType: mimeType,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Send Document to ${widget.classData.className}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.classData.subjectName} - ${widget.classData.subjectCode}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(_selectedFile == null ? 'Select File' : 'Change File'),
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 16),
                Text('Selected file: ${_selectedFile!.name}'),
                Text('Size: ${_selectedFile!.size} bytes'),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Students (${_selectedStudentIds.length}/${widget.students.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: _toggleSelectAll,
                    child: Text(
                      _selectedStudentIds.length == widget.students.length
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) {
                    final student = widget.students[index];
                    return CheckboxListTile(
                      title: Text(student.name),
                      value: _selectedStudentIds.contains(student.id),
                      onChanged: (value) {
                        _toggleStudentSelection(student.id);
                      },
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendDocument,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Document'),
        ),
      ],
    );
  }
}