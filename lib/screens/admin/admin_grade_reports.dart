
import 'package:flutter/material.dart';
import '../../services/grade_service.dart';
import '../../models/models.dart';
import '../../utils/grade_display_utils.dart';

class AdminGradeReportsScreen extends StatefulWidget {
  const AdminGradeReportsScreen({super.key});

  @override
  State<AdminGradeReportsScreen> createState() => _AdminGradeReportsScreenState();
}

class _AdminGradeReportsScreenState extends State<AdminGradeReportsScreen> {
  final GradeService _gradeService = GradeService();
  
  OrganizedSchoolGrades? _organizedGrades;
  GradeStatistics? _statistics;
  bool _isLoading = true;
  String? _error;
  
  // Filter state
  String? _selectedClassId;
  String? _selectedSubjectId;
  String? _selectedSemesterId;
  int? _selectedGradeNumber;
  
  // Available filter options
  List<SchoolClass> _classes = [];
  List<Subject> _subjects = [];
  List<Semester> _semesters = [];
  List<AcademicYear> _academicYears = [];
  
  // UI state
  bool _showFilters = true;
  String _sortBy = 'class'; // class, student, subject, grade
  bool _sortAscending = true;

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

      // Load organized grades with current filters
      final organizedGrades = await _gradeService.getSchoolGrades(
        classId: _selectedClassId,
        subjectId: _selectedSubjectId,
        semesterId: _selectedSemesterId,
        gradeNumber: _selectedGradeNumber,
      );

      // Load statistics
      final statistics = await _gradeService.getGradeStatistics(
        classId: _selectedClassId,
        subjectId: _selectedSubjectId,
        semesterId: _selectedSemesterId,
        gradeNumber: _selectedGradeNumber,
      );

