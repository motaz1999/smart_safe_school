import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../../services/teacher_service.dart';

class TeacherGradesScreen extends StatefulWidget {
  final TeacherClassSubject classSubject;
  final AcademicYear academicYear;
  final Semester semester;
  
  const TeacherGradesScreen({
    super.key,
    required this.classSubject,
    required this.academicYear,
    required this.semester,
  });

  @override
  State<TeacherGradesScreen> createState() => _TeacherGradesScreenState();
}

class _TeacherGradesScreenState extends State<TeacherGradesScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final TeacherService _teacherService = TeacherService();
  
  List<UserProfile> _students = [];
  List<Grade> _grades = [];
  bool _isLoading = true;
  String? _error;
  int _gradeNumber = 1;
  
  // Search controller for student filtering
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _filteredStudents = [];
  
  // Controllers for grade text fields
  List<TextEditingController> _gradeControllers = [];
  List<TextEditingController> _notesControllers = [];
  
  final List<int> _gradeNumbers = [1, 2];
  
  @override
  void initState() {
    super.initState();
    _loadStudentsAndGrades();
  }
  
  @override
  void dispose() {
    // Dispose of controllers when the widget is disposed
    _searchController.dispose();
    for (var controller in _gradeControllers) {
      controller.dispose();
    }
    for (var controller in _notesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudentsAndGrades() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load students in the class
      final students = await _teacherService.getStudentsInClass(
        widget.classSubject.classId,
        widget.classSubject.subjectId
      );
      
      // Load existing grades for the selected academic year and semester
      final grades = await _teacherService.getGrades(
        widget.classSubject.classId,
        widget.classSubject.subjectId,
        widget.academicYear.id, // Use academic year ID
        widget.semester.id,
        _gradeNumber
      );
      
      setState(() {
        _students = students;
        _filteredStudents = students;
        _grades = grades;
        _isLoading = false;
        
        // Initialize controllers with the loaded data
        _initializeControllers(students, grades);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _initializeControllers(List<UserProfile> students, List<Grade> grades) {
    // Dispose of existing controllers if they exist
    if (_gradeControllers.isNotEmpty) {
      for (var controller in _gradeControllers) {
        controller.dispose();
      }
    }
    if (_notesControllers.isNotEmpty) {
      for (var controller in _notesControllers) {
        controller.dispose();
      }
    }
    
    // Create new controllers
    _gradeControllers = List.generate(students.length, (index) {
      // Find existing grade for this student
      final existingGrade = grades.firstWhere(
        (grade) => grade.studentId == students[index].id,
        orElse: () => Grade(
          id: '',
          createdAt: DateTime.now(),
          studentId: students[index].id,
          subjectId: widget.classSubject.subjectId,
          teacherId: '', // Will be set when saving
          semesterId: widget.semester.id,
          gradeNumber: _gradeNumber,
          gradeValue: 0.0,
          maxGrade: 20.0,
          studentName: students[index].name,
          subjectName: widget.classSubject.subjectName,
          subjectCode: widget.classSubject.subjectCode,
        ),
      );
      // Only set text if gradeValue is not 0.0 (default) or if it was explicitly set to 0.0
      final gradeText = existingGrade.gradeValue != 0.0 ||
                     (existingGrade.id.isNotEmpty && existingGrade.gradeValue == 0.0)
                     ? existingGrade.gradeValue.toString()
                     : '';
      return TextEditingController(text: gradeText);
    });
    
    _notesControllers = List.generate(students.length, (index) {
      // Find existing grade for this student
      final existingGrade = grades.firstWhere(
        (grade) => grade.studentId == students[index].id,
        orElse: () => Grade(
          id: '',
          createdAt: DateTime.now(),
          studentId: students[index].id,
          subjectId: widget.classSubject.subjectId,
          teacherId: '', // Will be set when saving
          semesterId: widget.semester.id,
          gradeNumber: _gradeNumber,
          gradeValue: 0.0,
          maxGrade: 20.0,
          notes: '',
          studentName: students[index].name,
          subjectName: widget.classSubject.subjectName,
          subjectCode: widget.classSubject.subjectCode,
        ),
      );
      return TextEditingController(text: existingGrade.notes ?? '');
    });
  }
  
  // Filter students based on search text
  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where((student) =>
                student.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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
                        onPressed: _loadStudentsAndGrades,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStudentsAndGrades,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildGradeFilters(),
                      const SizedBox(height: 24),
                      _buildGradesList(),
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
              'Grade Management',
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
              'Enter grades for ${_students.length} students',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Search field for students
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Students',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterStudents,
            ),
            const SizedBox(height: 16),
            // Sort options
            Row(
              children: [
                const Text('Sort by:'),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: 'name',
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'grade', child: Text('Grade')),
                  ],
                  onChanged: (value) {
                    // TODO: Implement sorting functionality
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Grade Number:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _gradeNumber,
                  items: _gradeNumbers.map((number) {
                    return DropdownMenuItem(
                      value: number,
                      child: Text('Grade $number'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gradeNumber = value!;
                      _loadStudentsAndGrades();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveGrades,
              child: const Text('Save Grades'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Grades',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (_filteredStudents.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No students found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStudentsAndGrades,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else
          for (int i = 0; i < _filteredStudents.length; i++)
            _buildStudentGradeCard(_filteredStudents[i], _students.indexOf(_filteredStudents[i])),
      ],
    );
  }

  Widget _buildStudentGradeCard(UserProfile student, int index) {
    // Find if this student has an existing grade
    final existingGrade = _grades.firstWhere(
      (grade) => grade.studentId == student.id,
      orElse: () => Grade(
        id: '',
        createdAt: DateTime.now(),
        studentId: student.id,
        subjectId: widget.classSubject.subjectId,
        teacherId: '',
        semesterId: widget.semester.id,
        gradeNumber: _gradeNumber,
        gradeValue: 0.0,
        maxGrade: 20.0,
        studentName: student.name,
        subjectName: widget.classSubject.subjectName,
        subjectCode: widget.classSubject.subjectCode,
      ),
    );
    
    // Check if there's an existing grade value
    final hasExistingGrade = existingGrade.gradeValue > 0 ||
                           (existingGrade.id.isNotEmpty && existingGrade.gradeValue == 0.0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. ${student.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasExistingGrade)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '★',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${student.id.substring(0, 8)}', // Show first 8 characters of ID
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Grade (0-20)',
                      border: const OutlineInputBorder(),
                      suffixText: '/20',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: _gradeControllers[index],
                  ),
                ),
                const SizedBox(width: 16),
                if (hasExistingGrade)
                  Text(
                    'Existing: ${existingGrade.gradeValue}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              controller: _notesControllers[index],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGrades() async {
    try {
      // Collect grades from the UI
      final List<Grade> updatedGrades = [];
      final user = _supabase.auth.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      for (int i = 0; i < _students.length; i++) {
        final student = _students[i];
        final gradeText = _gradeControllers[i].text;
        final notesText = _notesControllers[i].text;
        
        // Validate grade input - allow empty grades
        double? gradeValue;
        if (gradeText.trim().isNotEmpty) {
          gradeValue = double.tryParse(gradeText);
          if (gradeValue == null) {
            throw Exception('Invalid grade value for ${student.name}. Please enter a valid number.');
          }
          if (gradeValue < 0 || gradeValue > 20) {
            throw Exception('Grade value for ${student.name} must be between 0 and 20');
          }
        } else {
          // Skip empty grades
          continue;
        }
        
        // Find existing grade for this student
        Grade? existingGrade;
        try {
          existingGrade = _grades.firstWhere((grade) => grade.studentId == student.id);
        } catch (e) {
          // No existing grade found
        }
        
        updatedGrades.add(Grade(
          id: existingGrade?.id ?? '',
          createdAt: existingGrade?.createdAt ?? DateTime.now(),
          studentId: student.id,
          subjectId: widget.classSubject.subjectId,
          teacherId: user.id,
          semesterId: widget.semester.id,
          gradeNumber: _gradeNumber,
          gradeValue: gradeValue,
          maxGrade: 20.0,
          notes: notesText.isEmpty ? null : notesText,
          studentName: student.name,
          subjectName: widget.classSubject.subjectName,
          subjectCode: widget.classSubject.subjectCode,
        ));
      }
      
      // Save grades using the teacher service
      if (updatedGrades.isNotEmpty) {
        await _teacherService.saveGrades(updatedGrades);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grades saved successfully')),
          );
          
          // Update the local grades list
          setState(() {
            _grades = updatedGrades;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No grades to save')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving grades: $e')),
        );
      }
    }
  }
}