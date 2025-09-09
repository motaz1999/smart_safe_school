import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/absence_record.dart';
import '../models/absence_summary_stats.dart';

class ExportService {
  /// Generate CSV content from absence records
  String generateCsvContent(
    List<AbsenceRecord> records,
    AbsenceSummaryStats summary,
  ) {
    return _generateCsvContent(records, summary);
  }

  /// Generate JSON content from absence records
  String generateJsonContent(
    List<AbsenceRecord> records,
    AbsenceSummaryStats summary,
  ) {
    return _generateJsonContent(records, summary);
  }

  /// Get export data for download (returns content and filename)
  ExportData getExportData(
    List<AbsenceRecord> records,
    AbsenceSummaryStats summary, {
    String format = 'csv',
    String? customFileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = customFileName ?? 'absence_report_$timestamp';
    
    switch (format.toLowerCase()) {
      case 'json':
        return ExportData(
          content: generateJsonContent(records, summary),
          fileName: '$fileName.json',
          mimeType: 'application/json',
        );
      case 'csv':
      default:
        return ExportData(
          content: generateCsvContent(records, summary),
          fileName: '$fileName.csv',
          mimeType: 'text/csv',
        );
    }
  }

  /// Generate CSV content from absence records
  String _generateCsvContent(List<AbsenceRecord> records, AbsenceSummaryStats summary) {
    final buffer = StringBuffer();
    
    // Add header with summary information
    buffer.writeln('# Absence Report Summary');
    buffer.writeln('# Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('# Total Absences: ${summary.totalAbsences}');
    buffer.writeln('# Students Affected: ${summary.uniqueStudentsAbsent}');
    buffer.writeln('# Absence Rate: ${summary.formattedAbsenceRate}');
    buffer.writeln('#');
    
    // Add CSV headers
    buffer.writeln('Date,Student Name,Student ID,Class,Subject,Teacher,Notes,Reason');
    
    // Add data rows
    for (final record in records) {
      buffer.writeln([
        record.formattedDate,
        _escapeCsvField(record.studentName),
        _escapeCsvField(record.studentNumber),
        _escapeCsvField(record.className),
        _escapeCsvField(record.subjectName),
        _escapeCsvField(record.teacherName),
        _escapeCsvField(record.notes ?? ''),
        _escapeCsvField(record.displayReason),
      ].join(','));
    }
    
    return buffer.toString();
  }

  /// Generate JSON content from absence records
  String _generateJsonContent(List<AbsenceRecord> records, AbsenceSummaryStats summary) {
    final data = {
      'metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'total_records': records.length,
        'export_format': 'json',
      },
      'summary': summary.toJson(),
      'records': records.map((record) => record.toJson()).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Escape CSV field to handle commas, quotes, and newlines
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Format date range for display
  String _formatDateRange(AbsenceSummaryStats summary) {
    // This is a simplified version - in a real implementation,
    // you might want to pass the actual date range
    return 'Recent Period';
  }

  /// Get available export formats
  List<ExportFormat> getAvailableFormats() {
    return [
      ExportFormat(
        id: 'csv',
        name: 'CSV (Comma Separated Values)',
        description: 'Compatible with Excel and Google Sheets',
        extension: '.csv',
        mimeType: 'text/csv',
        icon: 'table_chart',
      ),
      ExportFormat(
        id: 'json',
        name: 'JSON (JavaScript Object Notation)',
        description: 'Structured data format for developers',
        extension: '.json',
        mimeType: 'application/json',
        icon: 'code',
      ),
    ];
  }

  /// Validate export parameters
  void validateExportParameters(
    List<AbsenceRecord> records,
    AbsenceSummaryStats summary,
  ) {
    if (records.isEmpty) {
      throw ArgumentError('Cannot export empty records list');
    }
    
    // Check for reasonable file size (e.g., max 10,000 records)
    if (records.length > 10000) {
      throw ArgumentError('Too many records to export (max 10,000)');
    }
  }

  /// Get export file size estimate
  int estimateExportSize(List<AbsenceRecord> records, String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        // Rough estimate: ~150 bytes per record + headers
        return (records.length * 150) + 500;
      case 'json':
        // Rough estimate: ~300 bytes per record + metadata
        return (records.length * 300) + 1000;
      default:
        return 0;
    }
  }
}

class ExportFormat {
  final String id;
  final String name;
  final String description;
  final String extension;
  final String mimeType;
  final String icon;

  const ExportFormat({
    required this.id,
    required this.name,
    required this.description,
    required this.extension,
    required this.mimeType,
    required this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportFormat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ExportFormat(id: $id, name: $name)';
}

class ExportData {
  final String content;
  final String fileName;
  final String mimeType;

  const ExportData({
    required this.content,
    required this.fileName,
    required this.mimeType,
  });

  @override
  String toString() => 'ExportData(fileName: $fileName, mimeType: $mimeType)';
}