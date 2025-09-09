import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/models.dart';

/// Unified service for grade operations across all user types
class GradeService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Gets organized grades for a specific student
  Future<OrganizedStudentGrades> getStudentGrades(String studentId) async {
    try {
      // Get student's school ID first
      final studentProfile = await _supabase
          .from('profiles')
          .select('school_id, class_id, name')
          .eq('id', studentId)
          .single();

      final schoolId = studentProfile['school_id'] as int;

      // Get all grades for the student with related data
      final response = await _supabase
          .from('grades')
          .select('''
            *,
            subject:subjects!grades_subject_id_fkey(name, code),
            semester:semesters!grades_semester_id_fkey(name, semester_number, academic_year_id),
            academic_year:semesters!grades_semester_id_fkey(academic_year:academic_years!semesters_academic_year_id_fkey(name, start_date, end_date))
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      // Get academic years and semesters for context
      final academicYears = await getAcademicYears(schoolId);
      final semesters = await getAllSemesters(schoolId);

      return _organizeStudentGrades(response, academicYears, semesters, studentProfile);
    } catch (e) {
      throw GradeException('Failed to get student grades: $e');
    }
  }

  /// Gets organized grades for admin view with filtering
  Future<OrganizedSchoolGrades> getSchoolGrades({
    String? classId,
    String? subjectId,
    String? semesterId,
    int? gradeNumber,
  }) async {
    try {
      final schoolId = await _getCurrentUserSchoolId();

      // Build query with filters
      var query = _supabase
          .from('grades')
          .select('''
            *,
            student:profiles!grades_student_id_fkey(name, class_id),
            subject:subjects!grades_subject_id_fkey(name, code),
            semester:semesters!grades_semester_id_fkey(name, semester_number, academic_year_id),
            academic_year:semesters!grades_semester_id_fkey(academic_year:academic_years!semesters_academic_year_id_fkey(name))
          ''');

      // Apply filters
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      if (semesterId != null) {
        query = query.eq('semester_id', semesterId);
      }
      if (gradeNumber != null) {
        query = query.eq('grade_number', gradeNumber);
      }

      final response = await query.order('created_at', ascending: false);

      // Filter by class if specified (done in memory since it's a nested field)
      List<dynamic> filteredResponse = response;
      if (classId != null) {
        filteredResponse = response
            .where((grade) => grade['student']['class_id'] == classId)
            .toList();
      }

      // Get context data
      final classes = await getClasses(schoolId);
      final subjects = await getSubjects(schoolId);
      final academicYears = await getAcademicYears(schoolId);
      final semesters = await getAllSemesters(schoolId);

      return _organizeSchoolGrades(
        filteredResponse,
        classes,
        subjects,
        academicYears,
        semesters,
      );
    } catch (e) {
      throw GradeException('Failed to get school grades: $e');
    }
  }

  /// Gets grade statistics for admin dashboard
  Future<GradeStatistics> getGradeStatistics({
    String? classId,
    String? subjectId,
    String? semesterId,
    int? gradeNumber,
  }) async {
    try {
      final schoolId = await _getCurrentUserSchoolId();

      // Build base query
      var query = _supabase
          .from('grades')
          .select('''
            grade_value,
            student:profiles!grades_student_id_fkey(class_id),
            subject:subjects!grades_subject_id_fkey(name),
            semester:semesters!grades_semester_id_fkey(name)
          ''');

      // Apply filters
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      if (semesterId != null) {
        query = query.eq('semester_id', semesterId);
      }
      if (gradeNumber != null) {
        query = query.eq('grade_number', gradeNumber);
      }

      final response = await query;

      // Filter by class if specified
      List<dynamic> filteredResponse = response;
      if (classId != null) {
        filteredResponse = response
            .where((grade) => grade['student']['class_id'] == classId)
            .toList();
      }

      return _calculateStatistics(filteredResponse);
    } catch (e) {
      throw GradeException('Failed to get grade statistics: $e');
    }
  }

  /// Gets all academic years for the current school
  Future<List<AcademicYear>> getAcademicYears(int schoolId) async {
    try {
      final response = await _supabase
          .from('academic_years')
          .select('*')
          .eq('school_id', schoolId)
          .order('start_date', ascending: false);

      return response.map((json) => AcademicYear.fromJson(json)).toList();
    } catch (e) {
      throw GradeException('Failed to get academic years: $e');
    }
  }

  /// Gets all semesters for the current school
  Future<List<Semester>> getAllSemesters(int schoolId) async {
    try {
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
        json['academic_year_name'] = json['academic_year']?['name'];
        return Semester.fromJson(json);
      }).toList();
    } catch (e) {
      throw GradeException('Failed to get semesters: $e');
    }
  }

  /// Gets all subjects for the current school
  Future<List<Subject>> getSubjects(int schoolId) async {
    try {
      final response = await _supabase
          .from('subjects')
          .select('*')
          .eq('school_id', schoolId)
          .order('name');

      return response.map((json) => Subject.fromJson(json)).toList();
    } catch (e) {
      throw GradeException('Failed to get subjects: $e');
    }
  }

  /// Gets all classes for the current school
  Future<List<SchoolClass>> getClasses(int schoolId) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('*')
          .eq('school_id', schoolId)
          .order('name');

      return response.map((json) => SchoolClass.fromJson(json)).toList();
    } catch (e) {
      throw GradeException('Failed to get classes: $e');
    }
  }

  /// Helper method to get current user's school ID
  Future<int> _getCurrentUserSchoolId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw GradeException('User not authenticated');
      }

      final response = await _supabase
          .from('profiles')
          .select('school_id')
          .eq('id', user.id)
          .single();

      return response['school_id'] as int;
    } catch (e) {
      throw GradeException('Failed to get user school ID: $e');
    }
  }

  /// Organizes student grades by semester and subject
  OrganizedStudentGrades _organizeStudentGrades(
    List<dynamic> grades,
    List<AcademicYear> academicYears,
    List<Semester> semesters,
    Map<String, dynamic> studentProfile,
  ) {
    final Map<String, SemesterGrades> semesterGrades = {};

    for (final gradeJson in grades) {
      try {
        // Extract related data
        final subjectName = gradeJson['subject']?['name'] ?? 'Unknown Subject';
        final subjectCode = gradeJson['subject']?['code'] ?? '';
        final semesterName = gradeJson['semester']?['name'] ?? 'Unknown Semester';
        final semesterId = gradeJson['semester_id'] as String;
        final subjectId = gradeJson['subject_id'] as String;
        final gradeNumber = gradeJson['grade_number'] as int;

        // Add related data to grade JSON
        gradeJson['student_name'] = studentProfile['name'];
        gradeJson['subject_name'] = subjectName;
        gradeJson['subject_code'] = subjectCode;
        gradeJson['semester_name'] = semesterName;

        final grade = Grade.fromJson(gradeJson);

        // Initialize semester if not exists
        if (!semesterGrades.containsKey(semesterId)) {
          final semester = semesters.firstWhere(
            (s) => s.id == semesterId,
            orElse: () => Semester(
              id: semesterId,
              createdAt: DateTime.now(),
              academicYearId: '',
              name: semesterName,
              semesterNumber: 1,
              startDate: DateTime.now(),
              endDate: DateTime.now(),
            ),
          );
          semesterGrades[semesterId] = SemesterGrades(
            semester: semester,
            subjectsBySubjectId: {},
          );
        }

        // Initialize subject if not exists
        if (!semesterGrades[semesterId]!.subjectsBySubjectId.containsKey(subjectId)) {
          semesterGrades[semesterId]!.subjectsBySubjectId[subjectId] = SubjectGrades(
            subject: Subject(
              id: subjectId,
              createdAt: DateTime.now(),
              schoolId: studentProfile['school_id'],
              name: subjectName,
              code: subjectCode,
            ),
            gradesByGradeNumber: {},
          );
        }

        // Add grade to the appropriate grade number
        if (!semesterGrades[semesterId]!.subjectsBySubjectId[subjectId]!.gradesByGradeNumber.containsKey(gradeNumber)) {
          semesterGrades[semesterId]!.subjectsBySubjectId[subjectId]!.gradesByGradeNumber[gradeNumber] = [];
        }

        semesterGrades[semesterId]!.subjectsBySubjectId[subjectId]!.gradesByGradeNumber[gradeNumber]!.add(grade);
      } catch (e) {
        print('Error processing grade: $e');
        continue;
      }
    }

    return OrganizedStudentGrades(
      studentName: studentProfile['name'],
      studentId: studentProfile['id'] ?? '',
      classId: studentProfile['class_id'],
      semestersBySemesterId: semesterGrades,
      academicYears: academicYears,
      semesters: semesters,
    );
  }

  /// Organizes school grades by class, semester, and subject
  OrganizedSchoolGrades _organizeSchoolGrades(
    List<dynamic> grades,
    List<SchoolClass> classes,
    List<Subject> subjects,
    List<AcademicYear> academicYears,
    List<Semester> semesters,
  ) {
    final Map<String, ClassGrades> classGrades = {};

    for (final gradeJson in grades) {
    try {
      // Extract related data
      final studentName = gradeJson['student']?['name'] ?? 'Unknown Student';
      final classId = gradeJson['student']?['class_id'] as String;
      final subjectName = gradeJson['subject']?['name'] ?? 'Unknown Subject';
      final subjectCode = gradeJson['subject']?['code'] ?? '';
      final semesterName = gradeJson['semester']?['name'] ?? 'Unknown Semester';
      final semesterId = gradeJson['semester_id'] as String;
      final subjectId = gradeJson['subject_id'] as String;
      final gradeNumber = gradeJson['grade_number'] as int;

      // Find class name from the classes list
      final schoolClass = classes.firstWhere(
        (c) => c.id == classId,
        orElse: () => SchoolClass(
          id: classId,
          createdAt: DateTime.now(),
          schoolId: 0,
          name: 'Unknown Class',
          capacity: 30,
        ),
      );
      final className = schoolClass.name;

      // Add related data to grade JSON
      gradeJson['student_name'] = studentName;
      gradeJson['subject_name'] = subjectName;
      gradeJson['subject_code'] = subjectCode;
      gradeJson['semester_name'] = semesterName;

      final grade = Grade.fromJson(gradeJson);

      // Initialize class if not exists
      if (!classGrades.containsKey(classId)) {
        classGrades[classId] = ClassGrades(
          schoolClass: schoolClass,
          semestersBySemesterId: {},
        );
      }

        // Initialize semester if not exists
        if (!classGrades[classId]!.semestersBySemesterId.containsKey(semesterId)) {
          final semester = semesters.firstWhere(
            (s) => s.id == semesterId,
            orElse: () => Semester(
              id: semesterId,
              createdAt: DateTime.now(),
              academicYearId: '',
              name: semesterName,
              semesterNumber: 1,
              startDate: DateTime.now(),
              endDate: DateTime.now(),
            ),
          );
          classGrades[classId]!.semestersBySemesterId[semesterId] = SemesterGrades(
            semester: semester,
            subjectsBySubjectId: {},
          );
        }

        // Initialize subject if not exists
        if (!classGrades[classId]!.semestersBySemesterId[semesterId]!.subjectsBySubjectId.containsKey(subjectId)) {
          final subject = subjects.firstWhere(
            (s) => s.id == subjectId,
            orElse: () => Subject(
              id: subjectId,
              createdAt: DateTime.now(),
              schoolId: 0,
              name: subjectName,
              code: subjectCode,
            ),
          );
          classGrades[classId]!.semestersBySemesterId[semesterId]!.subjectsBySubjectId[subjectId] = SubjectGrades(
            subject: subject,
            gradesByGradeNumber: {},
          );
        }

        // Add grade to the appropriate grade number
        final subjectGrades = classGrades[classId]!.semestersBySemesterId[semesterId]!.subjectsBySubjectId[subjectId]!;
        if (!subjectGrades.gradesByGradeNumber.containsKey(gradeNumber)) {
          subjectGrades.gradesByGradeNumber[gradeNumber] = [];
        }

        subjectGrades.gradesByGradeNumber[gradeNumber]!.add(grade);
      } catch (e) {
        print('Error processing grade: $e');
        continue;
      }
    }

    return OrganizedSchoolGrades(
      classesByClassId: classGrades,
      classes: classes,
      subjects: subjects,
      academicYears: academicYears,
      semesters: semesters,
    );
  }

  /// Calculates grade statistics
  GradeStatistics _calculateStatistics(List<dynamic> grades) {
    if (grades.isEmpty) {
      return GradeStatistics(
        totalGrades: 0,
        averageGrade: 0.0,
        highestGrade: 0.0,
        lowestGrade: 0.0,
        gradeDistribution: {},
      );
    }

    final gradeValues = grades.map((g) => (g['grade_value'] as num).toDouble()).toList();
    final totalGrades = gradeValues.length;
    final averageGrade = gradeValues.reduce((a, b) => a + b) / totalGrades;
    final highestGrade = gradeValues.reduce((a, b) => a > b ? a : b);
    final lowestGrade = gradeValues.reduce((a, b) => a < b ? a : b);

    // Calculate grade distribution (A, B, C, D, F)
    final Map<String, int> distribution = {
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'F': 0,
    };

    for (final gradeValue in gradeValues) {
      final percentage = (gradeValue / 20) * 100;
      if (percentage >= 90) {
        distribution['A'] = distribution['A']! + 1;
      } else if (percentage >= 80) {
        distribution['B'] = distribution['B']! + 1;
      } else if (percentage >= 70) {
        distribution['C'] = distribution['C']! + 1;
      } else if (percentage >= 60) {
        distribution['D'] = distribution['D']! + 1;
      } else {
        distribution['F'] = distribution['F']! + 1;
      }
    }

    return GradeStatistics(
      totalGrades: totalGrades,
      averageGrade: averageGrade,
      highestGrade: highestGrade,
      lowestGrade: lowestGrade,
      gradeDistribution: distribution,
    );
  }
}

/// Data structure for organized student grades
class OrganizedStudentGrades {
  final String studentName;
  final String studentId;
  final String? classId;
  final Map<String, SemesterGrades> semestersBySemesterId;
  final List<AcademicYear> academicYears;
  final List<Semester> semesters;

  OrganizedStudentGrades({
    required this.studentName,
    required this.studentId,
    this.classId,
    required this.semestersBySemesterId,
    required this.academicYears,
    required this.semesters,
  });
}

/// Data structure for organized school grades
class OrganizedSchoolGrades {
  final Map<String, ClassGrades> classesByClassId;
  final List<SchoolClass> classes;
  final List<Subject> subjects;
  final List<AcademicYear> academicYears;
  final List<Semester> semesters;

  OrganizedSchoolGrades({
    required this.classesByClassId,
    required this.classes,
    required this.subjects,
    required this.academicYears,
    required this.semesters,
  });
}

/// Data structure for class grades
class ClassGrades {
  final SchoolClass schoolClass;
  final Map<String, SemesterGrades> semestersBySemesterId;

  ClassGrades({
    required this.schoolClass,
    required this.semestersBySemesterId,
  });
}

/// Data structure for semester grades
class SemesterGrades {
  final Semester semester;
  final Map<String, SubjectGrades> subjectsBySubjectId;

  SemesterGrades({
    required this.semester,
    required this.subjectsBySubjectId,
  });
}

/// Data structure for subject grades
class SubjectGrades {
  final Subject subject;
  final Map<int, List<Grade>> gradesByGradeNumber;

  SubjectGrades({
    required this.subject,
    required this.gradesByGradeNumber,
  });

  /// Calculate average for grade number 1
  double get averageGrade1 {
    final grades1 = gradesByGradeNumber[1] ?? [];
    if (grades1.isEmpty) return 0.0;
    return grades1.map((g) => g.gradeValue).reduce((a, b) => a + b) / grades1.length;
  }

  /// Calculate average for grade number 2
  double get averageGrade2 {
    final grades2 = gradesByGradeNumber[2] ?? [];
    if (grades2.isEmpty) return 0.0;
    return grades2.map((g) => g.gradeValue).reduce((a, b) => a + b) / grades2.length;
  }

  /// Calculate overall average
  double get overallAverage {
    final allGrades = <Grade>[];
    gradesByGradeNumber.values.forEach(allGrades.addAll);
    if (allGrades.isEmpty) return 0.0;
    return allGrades.map((g) => g.gradeValue).reduce((a, b) => a + b) / allGrades.length;
  }
}

/// Grade statistics data structure
class GradeStatistics {
  final int totalGrades;
  final double averageGrade;
  final double highestGrade;
  final double lowestGrade;
  final Map<String, int> gradeDistribution;

  GradeStatistics({
    required this.totalGrades,
    required this.averageGrade,
    required this.highestGrade,
    required this.lowestGrade,
    required this.gradeDistribution,
  });
}

/// Exception class for grade operations
class GradeException implements Exception {
  final String message;
  GradeException(this.message);

  @override
  String toString() => message;
}