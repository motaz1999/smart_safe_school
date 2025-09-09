# Logo Integration Plan

## Overview
This document outlines the steps required to integrate a new logo image into the login page of the Smart Safe School application.

## Current State Analysis
The current login screen (`lib/screens/auth/login_screen.dart`) uses a simple Material Icon for the logo:
```dart
// Logo and Title
Icon(
  Icons.school,
  size: 80,
  color: Theme.of(context).primaryColor,
),
```

## Implementation Steps

### 1. Create Assets Folder
- Create an `assets` folder in the project root directory
- This will be the standard location for all image assets in the Flutter project

### 2. Add Logo Image
- Place the `smart_safe_school_logo.png` file in the `assets` folder
- Ensure the image is properly sized for different screen densities if needed

### 3. Update pubspec.yaml
- Add the assets configuration to include the new assets folder:
```yaml
flutter:
  assets:
    - assets/
```

### 4. Modify Login Screen
Replace the current Icon widget with an Image widget:
```dart
// Replace this:
Icon(
  Icons.school,
  size: 80,
  color: Theme.of(context).primaryColor,
),

// With this:
Image.asset(
  'assets/smart_safe_school_logo.png',
  height: 80,
  width: 80,
),
```

### 5. Testing
- Verify the logo displays correctly on the login screen
- Check different screen sizes and orientations
- Ensure the app builds successfully after the changes

## File Locations
- Login Screen: `lib/screens/auth/login_screen.dart`
- Assets Folder: `assets/` (to be created)
- Logo File: `assets/smart_safe_school_logo.png` (to be added)
- Configuration: `pubspec.yaml`

## Implementation Considerations
1. Image sizing: The new logo should be appropriately sized for the login screen
2. Aspect ratio: Maintain the logo's original aspect ratio
3. Fallback: Consider providing a fallback in case the image fails to load
4. Performance: Ensure the logo file is optimized for web/mobile use