      setState(() {
        _organizedGrades = organizedGrades;
        _statistics = statistics;
        _classes = organizedGrades.classes;
        _subjects = organizedGrades.subjects;
        _semesters = organizedGrades.semesters;
        _academicYears = organizedGrades.academicYears;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _loadData();
  }

  void _clearFilters() {
    setState(() {
      _selectedClassId = null;
      _selectedSubjectId = null;
      _selectedSemesterId = null;
      _selectedGradeNumber = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_showFilters) _buildFilterPanel(),
                    _buildStatisticsPanel(),
                    Expanded(child: _buildGradesView()),
                  ],
                ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFilterDropdown(
                'Class',
                _selectedClassId,
                _classes.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                (value) => setState(() => _selectedClassId = value),
              ),
              _buildFilterDropdown(
                'Subject',
                _selectedSubjectId,
                _subjects.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                )).toList(),
                (value) => setState(() => _selectedSubjectId = value),
              ),
              _buildFilterDropdown(
                'Semester',
                _selectedSemesterId,
                _semesters.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                )).toList(),
                (value) => setState(() => _selectedSemesterId = value),
              ),
              _buildFilterDropdown(
                'Grade Number',
                _selectedGradeNumber?.toString(),
                [
                  DropdownMenuItem(value: '1', child: Text(GradeDisplayUtils.getGradeDisplayNameFromString('1'))),
                  DropdownMenuItem(value: '2', child: Text(GradeDisplayUtils.getGradeDisplayNameFromString('2'))),
                ],
                (value) => setState(() => _selectedGradeNumber = value != null ? int.parse(value) : null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Apply Filters'),
              ),
              const SizedBox(width: 16),
              Text(
                'Sort by:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'class', child: Text('Class')),
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'subject', child: Text('Subject')),
                  DropdownMenuItem(value: 'grade', child: Text('Grade')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
  ) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        value: value,
        items: [
          DropdownMenuItem<T>(
            value: null,
            child: Text('All ${label}s'),
          ),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatisticsPanel() {
    if (_statistics == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total Grades',
                '${_statistics!.totalGrades}',
                Icons.assignment,
                Colors.blue,
              ),
              _buildStatCard(
                'Average',
                '${_statistics!.averageGrade.toStringAsFixed(1)}/20',
                Icons.trending_up,
                _getGradeColor(_statistics!.averageGrade),
              ),
              _buildStatCard(
                'Highest',
                '${_statistics!.highestGrade.toStringAsFixed(1)}/20',
                Icons.star,
                Colors.green,
              ),
              _buildStatCard(
                'Lowest',
                '${_statistics!.lowestGrade.toStringAsFixed(1)}/20',
                Icons.trending_down,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGradeDistribution(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildGradeDistribution() {
    if (_statistics == null || _statistics!.gradeDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grade Distribution',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _statistics!.gradeDistribution.entries.map((entry) {
            final percentage = _statistics!.totalGrades > 0
                ? (entry.value / _statistics!.totalGrades * 100).round()
                : 0;
            return Column(
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${entry.value}'),
                Text(
                  '$percentage%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGradesView() {
    if (_organizedGrades == null || _organizedGrades!.classesByClassId.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No grades found'),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final classEntry in _organizedGrades!.classesByClassId.entries)
            _buildClassSection(classEntry.value),
        ],
      ),
    );
  }

  Widget _buildClassSection(ClassGrades classGrades) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          classGrades.schoolClass.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${classGrades.semestersBySemesterId.length} semesters'),
        children: [
          for (final semesterEntry in classGrades.semestersBySemesterId.entries)
            _buildSemesterSection(semesterEntry.value, classGrades.schoolClass),
        ],
      ),
    );
  }

  Widget _buildSemesterSection(SemesterGrades semesterGrades, SchoolClass schoolClass) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        title: Text(
          semesterGrades.semester.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${semesterGrades.subjectsBySubjectId.length} subjects'),
        children: [
          for (final subjectEntry in semesterGrades.subjectsBySubjectId.entries)
            _buildSubjectSection(subjectEntry.value, schoolClass, semesterGrades.semester),
        ],
      ),
    );
  }

  Widget _buildSubjectSection(SubjectGrades subjectGrades, SchoolClass schoolClass, Semester semester) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectGrades.subject.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Code: ${subjectGrades.subject.code}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (subjectGrades.overallAverage > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getGradeColor(subjectGrades.overallAverage).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getGradeColor(subjectGrades.overallAverage),
                        ),
                      ),
                      child: Text(
                        'Avg: ${subjectGrades.overallAverage.toStringAsFixed(1)}/20',
                        style: TextStyle(
                          color: _getGradeColor(subjectGrades.overallAverage),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGradeNumberSection(GradeDisplayUtils.getGradeDisplayName(1), subjectGrades.gradesByGradeNumber[1] ?? []),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGradeNumberSection(GradeDisplayUtils.getGradeDisplayName(2), subjectGrades.gradesByGradeNumber[2] ?? []),
                  ),
                ],
              ),
              if (subjectGrades.gradesByGradeNumber.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildStudentGradesList(subjectGrades),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeNumberSection(String title, List<Grade> grades) {
    if (grades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No grades',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final averageGrade = grades.map((g) => g.gradeValue).reduce((a, b) => a + b) / grades.length;
    final color = title.contains('1') ? Colors.blue : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${averageGrade.toStringAsFixed(1)}/20',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getGradeColor(averageGrade),
            ),
          ),
          Text(
            '${grades.length} students',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGradesList(SubjectGrades subjectGrades) {
    // Collect all grades with student info
    final List<Map<String, dynamic>> studentGrades = [];
    
    for (final gradeNumberEntry in subjectGrades.gradesByGradeNumber.entries) {
      for (final grade in gradeNumberEntry.value) {
        studentGrades.add({
          'grade': grade,
          'gradeNumber': gradeNumberEntry.key,
        });
      }
    }

    // Sort by student name
    studentGrades.sort((a, b) => (a['grade'] as Grade).studentName?.compareTo((b['grade'] as Grade).studentName ?? '') ?? 0);

    return ExpansionTile(
      title: Text('Student Grades (${studentGrades.length})'),
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: studentGrades.length,
            itemBuilder: (context, index) {
              final item = studentGrades[index];
              final grade = item['grade'] as Grade;
              final gradeNumber = item['gradeNumber'] as int;
              
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _getGradeColor(grade.gradeValue).withOpacity(0.2),
                  child: Text(
                    grade.gradeValue.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(grade.gradeValue),
                    ),
                  ),
                ),
                title: Text(
                  grade.studentName ?? 'Unknown Student',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  GradeDisplayUtils.getGradeDisplayName(gradeNumber),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade.gradeValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${grade.gradeValue}/20',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(grade.gradeValue),
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 18) {
      return Colors.green;
    } else if (grade >= 16) {
      return Colors.lightGreen;
    } else if (grade >= 14) {
      return Colors.orange;
    } else if (grade >= 12) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  String _getGradeLetter(double grade) {
    if (grade >= 18) {
      return 'A';
    } else if (grade >= 16) {
      return 'B';
    } else if (grade >= 14) {
      return 'C';
    } else if (grade >= 12) {
      return 'D';
    } else {
      return 'F';
    }
  }
}