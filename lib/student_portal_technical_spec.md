# Student Portal Technical Specification

## Architecture Overview

The student portal will be implemented as a tab-based navigation system with three main screens:
1. Home Screen - Profile management and quick access
2. Timetable Screen - Class schedule viewing
3. Grades Screen - Academic performance tracking

## File Structure

```
lib/
├── screens/
│   ├── student/
│   │   ├── student_main.dart       # Main portal with bottom navigation
│   │   ├── home_screen.dart        # Home screen with profile picture
│   │   └── ... (existing screens)
│   └── ...
├── services/
│   └── image_service.dart          # Image handling utilities
└── ...
```

## Component Details

### 1. Student Main Portal (student_main.dart)
- StatefulWidget managing bottom navigation
- Uses BottomNavigationBar with 3 items
- Maintains current index state
- Displays appropriate screen based on selected tab

### 2. Home Screen (home_screen.dart)
- Profile picture display with circular avatar
- Image picker integration (gallery/camera)
- Local storage using shared_preferences
- Welcome message with student name from AuthProvider
- Quick stats display (similar to current dashboard)

### 3. Image Service (image_service.dart)
- selectImage() - Opens image picker
- saveImageLocally() - Saves image to app directory
- getSavedImagePath() - Retrieves stored image path
- deleteImage() - Removes stored image

## Data Flow

1. User logs in through existing auth flow
2. AuthProvider provides user profile data
3. StudentMainScreen becomes app home
4. HomeScreen displays profile info and picture
5. User can select new profile image
6. Image saved locally and path stored
7. Image persists across app sessions

## State Management

- AuthProvider for user authentication/data
- shared_preferences for image path persistence
- Local state for navigation index
- Local state for image loading status

## UI/UX Considerations

- Consistent styling with existing app theme
- Responsive layout for different screen sizes
- Loading indicators for image operations
- Error handling with user feedback
- Accessibility support (semantic labels, etc.)