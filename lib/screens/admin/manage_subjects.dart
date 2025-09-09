import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/models.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final AdminService _adminService = AdminService();
  List<Subject> _subjects = [];
  List<UserProfile> _teachers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAndInitializeDefaultSubjects();
  }

  Future<void> _checkAndInitializeDefaultSubjects() async {
    try {
      // Check if school has subjects, and create default subjects if not
      final subjects = await _adminService.initializeDefaultSubjectsIfNeeded();
      
      // Update the state with the subjects (either existing or newly created default ones)
      if (mounted) {
        setState(() {
          _subjects = subjects;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final subjects = await _adminService.getSubjects();
      final teachers = await _adminService.getTeachers();

      setState(() {
        _subjects = subjects;
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Subject> get _filteredSubjects {
    if (_searchQuery.isEmpty) return _subjects;
    return _subjects.where((subject) =>
        subject.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        subject.code.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSubjectDialog(),
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
                labelText: 'Search subjects...',
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
                    : _filteredSubjects.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No subjects found'),
                                Text('Add your first subject to get started'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredSubjects.length,
                              itemBuilder: (context, index) {
                                final subject = _filteredSubjects[index];
                                return _buildSubjectCard(subject);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Code: ${subject.code}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (subject.description != null && subject.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subject.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditSubjectDialog(subject);
                        break;
                      case 'teachers':
                        _showAssignTeachersDialog(subject);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(subject);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'teachers',
                      child: ListTile(
                        leading: Icon(Icons.person_add),
                        title: Text('Assign Teachers'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Teachers: Loading...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => SubjectFormDialog(
        teachers: _teachers,
        onSave: (subjectData) async {
          try {
            print('🔍 DEBUG: ManageSubjectsScreen - Adding new subject: ${subjectData['name']}');
            await _adminService.createSubject(
              name: subjectData['name'],
              code: subjectData['code'],
              description: subjectData['description'],
              teacherIds: subjectData['teacherIds'],
            );
            print('🔍 DEBUG: ManageSubjectsScreen - Subject added successfully');
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subject added successfully')),
              );
            }
          } catch (e) {
            print('🔍 DEBUG: ManageSubjectsScreen - Error adding subject: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding subject: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditSubjectDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => SubjectFormDialog(
        subject: subject,
        teachers: _teachers,
        onSave: (subjectData) async {
          try {
            final updatedSubject = subject.copyWith(
              name: subjectData['name'],
              code: subjectData['code'],
              description: subjectData['description'],
            );
            await _adminService.updateSubject(updatedSubject);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subject updated successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating subject: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showAssignTeachersDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => TeacherAssignmentDialog(
        subject: subject,
        teachers: _teachers,
        onSave: (teacherIds) async {
          try {
            // This would need to be implemented in AdminService
            // For now, we'll show a placeholder message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Teacher assignment feature coming soon')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error assigning teachers: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.deleteSubject(subject.id);
                _loadData();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subject deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting subject: $e')),
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

class SubjectFormDialog extends StatefulWidget {
  final Subject? subject;
  final List<UserProfile> teachers;
  final Function(Map<String, dynamic>) onSave;

  const SubjectFormDialog({
    super.key,
    this.subject,
    required this.teachers,
    required this.onSave,
  });

  @override
  State<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  Set<String> _selectedTeacherIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _codeController.text = widget.subject!.code;
      _descriptionController.text = widget.subject!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subject != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Subject' : 'Add Subject'),
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
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Subject Code'),
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  maxLines: 3,
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 16),
                  const Text('Assign Teachers (Optional):'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: widget.teachers.isEmpty
                        ? const Center(child: Text('No teachers available'))
                        : ListView.builder(
                            itemCount: widget.teachers.length,
                            itemBuilder: (context, index) {
                              final teacher = widget.teachers[index];
                              return CheckboxListTile(
                                title: Text(teacher.name),
                                subtitle: Text(teacher.userId),
                                value: _selectedTeacherIds.contains(teacher.id),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedTeacherIds.add(teacher.id);
                                    } else {
                                      _selectedTeacherIds.remove(teacher.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
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
                'code': _codeController.text,
                'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
                'teacherIds': _selectedTeacherIds.toList(),
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

class TeacherAssignmentDialog extends StatefulWidget {
  final Subject subject;
  final List<UserProfile> teachers;
  final Function(List<String>) onSave;

  const TeacherAssignmentDialog({
    super.key,
    required this.subject,
    required this.teachers,
    required this.onSave,
  });

  @override
  State<TeacherAssignmentDialog> createState() => _TeacherAssignmentDialogState();
}

class _TeacherAssignmentDialogState extends State<TeacherAssignmentDialog> {
  late Set<String> _selectedTeacherIds;

  @override
  void initState() {
    super.initState();
    _selectedTeacherIds = <String>{}; // Will be loaded from database
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Teachers to ${widget.subject.name}'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: widget.teachers.isEmpty
            ? const Center(child: Text('No teachers available'))
            : ListView.builder(
                itemCount: widget.teachers.length,
                itemBuilder: (context, index) {
                  final teacher = widget.teachers[index];
                  return CheckboxListTile(
                    title: Text(teacher.name),
                    subtitle: Text(teacher.userId),
                    value: _selectedTeacherIds.contains(teacher.id),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedTeacherIds.add(teacher.id);
                        } else {
                          _selectedTeacherIds.remove(teacher.id);
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
            widget.onSave(_selectedTeacherIds.toList());
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}