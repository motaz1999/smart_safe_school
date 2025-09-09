import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/models.dart';

class ManageClassesContent extends StatefulWidget {
  const ManageClassesContent({super.key});

  @override
  State<ManageClassesContent> createState() => _ManageClassesContentState();
}

class _ManageClassesContentState extends State<ManageClassesContent> {
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
      print('🔍 DEBUG: _loadData - Starting to load classes...');
      
      // Check if context is still mounted before proceeding
      if (!mounted) {
        print('❌ DEBUG: Context not mounted in _loadData, aborting');
        return;
      }
      
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
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
      
      print('🔍 DEBUG: _loadData - Updating state with fetched classes...');
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
      
      print('🔍 DEBUG: _loadData - Classes loading completed successfully');
    } catch (e) {
      print('❌ DEBUG: _loadData - Error loading classes: $e');
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

  List<SchoolClass> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    return _classes.where((schoolClass) =>
        schoolClass.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (schoolClass.gradeLevel?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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

        // Add Class Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () => _showAddClassDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Class'),
            ),
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
            print('🔍 DEBUG: ManageClassesContent - Adding new class: ${classData['name']}');
            await _adminService.createClass(
              name: classData['name'],
              gradeLevel: classData['gradeLevel'],
              capacity: classData['capacity'],
            );
            print('🔍 DEBUG: ManageClassesContent - Class added successfully, reloading data...');
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class added successfully')),
              );
            }
          } catch (e) {
            print('❌ DEBUG: ManageClassesContent - Error adding class: $e');
            print('❌ DEBUG: ManageClassesContent - Error type: ${e.runtimeType}');
            if (e is Error) {
              print('❌ DEBUG: ManageClassesContent - Stack trace: ${e.stackTrace}');
            }
            
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
            print('🔍 DEBUG: ManageClassesContent - Updating class: ${classData['name']}');
            final updatedClass = schoolClass.copyWith(
              name: classData['name'],
              gradeLevel: classData['gradeLevel'],
              capacity: classData['capacity'],
            );
            await _adminService.updateClass(updatedClass);
            print('🔍 DEBUG: ManageClassesContent - Class updated successfully, reloading data...');
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class updated successfully')),
              );
            }
          } catch (e) {
            print('❌ DEBUG: ManageClassesContent - Error updating class: $e');
            print('❌ DEBUG: ManageClassesContent - Error type: ${e.runtimeType}');
            if (e is Error) {
              print('❌ DEBUG: ManageClassesContent - Stack trace: ${e.stackTrace}');
            }
            
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
    // For now, we'll show a simple dialog with student information
    // In a full implementation, this would be a more detailed view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View Students feature coming soon')),
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
                print('🔍 DEBUG: ManageClassesContent - Deleting class: ${schoolClass.name}');
                await _adminService.deleteClass(schoolClass.id);
                print('🔍 DEBUG: ManageClassesContent - Class deleted successfully, reloading data...');
                await _loadData();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class deleted successfully')),
                  );
                }
              } catch (e) {
                print('❌ DEBUG: ManageClassesContent - Error deleting class: $e');
                print('❌ DEBUG: ManageClassesContent - Error type: ${e.runtimeType}');
                if (e is Error) {
                  print('❌ DEBUG: ManageClassesContent - Stack trace: ${e.stackTrace}');
                }
                
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
  bool _isLoading = false;

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
                        'gradeLevel': _gradeLevelController.text.isEmpty ? null : _gradeLevelController.text,
                        'capacity': int.parse(_capacityController.text),
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