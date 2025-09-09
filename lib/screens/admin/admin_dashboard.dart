import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/document_service.dart';
import '../../models/models.dart';
import 'manage_students.dart';
import 'manage_teachers.dart';
import 'manage_classes.dart';
import 'manage_subjects.dart';
import 'manage_timetable.dart';
import 'admin_reports.dart';
import 'absence_reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  final DocumentService _documentService = DocumentService();
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await _adminService.getDashboardStats();
      
      setState(() {
        _dashboardStats = stats;
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
    print('🔍 DEBUG: AdminDashboard build() - Implementing fixed sidebar navigation');
    print('🔍 DEBUG: New layout structure - Fixed Sidebar: ✓, Main Content: ✓');
    print('🔍 DEBUG: Navigation method: Fixed sidebar layout');
    
    return Scaffold(
      body: Row(
        children: [
          // Fixed Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _buildFixedSidebar(context),
          ),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'profile':
                                _showProfile();
                                break;
                              case 'logout':
                                _handleLogout();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: ListTile(
                                leading: Icon(Icons.person),
                                title: Text('Profile'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: ListTile(
                                leading: Icon(Icons.logout),
                                title: Text('Logout'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Main Dashboard Content
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedSidebar(BuildContext context) {
    return Column(
      children: [
        // Sidebar Header with user info
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      authProvider.currentUser?.name
                              .substring(0, 1)
                              .toUpperCase() ??
                          'A',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.currentUser?.name ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authProvider.currentUser?.schoolName ?? 'School Administrator',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
        
        // Navigation Menu Items
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: true,
                  onTap: () {
                    print('🔍 DEBUG: Dashboard selected from fixed sidebar');
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.class_,
                  title: 'Manage Classes',
                  onTap: () {
                    print('🔍 DEBUG: Manage Classes selected from fixed sidebar');
                    _navigateToClasses();
                  },
                ),
                // Move Absence Reports to early position for testing
                _buildSidebarItem(
                  icon: Icons.event_busy,
                  title: 'Absence Reports',
                  onTap: () {
                    print('🔍 DEBUG: Absence Reports selected from fixed sidebar');
                    _navigateToAbsenceReports();
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.people,
                  title: 'Manage Students',
                  onTap: () {
                    print('🔍 DEBUG: Manage Students selected from fixed sidebar');
                    _navigateToStudents();
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.school,
                  title: 'Manage Teachers',
                  onTap: () {
                    print('🔍 DEBUG: Manage Teachers selected from fixed sidebar');
                    _navigateToTeachers();
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.schedule,
                  title: 'Manage Timetable',
                  onTap: () {
                    print('🔍 DEBUG: Manage Timetable selected from fixed sidebar');
                    _navigateToTimetable();
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.book,
                  title: 'Manage Subjects',
                  onTap: () {
                    print('🔍 DEBUG: Manage Subjects selected from fixed sidebar');
                    _navigateToSubjects();
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.description,
                  title: 'Send Documents',
                  onTap: () {
                    print('🔍 DEBUG: Send Documents selected from fixed sidebar');
                    _showSendDocumentDialog();
                  },
                ),
                const SizedBox(height: 20),
                _buildSidebarItem(
                  icon: Icons.analytics,
                  title: 'View Reports',
                  onTap: () {
                    print('🔍 DEBUG: View Reports selected from fixed sidebar');
                    _navigateToReports();
                  },
                ),
                // Add some bottom padding to ensure all items are accessible
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        
        // Footer with logout
        Container(
          padding: const EdgeInsets.all(16),
          child: _buildSidebarItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              print('🔍 DEBUG: Logout selected from fixed sidebar');
              _handleLogout();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            authProvider.currentUser?.name
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                authProvider.currentUser?.name ?? 'Admin',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                authProvider.currentUser?.schoolName ?? 'School Administrator',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Statistics Cards (without Quick Actions)
            Text(
              'School Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 32),

          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_dashboardStats == null) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Students',
          _dashboardStats!['students_count'].toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Teachers',
          _dashboardStats!['teachers_count'].toString(),
          Icons.school,
          Colors.green,
        ),
        _buildStatCard(
          'Classes',
          _dashboardStats!['classes_count'].toString(),
          Icons.class_,
          Colors.orange,
        ),
        _buildStatCard(
          'Subjects',
          _dashboardStats!['subjects_count'].toString(),
          Icons.book,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }



  void _showProfile() {
    // TODO: Implement profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile screen - Coming Soon')),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _navigateToStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageStudentsScreen()),
    );
  }

  void _navigateToTeachers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageTeachersScreen()),
    );
  }

  void _navigateToClasses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageClassesScreen()),
    );
  }

  void _navigateToSubjects() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageSubjectsScreen()),
    );
  }

  void _navigateToTimetable() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageTimetableScreen()),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
    );
  }

  void _navigateToAbsenceReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AbsenceReportsScreen()),
    );
  }

  void _showSendDocumentDialog() async {
    // Get current user profile
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Get all students in the school
    List<UserProfile> students = [];
    try {
      students = await _adminService.getStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
      return;
    }

    // Show document sending dialog
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return _AdminDocumentSendingDialog(
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

class _AdminDocumentSendingDialog extends StatefulWidget {
  final List<UserProfile> students;
  final DocumentService documentService;
  final String senderId;
  final int schoolId;

  const _AdminDocumentSendingDialog({
    required this.students,
    required this.documentService,
    required this.senderId,
    required this.schoolId,
  });

  @override
  State<_AdminDocumentSendingDialog> createState() => _AdminDocumentSendingDialogState();
}

class _AdminDocumentSendingDialogState extends State<_AdminDocumentSendingDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  PlatformFile? _selectedFile;
  List<String> _selectedStudentIds = [];
  bool _isSending = false;
  String _searchQuery = '';

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

  List<UserProfile> get _filteredStudents {
    if (_searchQuery.isEmpty) return widget.students;
    return widget.students.where((student) =>
        student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        student.userId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (student.className != null && student.className!.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
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
    print('DEBUG: _pickFile called in admin dialog');
    try {
      final file = await widget.documentService.pickFile();
      print('DEBUG: _pickFile got result in admin dialog: ${file != null ? 'got file' : 'no file'}');
      if (file != null) {
        setState(() {
          _selectedFile = file;
        });
        print('DEBUG: _pickFile updated state with file in admin dialog: ${file.name}');
      } else {
        print('DEBUG: _pickFile no file selected in admin dialog');
      }
    } catch (e) {
      print('ERROR: _pickFile failed in admin dialog: $e');
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
        const SnackBar(content: Text('Please select a file')),
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
        senderType: 'admin',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        filePath: filePath,
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
      title: const Text('Send Document to Students'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search students...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
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
                height: 300,
                child: ListView.builder(
                  itemCount: _filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    return CheckboxListTile(
                      title: Text(student.name),
                      subtitle: Text('${student.userId} - ${student.className ?? 'No class'}'),
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