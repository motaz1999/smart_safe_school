# Absence Reports Testing & Implementation Roadmap

## Implementation Roadmap

### Phase 1: Foundation & Data Layer (Week 1-2)

#### 1.1 Database Setup
- [ ] Create database migration scripts for indexes
- [ ] Implement database functions for absence queries
- [ ] Set up performance monitoring for queries
- [ ] Create test data generation scripts

#### 1.2 Data Models Implementation
- [ ] Create `AbsenceRecord` model
- [ ] Create `AbsenceSummaryStats` model
- [ ] Create `ClassAbsenceStats` model
- [ ] Create `StudentAbsenceStats` model
- [ ] Create `AbsenceTrendData` model
- [ ] Add comprehensive unit tests for all models

#### 1.3 Enhanced AttendanceService
- [ ] Implement `getAbsenceRecords()` method
- [ ] Implement `getAbsenceSummary()` method
- [ ] Implement `getAbsenceStatsByClass()` method
- [ ] Implement `getStudentsWithHighAbsences()` method
- [ ] Implement `getAbsenceTrends()` method
- [ ] Add error handling and validation
- [ ] Create comprehensive service tests

### Phase 2: UI Components & Screens (Week 3-4)

#### 2.1 Core UI Components
- [ ] Create `DateRangePicker` widget
- [ ] Create `AbsenceSummaryCard` widget
- [ ] Create `AbsenceRecordCard` widget
- [ ] Create `AbsenceFilters` widget
- [ ] Create `AbsenceTrendChart` widget
- [ ] Add responsive design support

#### 2.2 Main Absence Reports Screen
- [ ] Implement basic screen layout
- [ ] Add date range selection functionality
- [ ] Implement filtering and search
- [ ] Add pagination for large datasets
- [ ] Implement loading states and error handling
- [ ] Add pull-to-refresh functionality

#### 2.3 Navigation Integration
- [ ] Update admin dashboard sidebar
- [ ] Add proper navigation flow
- [ ] Implement breadcrumb navigation
- [ ] Add deep linking support

### Phase 3: Advanced Features (Week 5-6)

#### 3.1 Export Functionality
- [ ] Create `ExportService` class
- [ ] Implement CSV export
- [ ] Implement PDF export
- [ ] Add export progress indicators
- [ ] Implement file cleanup mechanisms
- [ ] Add export history tracking

#### 3.2 Analytics & Insights
- [ ] Implement absence trend analysis
- [ ] Create absence pattern detection
- [ ] Add predictive absence alerts
- [ ] Implement comparative analytics
- [ ] Create absence rate benchmarking

#### 3.3 Performance Optimization
- [ ] Implement caching layer
- [ ] Add query optimization
- [ ] Implement lazy loading
- [ ] Add background data refresh
- [ ] Optimize for large datasets

### Phase 4: Security & Testing (Week 7-8)

#### 4.1 Security Implementation
- [ ] Implement role-based access control
- [ ] Add data privacy compliance
- [ ] Implement audit logging
- [ ] Add rate limiting for exports
- [ ] Create security testing suite

#### 4.2 Comprehensive Testing
- [ ] Unit tests for all components
- [ ] Integration tests for workflows
- [ ] Widget tests for UI components
- [ ] Performance testing
- [ ] Security testing
- [ ] User acceptance testing

## Detailed Testing Plan

### Unit Testing Strategy

#### 1. Data Models Testing
```dart
// test/unit/models/absence_record_test.dart
void main() {
  group('AbsenceRecord', () {
    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'student_id': 'student-1',
        'student_name': 'John Doe',
        'absence_date': '2024-01-15',
        // ... more fields
      };
      
      final record = AbsenceRecord.fromJson(json);
      
      expect(record.id, equals('test-id'));
      expect(record.studentName, equals('John Doe'));
      expect(record.absenceDate, equals(DateTime(2024, 1, 15)));
    });

    test('should convert to JSON correctly', () {
      final record = AbsenceRecord(
        id: 'test-id',
        studentId: 'student-1',
        studentName: 'John Doe',
        absenceDate: DateTime(2024, 1, 15),
        // ... more fields
      );
      
      final json = record.toJson();
      
      expect(json['id'], equals('test-id'));
      expect(json['student_name'], equals('John Doe'));
      expect(json['absence_date'], equals('2024-01-15'));
    });

    test('should handle null values gracefully', () {
      final json = {
        'id': 'test-id',
        'student_id': 'student-1',
        'notes': null,
      };
      
      expect(() => AbsenceRecord.fromJson(json), returnsNormally);
    });
  });
}
```

