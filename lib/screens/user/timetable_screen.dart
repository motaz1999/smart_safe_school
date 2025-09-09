import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../teacher/attendance_screen.dart';

class UserTimetableScreen extends StatefulWidget {
  const UserTimetableScreen({super.key});

  @override
  State<UserTimetableScreen> createState() => _UserTimetableScreenState();
}

class _UserTimetableScreenState extends State<UserTimetableScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  List<TimetableEntry> _timetableEntries = [];
  bool _isLoading = true;
  String? _error;
  String? _userRole;
  
  // Current week dates
  DateTime _weekStart = DateTime.now();
  DateTime _weekEnd = DateTime.now();
  
  // Days of week with dates
  List<Map<String, dynamic>> _daysWithDates = [];
  
  final List<Map<String, dynamic>> _timeSlots = [
    {'slot': '08:00-09:00', 'start': TimeOfDay(hour: 8, minute: 0), 'end': TimeOfDay(hour: 9, minute: 0)},
    {'slot': '09:00-10:00', 'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 10, minute: 0)},
    {'slot': '10:00-11:00', 'start': TimeOfDay(hour: 10, minute: 0), 'end': TimeOfDay(hour: 11, minute: 0)},
    {'slot': '11:00-12:00', 'start': TimeOfDay(hour: 11, minute: 0), 'end': TimeOfDay(hour: 12, minute: 0)},
    {'slot': '12:00-13:00', 'start': TimeOfDay(hour: 12, minute: 0), 'end': TimeOfDay(hour: 13, minute: 0)},
    {'slot': '13:00-14:00', 'start': TimeOfDay(hour: 13, minute: 0), 'end': TimeOfDay(hour: 14, minute: 0)},
    {'slot': '14:00-15:00', 'start': TimeOfDay(hour: 14, minute: 0), 'end': TimeOfDay(hour: 15, minute: 0)},
    {'slot': '15:00-16:00', 'start': TimeOfDay(hour: 15, minute: 0), 'end': TimeOfDay(hour: 16, minute: 0)},
    {'slot': '16:00-17:00', 'start': TimeOfDay(hour: 16, minute: 0), 'end': TimeOfDay(hour: 17, minute: 0)},
    {'slot': '17:00-18:00', 'start': TimeOfDay(hour: 17, minute: 0), 'end': TimeOfDay(hour: 18, minute: 0)},
  ];

  @override
  void initState() {
    super.initState();
    _calculateCurrentWeek();
    _loadTimetable();
  }
  
  void _calculateCurrentWeek() {
    final now = DateTime.now();
    // Get the first day of the week (Monday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = monday;
    _weekEnd = monday.add(const Duration(days: 6));
    
    // Create list of days with dates
    _daysWithDates = List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      return {
        'date': date,
        'dayName': _getDayName(date.weekday),
        'dateString': '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
      };
    });
  }
  
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  
  Future<void> _loadTimetable() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user profile to determine role and class/subject
      final profileResponse = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();
      
      final schoolId = profileResponse['school_id'] as int;
      final role = profileResponse['user_type'] as String?;
      
      setState(() {
        _userRole = role;
      });
      
      List<dynamic> response;
      
      if (role == 'student') {
        // Students see their class timetable
        final classId = profileResponse['class_id'] as String?;
        if (classId == null) {
          throw Exception('Student not assigned to a class');
        }
        
        response = await _supabase
            .from('timetables')
            .select('''
              *,
              subjects(name, code)
            ''')
            .eq('class_id', classId)
            .eq('school_id', schoolId);
      } else if (role == 'teacher') {
        // Teachers see their own timetable
        response = await _supabase
            .from('timetables')
            .select('''
              *,
              subjects(name, code),
              classes(name)
            ''')
            .eq('teacher_id', user.id)
            .eq('school_id', schoolId);
      } else {
        throw Exception('Unsupported role: $role');
      }

      // Get unique teacher IDs from the timetable entries
      final teacherIds = response
          .map((json) => json['teacher_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .cast<String>();
      
      // Fetch teacher names separately
      Map<String, String> teacherNames = {};
      if (teacherIds.isNotEmpty) {
        try {
          final teachersResponse = await _supabase
              .from('profiles')
              .select('id, name')
              .inFilter('id', teacherIds.toList());
          
          for (final teacher in teachersResponse) {
            teacherNames[teacher['id']] = teacher['name'];
          }
        } catch (e) {
          print('Error fetching teacher names: $e');
        }
      }

      final entries = response.map((json) {
        // Add schoolId to the JSON for the fromJson method
        final jsonWithSchoolId = Map<String, dynamic>.from(json);
        jsonWithSchoolId['school_id'] = schoolId;
        
        // Add teacher name from our separate query
        final teacherId = json['teacher_id'] as String?;
        if (teacherId != null && teacherNames.containsKey(teacherId)) {
          jsonWithSchoolId['teacher_name'] = teacherNames[teacherId];
        }
        
        final entry = TimetableEntry.fromJson(jsonWithSchoolId);
        return entry;
      }).toList();
      
      setState(() {
        _timetableEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _navigateToAttendanceScreen(TimetableEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceScreen(
          classId: entry.classId,
          subjectId: entry.subjectId,
          teacherId: entry.teacherId,
          className: entry.className ?? 'Unknown Class',
          subjectName: entry.subjectName ?? 'Unknown Subject',
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        onPressed: _loadTimetable,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Week display
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _previousWeek,
                          ),
                          Text(
                            '${_getMonthName(_weekStart.month)} ${_weekStart.day} - ${_getMonthName(_weekEnd.month)} ${_weekEnd.day}, ${_weekStart.year}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _nextWeek,
                          ),
                        ],
                      ),
                    ),
                    // Timetable Grid
                    Expanded(
                      child: _buildTimetableGrid(),
                    ),
                  ],
                ),
    );
  }
  
  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _weekEnd = _weekEnd.subtract(const Duration(days: 7));
      _updateDaysWithDates();
    });
  }
  
  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _weekEnd = _weekEnd.add(const Duration(days: 7));
      _updateDaysWithDates();
    });
  }
  
  void _updateDaysWithDates() {
    // Create list of days with dates for the current week
    _daysWithDates = List.generate(7, (index) {
      final date = _weekStart.add(Duration(days: index));
      return {
        'date': date,
        'dayName': _getDayName(date.weekday),
        'dateString': '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
      };
    });
  }
  
  Widget _buildTimetableGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            border: TableBorder.all(color: Colors.grey[300]!),
            columnWidths: {
              0: const FixedColumnWidth(120),
              for (int i = 1; i <= 7; i++)
                i: const FixedColumnWidth(150),
            },
            children: [
              // Header row with dates
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[100]),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ..._daysWithDates.map((dayData) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(dayData['dayName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(dayData['dateString'], style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      )),
                ],
              ),
              // Time slot rows
              ..._timeSlots.map((timeSlotData) => _buildTimeSlotRow(timeSlotData)),
            ],
          ),
        ),
      ),
    );
  }
  
  TableRow _buildTimeSlotRow(Map<String, dynamic> timeSlotData) {
    final timeSlot = timeSlotData['slot'] as String;
    final startTime = timeSlotData['start'] as TimeOfDay;
    final endTime = timeSlotData['end'] as TimeOfDay;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(timeSlot, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        ..._daysWithDates.map((dayData) => _buildTimetableCell(dayData, timeSlot, startTime, endTime)),
      ],
    );
  }
  
  Widget _buildTimetableCell(Map<String, dynamic> dayData, String timeSlot, TimeOfDay startTime, TimeOfDay endTime) {
    final date = dayData['date'] as DateTime;
    final dayEnum = DayOfWeek.values[date.weekday - 1]; // Monday is 0
    
    // Find matching entries for this day and time slot
    final matchingEntries = _timetableEntries.where((entry) {
      // Check if day matches
      final dayMatches = entry.dayOfWeek == dayEnum;
      
      // Check if time ranges overlap
      final entryStart = entry.startTime.hour * 60 + entry.startTime.minute;
      final entryEnd = entry.endTime.hour * 60 + entry.endTime.minute;
      final slotStart = startTime.hour * 60 + startTime.minute;
      final slotEnd = endTime.hour * 60 + endTime.minute;
      
      // Check if the entry's time range overlaps with the slot time range
      final timeMatches = dayMatches && (
        (entryStart >= slotStart && entryStart < slotEnd) ||  // Entry starts within slot
        (entryEnd > slotStart && entryEnd <= slotEnd) ||      // Entry ends within slot
        (entryStart <= slotStart && entryEnd >= slotEnd)      // Entry spans entire slot
      );
      
      return timeMatches;
    }).toList();
    
    // Group consecutive entries with same subject and teacher
    final groupedEntries = _groupConsecutiveEntries(matchingEntries);
    
    if (groupedEntries.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
        ),
      );
    }
    
    // If we have one entry, display it normally
    if (groupedEntries.length == 1) {
      final entry = groupedEntries.first;
      return _buildTimetableEntryCell(entry);
    }
    
    // If we have multiple entries, stack them
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: groupedEntries.map((entry) => 
          Expanded(
            child: _buildTimetableEntryCell(entry, isCompact: true)
          )
        ).toList(),
      ),
    );
  }
  
  Widget _buildTimetableEntryCell(TimetableEntry entry, {bool isCompact = false}) {
    // For teachers, wrap the container in a GestureDetector to make it tappable
    if (_userRole == 'teacher') {
      return GestureDetector(
        onTap: () {
          _navigateToAttendanceScreen(entry);
        },
        child: Container(
          height: isCompact ? null : 80,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.subjectName ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 10 : 12
                ),
                textAlign: TextAlign.center,
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                entry.className ?? 'Unknown Class',
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10
                ),
                textAlign: TextAlign.center,
                maxLines: isCompact ? 1 : 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.startTime != entry.endTime && !isCompact)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    entry.timeRange,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // For students, keep the existing implementation
      return Container(
        height: isCompact ? null : 80,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              entry.subjectName ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 10 : 12
              ),
              textAlign: TextAlign.center,
              maxLines: isCompact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              entry.teacherName ?? 'Unknown',
              style: TextStyle(
                fontSize: isCompact ? 9 : 10
              ),
              textAlign: TextAlign.center,
              maxLines: isCompact ? 1 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (entry.startTime != entry.endTime && !isCompact)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  entry.timeRange,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }
  }
  
  List<TimetableEntry> _groupConsecutiveEntries(List<TimetableEntry> entries) {
    if (entries.isEmpty) return [];
    
    // Sort entries by start time
    entries.sort((a, b) {
      final aStart = a.startTime.hour * 60 + a.startTime.minute;
      final bStart = b.startTime.hour * 60 + b.startTime.minute;
      return aStart.compareTo(bStart);
    });
    
    final grouped = <TimetableEntry>[];
    
    for (int i = 0; i < entries.length; i++) {
      final current = entries[i];
      
      // Check if this entry should be merged with the previous one
      if (grouped.isNotEmpty) {
        final previous = grouped.last;
        
        // Same subject and teacher
        final sameSubject = current.subjectId == previous.subjectId;
        final sameTeacher = current.teacherId == previous.teacherId;
        
        // Consecutive time slots (current starts when previous ends)
        final previousEnd = previous.endTime.hour * 60 + previous.endTime.minute;
        final currentStart = current.startTime.hour * 60 + current.startTime.minute;
        final consecutive = previousEnd == currentStart;
        
        if (sameSubject && sameTeacher && consecutive) {
          // Merge entries by updating the end time of the previous entry
          grouped[grouped.length - 1] = previous.copyWith(
            endTime: current.endTime,
            updatedAt: DateTime.now(),
          );
          continue;
        }
      }
      
      // Add as a new entry
      grouped.add(current);
    }
    
    return grouped;
  }
}
