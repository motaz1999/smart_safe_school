import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../../services/teacher_service.dart';
import './semester_selection_screen.dart';

class AcademicYearSelectionScreen extends StatefulWidget {
  const AcademicYearSelectionScreen({super.key});

  @override
  State<AcademicYearSelectionScreen> createState() =>
      _AcademicYearSelectionScreenState();
}

class _AcademicYearSelectionScreenState
    extends State<AcademicYearSelectionScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final TeacherService _teacherService = TeacherService();

  List<AcademicYear> _academicYears = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAcademicYears();
  }

  Future<void> _loadAcademicYears() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load academic years from the teacher service
      final academicYears = await _teacherService.getAcademicYears();

      setState(() {
        _academicYears = academicYears;
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
                        onPressed: _loadAcademicYears,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAcademicYears,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildAcademicYearsList(),
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
              'Academic Year Selection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an academic year to enter grades',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicYearsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Academic Years',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (_academicYears.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No academic years found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAcademicYears,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else
          for (final academicYear in _academicYears)
            _buildAcademicYearCard(academicYear),
      ],
    );
  }

  Widget _buildAcademicYearCard(AcademicYear academicYear) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          academicYear.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                'Start: ${academicYear.startDate.toString().split(' ')[0]}'),
            Text('End: ${academicYear.endDate.toString().split(' ')[0]}'),
            if (academicYear.isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to semester selection screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SemesterSelectionScreen(
                academicYear: academicYear,
              ),
            ),
          );
        },
      ),
    );
  }
}