#### 2. AttendanceService Testing
```dart
// test/unit/services/attendance_service_test.dart
void main() {
  group('AttendanceService - Absence Methods', () {
    late AttendanceService service;
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = MockSupabaseClient();
      service = AttendanceService(client: mockClient);
    });

    test('getAbsenceRecords should return filtered results', () async {
      // Arrange
      final mockData = [
        {
          'id': 'absence-1',
          'student_name': 'John Doe',
          'absence_date': '2024-01-15',
          'is_present': false,
        }
      ];
      
      when(mockClient.from('attendance_records'))
          .thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.select(any))
          .thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.eq(any, any))
          .thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.execute())
          .thenAnswer((_) async => mockData);

      // Act
      final result = await service.getAbsenceRecords(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      // Assert
      expect(result, hasLength(1));
      expect(result.first.studentName, equals('John Doe'));
    });

    test('getAbsenceSummary should calculate statistics correctly', () async {
      // Test implementation
    });

    test('should handle database errors gracefully', () async {
      // Arrange
      when(mockClient.from('attendance_records'))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => service.getAbsenceRecords(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

### Integration Testing Strategy

#### 1. End-to-End Workflow Testing
```dart
// test/integration/absence_reports_flow_test.dart
void main() {
  group('Absence Reports Integration', () {
    testWidgets('complete absence report workflow', (tester) async {
      // Setup test data
      await setupTestDatabase();
      
      // Launch app and navigate to absence reports
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Login as admin
      await loginAsAdmin(tester);
      
      // Navigate to absence reports
      await tester.tap(find.text('Absence Reports'));
      await tester.pumpAndSettle();
      
      // Select date range
      await tester.tap(find.byType(DateRangePicker));
      await selectDateRange(tester, 
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31)
      );
      
      // Verify data loads
      expect(find.byType(AbsenceRecordCard), findsWidgets);
      expect(find.byType(AbsenceSummaryCard), findsOneWidget);
      
      // Test filtering
      await tester.enterText(find.byType(TextField), 'John');
      await tester.pumpAndSettle();
      
      // Verify filtered results
      expect(find.text('John Doe'), findsWidgets);
      
      // Test export functionality
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      
      // Verify export dialog
      expect(find.text('Export Options'), findsOneWidget);
    });
  });
}
```

#### 2. Database Integration Testing
```dart
// test/integration/database_integration_test.dart
void main() {
  group('Database Integration', () {
    late SupabaseClient supabase;
    late AttendanceService service;

    setUpAll(() async {
      // Setup test database
      supabase = await setupTestSupabase();
      service = AttendanceService(client: supabase);
      
      // Insert test data
      await insertTestAbsenceData();
    });

    test('should retrieve absence records with complex filters', () async {
      final result = await service.getAbsenceRecords(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        classId: 'class-1',
        searchQuery: 'John',
      );
      
      expect(result, isNotEmpty);
      expect(result.every((r) => r.className == 'Class 1A'), isTrue);
      expect(result.every((r) => r.studentName.contains('John')), isTrue);
    });

    test('should calculate accurate summary statistics', () async {
      final summary = await service.getAbsenceSummary(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );
      
      expect(summary.totalAbsences, greaterThan(0));
      expect(summary.uniqueStudentsAbsent, greaterThan(0));
      expect(summary.absenceRate, greaterThan(0));
      expect(summary.absenceRate, lessThanOrEqualTo(100));
    });
  });
}
```

### Widget Testing Strategy

#### 1. Absence Reports Screen Testing
```dart
// test/widget/absence_reports_screen_test.dart
void main() {
  group('AbsenceReportsScreen Widget', () {
    testWidgets('should display loading state initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AbsenceReportsScreen(),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display absence records when loaded', (tester) async {
      final mockService = MockAttendanceService();
      when(mockService.getAbsenceRecords(any))
          .thenAnswer((_) async => [mockAbsenceRecord]);
      
      await tester.pumpWidget(
        MaterialApp(
          home: AbsenceReportsScreen(service: mockService),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.byType(AbsenceRecordCard), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should handle error states gracefully', (tester) async {
      final mockService = MockAttendanceService();
      when(mockService.getAbsenceRecords(any))
          .thenThrow(Exception('Network error'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: AbsenceReportsScreen(service: mockService),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
```

#### 2. Component Widget Testing
```dart
// test/widget/absence_summary_card_test.dart
void main() {
  group('AbsenceSummaryCard Widget', () {
    testWidgets('should display summary statistics correctly', (tester) async {
      final summary = AbsenceSummaryStats(
        totalAbsences: 45,
        uniqueStudentsAbsent: 23,
        absenceRate: 12.5,
        // ... more fields
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AbsenceSummaryCard(summary: summary),
          ),
        ),
      );
      
      expect(find.text('45'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
      expect(find.text('12.5%'), findsOneWidget);
    });

    testWidgets('should handle zero values gracefully', (tester) async {
      final summary = AbsenceSummaryStats(
        totalAbsences: 0,
        uniqueStudentsAbsent: 0,
        absenceRate: 0.0,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AbsenceSummaryCard(summary: summary),
          ),
        ),
      );
      
      expect(find.text('No absences recorded'), findsOneWidget);
    });
  });
}
```

### Performance Testing Strategy

#### 1. Load Testing
```dart
// test/performance/load_test.dart
void main() {
  group('Performance Tests', () {
    test('should handle large datasets efficiently', () async {
      final service = AttendanceService();
      final stopwatch = Stopwatch()..start();
      
      // Generate large dataset (1000 absence records)
      await generateLargeAbsenceDataset(1000);
      
      final result = await service.getAbsenceRecords(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      
      stopwatch.stop();
      
      expect(result, hasLength(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // < 3 seconds
    });

    test('should paginate large results efficiently', () async {
      final service = AttendanceService();
      
      final result = await service.getAbsenceRecords(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        limit: 50,
        offset: 0,
      );
      
      expect(result, hasLength(50));
    });
  });
}
```

#### 2. Memory Usage Testing
```dart
// test/performance/memory_test.dart
void main() {
  group('Memory Usage Tests', () {
    test('should not leak memory with repeated operations', () async {
      final service = AttendanceService();
      
      for (int i = 0; i < 100; i++) {
        final result = await service.getAbsenceRecords(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        
        // Force garbage collection
        await Future.delayed(Duration(milliseconds: 10));
      }
      
      // Memory usage should remain stable
      // This would require platform-specific memory monitoring
    });
  });
}
```

### Security Testing Strategy

#### 1. Access Control Testing
```dart
// test/security/access_control_test.dart
void main() {
  group('Security Tests', () {
    test('should deny access to non-admin users', () async {
      final service = AttendanceService();
      
      // Mock non-admin user
      mockCurrentUser(UserType.student);
      
      expect(
        () => service.getAbsenceRecords(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('should allow access to admin users', () async {
      final service = AttendanceService();
      
      // Mock admin user
      mockCurrentUser(UserType.admin);
      
      expect(
        () => service.getAbsenceRecords(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        ),
        returnsNormally,
      );
    });
  });
}
```

#### 2. Data Privacy Testing
```dart
// test/security/data_privacy_test.dart
void main() {
  group('Data Privacy Tests', () {
    test('should not expose sensitive student data in exports', () async {
      final exportService = ExportService();
      
      final csvData = await exportService.exportAbsenceReportToCsv(
        mockAbsenceRecords,
        mockSummaryStats,
      );
      
      // Verify no sensitive data is exposed
      expect(csvData, isNot(contains('parent_contact')));
      expect(csvData, isNot(contains('home_address')));
    });

    test('should sanitize search queries', () async {
      final service = AttendanceService();
      
      // Test SQL injection attempt
      final maliciousQuery = "'; DROP TABLE students; --";
      
      expect(
        () => service.getAbsenceRecords(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
          searchQuery: maliciousQuery,
        ),
        returnsNormally,
      );
    });
  });
}
```

## Test Data Management

### Mock Data Generation
```dart
// test/helpers/mock_data_generator.dart
class MockDataGenerator {
  static List<AbsenceRecord> generateAbsenceRecords({
    int count = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final records = <AbsenceRecord>[];
    final random = Random();
    
    for (int i = 0; i < count; i++) {
      records.add(AbsenceRecord(
        id: 'absence-$i',
        studentId: 'student-${random.nextInt(100)}',
        studentName: _generateRandomName(),
        studentNumber: 'ST${1000 + i}',
        className: 'Class ${random.nextInt(12) + 1}A',
        subjectName: _getRandomSubject(),
        teacherName: _generateRandomTeacherName(),
        absenceDate: _generateRandomDate(startDate, endDate),
        notes: random.nextBool() ? _generateRandomNote() : null,
      ));
    }
    
    return records;
  }

  static AbsenceSummaryStats generateSummaryStats({
    int totalAbsences = 45,
    int uniqueStudentsAbsent = 23,
  }) {
    return AbsenceSummaryStats(
      totalAbsences: totalAbsences,
      uniqueStudentsAbsent: uniqueStudentsAbsent,
      daysWithAbsences: 12,
      averageAbsencesPerDay: totalAbsences / 12,
      absenceRate: (totalAbsences / 500) * 100, // Assuming 500 total records
      mostAbsentClass: 'Class 10A',
      mostAbsentSubject: 'Mathematics',
      topAbsentStudents: ['John Doe', 'Jane Smith', 'Bob Johnson'],
    );
  }
}
```

### Test Database Setup
```dart
// test/helpers/test_database_setup.dart
class TestDatabaseSetup {
  static Future<void> setupTestData() async {
    final supabase = SupabaseConfig.client;
    
    // Insert test schools
    await supabase.from('schools').insert([
      {'id': 'school-1', 'name': 'Test School'},
    ]);
    
    // Insert test classes
    await supabase.from('classes').insert([
      {'id': 'class-1', 'school_id': 'school-1', 'name': 'Class 10A'},
      {'id': 'class-2', 'school_id': 'school-1', 'name': 'Class 10B'},
    ]);
    
    // Insert test students
    await supabase.from('students').insert([
      {
        'id': 'student-1',
        'school_id': 'school-1',
        'class_id': 'class-1',
        'name': 'John Doe',
        'student_id': 'ST001',
      },
      // ... more test students
    ]);
    
    // Insert test attendance records
    await supabase.from('attendance_records').insert([
      {
        'id': 'absence-1',
        'student_id': 'student-1',
        'subject_id': 'subject-1',
        'teacher_id': 'teacher-1',
        'attendance_date': '2024-01-15',
        'is_present': false,
        'notes': 'Sick leave',
      },
      // ... more test records
    ]);
  }
  
  static Future<void> cleanupTestData() async {
    final supabase = SupabaseConfig.client;
    
    await supabase.from('attendance_records').delete().neq('id', '');
    await supabase.from('students').delete().neq('id', '');
    await supabase.from('classes').delete().neq('id', '');
    await supabase.from('schools').delete().neq('id', '');
  }
}
```

## Continuous Integration Setup

### GitHub Actions Workflow
```yaml
# .github/workflows/absence_reports_tests.yml
name: Absence Reports Tests

on:
  push:
    paths:
      - 'lib/models/absence_*.dart'
      - 'lib/services/attendance_service.dart'
      - 'lib/screens/admin/absence_reports_screen.dart'
      - 'test/**'
  pull_request:
    paths:
      - 'lib/models/absence_*.dart'
      - 'lib/services/attendance_service.dart'
      - 'lib/screens/admin/absence_reports_screen.dart'
      - 'test/**'

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run unit tests
      run: flutter test test/unit/
    
    - name: Run widget tests
      run: flutter test test/widget/
    
    - name: Run integration tests
      run: flutter test test/integration/
    
    - name: Generate coverage report
      run: flutter test --coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
```

This comprehensive testing and implementation roadmap provides a structured approach to building the absence reporting system with high quality, security, and performance standards.