# Academic Year Management Implementation Plan

## Overview
This document outlines the implementation plan for adding academic year management functionality to the Smart Safe School application, including automatic semester creation when a school is created.

## Current State Analysis
Based on the code review, the application currently does not have:
- Academic year management screens
- Semester management screens
- Functionality to create academic years with specific semester dates
- Automatic creation of academic years when schools are created

## Proposed Implementation

### 1. Database Functions
We've already created the necessary database functions:
- Modified `create_academic_year` function to create semesters with specific dates
- Created `create_school_with_academic_year` function to automatically create schools with academic years and semesters

### 2. Flutter App Implementation

#### A. Add Academic Year Model Methods
We need to add methods to the `AcademicYear` model to support the new functionality:

```dart
// In lib/models/academic_year.dart
class AcademicYear extends BaseModel {
  // ... existing code ...
  
  // Add a method to create academic year with semesters
  static Future<AcademicYear> createAcademicYearWithSemesters({
    required int schoolId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Implementation to call the database function
  }
}
```

#### B. Add Academic Year Service Methods
We need to add methods to the `AdminService` to support academic year management:

```dart
// In lib/services/admin_service.dart
class AdminService {
  // ... existing code ...
  
  // Create academic year with semesters
  Future<AcademicYear> createAcademicYearWithSemesters({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Implementation to call the database function
  }
  
  // Get academic years
  Future<List<AcademicYear>> getAcademicYears() async {
    // Implementation to get academic years for the current school
  }
  
  // Get semesters
  Future<List<Semester>> getSemesters() async {
    // Implementation to get semesters for the current school
  }
}
```

#### C. Create Academic Year Management Screens
We need to create new screens for managing academic years:

1. **ManageAcademicYearsScreen** - Main screen for academic year management
2. **AcademicYearFormDialog** - Dialog for creating/editing academic years
3. **SemesterListScreen** - Screen to view semesters for an academic year

#### D. Update Admin Dashboard
We need to add navigation to the academic year management screen in the admin dashboard:

```dart
// In lib/screens/admin/admin_dashboard.dart
// Add new navigation item
_buildSidebarItem(
  icon: Icons.calendar_today,
  title: 'Manage Academic Years',
  onTap: () {
    _navigateToAcademicYears();
  },
),
```

#### E. Update School Creation Process
Since there's no existing school creation functionality in the app, we would need to:
1. Create a new screen for school creation
2. Implement the school creation process using the new database function
3. Add navigation to this screen from an appropriate place

However, based on the current app structure, it seems schools are created outside the app (possibly through direct database operations or a separate admin interface), and users are assigned to schools during their profile creation.

## Implementation Steps

### Step 1: Update Academic Year Model
- Add methods to support calling the database functions
- Ensure proper JSON serialization/deserialization

### Step 2: Update Admin Service
- Add methods for academic year and semester management
- Implement calls to the database functions

### Step 3: Create Academic Year Management Screens
- Create `manage_academic_years.dart` and related content files
- Create UI components for displaying academic years and semesters
- Implement forms for creating/editing academic years

### Step 4: Update Admin Dashboard
- Add navigation item for academic year management
- Implement navigation to the new screens

### Step 5: Integration Testing
- Test the academic year creation with semesters
- Test the school creation with academic years (if implemented)
- Verify that existing functionality still works correctly

## Files to Create/Modify

### Create New Files
1. `lib/screens/admin/manage_academic_years.dart` - Main screen
2. `lib/screens/admin/manage_academic_years_content.dart` - Content widget
3. `lib/screens/admin/academic_year_form.dart` - Form dialog
4. `lib/screens/admin/manage_semesters.dart` - Semester management screen

### Modify Existing Files
1. `lib/models/academic_year.dart` - Add new methods
2. `lib/services/admin_service.dart` - Add new methods
3. `lib/screens/admin/admin_dashboard.dart` - Add navigation

## Testing Plan
1. Unit tests for new model methods
2. Unit tests for new service methods
3. Widget tests for new screens
4. Integration tests for the complete workflow
5. Manual testing to verify the semester dates are correctly set