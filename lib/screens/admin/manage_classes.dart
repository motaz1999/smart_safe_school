import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/models.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final AdminService _adminService = AdminService();
  List<SchoolClass> _classes = [];
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

      final classes = await _adminService.getClasses();

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

  List<SchoolClass> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    return _classes.where((schoolClass) =>
        schoolClass.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (schoolClass.gradeLevel?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddClassDialog(),
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
                labelText: 'Search classes...',
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
                    : _filteredClasses.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No classes found'),
                                Text('Add your first class to get started'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredClasses.length,
                              itemBuilder: (context, index) {
                                final schoolClass = _filteredClasses[index];
                                return _buildClassCard(schoolClass);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(SchoolClass schoolClass) {
    final enrollmentPercentage = schoolClass.capacity > 0
        ? ((schoolClass.currentEnrollment ?? 0) / schoolClass.capacity)
        : 0.0;
    
    Color enrollmentColor = Colors.green;
    if (enrollmentPercentage > 0.8) {
      enrollmentColor = Colors.orange;
    }
    if (enrollmentPercentage >= 1.0) {
      enrollmentColor = Colors.red;
    }

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
                        schoolClass.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (schoolClass.gradeLevel != null)
                        Text(
                          'Grade: ${schoolClass.gradeLevel}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditClassDialog(schoolClass);
                        break;
                      case 'students':
                        _showClassStudents(schoolClass);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(schoolClass);
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
                      value: 'students',
                      child: ListTile(
                        leading: Icon(Icons.people),
                        title: Text('View Students'),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: enrollmentColor),
                const SizedBox(width: 4),
                Text(
                  '${schoolClass.currentEnrollment ?? 0}/${schoolClass.capacity} students',
                  style: TextStyle(color: enrollmentColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: enrollmentPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(enrollmentColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(
        onSave: (classData) async {
          try {
            await _adminService.createClass(
              name: classData['name'],
              gradeLevel: classData['gradeLevel'],
              capacity: classData['capacity'],
            );
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class added successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding class: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditClassDialog(SchoolClass schoolClass) {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(
        schoolClass: schoolClass,
        onSave: (classData) async {
          try {
            final updatedClass = schoolClass.copyWith(
              name: classData['name'],
              gradeLevel: classData['gradeLevel'],
              capacity: classData['capacity'],
            );
            await _adminService.updateClass(updatedClass);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class updated successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating class: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showClassStudents(SchoolClass schoolClass) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassStudentsScreen(schoolClass: schoolClass),
      ),
    );
  }

  void _showDeleteConfirmation(SchoolClass schoolClass) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${schoolClass.name}"?'),
            const SizedBox(height: 8),
            if ((schoolClass.currentEnrollment ?? 0) > 0)
              Text(
                'Warning: This class has ${schoolClass.currentEnrollment ?? 0} enrolled students.',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.deleteClass(schoolClass.id);
                _loadData();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting class: $e')),
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

class ClassFormDialog extends StatefulWidget {
  final SchoolClass? schoolClass;
  final Function(Map<String, dynamic>) onSave;

  const ClassFormDialog({
    super.key,
    this.schoolClass,
    required this.onSave,
  });

  @override
  State<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gradeLevelController = TextEditingController();
  final _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.schoolClass != null) {
      _nameController.text = widget.schoolClass!.name;
      _gradeLevelController.text = widget.schoolClass!.gradeLevel ?? '';
      _capacityController.text = widget.schoolClass!.capacity.toString();
    } else {
      _capacityController.text = '30'; // Default capacity
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schoolClass != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Class' : 'Add Class'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradeLevelController,
                decoration: const InputDecoration(labelText: 'Grade Level (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Required';
                  final capacity = int.tryParse(value!);
                  if (capacity == null || capacity <= 0) {
                    return 'Must be a positive number';
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'name': _nameController.text,
                'gradeLevel': _gradeLevelController.text.isEmpty ? null : _gradeLevelController.text,
                'capacity': int.parse(_capacityController.text),
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

class ClassStudentsScreen extends StatefulWidget {
  final SchoolClass schoolClass;

  const ClassStudentsScreen({super.key, required this.schoolClass});

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  final AdminService _adminService = AdminService();
  List<UserProfile> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final students = await _adminService.getStudents(classId: widget.schoolClass.id);

      setState(() {
        _students = students;
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
        title: Text('${widget.schoolClass.name} Students'),
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
                        onPressed: _loadStudents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _students.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No students in this class'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                student.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(student.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${student.userId}'),
                                if (student.parentContact != null)
                                  Text('Parent: ${student.parentContact}'),
                              ],
                            ),
                            isThreeLine: student.parentContact != null,
                          ),
                        );
                      },
                    ),
    );
  }
}