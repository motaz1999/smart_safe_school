import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';

class ManageTimetableContent extends StatefulWidget {
  const ManageTimetableContent({super.key});

  @override
  State<ManageTimetableContent> createState() => _ManageTimetableContentState();
}

class _ManageTimetableContentState extends State<ManageTimetableContent> {
  final AdminService _adminService = AdminService();
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  List<SchoolClass> _classes = [];
  List<Subject> _subjects = [];
  List<UserProfile> _teachers = [];
  List<TimetableEntry> _timetableEntries = [];
  
  String? _selectedClassId;
  bool _isLoading = true;
  String? _error;

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

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
  ];

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

      final classes = await _adminService.getClasses();
      final subjects = await _adminService.getSubjects();
      final teachers = await _adminService.getTeachers();

      setState(() {
        _classes = classes;
        _subjects = subjects;
        _teachers = teachers;
        _isLoading = false;
      });

      if (_classes.isNotEmpty && _selectedClassId == null) {
        _selectedClassId = _classes.first.id;
        await _loadTimetable();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTimetable() async {
    if (_selectedClassId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user's school ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('school_id')
          .eq('id', user.id)
          .single();

      final schoolId = profileResponse['school_id'] as int;

      final response = await _supabase
          .from('timetables')
          .select('''
            *,
            subjects(name, code),
            profiles!timetables_teacher_id_fkey(name)
          ''')
          .eq('class_id', _selectedClassId!)
          .eq('school_id', schoolId);
      
      final entries = <TimetableEntry>[];
      for (final json in response) {
        try {
          // Add schoolId to the JSON for the fromJson method
          final jsonWithSchoolId = Map<String, dynamic>.from(json);
          jsonWithSchoolId['school_id'] = schoolId;
          
          // Get class name
          String className = '';
          if (_classes.isNotEmpty && json['class_id'] != null) {
            try {
              final classObj = _classes.firstWhere(
                (c) => c.id == json['class_id'],
              );
              className = classObj.name;
            } catch (e) {
              className = 'Unknown';
            }
          }
          jsonWithSchoolId['class_name'] = className;
          
          final entry = TimetableEntry.fromJson(jsonWithSchoolId);
          entries.add(entry);
        } catch (entryError) {
          print('Error processing entry: $entryError');
        }
      }
      
      setState(() {
        _timetableEntries = entries;
        _isLoading = false;
      });
      
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timetable: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Class Selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Select Class: '),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  isExpanded: true,
                  items: _classes.map((schoolClass) {
                    return DropdownMenuItem(
                      value: schoolClass.id,
                      child: Text(schoolClass.name),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      _selectedClassId = value;
                    });
                    await _loadTimetable();
                  },
                ),
              ),
            ],
          ),
        ),

        // Timetable Grid
        Expanded(
          child: _isLoading
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
                  : _selectedClassId == null
                      ? const Center(child: Text('Please select a class'))
                      : _buildTimetableGrid(),
        ),
      ],
    );
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
              for (int i = 1; i <= _daysOfWeek.length; i++)
                i: const FixedColumnWidth(150),
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[100]),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ..._daysOfWeek.map((day) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        ..._daysOfWeek.map((day) => _buildTimetableCell(day, timeSlot, startTime, endTime)),
      ],
    );
  }

  Widget _buildTimetableCell(String day, String timeSlot, TimeOfDay startTime, TimeOfDay endTime) {
    final dayEnum = DayOfWeek.values.firstWhere(
      (e) => e.name.toLowerCase() == day.toLowerCase(),
    );
    
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
      return GestureDetector(
        onTap: () => _showTimetableEntryDialog(day, timeSlot, startTime, endTime, null),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.grey),
          ),
        ),
      );
    }
    
    // If we have one entry, display it normally
    if (groupedEntries.length == 1) {
      final entry = groupedEntries.first;
      return _buildTimetableEntryCell(entry, day, timeSlot, startTime, endTime);
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
            child: _buildTimetableEntryCell(entry, day, timeSlot, startTime, endTime, isCompact: true)
          )
        ).toList(),
      ),
    );
  }
  
  Widget _buildTimetableEntryCell(TimetableEntry entry, String day, String timeSlot, TimeOfDay startTime, TimeOfDay endTime, {bool isCompact = false}) {
    return GestureDetector(
      onTap: () => _showTimetableEntryDialog(day, timeSlot, startTime, endTime, entry),
      child: Container(
        height: isCompact ? null : 80,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.grey[300]!),
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
          ],
        ),
      ),
    );
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

  void _showTimetableEntryDialog(String day, String timeSlot, TimeOfDay startTime, TimeOfDay endTime, TimetableEntry? entry) {
    showDialog(
      context: context,
      builder: (context) => TimetableEntryDialog(
        day: day,
        timeSlot: timeSlot,
        entry: entry,
        subjects: _subjects,
        teachers: _teachers,
        onSave: (subjectId, teacherId) async {
          try {
            // Check for teacher scheduling conflicts
            final hasConflict = await _adminService.checkTeacherConflict(
              teacherId: teacherId,
              dayOfWeek: day.toLowerCase(),
              startTime: startTime,
              endTime: endTime,
              entryId: entry?.id, // Pass entry ID for updates to exclude it from conflict check
            );
            
            if (hasConflict) {
              // Show conflict error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This teacher is already assigned to another subject during this time slot.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return; // Don't proceed with saving
            }
            
            if (entry != null && entry.id.isNotEmpty) {
              // Update existing entry
              await _supabase.from('timetables').update({
                'subject_id': subjectId,
                'teacher_id': teacherId,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', entry.id);
            } else {
              // Create new entry
              // Get current user's school ID
              final user = _supabase.auth.currentUser;
              if (user == null) {
                throw Exception('User not authenticated');
              }
              
              final profileResponse = await _supabase
                  .from('profiles')
                  .select('school_id')
                  .eq('id', user.id)
                  .single();
              
              final schoolId = profileResponse['school_id'] as int;
              
              await _supabase.from('timetables').insert({
                'school_id': schoolId,
                'class_id': _selectedClassId!,
                'subject_id': subjectId,
                'teacher_id': teacherId,
                'day_of_week': day.toLowerCase(),
                'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
                'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
              });
            }
            await _loadTimetable();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timetable updated successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating timetable: $e')),
              );
            }
          }
        },
        onDelete: entry != null && entry.id.isNotEmpty
            ? () async {
                try {
                  await _supabase.from('timetables').delete().eq('id', entry.id);
                  await _loadTimetable();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Timetable entry deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting entry: $e')),
                    );
                  }
                }
              }
            : null,
      ),
    );
  }
}

