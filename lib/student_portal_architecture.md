# Student Portal Architecture

## Component Diagram

```mermaid
graph TD
    A[Main.dart] --> B[AuthWrapper]
    B --> C[StudentMainScreen]
    C --> D[BottomNavigationBar]
    D --> E[HomeScreen]
    D --> F[TimetableScreen]
    D --> G[GradesScreen]
    E --> H[ImageService]
    H --> I[ImagePicker]
    H --> J[PathProvider]
    H --> K[SharedPreferences]
    
    style A fill:#f9f,stroke:#333
    style B fill:#f9f,stroke:#333
    style C fill:#bbf,stroke:#333
    style D fill:#bfb,stroke:#333
    style E fill:#fbb,stroke:#333
    style F fill:#fbb,stroke:#333
    style G fill:#fbb,stroke:#333
    style H fill:#ffb,stroke:#333
```

## Navigation Flow

```mermaid
graph LR
    A[Login] --> B[AuthWrapper]
    B --> C{Role Check}
    C -->|Student| D[StudentMainScreen]
    D --> E[Home Tab]
    D --> F[Timetable Tab]
    D --> G[Grades Tab]
    E --> H[Profile Image]
    H --> I[Select Image]
    I --> J[Save Locally]
    
    style A fill:#f9f,stroke:#333
    style B fill:#f9f,stroke:#333
    style C fill:#ff9,stroke:#333
    style D fill:#bbf,stroke:#333
    style E fill:#bfb,stroke:#333
    style F fill:#bfb,stroke:#333
    style G fill:#bfb,stroke:#333
    style H fill:#fbb,stroke:#333
    style I fill:#ffb,stroke:#333
    style J fill:#ffb,stroke:#333
```

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant Main
    participant AuthWrapper
    participant StudentMain
    participant HomeScreen
    participant ImageService
    participant Storage
    
    User->>Main: App Launch
    Main->>AuthWrapper: Initialize
    AuthWrapper->>StudentMain: Authenticated Student
    StudentMain->>HomeScreen: Show Home Tab
    User->>HomeScreen: Tap Profile Picture
    HomeScreen->>ImageService: Request Image Selection
    ImageService->>Storage: Save Image Path
    Storage-->>ImageService: Return Success
    ImageService-->>HomeScreen: Update UI