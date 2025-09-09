import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final AdminService _adminService = AdminService();
  final SupabaseClient _supabase = SupabaseConfig.client;
  List<UserProfile> _teachers = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final teachers = await _adminService.getTeachers();
      final subjects = await _adminService.getSubjects();

      setState(() {
        _teachers = teachers;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<UserProfile> get _filteredTeachers {
    if (_searchQuery.isEmpty) return _teachers;
    return _teachers.where((teacher) =>
        teacher.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        teacher.userId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTeacherDialog(),
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
                labelText: 'Search teachers...',
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
            child: _isLoading
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
                    : _filteredTeachers.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No teachers found'),
                                Text('Add your first teacher to get started'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredTeachers.length,
                              itemBuilder: (context, index) {
                                final teacher = _filteredTeachers[index];
                                return _buildTeacherCard(teacher);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(UserProfile teacher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                teacher.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(teacher.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${teacher.userId}'),
                if (teacher.phone != null)
                  Text('Phone: ${teacher.phone}'),
                Text('Subjects: Loading...'), // Will be loaded separately
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditTeacherDialog(teacher);
                    break;
                  case 'subjects':
                    _showAssignSubjectsDialog(teacher);
                    break;
                  case 'password':
                    _showChangePasswordDialog(teacher);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(teacher);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'subjects',
                  child: Text('Assign Subjects'),
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
                  onPressed: () => _showChangePasswordDialog(teacher),
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

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder: (context) => TeacherFormDialog(
        onSave: (teacherData) async {
          try {
            await _adminService.createTeacher(
              email: teacherData['email'],
              password: teacherData['password'],
              name: teacherData['name'],
              gender: teacherData['gender'],
              phone: teacherData['phone'],
            );
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Teacher added successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding teacher: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditTeacherDialog(UserProfile teacher) {
    showDialog(
      context: context,
      builder: (context) => TeacherFormDialog(
        teacher: teacher,
        onSave: (teacherData) async {
          try {
            final updatedTeacher = teacher.copyWith(
              name: teacherData['name'],
              phone: teacherData['phone'],
              gender: teacherData['gender'],
            );
            await _adminService.updateUserProfile(updatedTeacher);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Teacher updated successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating teacher: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showAssignSubjectsDialog(UserProfile teacher) {
    showDialog(
      context: context,
      builder: (context) => SubjectAssignmentDialog(
        teacher: teacher,
        subjects: _subjects,
        onSave: (subjectIds) async {
          try {
            // Update teacher subjects
            await _supabase.from('teacher_subjects').delete().eq('teacher_id', teacher.id);
            for (final subjectId in subjectIds) {
              await _supabase.from('teacher_subjects').insert({
                'teacher_id': teacher.id,
                'subject_id': subjectId,
              });
            }
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subjects assigned successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error assigning subjects: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showChangePasswordDialog(UserProfile teacher) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(
        user: teacher,
        onSave: (newPassword) async {
          try {
            await _adminService.changeUserPassword(teacher.userId, newPassword);
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

  void _showDeleteConfirmation(UserProfile teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Are you sure you want to delete ${teacher.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.deleteUserProfile(teacher.id);
                _loadData();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teacher deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting teacher: $e')),
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

class TeacherFormDialog extends StatefulWidget {
  final UserProfile? teacher;
  final Function(Map<String, dynamic>) onSave;

  const TeacherFormDialog({
    super.key,
    this.teacher,
    required this.onSave,
  });

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  Gender? _selectedGender;

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _nameController.text = widget.teacher!.name;
      _emailController.text = widget.teacher!.email;
      _phoneController.text = widget.teacher!.phone ?? '';
      _selectedGender = widget.teacher!.gender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.teacher != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Teacher' : 'Add Teacher'),
      content: SizedBox(
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
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone (Optional)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Gender>(
                  decoration: const InputDecoration(labelText: 'Gender'),
                  value: _selectedGender,
                  items: Gender.values.map((gender) {
                    return DropdownMenuItem<Gender>(
                      value: gender,
                      child: Text(gender.name[0].toUpperCase() + gender.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'name': _nameController.text,
                'email': _emailController.text,
                'password': _passwordController.text,
                'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
                'gender': _selectedGender,
              };
              widget.onSave(data);
              Navigator.of(context).pop();
            }
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

class SubjectAssignmentDialog extends StatefulWidget {
  final UserProfile teacher;
  final List<Subject> subjects;
  final Function(List<String>) onSave;

  const SubjectAssignmentDialog({
    super.key,
    required this.teacher,
    required this.subjects,
    required this.onSave,
  });

  @override
  State<SubjectAssignmentDialog> createState() => _SubjectAssignmentDialogState();
}

class _SubjectAssignmentDialogState extends State<SubjectAssignmentDialog> {
  late Set<String> _selectedSubjectIds;

  @override
  void initState() {
    super.initState();
    _selectedSubjectIds = <String>{}; // Will be loaded from database
    _loadTeacherSubjects();
  }

  Future<void> _loadTeacherSubjects() async {
    try {
      final response = await SupabaseConfig.client
          .from('teacher_subjects')
          .select('subject_id')
          .eq('teacher_id', widget.teacher.id);
      
      setState(() {
        _selectedSubjectIds = Set<String>.from(
          response.map((item) => item['subject_id'] as String)
        );
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Subjects to ${widget.teacher.name}'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: widget.subjects.isEmpty
            ? const Center(child: Text('No subjects available'))
            : ListView.builder(
                itemCount: widget.subjects.length,
                itemBuilder: (context, index) {
                  final subject = widget.subjects[index];
                  return CheckboxListTile(
                    title: Text(subject.name),
                    subtitle: Text(subject.code),
                    value: _selectedSubjectIds.contains(subject.id),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSubjectIds.add(subject.id);
                        } else {
                          _selectedSubjectIds.remove(subject.id);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedSubjectIds.toList());
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
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