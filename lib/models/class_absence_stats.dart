class ClassAbsenceStats {
  final String classId;
  final String className;
  final int totalStudents;
  final int studentsWithAbsences;
  final int totalAbsences;
  final double absenceRate;
  final double averageAbsencesPerStudent;
  final List<SubjectAbsenceStats> subjectBreakdown;
  final DateTime? lastAbsenceDate;
  final String? mostAbsentStudent;
  final String? mostProblematicSubject;

  ClassAbsenceStats({
    required this.classId,
    required this.className,
    required this.totalStudents,
    required this.studentsWithAbsences,
    required this.totalAbsences,
    required this.absenceRate,
    required this.averageAbsencesPerStudent,
    this.subjectBreakdown = const [],
    this.lastAbsenceDate,
    this.mostAbsentStudent,
    this.mostProblematicSubject,
  });

  factory ClassAbsenceStats.fromJson(Map<String, dynamic> json) {
    return ClassAbsenceStats(
      classId: json['class_id'] ?? '',
      className: json['class_name'] ?? '',
      totalStudents: json['total_students'] ?? 0,
      studentsWithAbsences: json['students_with_absences'] ?? 0,
      totalAbsences: json['total_absences'] ?? 0,
      absenceRate: (json['absence_rate'] ?? 0.0).toDouble(),
      averageAbsencesPerStudent: (json['average_absences_per_student'] ?? 0.0).toDouble(),
      subjectBreakdown: json['subject_breakdown'] != null
          ? (json['subject_breakdown'] as List)
              .map((item) => SubjectAbsenceStats.fromJson(item))
              .toList()
          : [],
      lastAbsenceDate: json['last_absence_date'] != null
          ? DateTime.parse(json['last_absence_date'])
          : null,
      mostAbsentStudent: json['most_absent_student'],
      mostProblematicSubject: json['most_problematic_subject'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
      'total_students': totalStudents,
      'students_with_absences': studentsWithAbsences,
      'total_absences': totalAbsences,
      'absence_rate': absenceRate,
      'average_absences_per_student': averageAbsencesPerStudent,
      'subject_breakdown': subjectBreakdown.map((item) => item.toJson()).toList(),
      'last_absence_date': lastAbsenceDate?.toIso8601String(),
      'most_absent_student': mostAbsentStudent,
      'most_problematic_subject': mostProblematicSubject,
    };
  }

  String get formattedAbsenceRate => '${absenceRate.toStringAsFixed(1)}%';

  String get formattedAveragePerStudent => averageAbsencesPerStudent.toStringAsFixed(1);

  // Calculate the percentage of students with absences
  double get studentAbsencePercentage {
    if (totalStudents == 0) return 0.0;
    return (studentsWithAbsences / totalStudents) * 100;
  }

  String get formattedStudentAbsencePercentage => '${studentAbsencePercentage.toStringAsFixed(1)}%';

  // Get the subject with the highest absence rate
  SubjectAbsenceStats? get mostProblematicSubjectStats {
    if (subjectBreakdown.isEmpty) return null;
    
    return subjectBreakdown.reduce((a, b) => 
        a.absenceCount > b.absenceCount ? a : b);
  }

  // Check if this class has concerning absence levels
  bool get hasConcerningAbsenceLevel => absenceRate > 15.0; // More than 15% absence rate

  // Check if this class needs attention
  bool get needsAttention => 
      hasConcerningAbsenceLevel || 
      (studentAbsencePercentage > 50.0); // More than 50% of students have absences

  ClassAbsenceStats copyWith({
    String? classId,
    String? className,
    int? totalStudents,
    int? studentsWithAbsences,
    int? totalAbsences,
    double? absenceRate,
    double? averageAbsencesPerStudent,
    List<SubjectAbsenceStats>? subjectBreakdown,
    DateTime? lastAbsenceDate,
    String? mostAbsentStudent,
    String? mostProblematicSubject,
  }) {
    return ClassAbsenceStats(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      totalStudents: totalStudents ?? this.totalStudents,
      studentsWithAbsences: studentsWithAbsences ?? this.studentsWithAbsences,
      totalAbsences: totalAbsences ?? this.totalAbsences,
      absenceRate: absenceRate ?? this.absenceRate,
      averageAbsencesPerStudent: averageAbsencesPerStudent ?? this.averageAbsencesPerStudent,
      subjectBreakdown: subjectBreakdown ?? this.subjectBreakdown,
      lastAbsenceDate: lastAbsenceDate ?? this.lastAbsenceDate,
      mostAbsentStudent: mostAbsentStudent ?? this.mostAbsentStudent,
      mostProblematicSubject: mostProblematicSubject ?? this.mostProblematicSubject,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassAbsenceStats &&
        other.classId == classId &&
        other.totalAbsences == totalAbsences &&
        other.absenceRate == absenceRate;
  }

  @override
  int get hashCode {
    return classId.hashCode ^ totalAbsences.hashCode ^ absenceRate.hashCode;
  }

  @override
  String toString() {
    return 'ClassAbsenceStats{className: $className, totalAbsences: $totalAbsences, absenceRate: $absenceRate}';
  }
}

class SubjectAbsenceStats {
  final String subjectId;
  final String subjectName;
  final int absenceCount;
  final double absenceRate;
  final int studentsAffected;

  SubjectAbsenceStats({
    required this.subjectId,
    required this.subjectName,
    required this.absenceCount,
    required this.absenceRate,
    required this.studentsAffected,
  });

  factory SubjectAbsenceStats.fromJson(Map<String, dynamic> json) {
    return SubjectAbsenceStats(
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject_name'] ?? '',
      absenceCount: json['absence_count'] ?? 0,
      absenceRate: (json['absence_rate'] ?? 0.0).toDouble(),
      studentsAffected: json['students_affected'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'subject_name': subjectName,
      'absence_count': absenceCount,
      'absence_rate': absenceRate,
      'students_affected': studentsAffected,
    };
  }

  String get formattedAbsenceRate => '${absenceRate.toStringAsFixed(1)}%';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubjectAbsenceStats &&
        other.subjectId == subjectId &&
        other.absenceCount == absenceCount;
  }

  @override
  int get hashCode {
    return subjectId.hashCode ^ absenceCount.hashCode;
  }

  @override
  String toString() {
    return 'SubjectAbsenceStats{subjectName: $subjectName, absenceCount: $absenceCount}';
  }
}