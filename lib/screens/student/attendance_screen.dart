import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../services/attendance_service.dart';
import '../../core/config/supabase_config.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final AttendanceService _attendanceService = AttendanceService();
  
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user profile from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.currentUser;
      
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      if (userProfile.userType.name != 'student') {
        throw Exception('Access denied: Only students can view attendance records');
      }

      final studentId = userProfile.id;

      // Load attendance records for the student (last 60 days)
      final records = await _attendanceService.getStudentAttendanceRecords(
        studentId: studentId,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now(),
        limit: 50,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendance,
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
                        onPressed: _loadAttendance,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAttendance,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildAttendanceSummary(),
                      const SizedBox(height: 24),
                      _buildAttendanceList(),
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
              'Attendance Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your attendance records across all subjects',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    // Calculate attendance statistics
    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;
    
    for (final record in _attendanceRecords) {
      if (record.isPresent) {
        presentCount++;
      } else {
        absentCount++;
      }
    }
    
    final totalCount = _attendanceRecords.length;
    final attendanceRate = totalCount > 0 ? (presentCount / totalCount) * 100 : 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Attendance Rate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${attendanceRate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _getAttendanceColor(attendanceRate.toDouble()),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: attendanceRate / 100,
              backgroundColor: Colors.grey[300],
              color: _getAttendanceColor(attendanceRate.toDouble()),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCount('Present', presentCount, Colors.green),
                _buildStatusCount('Late', lateCount, Colors.orange),
                _buildStatusCount('Absent', absentCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
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

  Color _getAttendanceColor(double rate) {
    if (rate >= 90) {
      return Colors.green;
    } else if (rate >= 80) {
      return Colors.lightGreen;
    } else if (rate >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildAttendanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Records',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        for (final record in _attendanceRecords)
          _buildAttendanceCard(record),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final date = record.attendanceDate;
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
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          record.subjectName ?? 'Unknown Subject',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(date)),
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