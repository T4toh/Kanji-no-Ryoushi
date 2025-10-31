# Kanji no Ryoushi - AI Agent Instructions

## Project Overview

Japanese OCR (Optical Character Recognition) Flutter app using Google ML Kit. The app processes images with Japanese text and displays recognized characters using ML Kit's Japanese script recognition.

## Architecture

**Single-file structure**: All code currently in `lib/main.dart` with:

- `MyApp`: Root MaterialApp widget
- `OCRTestPage`: Stateful page that auto-runs OCR on init
- `_OCRTestPageState`: Handles OCR processing workflow

**OCR Pipeline** (see `_testOCR()` method):

1. Load image from `assets/images/prueba_texto.png` via `rootBundle`
2. Write bytes to temporary file (ML Kit requires file-based `InputImage`)
3. Initialize `TextRecognizer(script: TextRecognitionScript.japanese)`
4. Process image and display results in `SelectableText` widget
5. Always close `textRecognizer` after processing

## Key Dependencies & Configuration

**ML Kit Integration**:

- `google_mlkit_text_recognition: ^0.15.0` for OCR
- Android: Requires explicit native dependency in `android/app/build.gradle.kts`:
  ```kotlin
  dependencies {
      implementation("com.google.mlkit:text-recognition-japanese:16.0.0")
  }
  ```
- iOS: Auto-configured via CocoaPods

**Asset Management**:

- Test images must be declared in `pubspec.yaml` under `flutter.assets`
- Current test asset: `assets/images/prueba_texto.png`

## Development Workflows

**Running the app**:

```bash
flutter run  # Auto-executes OCR on startup via initState
```

**Testing OCR with new images**:

1. Add image to `assets/images/`
2. Update `pubspec.yaml` assets list
3. Change path in `_testOCR()` method (line ~32)
4. Hot restart (not hot reload - asset changes require full restart)

**Testing**:

- `test/widget_test.dart` is outdated (expects counter app, not OCR UI)
- Run tests: `flutter test` (will currently fail)
- **TODO**: Update widget tests to verify OCR UI elements

**Building**:

```bash
flutter build apk      # Android
flutter build ios      # iOS (requires macOS)
```

## Code Conventions

**State Management**: Using vanilla `setState()` - no external state management package

**Error Handling**: Try-catch blocks with dual output:

- Console: `print()` statements (debugging)
- UI: Updates `recognizedText` with error messages

**String Literals**:

- Spanish UI strings (e.g., `'OCR Japonés'`, `'No se reconoció texto'`)
- Spanish comments throughout codebase

**Linting**: Uses `package:flutter_lints/flutter.yaml` (strict Flutter recommended rules)

## Platform-Specific Notes

**Android**:

- Package: `com.example.kanji_no_ryoushi`
- Min SDK: Determined by Flutter (check `android/build.gradle.kts`)
- Java 11 compatibility required

**iOS**:

- Display name: "Kanji No Ryoushi"
- Bundle ID: Auto-configured
- Supports all orientations (portrait + landscape)

## Common Gotchas

1. **ML Kit file requirement**: `InputImage.fromFile()` is mandatory - direct byte processing not supported
2. **Temporary file cleanup**: Current implementation doesn't explicitly delete temp files (relies on OS cleanup)
3. **Asset hot reload**: Asset changes require app restart, not hot reload
4. **TextRecognizer disposal**: Always call `.close()` to prevent memory leaks
5. **Spanish localization**: UI is in Spanish, keep consistency when adding new strings

## When Adding Features

**Image picker integration** (already has dependency):

```dart
// Use image_picker: ^1.2.0 to select photos
import 'package:image_picker/image_picker.dart';
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.gallery);
```

**Persistent storage** (already has dependency):

```dart
// Use path_provider: ^2.1.5 for app directories
final appDir = await getApplicationDocumentsDirectory();
```

**New screens**: Consider splitting `lib/main.dart` into:

- `lib/main.dart` - App entry + routing
- `lib/screens/ocr_page.dart` - OCR functionality
- `lib/services/ocr_service.dart` - ML Kit logic
