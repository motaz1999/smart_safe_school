# App Icon Update Guide

This guide will help you update your Flutter app's icons with your custom logo.

## Prerequisites

1. Your logo file: `assets/smart_safe_school_logo.png`
2. Image editing software (optional but recommended):
   - Online tools: https://www.figma.com/, https://www.canva.com/, or https://www.photopea.com/
   - Desktop software: GIMP (free) or Adobe Photoshop

## Android App Icon Update

### Required Icon Sizes
- mipmap-mdpi: 48x48 pixels
- mipmap-hdpi: 72x72 pixels
- mipmap-xhdpi: 96x96 pixels
- mipmap-xxhdpi: 144x144 pixels
- mipmap-xxxhdpi: 192x192 pixels

### Steps to Update Android Icons

1. Open your logo file (`assets/smart_safe_school_logo.png`) in an image editor
2. Resize your logo to each of the required sizes listed above
3. If your logo has transparency, place it on a colored background (typically white or your brand color)
4. Save each resized version with the name `ic_launcher.png`
5. Replace the existing files in these directories:
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

## iOS App Icon Update

### Required Icon Sizes
- Icon-App-20x20@1x.png: 20x20 pixels
- Icon-App-20x20@2x.png: 40x40 pixels
- Icon-App-20x20@3x.png: 60x60 pixels
- Icon-App-29x29@1x.png: 29x29 pixels
- Icon-App-29x29@2x.png: 58x58 pixels
- Icon-App-29x29@3x.png: 87x87 pixels
- Icon-App-40x40@1x.png: 40x40 pixels
- Icon-App-40x40@2x.png: 80x80 pixels
- Icon-App-40x40@3x.png: 120x120 pixels
- Icon-App-60x60@2x.png: 120x120 pixels
- Icon-App-60x60@3x.png: 180x180 pixels
- Icon-App-76x76@1x.png: 76x76 pixels
- Icon-App-76x76@2x.png: 152x152 pixels
- Icon-App-83.5x83.5@2x.png: 167x167 pixels
- Icon-App-1024x1024@1x.png: 1024x1024 pixels

### Steps to Update iOS Icons

1. Open your logo file (`assets/smart_safe_school_logo.png`) in an image editor
2. Create each of the required sizes listed above
3. Save each version with the appropriate name in:
   `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Alternative: Automated Icon Generation

You can use online tools to automatically generate all required icon sizes:

1. Visit https://www.favicon-generator.org/ or https://appicon.co/
2. Upload your `smart_safe_school_logo.png` file
3. Download the generated icon pack
4. Extract and replace the existing icon files in your project

## Testing the Changes

After updating the icons:

1. Clean your Flutter project:
   ```
   flutter clean
   flutter pub get
   ```

2. Rebuild your app:
   ```
   flutter build
   ```

3. For Android, you can test with:
   ```
   flutter run
   ```

4. For iOS, open the project in Xcode and run from there

## Important Notes

1. Make sure your logo has appropriate contrast for visibility
2. Consider having a simplified version of your logo for smaller sizes
3. The 1024x1024 iOS icon is used to generate all other sizes automatically in some tools
4. Always test your app on different devices to ensure the icons display correctly

## Troubleshooting

If icons don't update:

1. Delete the app from your device/emulator
2. Run `flutter clean` and `flutter pub get`
3. Rebuild and redeploy the app
4. Check that all file names match exactly