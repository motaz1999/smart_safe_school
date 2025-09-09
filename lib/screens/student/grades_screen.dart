import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../services/grade_service.dart';
import '../../utils/grade_display_utils.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> with SingleTickerProviderStateMixin {
  final GradeService _gradeService = GradeService();
  
  OrganizedStudentGrades? _organizedGrades;
  bool _isLoading = true;
  String? _error;
  
  TabController? _tabController;
  List<Semester> _semesters = [];
  
  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Load organized grades using the new service
      final organizedGrades = await _gradeService.getStudentGrades(user.id);
      
      // Extract semesters and set up tab controller
      final semesters = organizedGrades.semesters
          .where((semester) => organizedGrades.semestersBySemesterId.containsKey(semester.id))
          .toList();
      
      setState(() {
        _organizedGrades = organizedGrades;
        _semesters = semesters;
        _isLoading = false;
        
        // Initialize tab controller
        _tabController?.dispose();
        _tabController = TabController(length: semesters.length, vsync: this);
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
        title: const Text('My Grades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGrades,
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
                        onPressed: _loadGrades,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _organizedGrades == null || _semesters.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No grades available yet'),
                          SizedBox(height: 8),
                          Text(
                            'Your grades will appear here once your teachers have entered them.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Column(
                     children: [
                       _buildTabBar(),
                       Expanded(
                         child: RefreshIndicator(
                           onRefresh: _loadGrades,
                           child: TabBarView(
                             controller: _tabController,
                             children: _semesters.map((semester) => _buildSemesterView(semester)).toList(),
                           ),
                         ),
                       ),
                     ],
                   ),
    );
  }


  Widget _buildTabBar() {
    if (_semesters.isEmpty) return const SizedBox.shrink();
    
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: _semesters.map((semester) => Tab(
          text: semester.name,
        )).toList(),
      ),
    );
  }

  Widget _buildSemesterView(Semester semester) {
    final semesterGrades = _organizedGrades!.semestersBySemesterId[semester.id];
    if (semesterGrades == null || semesterGrades.subjectsBySubjectId.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No grades for this semester'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSemesterOverview(semesterGrades),
        const SizedBox(height: 24),
        _buildSubjectsList(semesterGrades),
      ],
    );
  }

  Widget _buildSemesterOverview(SemesterGrades semesterGrades) {
    // Calculate overall semester average
    double totalGradeValue = 0.0;
    int totalGradeCount = 0;
    
    for (final subjectGrades in semesterGrades.subjectsBySubjectId.values) {
      for (final gradeList in subjectGrades.gradesByGradeNumber.values) {
        for (final grade in gradeList) {
          totalGradeValue += grade.gradeValue;
          totalGradeCount++;
        }
      }
    }
    
    final overallAverage = totalGradeCount > 0 ? totalGradeValue / totalGradeCount : 0.0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Semester Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Overall Average',
                  '${overallAverage.toStringAsFixed(1)}/20',
                  _getGradeColor(overallAverage),
                ),
                _buildStatItem(
                  'Subjects',
                  '${semesterGrades.subjectsBySubjectId.length}',
                  Colors.blue,
                ),
                _buildStatItem(
                  'Total Grades',
                  '$totalGradeCount',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: overallAverage / 20,
              backgroundColor: Colors.grey[300],
              color: _getGradeColor(overallAverage),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${((overallAverage / 20) * 100).toStringAsFixed(1)}% (${_getGradeLetter(overallAverage)})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getGradeColor(overallAverage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubjectsList(SemesterGrades semesterGrades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Grades',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        for (final subjectGrades in semesterGrades.subjectsBySubjectId.values)
          _buildSubjectCard(subjectGrades),
      ],
    );
  }

  Widget _buildSubjectCard(SubjectGrades subjectGrades) {
    final grade1List = subjectGrades.gradesByGradeNumber[1] ?? [];
    final grade2List = subjectGrades.gradesByGradeNumber[2] ?? [];
    
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectGrades.subject.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getGradeColor(subjectGrades.overallAverage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getGradeColor(subjectGrades.overallAverage),
                        width: 1,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGradeSection(GradeDisplayUtils.getGradeDisplayName(1), grade1List, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGradeSection(GradeDisplayUtils.getGradeDisplayName(2), grade2List, Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSection(String title, List<Grade> grades, Color color) {
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Not graded yet',
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
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${averageGrade.toStringAsFixed(1)}/20',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getGradeColor(averageGrade),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${((averageGrade / 20) * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: _getGradeColor(averageGrade),
            ),
          ),
          if (grades.length > 1)
            Text(
              '${grades.length} grades',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
        ],
      ),
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