class TimetableEntryDialog extends StatefulWidget {
  final String day;
  final String timeSlot;
  final TimetableEntry? entry;
  final List<Subject> subjects;
  final List<UserProfile> teachers;
  final Function(String subjectId, String teacherId) onSave;
  final VoidCallback? onDelete;

  const TimetableEntryDialog({
    super.key,
    required this.day,
    required this.timeSlot,
    this.entry,
    required this.subjects,
    required this.teachers,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<TimetableEntryDialog> createState() => _TimetableEntryDialogState();
}

class _TimetableEntryDialogState extends State<TimetableEntryDialog> {
  String? _selectedSubjectId;
  String? _selectedTeacherId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _selectedSubjectId = widget.entry!.subjectId;
      _selectedTeacherId = widget.entry!.teacherId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null && widget.entry!.id.isNotEmpty;

    return AlertDialog(
      title: Text('${isEditing ? 'Edit' : 'Add'} Timetable Entry'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day: ${widget.day}'),
                  Text('Time: ${widget.timeSlot}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: widget.subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject.id,
                        child: Text('${subject.name} (${subject.code})'),
                      );
                    }).toList(),
                    onChanged: _isLoading ? null : (value) => setState(() => _selectedSubjectId = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedTeacherId,
                    decoration: const InputDecoration(labelText: 'Teacher'),
                    items: widget.teachers.map((teacher) {
                      return DropdownMenuItem(
                        value: teacher.id,
                        child: Text(teacher.name),
                      );
                    }).toList(),
                    onChanged: _isLoading ? null : (value) => setState(() => _selectedTeacherId = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                ],
              ),
            ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.onDelete!();
                  },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedSubjectId == null || _selectedTeacherId == null
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    await widget.onSave(_selectedSubjectId!, _selectedTeacherId!);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}