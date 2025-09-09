class StudentAbsenceStats {
  final String studentId;
  final String studentName;
  final String studentNumber;
  final String classId;
  final String className;
  final int totalAbsences;
  final double absenceRate;
  final List<DateTime> absenceDates;
  final Map<String, int> absencesBySubject;
  final String? mostAbsentSubject;
  final DateTime? lastAbsenceDate;
  final DateTime? firstAbsenceDate;
  final List<String> commonReasons;
  final bool isHighRisk;

  StudentAbsenceStats({
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    required this.classId,
    required this.className,
    required this.totalAbsences,
    required this.absenceRate,
    this.absenceDates = const [],
    this.absencesBySubject = const {},
    this.mostAbsentSubject,
    this.lastAbsenceDate,
    this.firstAbsenceDate,
    this.commonReasons = const [],
    this.isHighRisk = false,
  });

  factory StudentAbsenceStats.fromJson(Map<String, dynamic> json) {
    return StudentAbsenceStats(
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      studentNumber: json['student_number'] ?? '',
      classId: json['class_id'] ?? '',
      className: json['class_name'] ?? '',
      totalAbsences: json['total_absences'] ?? 0,
      absenceRate: (json['absence_rate'] ?? 0.0).toDouble(),
      absenceDates: json['absence_dates'] != null
          ? (json['absence_dates'] as List)
              .map((date) => DateTime.parse(date))
              .toList()
          : [],
      absencesBySubject: json['absences_by_subject'] != null
          ? Map<String, int>.from(json['absences_by_subject'])
          : {},
      mostAbsentSubject: json['most_absent_subject'],
      lastAbsenceDate: json['last_absence_date'] != null
          ? DateTime.parse(json['last_absence_date'])
          : null,
      firstAbsenceDate: json['first_absence_date'] != null
          ? DateTime.parse(json['first_absence_date'])
          : null,
      commonReasons: json['common_reasons'] != null
          ? List<String>.from(json['common_reasons'])
          : [],
      isHighRisk: json['is_high_risk'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'student_number': studentNumber,
      'class_id': classId,
      'class_name': className,
      'total_absences': totalAbsences,
      'absence_rate': absenceRate,
      'absence_dates': absenceDates.map((date) => date.toIso8601String()).toList(),
      'absences_by_subject': absencesBySubject,
      'most_absent_subject': mostAbsentSubject,
      'last_absence_date': lastAbsenceDate?.toIso8601String(),
      'first_absence_date': firstAbsenceDate?.toIso8601String(),
      'common_reasons': commonReasons,
      'is_high_risk': isHighRisk,
    };
  }

  String get formattedAbsenceRate => '${absenceRate.toStringAsFixed(1)}%';

  // Get the number of consecutive absence days
  int get consecutiveAbsenceDays {
    if (absenceDates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(absenceDates)
      ..sort((a, b) => b.compareTo(a)); // Most recent first
    
    int consecutive = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final current = sortedDates[i];
      final previous = sortedDates[i - 1];
      
      // Check if dates are consecutive (accounting for weekends)
      final daysDifference = previous.difference(current).inDays;
      if (daysDifference <= 3) { // Allow for weekends
        consecutive++;
      } else {
        break;
      }
    }
    
    return consecutive;
  }

  // Get absence frequency (absences per week)
  double get absenceFrequency {
    if (absenceDates.isEmpty) return 0.0;
    
    final firstDate = firstAbsenceDate ?? absenceDates.first;
    final lastDate = lastAbsenceDate ?? absenceDates.last;
    final weeksDifference = lastDate.difference(firstDate).inDays / 7;
    
    if (weeksDifference <= 0) return totalAbsences.toDouble();
    
    return totalAbsences / weeksDifference;
  }

  String get formattedAbsenceFrequency => '${absenceFrequency.toStringAsFixed(1)} per week';

  // Get the subject with the most absences
  MapEntry<String, int>? get mostAbsentSubjectEntry {
    if (absencesBySubject.isEmpty) return null;
    
    return absencesBySubject.entries.reduce((a, b) => 
        a.value > b.value ? a : b);
  }

  // Check if student has concerning absence pattern
  bool get hasConcerningPattern {
    return absenceRate > 20.0 || // More than 20% absence rate
           consecutiveAbsenceDays >= 3 || // 3+ consecutive absences
           absenceFrequency > 2.0; // More than 2 absences per week
  }

  // Get absence trend over time (simplified)
  String get absenceTrend {
    if (absenceDates.length < 2) return 'Insufficient data';
    
    final sortedDates = List<DateTime>.from(absenceDates)..sort();
    final midPoint = sortedDates.length ~/ 2;
    
    final firstHalf = sortedDates.take(midPoint).length;
    final secondHalf = sortedDates.skip(midPoint).length;
    
    if (secondHalf > firstHalf) {
      return 'Increasing';
    } else if (secondHalf < firstHalf) {
      return 'Decreasing';
    } else {
      return 'Stable';
    }
  }

  // Get days since last absence
  int? get daysSinceLastAbsence {
    if (lastAbsenceDate == null) return null;
    return DateTime.now().difference(lastAbsenceDate!).inDays;
  }

  String? get formattedDaysSinceLastAbsence {
    final days = daysSinceLastAbsence;
    if (days == null) return null;
    
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  // Get risk level based on absence patterns
  String get riskLevel {
    if (absenceRate > 30.0 || consecutiveAbsenceDays >= 5) {
      return 'High';
    } else if (absenceRate > 15.0 || consecutiveAbsenceDays >= 3) {
      return 'Medium';
    } else if (absenceRate > 5.0) {
      return 'Low';
    } else {
      return 'Normal';
    }
  }

  StudentAbsenceStats copyWith({
    String? studentId,
    String? studentName,
    String? studentNumber,
    String? classId,
    String? className,
    int? totalAbsences,
    double? absenceRate,
    List<DateTime>? absenceDates,
    Map<String, int>? absencesBySubject,
    String? mostAbsentSubject,
    DateTime? lastAbsenceDate,
    DateTime? firstAbsenceDate,
    List<String>? commonReasons,
    bool? isHighRisk,
  }) {
    return StudentAbsenceStats(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      totalAbsences: totalAbsences ?? this.totalAbsences,
      absenceRate: absenceRate ?? this.absenceRate,
      absenceDates: absenceDates ?? this.absenceDates,
      absencesBySubject: absencesBySubject ?? this.absencesBySubject,
      mostAbsentSubject: mostAbsentSubject ?? this.mostAbsentSubject,
      lastAbsenceDate: lastAbsenceDate ?? this.lastAbsenceDate,
      firstAbsenceDate: firstAbsenceDate ?? this.firstAbsenceDate,
      commonReasons: commonReasons ?? this.commonReasons,
      isHighRisk: isHighRisk ?? this.isHighRisk,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentAbsenceStats &&
        other.studentId == studentId &&
        other.totalAbsences == totalAbsences &&
        other.absenceRate == absenceRate;
  }

  @override
  int get hashCode {
    return studentId.hashCode ^ totalAbsences.hashCode ^ absenceRate.hashCode;
  }

  @override
  String toString() {
    return 'StudentAbsenceStats{studentName: $studentName, totalAbsences: $totalAbsences, absenceRate: $absenceRate, riskLevel: $riskLevel}';
  }
}