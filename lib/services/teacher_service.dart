import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/models.dart';

class TeacherService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Gets all classes and subjects that the current teacher is assigned to
  Future<List<TeacherClassSubject>> getTeacherClassesAndSubjects() async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw TeacherException('User not authenticated');
      }

      // Get current user's school ID
      final profileResponse = await _supabase
          .from('profiles')
          .select('school_id')
          .eq('id', user.id)
          .single();

      final schoolId = profileResponse['school_id'] as int;

      // Query timetable entries for this teacher
      final response = await _supabase
          .from('timetables')
          .select('''
            class_id,
            classes(name),
            subject_id,
            subjects(name, code)
          ''')
          .eq('teacher_id', user.id)
          .eq('school_id', schoolId);

      // Create a set to store unique class/subject combinations
      final uniqueCombinations = <String, TeacherClassSubject>{};

      // Process each timetable entry
      for (final entry in response) {
        final classId = entry['class_id'] as String;
        final className = entry['classes']['name'] as String;
        final subjectId = entry['subject_id'] as String;
        final subjectName = entry['subjects']['name'] as String;
        final subjectCode = entry['subjects']['code'] as String;

        // Create a unique key for this combination
        final key = '$classId-$subjectId';

        // If we haven't seen this combination before, add it
        if (!uniqueCombinations.containsKey(key)) {
          // Get student count for this class
          final studentCountResponse = await _supabase
              .from('profiles')
              .select('id')
              .eq('class_id', classId)
              .eq('user_type', 'student')
              .eq('school_id', schoolId);

          uniqueCombinations[key] = TeacherClassSubject(
            id: key,
            createdAt: DateTime.now(),
            classId: classId,
            className: className,
            subjectId: subjectId,
            subjectName: subjectName,
            subjectCode: subjectCode,
            studentCount: studentCountResponse.length,
          );
        }
      }

      // Convert the map values to a list
      return uniqueCombinations.values.toList();
    } catch (e) {
      throw TeacherException('Failed to get teacher classes and subjects: $e');
    }
  }

  /// Gets students in a specific class for a specific subject
  Future<List<UserProfile>> getStudentsInClass(String classId, String subjectId) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw TeacherException('User not authenticated');
      }

      // Get current user's school ID
      final profileResponse = await _supabase
          .from('profiles')
          .select('school_id')
          .eq('id', user.id)
          .single();

      final schoolId = profileResponse['school_id'] as int;

      // Get all students in the school using the RPC function
      final response = await _supabase.rpc('get_users_by_type', params: {
        'p_school_id': schoolId,
        'p_user_type': 'student',
      });

      // Filter students by classId
      final studentsInClass = (response as List)
          .where((json) => json['class_id'] == classId)
          .map((json) => UserProfile.fromJson(json))
          .toList();

      return studentsInClass;
    } catch (e) {
      throw TeacherException('Failed to get students in class: $e');
    }
  }

  /// Saves a list of grades to the database
  Future<void> saveGrades(List<Grade> grades) async {
    try {
      // Convert grades to JSON format for database insertion
      final gradesJson = grades.map((grade) {
        final json = grade.toJson();
        // Remove UI-only fields that don't exist in the database
        json.remove('student_name');
        json.remove('subject_name');
        json.remove('subject_code');
        json.remove('teacher_name');
        json.remove('semester_name');
        // Remove updated_at if it's null
        if (json['updated_at'] == null) {
          json.remove('updated_at');
        }
        // Remove id if it's empty since the database will generate it
        if (json['id'] == '') {
          json.remove('id');
        }
        return json;
      }).toList();

      // Insert grades into the database
      await _supabase
          .from('grades')
          .upsert(gradesJson, onConflict: 'student_id,subject_id,semester_id,grade_number');
    } catch (e) {
      throw TeacherException('Failed to save grades: $e');
    }
  }

  /// Gets existing grades for a specific class, subject, academic year, semester, and grade number
  Future<List<Grade>> getGrades(String classId, String subjectId, String academicYearId, String semesterId, int gradeNumber) async {
    try {
      // If semesterId is empty, return an empty list
      if (semesterId.isEmpty) {
        return [];
      }
      
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw TeacherException('User not authenticated');
      }
      
      // First, get all students in the specified class
      final studentsInClass = await getStudentsInClass(classId, subjectId);
      final studentIdsInClass = studentsInClass.map((student) => student.id).toSet();
      
      // Query the database for grades
      final response = await _supabase
          .from('grades')
          .select('''
            *,
            student:profiles!grades_student_id_fkey(name),
            subject:subjects!grades_subject_id_fkey(name, code),
            semester:semesters!grades_semester_id_fkey(name)
          ''')
          .eq('subject_id', subjectId)
          .eq('semester_id', semesterId)
          .eq('grade_number', gradeNumber)
          .eq('teacher_id', user.id);
      
      // Filter grades to only include those for students in the class
      final filteredResponse = (response as List)
          .where((json) => studentIdsInClass.contains(json['student_id']))
          .toList();
      
      // Convert response to Grade objects
      return filteredResponse.map((json) {
        // Add related data from the joined tables
        json['student_name'] = json['student']?['name'];
        json['subject_name'] = json['subject']?['name'];
        json['subject_code'] = json['subject']?['code'];
        json['semester_name'] = json['semester']?['name'];
        return Grade.fromJson(json);
      }).toList();
    } catch (e) {
      throw TeacherException('Failed to get grades: $e');
    }
  }
  
  /// Gets the current academic year and semester for the teacher's school
  Future<Map<String, dynamic>?> getCurrentAcademicPeriod() async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      // Get current academic year
      final academicYearResponse = await _supabase
          .from('academic_years')
          .select('*')
          .eq('school_id', schoolId)
          .eq('is_current', true)
          .maybeSingle();
      
      if (academicYearResponse == null) {
        return null;
      }
      
      final academicYear = AcademicYear.fromJson(academicYearResponse);
      
      // Get current semester
      final semesterResponse = await _supabase.rpc('get_current_semester', params: {
        'p_school_id': schoolId,
      });
      
      if (semesterResponse == null || (semesterResponse as List).isEmpty) {
        return {
          'academicYear': academicYear,
          'semester': null,
        };
      }
      
      final semesterData = semesterResponse[0];
      final semester = Semester(
        id: semesterData['semester_id'],
        createdAt: DateTime.now(),
        academicYearId: academicYear.id,
        name: semesterData['semester_name'],
        semesterNumber: semesterData['semester_number'],
        startDate: DateTime.now(), // Placeholder
        endDate: DateTime.now(), // Placeholder
      );
      
      return {
        'academicYear': academicYear,
        'semester': semester,
      };
    } catch (e) {
      throw TeacherException('Failed to get current academic period: $e');
    }
  }

  /// Helper method to get current user's school ID
  Future<int> _getCurrentUserSchoolId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw TeacherException('User not authenticated');
      }

      final response = await _supabase
          .from('profiles')
          .select('school_id')
          .eq('id', user.id)
          .single();

      return response['school_id'] as int;
    } catch (e) {
      throw TeacherException('Failed to get user school ID: $e');
    }
  }
