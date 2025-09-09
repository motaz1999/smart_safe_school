import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/models.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final AdminService _adminService = AdminService();
  List<UserProfile> _students = [];
  List<SchoolClass> _classes = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('🔍 DEBUG: _loadData - Starting to load data...');
      
      // Check if context is still mounted before proceeding
      if (!mounted) {
        print('❌ DEBUG: Context not mounted in _loadData, aborting');
        return;
      }
      
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      print('🔍 DEBUG: _loadData - Fetching students...');
      final students = await _adminService.getStudents().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout while fetching students');
        },
      );
      
      // Check if context is still mounted after students fetch
      if (!mounted) {
        print('❌ DEBUG: Context not mounted after students fetch, aborting');
        return;
      }
      
      print('🔍 DEBUG: _loadData - Fetching classes...');
      final classes = await _adminService.getClasses().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout while fetching classes');
        },
      );
      
      // Check if context is still mounted after classes fetch
      if (!mounted) {
        print('❌ DEBUG: Context not mounted after classes fetch, aborting');
        return;
      }
      
      print('🔍 DEBUG: _loadData - Updating state with fetched data...');
      setState(() {
        _students = students;
        _classes = classes;
        _isLoading = false;
      });
      
      print('🔍 DEBUG: _loadData - Data loading completed successfully');
    } catch (e) {
      print('❌ DEBUG: _loadData - Error loading data: $e');
      print('❌ DEBUG: _loadData - Error type: ${e.runtimeType}');
      
      // Check if context is still mounted before setting error state
      if (!mounted) {
        print('❌ DEBUG: Context not mounted in error handler, cannot set error state');
        return;
      }
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<UserProfile> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((student) =>
        student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        student.userId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddStudentDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
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
          ),

          // Content
          Expanded(
            child: Stack(
              children: [
                _isLoading
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
                                  onPressed: _loadData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _filteredStudents.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('No students found'),
                                    Text('Add your first student to get started'),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = _filteredStudents[index];
                                    return _buildStudentCard(student);
                                  },
                                ),
                              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(UserProfile student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                student.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(student.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${student.userId}'),
                Text('Class: ${student.className ?? 'Not assigned'}'),
                if (student.gender != null)
                  Text('Gender: ${student.gender?.name}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditStudentDialog(student);
                    break;
                  case 'password':
                    _showChangePasswordDialog(student);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(student);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'password',
                  child: Text('Change Password'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
            isThreeLine: true,
          ),
          // Add a visible button for changing password
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showChangePasswordDialog(student),
                  icon: const Icon(Icons.lock, size: 18),
                  label: const Text('Change Password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(
        classes: _classes,
        onSave: (studentData) async {
          try {
            print('🔍 DEBUG: ManageStudentsScreen - Adding new student: ${studentData['name']}');
            await _adminService.createStudent(
              email: studentData['email'],
              password: studentData['password'],
              name: studentData['name'],
              classId: studentData['classId'],
              parentContact: studentData['parentContact'],
              gender: studentData['gender'],
              phone: studentData['phone'],
            );
            print('🔍 DEBUG: ManageStudentsScreen - Student added successfully, reloading data...');
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student added successfully')),
              );
            }
          } catch (e) {
            print('❌ DEBUG: ManageStudentsScreen - Error adding student: $e');
            print('❌ DEBUG: ManageStudentsScreen - Error type: ${e.runtimeType}');
            if (e is Error) {
              print('❌ DEBUG: ManageStudentsScreen - Stack trace: ${e.stackTrace}');
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding student: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditStudentDialog(UserProfile student) {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(
        student: student,
        classes: _classes,
        onSave: (studentData) async {
          try {
            final updatedStudent = student.copyWith(
              name: studentData['name'],
              phone: studentData['phone'],
              classId: studentData['classId'],
              gender: studentData['gender'],
            );
            await _adminService.updateUserProfile(updatedStudent);
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student updated successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating student: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showChangePasswordDialog(UserProfile student) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(
        user: student,
        onSave: (newPassword) async {
          try {
            await _adminService.changeUserPassword(student.userId, newPassword);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error changing password: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(UserProfile student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.deleteUserProfile(student.id);
                _loadData();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting student: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class StudentFormDialog extends StatefulWidget {
  final UserProfile? student;
  final List<SchoolClass> classes;
  final Function(Map<String, dynamic>) onSave;

  const StudentFormDialog({
    super.key,
    this.student,
    required this.classes,
    required this.onSave,
  });

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentContactController = TextEditingController();
  Gender? _selectedGender;
  String? _selectedClassId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _emailController.text = widget.student!.email;
      _phoneController.text = widget.student!.phone ?? '';
      _parentContactController.text = widget.student!.parentContact ?? '';
      _selectedGender = widget.student!.gender;
      _selectedClassId = widget.student!.classId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Student' : 'Add Student'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: 400,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      if (!isEditing) ...[
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) => value?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (value) => value?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: widget.classes.map((schoolClass) {
                          return DropdownMenuItem(
                            value: schoolClass.id,
                            child: Text(schoolClass.name),
                          );
                        }).toList(),
                        onChanged: _isLoading ? null : (value) => setState(() => _selectedClassId = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone (Optional)'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _parentContactController,
                        decoration: const InputDecoration(labelText: 'Parent Contact'),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Gender>(
                        value: _selectedGender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: Gender.values.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender.name),
                          );
                        }).toList(),
                        onChanged: _isLoading ? null : (value) => setState(() => _selectedGender = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      final data = {
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'password': _passwordController.text,
                        'classId': _selectedClassId!,
                        'parentContact': _parentContactController.text,
                        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
                        'gender': _selectedGender,
                      };
                      await widget.onSave(data);
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  }
                },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  final UserProfile user;
  final Function(String) onSave;

  const ChangePasswordDialog({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Password for ${widget.user.name}'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: 400,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Enter password again',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      await widget.onSave(_passwordController.text);
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  }
                },
          child: const Text('Change Password'),
        ),
      ],
    );
  }
}