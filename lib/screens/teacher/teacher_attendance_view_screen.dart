import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../services/attendance_service.dart';

class TeacherAttendanceViewScreen extends StatefulWidget {
  const TeacherAttendanceViewScreen({super.key});

  @override
  State<TeacherAttendanceViewScreen> createState() => _TeacherAttendanceViewScreenState();
}

class _TeacherAttendanceViewScreenState extends State<TeacherAttendanceViewScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // 'all', 'present', 'absent'
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current teacher profile from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.currentUser;
      
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      if (userProfile.userType.name != 'teacher') {
        throw Exception('Access denied: Only teachers can view student attendance records');
      }

      final teacherId = userProfile.id;

      // Load attendance records for the teacher's students
      final records = await _attendanceService.getTeacherStudentAttendanceRecords(
        teacherId: teacherId,
        startDate: _startDate,
        endDate: _endDate,
        limit: 100,
      );
      
      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AttendanceRecord> get _filteredRecords {
    switch (_selectedFilter) {
      case 'present':
        return _attendanceRecords.where((record) => record.isPresent).toList();
      case 'absent':
        return _attendanceRecords.where((record) => !record.isPresent).toList();
      default:
        return _attendanceRecords;
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAttendanceRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceRecords,
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
                        onPressed: _loadAttendanceRecords,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(),
                    _buildFilterChips(),
                    Expanded(
                      child: _buildAttendanceList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    final totalRecords = _attendanceRecords.length;
    final presentCount = _attendanceRecords.where((r) => r.isPresent).length;
    final absentCount = _attendanceRecords.where((r) => !r.isPresent).length;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Period: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total', totalRecords, Colors.blue),
                _buildStatCard('Present', presentCount, Colors.green),
                _buildStatCard('Absent', absentCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedFilter == 'all',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'all';
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Present'),
            selected: _selectedFilter == 'present',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'present';
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Absent'),
            selected: _selectedFilter == 'absent',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'absent';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    final filteredRecords = _filteredRecords;
    
    if (filteredRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No attendance records found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendanceRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          final record = filteredRecords[index];
          return _buildAttendanceCard(record);
        },
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final isPresent = record.isPresent;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isPresent) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'PRESENT';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'ABSENT';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          record.studentName ?? 'Unknown Student',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${record.subjectName ?? 'Unknown Subject'}'),
            Text('Date: ${_formatDate(record.attendanceDate)}'),
            if (record.notes != null && record.notes!.isNotEmpty)
              Text(
                'Note: ${record.notes}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}