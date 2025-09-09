class AbsenceSummaryStats {
  final int totalAbsences;
  final int uniqueStudentsAbsent;
  final int daysWithAbsences;
  final double averageAbsencesPerDay;
  final double absenceRate;
  final String? mostAbsentClass;
  final String? mostAbsentSubject;
  final List<String> topAbsentStudents;
  final Map<String, int> absencesByReason;
  final Map<String, int> absencesByClass;
  final Map<String, int> absencesBySubject;

  AbsenceSummaryStats({
    required this.totalAbsences,
    required this.uniqueStudentsAbsent,
    required this.daysWithAbsences,
    required this.averageAbsencesPerDay,
    required this.absenceRate,
    this.mostAbsentClass,
    this.mostAbsentSubject,
    this.topAbsentStudents = const [],
    this.absencesByReason = const {},
    this.absencesByClass = const {},
    this.absencesBySubject = const {},
  });

  factory AbsenceSummaryStats.fromJson(Map<String, dynamic> json) {
    return AbsenceSummaryStats(
      totalAbsences: json['total_absences'] ?? 0,
      uniqueStudentsAbsent: json['unique_students_absent'] ?? 0,
      daysWithAbsences: json['days_with_absences'] ?? 0,
      averageAbsencesPerDay: (json['average_absences_per_day'] ?? 0.0).toDouble(),
      absenceRate: (json['absence_rate'] ?? 0.0).toDouble(),
      mostAbsentClass: json['most_absent_class'],
      mostAbsentSubject: json['most_absent_subject'],
      topAbsentStudents: json['top_absent_students'] != null
          ? List<String>.from(json['top_absent_students'])
          : [],
      absencesByReason: json['absences_by_reason'] != null
          ? Map<String, int>.from(json['absences_by_reason'])
          : {},
      absencesByClass: json['absences_by_class'] != null
          ? Map<String, int>.from(json['absences_by_class'])
          : {},
      absencesBySubject: json['absences_by_subject'] != null
          ? Map<String, int>.from(json['absences_by_subject'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_absences': totalAbsences,
      'unique_students_absent': uniqueStudentsAbsent,
      'days_with_absences': daysWithAbsences,
      'average_absences_per_day': averageAbsencesPerDay,
      'absence_rate': absenceRate,
      'most_absent_class': mostAbsentClass,
      'most_absent_subject': mostAbsentSubject,
      'top_absent_students': topAbsentStudents,
      'absences_by_reason': absencesByReason,
      'absences_by_class': absencesByClass,
      'absences_by_subject': absencesBySubject,
    };
  }

  bool get hasData => totalAbsences > 0;

  String get formattedAbsenceRate => '${absenceRate.toStringAsFixed(1)}%';

  String get formattedAveragePerDay => averageAbsencesPerDay.toStringAsFixed(1);

  // Get the most problematic class (highest absence count)
  String? get mostProblematicClass {
    if (absencesByClass.isEmpty) return null;
    
    final sortedClasses = absencesByClass.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedClasses.first.key;
  }

  // Get the most problematic subject (highest absence count)
  String? get mostProblematicSubject {
    if (absencesBySubject.isEmpty) return null;
    
    final sortedSubjects = absencesBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedSubjects.first.key;
  }

  // Get the most common absence reason
  String? get mostCommonReason {
    if (absencesByReason.isEmpty) return null;
    
    final sortedReasons = absencesByReason.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedReasons.first.key;
  }

  // Calculate absence trend (positive = increasing, negative = decreasing)
  double calculateTrend(AbsenceSummaryStats? previousPeriod) {
    if (previousPeriod == null || previousPeriod.totalAbsences == 0) {
      return 0.0;
    }
    
    return ((totalAbsences - previousPeriod.totalAbsences) / 
            previousPeriod.totalAbsences) * 100;
  }

  AbsenceSummaryStats copyWith({
    int? totalAbsences,
    int? uniqueStudentsAbsent,
    int? daysWithAbsences,
    double? averageAbsencesPerDay,
    double? absenceRate,
    String? mostAbsentClass,
    String? mostAbsentSubject,
    List<String>? topAbsentStudents,
    Map<String, int>? absencesByReason,
    Map<String, int>? absencesByClass,
    Map<String, int>? absencesBySubject,
  }) {
    return AbsenceSummaryStats(
      totalAbsences: totalAbsences ?? this.totalAbsences,
      uniqueStudentsAbsent: uniqueStudentsAbsent ?? this.uniqueStudentsAbsent,
      daysWithAbsences: daysWithAbsences ?? this.daysWithAbsences,
      averageAbsencesPerDay: averageAbsencesPerDay ?? this.averageAbsencesPerDay,
      absenceRate: absenceRate ?? this.absenceRate,
      mostAbsentClass: mostAbsentClass ?? this.mostAbsentClass,
      mostAbsentSubject: mostAbsentSubject ?? this.mostAbsentSubject,
      topAbsentStudents: topAbsentStudents ?? this.topAbsentStudents,
      absencesByReason: absencesByReason ?? this.absencesByReason,
      absencesByClass: absencesByClass ?? this.absencesByClass,
      absencesBySubject: absencesBySubject ?? this.absencesBySubject,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AbsenceSummaryStats &&
        other.totalAbsences == totalAbsences &&
        other.uniqueStudentsAbsent == uniqueStudentsAbsent &&
        other.daysWithAbsences == daysWithAbsences &&
        other.averageAbsencesPerDay == averageAbsencesPerDay &&
        other.absenceRate == absenceRate;
  }

  @override
  int get hashCode {
    return totalAbsences.hashCode ^
        uniqueStudentsAbsent.hashCode ^
        daysWithAbsences.hashCode ^
        averageAbsencesPerDay.hashCode ^
        absenceRate.hashCode;
  }

  @override
  String toString() {
    return 'AbsenceSummaryStats{totalAbsences: $totalAbsences, uniqueStudentsAbsent: $uniqueStudentsAbsent, absenceRate: $absenceRate}';
  }

  // Create empty stats for when no data is available
  static AbsenceSummaryStats empty() {
    return AbsenceSummaryStats(
      totalAbsences: 0,
      uniqueStudentsAbsent: 0,
      daysWithAbsences: 0,
      averageAbsencesPerDay: 0.0,
      absenceRate: 0.0,
    );
  }
}