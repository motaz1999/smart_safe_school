# Teacher Grade Navigation Flow

## Current Flow
```mermaid
graph TD
    A[Teacher Dashboard] --> B[Grades Quick Action]
    B --> C[Class Selection Sheet]
    C --> D[Load Teacher Classes/Subjects]
    C --> E[Select Class/Subject]
    E --> F[Teacher Grades Screen]
```

## New Flow
```mermaid
graph TD
    A[Teacher Dashboard] --> B[Grades Quick Action]
    B --> C[Academic Year Selection Screen]
    C --> D[Select Academic Year]
    D --> E[Semester Selection Screen]
    E --> F[Select Semester]
    F --> G[Subject/Class Selection Screen]
    G --> H[Select Subject/Class]
    H --> I[Teacher Grades Screen]
```

## Implementation Steps

1. Create AcademicYearSelectionScreen
2. Create SemesterSelectionScreen
3. Modify Subject/Class Selection to filter by academic year/semester
4. Update TeacherDashboard to navigate to AcademicYearSelectionScreen instead of showing class selection sheet
5. Update navigation flow between all screens