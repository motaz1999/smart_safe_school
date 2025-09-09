import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import 'manage_students_content.dart';
import 'manage_teachers_content.dart';
import 'manage_classes_content.dart';
import 'manage_subjects_content.dart';
import 'manage_timetable_content.dart';
import 'admin_reports.dart';
import 'admin_grade_reports.dart';
import 'absence_reports_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final AdminService _adminService = AdminService();
  int _selectedIndex = 0;
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  String? _error;
  
  // Global keys to access the state of content widgets
  final GlobalKey<ManageStudentsContentState> _studentsContentKey = GlobalKey();
  final GlobalKey<ManageTeachersContentState> _teachersContentKey = GlobalKey();
  final GlobalKey<ManageSubjectsContentState> _subjectsContentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await _adminService.getDashboardStats();
      
      setState(() {
        _dashboardStats = stats;
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
      body: Row(
        children: [
          // Fixed Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _buildFixedSidebar(context),
          ),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          _getTitleForIndex(_selectedIndex),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Add buttons for specific management screens
                        if (_selectedIndex == 2) // Manage Students
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              // Call the public method in the state
                              final state = _studentsContentKey.currentState;
                              if (state != null) {
                                state.showAddStudentDialog();
                              }
                            },
                          ),
                        if (_selectedIndex == 3) // Manage Teachers
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              // Call the public method in the state
                              final state = _teachersContentKey.currentState;
                              if (state != null) {
                                state.showAddTeacherDialog();
                              }
                            },
                          ),
                        if (_selectedIndex == 5) // Manage Subjects
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              // Call the public method in the state
                              final state = _subjectsContentKey.currentState;
                              if (state != null) {
                                state.showAddSubjectDialog();
                              }
                            },
                          ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'profile':
                                _showProfile();
                                break;
                              case 'logout':
                                _handleLogout();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: ListTile(
                                leading: Icon(Icons.person),
                                title: Text('Profile'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: ListTile(
                                leading: Icon(Icons.logout),
                                title: Text('Logout'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Main Dashboard Content
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedSidebar(BuildContext context) {
    return Column(
      children: [
        // Sidebar Header with user info
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      authProvider.currentUser?.name
                              .substring(0, 1)
                              .toUpperCase() ??
                          'A',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.currentUser?.name ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authProvider.currentUser?.schoolName ?? 'School Administrator',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
        
        // Navigation Menu Items
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildSidebarItem(
                icon: Icons.dashboard,
                title: 'Dashboard',
                isSelected: _selectedIndex == 0,
                onTap: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              _buildSidebarItem(
                icon: Icons.class_,
                title: 'Manage Classes',
                isSelected: _selectedIndex == 1,
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              _buildSidebarItem(
                icon: Icons.people,
                title: 'Manage Students',
                isSelected: _selectedIndex == 2,
                onTap: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              _buildSidebarItem(
                icon: Icons.school,
                title: 'Manage Teachers',
                isSelected: _selectedIndex == 3,
                onTap: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
              _buildSidebarItem(
                icon: Icons.schedule,
                title: 'Manage Timetable',
                isSelected: _selectedIndex == 4,
                onTap: () {
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
              ),
              _buildSidebarItem(
                icon: Icons.book,
                title: 'Manage Subjects',
                isSelected: _selectedIndex == 5,
                onTap: () {
                  setState(() {
                    _selectedIndex = 5;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildSidebarItem(
                icon: Icons.event_busy,
                title: 'Absence Reports',
                isSelected: _selectedIndex == 6,
                onTap: () {
                  setState(() {
                    _selectedIndex = 6;
                  });
                },
              ),
              _buildSidebarItem(
                icon: Icons.grade,
                title: 'Grade Reports',
                isSelected: _selectedIndex == 7,
                onTap: () {
                  setState(() {
                    _selectedIndex = 7;
                  });
                },
              ),
              _buildSidebarItem(
                icon: Icons.analytics,
                title: 'View Reports',
                isSelected: _selectedIndex == 8,
                onTap: () {
                  setState(() {
                    _selectedIndex = 8;
                  });
                },
              ),
            ],
          ),
        ),
        
        // Footer with logout
        Container(
          padding: const EdgeInsets.all(16),
          child: _buildSidebarItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              _handleLogout();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0: // Dashboard
        return _buildDashboardContent();
      case 1: // Manage Classes
        return const ManageClassesContent();
      case 2: // Manage Students
        return ManageStudentsContent(key: _studentsContentKey);
      case 3: // Manage Teachers
        return ManageTeachersContent(key: _teachersContentKey);
      case 4: // Manage Timetable
        return const ManageTimetableContent();
      case 5: // Manage Subjects
        return ManageSubjectsContent(key: _subjectsContentKey);
      case 6: // Absence Reports
        return const AbsenceReportsScreen();
      case 7: // Grade Reports
        return const AdminGradeReportsScreen();
      case 8: // View Reports
        return const AdminReportsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            authProvider.currentUser?.name
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                authProvider.currentUser?.name ?? 'Admin',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                authProvider.currentUser?.schoolName ?? 'School Administrator',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Statistics Cards (without Quick Actions)
            Text(
              'School Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 32),

          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_dashboardStats == null) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Students',
          _dashboardStats!['students_count'].toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Teachers',
          _dashboardStats!['teachers_count'].toString(),
          Icons.school,
          Colors.green,
        ),
        _buildStatCard(
          'Classes',
          _dashboardStats!['classes_count'].toString(),
          Icons.class_,
          Colors.orange,
        ),
        _buildStatCard(
          'Subjects',
          _dashboardStats!['subjects_count'].toString(),
          Icons.book,
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
            Icon(
              icon,
              size: 32,
              color: color,
            ),
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
            ),
          ],
        ),
      ),
    );
  }


  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Manage Classes';
      case 2:
        return 'Manage Students';
      case 3:
        return 'Manage Teachers';
      case 4:
        return 'Manage Timetable';
      case 5:
        return 'Manage Subjects';
      case 6:
        return 'Absence Reports';
      case 7:
        return 'Grade Reports';
      case 8:
        return 'View Reports';
      default:
        return 'Admin Dashboard';
    }
  }

  void _addStudent() {
    // Show a snackbar indicating this feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add student feature coming soon')),
    );
  }

  void _addTeacher() {
    // Show a snackbar indicating this feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add teacher feature coming soon')),
    );
  }

  void _addSubject() {
    // Show a snackbar indicating this feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add subject feature coming soon')),
    );
  }

  void _showProfile() {
    // TODO: Implement profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile screen - Coming Soon')),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}