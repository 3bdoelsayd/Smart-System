# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Smart University System** - نظام إدارة جامعي متكامل يدعم اللغتين العربية والإنجليزية مع قلب الاتجاه (RTL/LTR).

- **Stack**: Flutter/Dart + Firebase (Firestore, Auth, Storage) + Supabase
- **Version**: 1.0.0+7
- **Roles**: Students, Doctors, Teaching Assistants, Managers, Super Admin
- **Key Features**: Attendance tracking with GPS, research submissions, exam management, real-time notifications

## Common Commands

### Development
```powershell
# Run the app
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Run with environment variables (for production)
flutter run --dart-define=FIREBASE_ANDROID_API_KEY=<key> --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>

# Hot reload (automatic during flutter run)
# Press 'r' in terminal
```

### Testing & Quality
```powershell
# Analyze code
flutter analyze

# Run tests
flutter test

# Run specific test
flutter test test/services/data_service_test.dart

# Check for Flutter issues
flutter doctor
```

### Build
```powershell
# Build APK for Android
flutter build apk --release

# Build iOS
flutter build ios --release

# Build for web
flutter build web --release
```

## High-Level Architecture

### Core Service Layer
The app uses a **singleton pattern** for services with `DataService` as the central data orchestrator:

- **`lib/services/data_service.dart`** (2100+ lines): Main data layer handling all Firebase operations, authentication, role management, and state. **This is the heart of the system** - most features touch this file.
- **`lib/services/api_service.dart`**: Thin wrapper over DataService for external integrations
- **`lib/services/exam_service.dart`**: Exam creation, grading, and management
- **`lib/services/notification_service.dart`**: Local and push notifications

### Authentication Flow
Multi-role authentication supporting different email patterns:
- Students: `<code>.college@smart.com` (e.g., `2024001.college@smart.com`)
- Doctors: `DOC_<code>@smart.com`
- TAs: `TA_<code>@smart.com`
- Managers/Admins: Custom emails

**Security notes**:
- Cross-college access control implemented in `data_service.dart:426-475`
- Device binding for students (one device per student)
- GPS validation for attendance (currently disabled at `attendance_scan_screen.dart:18-19`)

### Data Structure
```
Firestore:
  /colleges/{collegeId}
    /students/{studentId}
    /doctors/{doctorId}
    /tas/{taId}
    /managers/{managerId}
    /levels/{levelId}/students/{studentId}
    /attendance/{attendanceId}
    /researches/{researchId}
    /exams/{examId}
    /private_chats/{chatId}
```

### Screen Organization
42 screens organized by role:
- **Student**: `student_home_screen.dart`, `attendance_scan_screen.dart`, `research_upload_screen.dart`, `student_results_screen.dart`, `student_exams_list_screen.dart`
- **Doctor**: `doctor_home_screen.dart`, `attendance_management_screen.dart`, `research_submissions_screen.dart`, `doctor_exams_list_screen.dart`
- **Admin**: `admin_home_screen.dart`, `manager_dashboard.dart`, `super_admin_dashboard.dart`
- **Shared**: `unified_login_screen.dart`, `settings_screen.dart`, `notifications_screen.dart`

### State Management
Uses `ChangeNotifier` pattern with `DataService` extending `ChangeNotifier`. Screens listen via `Provider` and rebuild on `notifyListeners()`.

**Performance concern**: 126 `StreamBuilder` widgets without pagination cause excessive Firebase reads (20K-30K/day approaching Spark plan limit of 50K).

## Important Context

### Current Branch: security-fix
This branch contains security hardening work including:
- Cross-college login vulnerability fix
- Research topic model with deadline enforcement (`lib/models/research_topic_model.dart`)
- Firestore constants extraction (`lib/services/firestore_constants.dart`)

### Known Issues (from audit)
1. **Firestore Rules** (firestore.rules:61-69): Wildcard allows authenticated users to read/write all data - **CRITICAL**
2. **GPS disabled** (attendance_scan_screen.dart:18): `enableLocationCheck = false` allows attendance from anywhere
3. **Hardcoded secrets** (main.dart, firebase_options.dart): API keys in source
4. **129 phantom accounts**: Firebase Auth users without Firestore data
5. **Password storage**: Plain passwords saved in SharedPreferences
6. **Dummy data**: "commerce" and "testers" colleges in production
7. **39 hardcoded passwords**: "123456" scattered across dashboards

### Firebase Quota Management
- Current: 20K-30K reads/day
- Limit: 50K/day (Spark plan)
- **Solution needed**: Implement pagination, caching, and reduce StreamBuilder usage

### Bilingual Support
All user-facing strings go through `DataService.translate(key)`:
```dart
Text(DataService().translate('home')) // Returns 'الرئيسية' or 'Home'
```

## Development Guidelines

### When Modifying DataService
- This file is **large** (2100+ lines) and central to everything
- Always read the relevant section before modifying
- Test authentication flows after changes (student, doctor, TA, manager)
- Check impact on both Arabic and English UIs

### When Adding Firebase Operations
- Use existing `DataService` methods when possible
- Follow the singleton pattern
- Add proper error handling with bilingual messages
- Consider quota impact (prefer batched reads, avoid N+1 queries)

### When Working with Firestore Rules
- **NEVER** deploy rules without testing on Firebase Emulator first
- Test with different roles (student, doctor, manager)
- Document security model changes in commit messages

### Secrets Management
The app currently has hardcoded API keys. To fix:
1. Use `String.fromEnvironment()` for all keys
2. Pass keys via `--dart-define` at build time
3. Add `lib/config/secrets*.dart` to `.gitignore`
4. See security-fix branch for partial implementation

### Memory Leaks
`student_home_screen.dart` has documented memory leaks from unclosed streams. Dispose all `StreamSubscription` objects properly.

## Testing Strategy

### Manual Testing Checklist
- [ ] Login flow for all 5 roles
- [ ] Cross-college access prevention (student from College A cannot see College B data)
- [ ] GPS attendance validation (when enabled)
- [ ] Research submission with deadlines
- [ ] Exam creation and grading
- [ ] Arabic/English language switch
- [ ] Dark/Light theme switch

### Firebase Emulator Testing
```powershell
firebase emulators:start --only firestore,auth
# Update firebase.json to point to emulator
# Test Firestore rules before deploying
```

## File Size Warnings
Large files requiring careful modification:
- `lib/services/data_service.dart` (2100+ lines) - consider splitting
- `lib/Screens/super_admin_dashboard.dart` (3265 lines) - needs refactoring
- `lib/Screens/student_home_screen.dart` - has memory leaks

## External Dependencies
Key packages:
- `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`
- `supabase_flutter` (file storage alternative)
- `file_picker` (research uploads)
- `qr_code_scanner`, `qr_flutter` (attendance QR codes)
- `geolocator` (GPS validation)
- `flutter_local_notifications` (notifications)
- `excel` (attendance/grade exports)

## Security Considerations
- **GPS check**: Currently disabled - enable before production with `enableLocationCheck = true`
- **Firestore Rules**: Need complete rewrite before production
- **Secrets**: Must be externalized before any public deployment
- **Device binding**: Only applies to students, not staff
- **Cross-college access**: Fixed in security-fix branch

## Deployment Notes
**DO NOT DEPLOY** until P0 issues are resolved:
1. Firestore rules hardening
2. GPS validation enabled
3. Secrets externalized
4. Phantom accounts cleaned
5. Password storage removed from SharedPreferences

Refer to `.claude/plans/declarative-crunching-candle.md` for complete audit findings and remediation plan.
