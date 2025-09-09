import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../models/absence_record.dart';
import '../models/absence_summary_stats.dart';
import '../models/class_absence_stats.dart';
import '../models/student_absence_stats.dart';
import '../providers/auth_provider.dart';
import '../core/config/supabase_config.dart';

class AttendanceService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Saves a list of attendance records to the database
  Future<void> saveAttendanceRecords(List<AttendanceRecord> records) async {
    try {
      // Convert records to JSON format for database insertion
      // Exclude updated_at field as it doesn't exist in the attendance_records table
      final recordsJson = records.map((record) {
        final json = record.toJson();
        // Remove fields that don't exist in the attendance_records table
        json.remove('updated_at'); // Remove updated_at as it's not in the table schema
        // Remove id if it's empty since the database will generate it
        if (json['id'] == '') {
          json.remove('id');
        }
        // Remove UI-only fields that don't exist in the database
        json.remove('student_name');
        json.remove('subject_name');
        json.remove('teacher_name');
        return json;
      }).toList();
      
      // Insert records into the database
      await _supabase
          .from('attendance_records')
          .upsert(recordsJson, onConflict: 'student_id,subject_id,attendance_date');
    } catch (e) {
      throw Exception('Failed to save attendance records: $e');
    }
  }

  /// Loads attendance records for a specific class, subject, and date
  Future<List<AttendanceRecord>> loadAttendanceRecords({
    required String classId,
    required String subjectId,
    required DateTime date,
  }) async {
    try {
      // Format date as string for query
      final dateString = date.toIso8601String().split('T')[0];
      
      // Query the database for attendance records
      final response = await _supabase
          .from('attendance_records')
          .select('''
            *,
            student:profiles!attendance_records_student_id_fkey(name)
          ''')
          .eq('subject_id', subjectId)
          .eq('attendance_date', dateString);
      
      // Convert response to AttendanceRecord objects
      return response.map((json) {
        // Add student_name from the joined profiles table
        json['student_name'] = json['student']?['name'];
        return AttendanceRecord.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load attendance records: $e');
    }
  }

  /// Updates a single attendance record
  Future<void> updateAttendanceRecord(AttendanceRecord record) async {
    try {
      // Convert record to JSON and remove updated_at field
      final json = record.toJson();
      // Remove fields that don't exist in the attendance_records table
      json.remove('updated_at'); // Remove updated_at as it's not in the table schema
      // Remove id if it's empty (for new records)
      if (json['id'] == '') {
        json.remove('id');
      }
      // Remove UI-only fields that don't exist in the database
      json.remove('student_name');
      json.remove('subject_name');
      json.remove('teacher_name');
      
      await _supabase
          .from('attendance_records')
          .update(json)
          .eq('id', record.id);
    } catch (e) {
      throw Exception('Failed to update attendance record: $e');
    }
  }

  /// Deletes an attendance record
  Future<void> deleteAttendanceRecord(String recordId) async {
    try {
      await _supabase
          .from('attendance_records')
          .delete()
          .eq('id', recordId);
    } catch (e) {
      throw Exception('Failed to delete attendance record: $e');
    }
  }

  /// Checks if attendance has already been marked for a class, subject, and date
  Future<bool> doesAttendanceExist({
    required String classId,
    required String subjectId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .from('attendance_records')
          .select('id')
          .eq('subject_id', subjectId)
          .eq('attendance_date', dateString)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check attendance existence: $e');
    }
  }

  /// Gets attendance records for a specific student
  Future<List<AttendanceRecord>> getStudentAttendanceRecords({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      // Set default date range if not provided (last 30 days)
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));
      
      final startDateStr = start.toIso8601String().split('T')[0];
      final endDateStr = end.toIso8601String().split('T')[0];

      // Query attendance records for the student
      var query = _supabase
          .from('attendance_records')
          .select('''
            *,
            subject:subjects!attendance_records_subject_id_fkey(name),
            teacher:profiles!attendance_records_teacher_id_fkey(name)
          ''')
          .eq('student_id', studentId)
          .gte('attendance_date', startDateStr)
          .lte('attendance_date', endDateStr)
          .order('attendance_date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      // Convert response to AttendanceRecord objects
      return response.map((json) {
        // Add subject and teacher names from joined tables
        json['subject_name'] = json['subject']?['name'];
        json['teacher_name'] = json['teacher']?['name'];
        return AttendanceRecord.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load student attendance records: $e');
    }
  }

  /// Gets attendance records for all students taught by a specific teacher
  Future<List<AttendanceRecord>> getTeacherStudentAttendanceRecords({
    required String teacherId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? classId,
    String? subjectId,
  }) async {
    try {
      // Set default date range if not provided (last 30 days)
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));
      
      final startDateStr = start.toIso8601String().split('T')[0];
      final endDateStr = end.toIso8601String().split('T')[0];

      // Build the base query
      var baseQuery = _supabase
          .from('attendance_records')
          .select('''
            *,
            student:profiles!attendance_records_student_id_fkey(
              id,
              name,
              user_id,
              class_id
            ),
            subject:subjects!attendance_records_subject_id_fkey(name),
            teacher:profiles!attendance_records_teacher_id_fkey(name)
          ''')
          .eq('teacher_id', teacherId)
          .gte('attendance_date', startDateStr)
          .lte('attendance_date', endDateStr);

      // Apply optional filters
      if (subjectId != null) {
        baseQuery = baseQuery.eq('subject_id', subjectId);
      }

      // Apply ordering and limit
      var finalQuery = baseQuery.order('attendance_date', ascending: false);
      
      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;

      // Filter by class_id if specified (done after query since we can't filter on joined table directly)
      List<dynamic> filteredResponse = response;
      if (classId != null) {
        filteredResponse = response.where((record) {
          return record['student']?['class_id'] == classId;
        }).toList();
      }

      // Get class names for students separately
      final studentClassIds = response
          .map((json) => json['student']?['class_id'])
          .where((classId) => classId != null)
          .toSet()
          .toList();

      Map<String, String> classNames = {};
      if (studentClassIds.isNotEmpty) {
        try {
          final classResponse = await _supabase
              .from('classes')
              .select('id, name')
              .inFilter('id', studentClassIds);
          
          for (final classData in classResponse) {
            classNames[classData['id']] = classData['name'];
          }
        } catch (e) {
          // If class lookup fails, continue without class names
          print('Warning: Could not load class names: $e');
        }
      }

      // Convert response to AttendanceRecord objects
      return response.map((json) {
        // Add student, subject, and teacher names from joined tables
        final student = json['student'];
        final subject = json['subject'];
        final teacher = json['teacher'];
        final classId = student?['class_id'];
        
        json['student_name'] = student?['name'];
        json['subject_name'] = subject?['name'];
        json['teacher_name'] = teacher?['name'];
        json['class_name'] = classNames[classId];
        json['student_number'] = student?['user_id'];
        
        return AttendanceRecord.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load teacher student attendance records: $e');
    }
  }

  // ============================================================================
  // ABSENCE-FOCUSED METHODS
  // ============================================================================

  /// Validates admin access for absence reports
  Future<void> _validateAdminAccess(BuildContext? context) async {
    if (context == null) {
      throw Exception('Context required for admin validation');
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      throw Exception('Admin access required for absence reports');
    }
  }

  /// Get all absence records for a date range with optional filters
  Future<List<AbsenceRecord>> getAbsenceRecords({
    required DateTime startDate,
    required DateTime endDate,
    String? classId,
    String? subjectId,
    String? studentId,
    String? searchQuery,
    int? limit,
    int? offset,
    BuildContext? context,
  }) async {
    try {
      // Validate admin access
      if (context != null) {
        await _validateAdminAccess(context);
      }

      // Build the query step by step
      var query = _supabase
          .from('attendance_records')
          .select('''
            *,
            student:profiles!attendance_records_student_id_fkey(
              id,
              name,
              user_id,
              class_id
            ),
            subject:subjects!attendance_records_subject_id_fkey(name),
            teacher:profiles!attendance_records_teacher_id_fkey(name)
          ''')
          .eq('is_present', false)
          .gte('attendance_date', startDate.toIso8601String().split('T')[0])
          .lte('attendance_date', endDate.toIso8601String().split('T')[0]);

      // Apply filters
      if (classId != null) {
        query = query.eq('student.class_id', classId);
      }
      
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      
      if (studentId != null) {
        query = query.eq('student_id', studentId);
      }

      // Apply search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'student.name.ilike.%$searchQuery%,'
          'student.user_id.ilike.%$searchQuery%,'
          'subject.name.ilike.%$searchQuery%,'
          'teacher.name.ilike.%$searchQuery%'
        );
      }

      // Apply ordering and pagination in final step
      var finalQuery = query.order('attendance_date', ascending: false);

      if (limit != null && offset != null) {
        finalQuery = finalQuery.range(offset, offset + limit - 1);
      } else if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;

      // Get class names for students separately
      final studentClassIds = response
          .map((json) => json['student']?['class_id'])
          .where((classId) => classId != null)
          .toSet()
          .toList();

      Map<String, String> classNames = {};
      if (studentClassIds.isNotEmpty) {
        try {
          final classResponse = await _supabase
              .from('classes')
              .select('id, name')
              .inFilter('id', studentClassIds);
          
          for (final classData in classResponse) {
            classNames[classData['id']] = classData['name'];
          }
        } catch (e) {
          // If class lookup fails, continue without class names
          print('Warning: Could not load class names: $e');
        }
      }

      return response.map((json) {
        // Extract nested data
        final student = json['student'];
        final subject = json['subject'];
        final teacher = json['teacher'];
        final classId = student?['class_id'] ?? '';

        return AbsenceRecord(
          id: json['id'],
          createdAt: DateTime.parse(json['created_at']),
          studentId: json['student_id'],
          studentName: student?['name'] ?? 'Unknown Student',
          studentNumber: student?['user_id'] ?? '',
          classId: classId,
          className: classNames[classId] ?? 'Unknown Class',
          subjectId: json['subject_id'],
          subjectName: subject?['name'] ?? 'Unknown Subject',
          teacherId: json['teacher_id'],
          teacherName: teacher?['name'] ?? 'Unknown Teacher',
          absenceDate: DateTime.parse(json['attendance_date']),
          notes: json['notes'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load absence records: $e');
    }
  }

  /// Get absence summary statistics for a date range
  Future<AbsenceSummaryStats> getAbsenceSummary({
    required DateTime startDate,
    required DateTime endDate,
    BuildContext? context,
  }) async {
    try {
      // Validate admin access
      if (context != null) {
        await _validateAdminAccess(context);
      }

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      // Get basic absence statistics
      final absenceQuery = await _supabase
          .from('attendance_records')
          .select('id, student_id, attendance_date, notes')
          .eq('is_present', false)
          .gte('attendance_date', startDateStr)
          .lte('attendance_date', endDateStr);

      final totalAbsences = absenceQuery.length;
      final uniqueStudentsAbsent = absenceQuery
          .map((record) => record['student_id'])
          .toSet()
          .length;
      
      final uniqueDates = absenceQuery
          .map((record) => record['attendance_date'])
          .toSet()
          .length;

      final averageAbsencesPerDay = uniqueDates > 0
          ? totalAbsences / uniqueDates
          : 0.0;

      // Get total possible attendance records for absence rate calculation
      final totalRecordsQuery = await _supabase
          .from('attendance_records')
          .select('id')
          .gte('attendance_date', startDateStr)
          .lte('attendance_date', endDateStr);

      final totalRecords = totalRecordsQuery.length;
      final absenceRate = totalRecords > 0
          ? (totalAbsences / totalRecords) * 100
          : 0.0;

      // Get most absent class
      final classAbsencesQuery = await _supabase
          .from('attendance_records')
          .select('''
            student_id,
            profiles!attendance_records_student_id_fkey(
              class_id
            )
          ''')
          .eq('is_present', false)
          .gte('attendance_date', startDateStr)
          .lte('attendance_date', endDateStr);

      // Get class names separately
      final classIds = classAbsencesQuery
          .map((record) => record['profiles']?['class_id'])
          .where((classId) => classId != null)
          .toSet()
          .toList();

      Map<String, String> classIdToName = {};
      if (classIds.isNotEmpty) {
        try {
          final classNamesQuery = await _supabase
              .from('classes')
              .select('id, name')
              .inFilter('id', classIds);
          
          for (final classData in classNamesQuery) {
            classIdToName[classData['id']] = classData['name'];
          }
        } catch (e) {
          print('Warning: Could not load class names for summary: $e');
        }
      }

      final classAbsenceCounts = <String, int>{};
      for (final record in classAbsencesQuery) {
        final classId = record['profiles']?['class_id'];
        final className = classIdToName[classId];
        if (className != null) {
          classAbsenceCounts[className] = (classAbsenceCounts[className] ?? 0) + 1;
        }
      }

      final mostAbsentClass = classAbsenceCounts.isNotEmpty
          ? classAbsenceCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : null;

      // Get most absent subject
      final subjectAbsencesQuery = await _supabase
          .from('attendance_records')
          .select('''
            subject_id,
            subjects!attendance_records_subject_id_fkey(name)
          ''')
          .eq('is_present', false)
          .gte('attendance_date', startDateStr)
          .lte('attendance_date', endDateStr);

      final subjectAbsenceCounts = <String, int>{};
      for (final record in subjectAbsencesQuery) {
        final subjectName = record['subjects']?['name'];
        if (subjectName != null) {
          subjectAbsenceCounts[subjectName] = (subjectAbsenceCounts[subjectName] ?? 0) + 1;
        }
      }

      final mostAbsentSubject = subjectAbsenceCounts.isNotEmpty
          ? subjectAbsenceCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : null;

      // Get top absent students
      final studentAbsenceCounts = <String, int>{};
      final studentNames = <String, String>{};
      
      for (final record in absenceQuery) {
        final studentId = record['student_id'];
        studentAbsenceCounts[studentId] = (studentAbsenceCounts[studentId] ?? 0) + 1;
      }

      // Get student names for top absent students
      if (studentAbsenceCounts.isNotEmpty) {
        final topStudentIds = studentAbsenceCounts.entries
            .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
        
        final topStudentIdsToQuery = topStudentIds
            .take(5)
            .map((e) => e.key)
            .toList();

        final studentNamesQuery = await _supabase
            .from('profiles')
            .select('id, name')
            .inFilter('id', topStudentIdsToQuery);

        for (final student in studentNamesQuery) {
          studentNames[student['id']] = student['name'];
        }
      }

      final topAbsentStudents = studentAbsenceCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      final topAbsentStudentNames = topAbsentStudents
          .take(5)
          .map((e) => studentNames[e.key] ?? 'Unknown')
          .toList();

      // Analyze absence reasons
      final absencesByReason = <String, int>{};
      for (final record in absenceQuery) {
        final notes = record['notes'] as String?;
        if (notes != null && notes.isNotEmpty) {
          // Simple categorization based on common keywords
          if (notes.toLowerCase().contains('sick')) {
            absencesByReason['Sick'] = (absencesByReason['Sick'] ?? 0) + 1;
          } else if (notes.toLowerCase().contains('family')) {
            absencesByReason['Family'] = (absencesByReason['Family'] ?? 0) + 1;
          } else if (notes.toLowerCase().contains('medical')) {
            absencesByReason['Medical'] = (absencesByReason['Medical'] ?? 0) + 1;
          } else {
            absencesByReason['Other'] = (absencesByReason['Other'] ?? 0) + 1;
          }
        } else {
          absencesByReason['No reason'] = (absencesByReason['No reason'] ?? 0) + 1;
        }
      }

      return AbsenceSummaryStats(
        totalAbsences: totalAbsences,
        uniqueStudentsAbsent: uniqueStudentsAbsent,
        daysWithAbsences: uniqueDates,
        averageAbsencesPerDay: averageAbsencesPerDay,
        absenceRate: absenceRate,
        mostAbsentClass: mostAbsentClass,
        mostAbsentSubject: mostAbsentSubject,
        topAbsentStudents: topAbsentStudentNames,
        absencesByReason: absencesByReason,
        absencesByClass: classAbsenceCounts,
        absencesBySubject: subjectAbsenceCounts,
      );
    } catch (e) {
      throw Exception('Failed to load absence summary: $e');
    }
  }

  /// Get absence statistics by class
  Future<List<ClassAbsenceStats>> getAbsenceStatsByClass({
    required DateTime startDate,
    required DateTime endDate,
    BuildContext? context,
  }) async {
    try {
      // Validate admin access
      if (context != null) {
        await _validateAdminAccess(context);
      }

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      // Get all classes
      final classesQuery = await _supabase
          .from('classes')
          .select('id, name');

      final classStats = <ClassAbsenceStats>[];

      for (final classData in classesQuery) {
        final classId = classData['id'];
        final className = classData['name'];

        // Get total students in class
        final studentsQuery = await _supabase
            .from('profiles')
            .select('id')
            .eq('class_id', classId)
            .eq('user_type', 'student');

        final totalStudents = studentsQuery.length;

        // Get absence records for this class
        final absenceQuery = await _supabase
            .from('attendance_records')
            .select('''
              id,
              student_id,
              subject_id,
              attendance_date,
              profiles!attendance_records_student_id_fkey(class_id),
              subjects!attendance_records_subject_id_fkey(name)
            ''')
            .eq('is_present', false)
            .eq('profiles.class_id', classId)
            .gte('attendance_date', startDateStr)
            .lte('attendance_date', endDateStr);

        final totalAbsences = absenceQuery.length;
        final studentsWithAbsences = absenceQuery
            .map((record) => record['student_id'])
            .toSet()
            .length;

        // Calculate absence rate (assuming total possible attendance records)
        final totalPossibleRecords = totalStudents *
            endDate.difference(startDate).inDays *
            5; // Assuming 5 subjects per day (rough estimate)
        
        final absenceRate = totalPossibleRecords > 0
            ? (totalAbsences / totalPossibleRecords) * 100
            : 0.0;

        final averageAbsencesPerStudent = totalStudents > 0
            ? totalAbsences / totalStudents
            : 0.0;

        // Get subject breakdown
        final subjectAbsenceCounts = <String, int>{};
        for (final record in absenceQuery) {
          final subjectName = record['subjects']?['name'];
          if (subjectName != null) {
            subjectAbsenceCounts[subjectName] =
                (subjectAbsenceCounts[subjectName] ?? 0) + 1;
          }
        }

        final subjectBreakdown = subjectAbsenceCounts.entries
            .map((entry) => SubjectAbsenceStats(
                  subjectId: '', // We don't have subject ID in this context
                  subjectName: entry.key,
                  absenceCount: entry.value,
                  absenceRate: totalPossibleRecords > 0
                      ? (entry.value / totalPossibleRecords) * 100
                      : 0.0,
                  studentsAffected: 0, // Would need additional query
                ))
            .toList();

        classStats.add(ClassAbsenceStats(
          classId: classId,
          className: className,
          totalStudents: totalStudents,
          studentsWithAbsences: studentsWithAbsences,
          totalAbsences: totalAbsences,
          absenceRate: absenceRate,
          averageAbsencesPerStudent: averageAbsencesPerStudent,
          subjectBreakdown: subjectBreakdown,
          lastAbsenceDate: absenceQuery.isNotEmpty
              ? DateTime.parse(absenceQuery.first['attendance_date'])
              : null,
        ));
      }

      // Sort by total absences (highest first)
      classStats.sort((a, b) => b.totalAbsences.compareTo(a.totalAbsences));

      return classStats;
    } catch (e) {
      throw Exception('Failed to load class absence statistics: $e');
    }
  }

  /// Get students with highest absence rates
  Future<List<StudentAbsenceStats>> getStudentsWithHighAbsences({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
    BuildContext? context,
  }) async {
    try {
      // Validate admin access
      if (context != null) {
        await _validateAdminAccess(context);
      }

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      // Get absence records with student information
      final absenceQuery = await _supabase
          .from('attendance_records')
          .select('''
            student_id,
            attendance_date,
            subject_id,
            profiles!attendance_records_student_id_fkey(
              id,
              name,
              user_id,
              class_id
            ),
            subjects!attendance_records_subject_id_fkey(name)
          ''')
          .eq('is_present', false)
          .gte('attendance_date', startDateStr)
          .lte('attendance_date', endDateStr);

      // Get class names separately
      final studentClassIds = absenceQuery
          .map((record) => record['profiles']?['class_id'])
          .where((classId) => classId != null)
          .toSet()
          .toList();

      Map<String, String> classIdToName = {};
      if (studentClassIds.isNotEmpty) {
        try {
          final classNamesQuery = await _supabase
              .from('classes')
              .select('id, name')
              .inFilter('id', studentClassIds);
          
          for (final classData in classNamesQuery) {
            classIdToName[classData['id']] = classData['name'];
          }
        } catch (e) {
          print('Warning: Could not load class names for student stats: $e');
        }
      }

      // Group by student
      final studentAbsenceData = <String, List<Map<String, dynamic>>>{};
      for (final record in absenceQuery) {
        final studentId = record['student_id'];
        if (!studentAbsenceData.containsKey(studentId)) {
          studentAbsenceData[studentId] = [];
        }
        studentAbsenceData[studentId]!.add(record);
      }

      final studentStats = <StudentAbsenceStats>[];

      for (final entry in studentAbsenceData.entries) {
        final studentId = entry.key;
        final absenceRecords = entry.value;
        
        if (absenceRecords.isEmpty) continue;

        final firstRecord = absenceRecords.first;
        final student = firstRecord['profiles'];
        final classId = student?['class_id'] ?? '';

        final totalAbsences = absenceRecords.length;
        final absenceDates = absenceRecords
            .map((record) => DateTime.parse(record['attendance_date']))
            .toList()
          ..sort();

        // Calculate absence rate (rough estimate)
        final totalDays = endDate.difference(startDate).inDays;
        final absenceRate = totalDays > 0 ? (totalAbsences / totalDays) * 100 : 0.0;

        // Get absences by subject
        final absencesBySubject = <String, int>{};
        for (final record in absenceRecords) {
          final subjectName = record['subjects']?['name'];
          if (subjectName != null) {
            absencesBySubject[subjectName] =
                (absencesBySubject[subjectName] ?? 0) + 1;
          }
        }

        final mostAbsentSubject = absencesBySubject.isNotEmpty
            ? absencesBySubject.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
            : null;

        studentStats.add(StudentAbsenceStats(
          studentId: studentId,
          studentName: student?['name'] ?? 'Unknown Student',
          studentNumber: student?['user_id'] ?? '',
          classId: classId,
          className: classIdToName[classId] ?? 'Unknown Class',
          totalAbsences: totalAbsences,
          absenceRate: absenceRate,
          absenceDates: absenceDates,
          absencesBySubject: absencesBySubject,
          mostAbsentSubject: mostAbsentSubject,
          lastAbsenceDate: absenceDates.isNotEmpty ? absenceDates.last : null,
          firstAbsenceDate: absenceDates.isNotEmpty ? absenceDates.first : null,
          isHighRisk: absenceRate > 20.0, // More than 20% absence rate
        ));
      }

      // Sort by absence rate (highest first) and limit results
      studentStats.sort((a, b) => b.absenceRate.compareTo(a.absenceRate));
      
      return studentStats.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to load student absence statistics: $e');
    }
  }
}