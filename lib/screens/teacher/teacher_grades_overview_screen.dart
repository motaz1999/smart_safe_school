import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../../services/teacher_service.dart';

class TeacherGradesOverviewScreen extends StatefulWidget {
  const TeacherGradesOverviewScreen({super.key});

  @override
  State<TeacherGradesOverviewScreen> createState() => _TeacherGradesOverviewScreenState();
}

class _TeacherGradesOverviewScreenState extends State<TeacherGradesOverviewScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final TeacherService _teacherService = TeacherService();

  Map<String, Map<String, Map<int, List<Grade>>>> _organizedGrades = {};
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // For organizing semester and subject data
  Map<String, String> _semesterNames = {};
  Map<String, Map<String, Map<String, String>>> _subjectInfo = {}; // semesterId -> subjectId -> {name, code}

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGrades();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadGrades() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load organized grades and statistics
      final grades = await _teacherService.getAllTeacherGrades();
      final stats = await _teacherService.getGradeStatistics();

      // Extract semester and subject information for display
      _extractDisplayInfo(grades);

      setState(() {
        _organizedGrades = grades;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _extractDisplayInfo(Map<String, Map<String, Map<int, List<Grade>>>> grades) {
    _semesterNames.clear();
    _subjectInfo.clear();

    for (final semesterId in grades.keys) {
      for (final subjectId in grades[semesterId]!.keys) {
        for (final gradeNumber in grades[semesterId]![subjectId]!.keys) {
          final gradesList = grades[semesterId]![subjectId]![gradeNumber]!;
          if (gradesList.isNotEmpty) {
            final firstGrade = gradesList.first;
            
            // Store semester name
            _semesterNames[semesterId] = firstGrade.semesterName ?? 'Unknown Semester';
            
            // Store subject info
            if (!_subjectInfo.containsKey(semesterId)) {
              _subjectInfo[semesterId] = {};
            }
            _subjectInfo[semesterId]![subjectId] = {
              'name': firstGrade.subjectName ?? 'Unknown Subject',
              'code': firstGrade.subjectCode ?? '',
            };
          }
        }
      }
    }
  }

  List<String> _getFilteredSemesters() {
    if (_searchQuery.isEmpty) {
      return _organizedGrades.keys.toList();
    }
    
    return _organizedGrades.keys.where((semesterId) {
      final semesterName = _semesterNames[semesterId] ?? '';
      return semesterName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSafeSchool'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Grades'),
            Tab(text: 'Statistics'),
          ],
        ),
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search semesters...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGradesView(),
                _buildStatisticsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    final filteredSemesters = _getFilteredSemesters();

    if (filteredSemesters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No grades found'),
            const SizedBox(height: 8),
            const Text('Start by entering grades for your classes'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: filteredSemesters.length,
        itemBuilder: (context, index) {
          final semesterId = filteredSemesters[index];
          return _buildSemesterCard(semesterId);
        },
      ),
    );
  }

  Widget _buildSemesterCard(String semesterId) {
    final semesterName = _semesterNames[semesterId] ?? 'Unknown Semester';
    final subjects = _organizedGrades[semesterId] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(
          semesterName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text('${subjects.length} subjects'),
        children: subjects.keys.map((subjectId) {
          return _buildSubjectSection(semesterId, subjectId);
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectSection(String semesterId, String subjectId) {
    final subjectInfo = _subjectInfo[semesterId]?[subjectId];
    final subjectName = subjectInfo?['name'] ?? 'Unknown Subject';
    final subjectCode = subjectInfo?['code'] ?? '';
    final gradeNumbers = _organizedGrades[semesterId]![subjectId]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: Colors.grey[50],
        child: ExpansionTile(
          title: Text(
            '$subjectName ($subjectCode)',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text('${gradeNumbers.length} grade sets'),
          children: gradeNumbers.keys.map((gradeNumber) {
            return _buildGradeNumberSection(semesterId, subjectId, gradeNumber);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGradeNumberSection(String semesterId, String subjectId, int gradeNumber) {
    final grades = _organizedGrades[semesterId]![subjectId]![gradeNumber]!;
    final averageGrade = grades.isNotEmpty 
        ? grades.map((g) => g.gradeValue).reduce((a, b) => a + b) / grades.length
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        color: Colors.white,
        child: ExpansionTile(
          title: Text(
            'Grade $gradeNumber',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            '${grades.length} students • Average: ${averageGrade.toStringAsFixed(1)}/20',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: grades.map((grade) {
                  return _buildGradeItem(grade);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeItem(Grade grade) {
    final gradeColor = _getGradeColor(grade.gradeValue);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              grade.studentName ?? 'Unknown Student',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '${grade.gradeValue.toStringAsFixed(1)}/20',
                style: TextStyle(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (grade.notes != null && grade.notes!.isNotEmpty)
            Expanded(
              flex: 2,
              child: Text(
                grade.notes!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 16) return Colors.green;
    if (grade >= 14) return Colors.lightGreen;
    if (grade >= 12) return Colors.orange;
    if (grade >= 10) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _buildStatisticsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade Statistics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Statistics Cards
            _buildStatsGrid(),
            const SizedBox(height: 32),
            
            // Grade Distribution
            _buildGradeDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Grades',
          _statistics['total_grades']?.toString() ?? '0',
          Icons.grade,
          Colors.blue,
        ),
        _buildStatCard(
          'Semesters',
          _statistics['unique_semesters']?.toString() ?? '0',
          Icons.calendar_today,
          Colors.green,
        ),
        _buildStatCard(
          'Subjects',
          _statistics['unique_subjects']?.toString() ?? '0',
          Icons.book,
          Colors.orange,
        ),
        _buildStatCard(
          'Average Grade',
          (_statistics['average_grade'] as double?)?.toStringAsFixed(1) ?? '0.0',
          Icons.trending_up,
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
            Icon(icon, size: 32, color: color),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistribution() {
    // Calculate grade distribution from organized grades
    final Map<String, int> distribution = {
      'Excellent (16-20)': 0,
      'Good (14-16)': 0,
      'Average (12-14)': 0,
      'Below Average (10-12)': 0,
      'Poor (0-10)': 0,
    };

    for (final semester in _organizedGrades.values) {
      for (final subject in semester.values) {
        for (final gradeList in subject.values) {
          for (final grade in gradeList) {
            if (grade.gradeValue >= 16) {
              distribution['Excellent (16-20)'] = distribution['Excellent (16-20)']! + 1;
            } else if (grade.gradeValue >= 14) {
              distribution['Good (14-16)'] = distribution['Good (14-16)']! + 1;
            } else if (grade.gradeValue >= 12) {
              distribution['Average (12-14)'] = distribution['Average (12-14)']! + 1;
            } else if (grade.gradeValue >= 10) {
              distribution['Below Average (10-12)'] = distribution['Below Average (10-12)']! + 1;
            } else {
              distribution['Poor (0-10)'] = distribution['Poor (0-10)']! + 1;
            }
          }
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final percentage = _statistics['total_grades'] > 0 
                  ? (entry.value / _statistics['total_grades'] * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 2,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getDistributionColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getDistributionColor(String category) {
    switch (category) {
      case 'Excellent (16-20)':
        return Colors.green;
      case 'Good (14-16)':
        return Colors.lightGreen;
      case 'Average (12-14)':
        return Colors.orange;
      case 'Below Average (10-12)':
        return Colors.deepOrange;
      case 'Poor (0-10)':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}