/// Gets all academic years for the current school
  Future<List<AcademicYear>> getAcademicYears() async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      final response = await _supabase
          .from('academic_years')
          .select('*')
          .eq('school_id', schoolId)
          .order('start_date', ascending: false);
      
      return response.map((json) => AcademicYear.fromJson(json)).toList();
    } catch (e) {
      throw TeacherException('Failed to get academic years: $e');
    }
  }
  
  /// Gets all semesters for the current school
  Future<List<Semester>> getSemesters() async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      // First get all academic years for this school
      final academicYearsResponse = await _supabase
          .from('academic_years')
          .select('id')
          .eq('school_id', schoolId);
      
      final academicYearIds = academicYearsResponse.map((ay) => ay['id']).toList();
      
      if (academicYearIds.isEmpty) {
        return [];
      }
      
      // Then get all semesters for these academic years
      final response = await _supabase
          .from('semesters')
          .select('''
            *,
            academic_year:academic_years!semesters_academic_year_id_fkey(name)
          ''')
          .inFilter('academic_year_id', academicYearIds)
          .order('start_date', ascending: false);
      
      return response.map((json) {
        // Add academic year name to the semester
        json['academic_year_name'] = json['academic_year']?['name'];
        return Semester.fromJson(json);
      }).toList();
    } catch (e) {
      throw TeacherException('Failed to get semesters: $e');
    }
  }
  
  /// Gets the current semester for the current school
  Future<Semester?> getCurrentSemester() async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      final response = await _supabase.rpc('get_current_semester', params: {
        'p_school_id': schoolId,
      });
      
      if (response == null || (response as List).isEmpty) {
        return null;
      }
      
      final semesterData = response[0];
      return Semester(
        id: semesterData['semester_id'],
        createdAt: DateTime.now(),
        academicYearId: '', // This won't be used in this context
        name: semesterData['semester_name'],
        semesterNumber: semesterData['semester_number'],
        startDate: DateTime.now(), // Placeholder
        endDate: DateTime.now(), // Placeholder
      );
    } catch (e) {
      throw TeacherException('Failed to get current semester: $e');
    }
  }

  /// Gets all grades for the teacher organized by semester, subject, and grade number
  Future<Map<String, Map<String, Map<int, List<Grade>>>>> getAllTeacherGrades() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw TeacherException('User not authenticated');
      }

      print('=== GET ALL TEACHER GRADES START ===');
      print('Teacher ID: ${user.id}');

      // Get all grades for this teacher with related data
      final response = await _supabase
          .from('grades')
          .select('''
            *,
            student:profiles!grades_student_id_fkey(name, class_id),
            subject:subjects!grades_subject_id_fkey(name, code),
            semester:semesters!grades_semester_id_fkey(name, academic_year_id),
            academic_year:semesters!grades_semester_id_fkey(academic_year:academic_years!semesters_academic_year_id_fkey(name))
          ''')
          .eq('teacher_id', user.id)
          .order('created_at', ascending: false);

      print('Found ${response.length} grades');

      // Organize grades by semester -> subject -> grade number
      final Map<String, Map<String, Map<int, List<Grade>>>> organizedGrades = {};

      for (final gradeJson in response) {
        try {
          // Extract related data
          final studentName = gradeJson['student']?['name'] ?? 'Unknown Student';
          final subjectName = gradeJson['subject']?['name'] ?? 'Unknown Subject';
          final subjectCode = gradeJson['subject']?['code'] ?? '';
          final semesterName = gradeJson['semester']?['name'] ?? 'Unknown Semester';
          final semesterId = gradeJson['semester_id'] as String;
          final subjectId = gradeJson['subject_id'] as String;
          final gradeNumber = gradeJson['grade_number'] as int;

          // Add related data to grade JSON
          gradeJson['student_name'] = studentName;
          gradeJson['subject_name'] = subjectName;
          gradeJson['subject_code'] = subjectCode;
          gradeJson['semester_name'] = semesterName;

          // Create Grade object
          final grade = Grade.fromJson(gradeJson);

          // Organize by semester
          if (!organizedGrades.containsKey(semesterId)) {
            organizedGrades[semesterId] = {};
          }

          // Organize by subject within semester
          if (!organizedGrades[semesterId]!.containsKey(subjectId)) {
            organizedGrades[semesterId]![subjectId] = {};
          }

          // Organize by grade number within subject
          if (!organizedGrades[semesterId]![subjectId]!.containsKey(gradeNumber)) {
            organizedGrades[semesterId]![subjectId]![gradeNumber] = [];
          }

          // Add grade to the organized structure
          organizedGrades[semesterId]![subjectId]![gradeNumber]!.add(grade);

          print('Added grade for ${studentName} in ${subjectName} (${semesterName}) - Grade ${gradeNumber}: ${grade.gradeValue}');
        } catch (e) {
          print('Error processing grade: $e');
          continue;
        }
      }

      print('=== GET ALL TEACHER GRADES END (SUCCESS) ===');
      return organizedGrades;
    } catch (e) {
      print('=== GET ALL TEACHER GRADES ERROR ===');
      print('Error: $e');
      throw TeacherException('Failed to get all teacher grades: $e');
    }
  }

  /// Gets grade statistics for the teacher
  Future<Map<String, dynamic>> getGradeStatistics() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw TeacherException('User not authenticated');
      }

      // Get all grades for this teacher
      final response = await _supabase
          .from('grades')
          .select('grade_value, semester_id, subject_id')
          .eq('teacher_id', user.id);

      final totalGrades = response.length;
      final uniqueSemesters = <String>{};
      final uniqueSubjects = <String>{};
      double totalGradeValue = 0.0;

      for (final grade in response) {
        uniqueSemesters.add(grade['semester_id']);
        uniqueSubjects.add(grade['subject_id']);
        totalGradeValue += (grade['grade_value'] as num).toDouble();
      }

      final averageGrade = totalGrades > 0 ? totalGradeValue / totalGrades : 0.0;

      return {
        'total_grades': totalGrades,
        'unique_semesters': uniqueSemesters.length,
        'unique_subjects': uniqueSubjects.length,
        'average_grade': averageGrade,
      };
    } catch (e) {
      throw TeacherException('Failed to get grade statistics: $e');
    }
  }
}

class TeacherException implements Exception {
  final String message;
  TeacherException(this.message);

  @override
  String toString() => message;
}