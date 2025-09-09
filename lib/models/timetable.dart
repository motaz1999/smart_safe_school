import 'package:flutter/material.dart';
import 'base_model.dart';

enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class TimetableEntry extends BaseModel {
  final int schoolId;
  final String classId;
  final String subjectId;
  final String teacherId;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  
  // Additional fields for UI
  final String? className;
  final String? subjectName;
  final String? subjectCode;
  final String? teacherName;

  TimetableEntry({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.className,
    this.subjectName,
    this.subjectCode,
    this.teacherName,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      schoolId: json['school_id'] is int ? json['school_id'] : int.parse(json['school_id'].toString()),
      classId: json['class_id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      dayOfWeek: json['day_of_week'] != null
          ? DayOfWeek.values.firstWhere(
              (e) => e.name == json['day_of_week'],
            )
          : DayOfWeek.monday,
      startTime: _parseTime(json['start_time']),
      endTime: _parseTime(json['end_time']),
      className: json['classes'] != null ? json['classes']['name'] as String? : json['class_name'] as String?,
      subjectName: json['subjects'] != null ? json['subjects']['name'] as String? : json['subject_name'] as String?,
      subjectCode: json['subjects'] != null ? json['subjects']['code'] as String? : json['subject_code'] as String?,
      teacherName: json['teacher'] != null ? json['teacher']['name'] as String? : json['teacher_name'] as String?,
    );
  }

  static TimeOfDay _parseTime(String? timeString) {
    if (timeString == null) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'class_id': classId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'day_of_week': dayOfWeek.name,
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get timeRange {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
  
  bool conflictsWith(TimetableEntry other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    
    final thisStart = startTime.hour * 60 + startTime.minute;
    final thisEnd = endTime.hour * 60 + endTime.minute;
    final otherStart = other.startTime.hour * 60 + other.startTime.minute;
    final otherEnd = other.endTime.hour * 60 + other.endTime.minute;
    
    return (thisStart < otherEnd && thisEnd > otherStart);
  }

  TimetableEntry copyWith({
    int? schoolId,
    String? classId,
    String? subjectId,
    String? teacherId,
    DayOfWeek? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? className,
    String? subjectName,
    String? subjectCode,
    String? teacherName,
    DateTime? updatedAt,
  }) {
    return TimetableEntry(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      className: className ?? this.className,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}