import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final AdminService _adminService = AdminService();
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _classStats = [];
  List<Map<String, dynamic>> _attendanceStats = [];
  List<Map<String, dynamic>> _gradeStats = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load dashboard stats
      final dashboardStats = await _adminService.getDashboardStats();
      
      // Load class statistics
      final classStats = await _loadClassStatistics();
      
      // Load attendance statistics
      final attendanceStats = await _loadAttendanceStatistics();
      
      // Load grade statistics
      final gradeStats = await _loadGradeStatistics();

      setState(() {
        _dashboardStats = dashboardStats;
        _classStats = classStats;
        _attendanceStats = attendanceStats;
        _gradeStats = gradeStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadClassStatistics() async {
    try {
      final classes = await _adminService.getClasses();
      final stats = <Map<String, dynamic>>[];
      
      for (final schoolClass in classes) {
        final studentCount = await _supabase
            .from('profiles')
            .select('id')
            .eq('class_id', schoolClass.id)
            .eq('user_type', 'student');
            
        stats.add({
          'class_name': schoolClass.name,
          'capacity': schoolClass.capacity,
          'enrolled': studentCount.length,
          'utilization': schoolClass.capacity > 0 
              ? (studentCount.length / schoolClass.capacity * 100).round()
              : 0,
        });
      }
      
      return stats;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadAttendanceStatistics() async {
    try {
      // Get attendance data for the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final attendanceData = await _supabase
          .from('attendance_records')
          .select('status, date')
          .gte('date', thirtyDaysAgo.toIso8601String().split('T')[0]);
      
      final totalRecords = attendanceData.length;
      final presentRecords = attendanceData.where((record) => record['status'] == 'present').length;
      final absentRecords = attendanceData.where((record) => record['status'] == 'absent').length;
      final lateRecords = attendanceData.where((record) => record['status'] == 'late').length;
      
      return [
        {
          'label': 'Present',
          'count': presentRecords,
          'percentage': totalRecords > 0 ? (presentRecords / totalRecords * 100).round() : 0,
          'color': Colors.green,
        },
        {
          'label': 'Absent',
          'count': absentRecords,
          'percentage': totalRecords > 0 ? (absentRecords / totalRecords * 100).round() : 0,
          'color': Colors.red,
        },
        {
          'label': 'Late',
          'count': lateRecords,
          'percentage': totalRecords > 0 ? (lateRecords / totalRecords * 100).round() : 0,
          'color': Colors.orange,
        },
      ];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadGradeStatistics() async {
    try {
      final grades = await _supabase
          .from('grades')
          .select('grade_value');
      
      if (grades.isEmpty) return [];
      
      final gradeValues = grades.map((g) => g['grade_value'] as double).toList();
      final average = gradeValues.reduce((a, b) => a + b) / gradeValues.length;
      
      final aGrades = gradeValues.where((g) => g >= 90).length;
      final bGrades = gradeValues.where((g) => g >= 80 && g < 90).length;
      final cGrades = gradeValues.where((g) => g >= 70 && g < 80).length;
      final dGrades = gradeValues.where((g) => g >= 60 && g < 70).length;
      final fGrades = gradeValues.where((g) => g < 60).length;
      
      return [
        {
          'grade': 'A (90-100)',
          'count': aGrades,
          'percentage': (aGrades / grades.length * 100).round(),
          'color': Colors.green,
        },
        {
          'grade': 'B (80-89)',
          'count': bGrades,
          'percentage': (bGrades / grades.length * 100).round(),
          'color': Colors.blue,
        },
        {
          'grade': 'C (70-79)',
          'count': cGrades,
          'percentage': (cGrades / grades.length * 100).round(),
          'color': Colors.orange,
        },
        {
          'grade': 'D (60-69)',
          'count': dGrades,
          'percentage': (dGrades / grades.length * 100).round(),
          'color': Colors.yellow,
        },
        {
          'grade': 'F (0-59)',
          'count': fGrades,
          'percentage': (fGrades / grades.length * 100).round(),
          'color': Colors.red,
        },
      ];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
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
                        onPressed: _loadReports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards
                        _buildOverviewSection(),
                        const SizedBox(height: 24),
                        
                        // Class Statistics
                        _buildClassStatisticsSection(),
                        const SizedBox(height: 24),
                        
                        // Attendance Statistics
                        _buildAttendanceStatisticsSection(),
                        const SizedBox(height: 24),
                        
                        // Grade Statistics
                        _buildGradeStatisticsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'School Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Students',
              _dashboardStats['students_count']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Teachers',
              _dashboardStats['teachers_count']?.toString() ?? '0',
              Icons.school,
              Colors.green,
            ),
            _buildStatCard(
              'Classes',
              _dashboardStats['classes_count']?.toString() ?? '0',
              Icons.class_,
              Colors.orange,
            ),
            _buildStatCard(
              'Subjects',
              _dashboardStats['subjects_count']?.toString() ?? '0',
              Icons.book,
              Colors.purple,
            ),
          ],
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
                color: color,
                fontWeight: FontWeight.bold,
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

  Widget _buildClassStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Utilization',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (_classStats.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No class data available'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _classStats.map((stat) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(stat['class_name']),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${stat['enrolled']}/${stat['capacity']} students'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: stat['capacity'] > 0 
                                    ? stat['enrolled'] / stat['capacity'] 
                                    : 0,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  stat['utilization'] > 80 
                                      ? Colors.red 
                                      : stat['utilization'] > 60 
                                          ? Colors.orange 
                                          : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${stat['utilization']}%',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttendanceStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance (Last 30 Days)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (_attendanceStats.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No attendance data available'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _attendanceStats.map((stat) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: stat['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(stat['label']),
                        ),
                        Text('${stat['count']} (${stat['percentage']}%)'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGradeStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grade Distribution',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (_gradeStats.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No grade data available'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _gradeStats.map((stat) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: stat['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(stat['grade']),
                        ),
                        Text('${stat['count']} (${stat['percentage']}%)'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}