# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Smart University System** - Flutter-based university management system with Arabic/English bilingual support (RTL/LTR).

- **Stack**: Flutter/Dart + Firebase (Firestore, Auth, Storage) + Supabase
- **Version**: 1.0.0+7
- **Roles**: Students, Doctors, Teaching Assistants, Managers, Super Admin
- **Core Features**: Attendance tracking with GPS, research submissions, exam management, real-time notifications

## Common Commands

```powershell
# Run the app
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test

# Build APK
flutter build apk --release
```

## Context Conservation Rules

**IMPORTANT**: This project approaches Firebase Spark plan limits (50K reads/day). Minimize unnecessary reads:

1. **Do NOT explore** without specific instruction - read only what you need
2. **Read specific line ranges** when possible, not entire files
3. **NEVER read** these directories:
   - `build/`
   - `.dart_tool/`
   - `android/`
   - `ios/`
   - `web/`
4. Use `Grep` to locate code before reading files
5. Avoid reading large files (`data_service.dart`: 2100+ lines, `super_admin_dashboard.dart`: 3265 lines) unless necessary

## Architecture

### Service Layer (Singleton Pattern)
- **`lib/services/data_service.dart`** (2100+ lines) - Central data orchestrator: Firebase ops, auth, role management, state
- **`lib/services/api_service.dart`** - Thin wrapper over DataService
- **`lib/services/exam_service.dart`** - Exam creation and grading
- **`lib/services/notification_service.dart`** - Notifications

### Authentication Patterns
Multi-role authentication with different email formats:
- Students: `<code>.college@smart.com` (e.g., `2024001.college@smart.com`)
- Doctors: `DOC_<code>@smart.com`
- TAs: `TA_<code>@smart.com`
- Managers: Custom emails

**Security**: Cross-college access control in [`data_service.dart:426-475`](lib/services/data_service.dart:426)

### Firestore Structure
```
/colleges/{collegeId}
  /students/{studentId}
  /doctors/{doctorId}
  /tas/{taId}
  /managers/{managerId}
  /levels/{levelId}/students/{studentId}
  /attendance/{attendanceId}
  /researches/{researchId}
  /exams/{examId}
```

### State Management
Uses `ChangeNotifier` pattern with `DataService` extending `ChangeNotifier`. Screens listen via `Provider`.

### Screen Organization
42 screens in [`lib/Screens/`](lib/Screens/):
- Student: [`student_home_screen.dart`](lib/Screens/student_home_screen.dart), [`attendance_scan_screen.dart`](lib/Screens/attendance_scan_screen.dart), [`research_upload_screen.dart`](lib/Screens/research_upload_screen.dart)
- Doctor: [`doctor_home_screen.dart`](lib/Screens/doctor_home_screen.dart), [`attendance_management_screen.dart`](lib/Screens/attendance_management_screen.dart)
- Admin: [`admin_home_screen.dart`](lib/Screens/admin_home_screen.dart), [`super_admin_dashboard.dart`](lib/Screens/super_admin_dashboard.dart)

## Sensitive Files

**Handle with care**:
- [`firestore.rules`](firestore.rules) - Security rules (has critical wildcard at lines 61-69)
- [`lib/firebase_options.dart`](lib/firebase_options.dart) - Contains hardcoded API keys
- [`lib/main.dart`](lib/main.dart) - Supabase keys hardcoded (lines 71-72)
- [`lib/services/data_service.dart`](lib/services/data_service.dart) - 2100+ lines, core of everything

## Current Branch: security-fix

Contains:
- Cross-college login vulnerability fix
- Research topic model with deadline enforcement
- Firestore constants extraction

## Deployment

**⚠️ DO NOT DEPLOY** until P0 issues are resolved. See [`.claude/plans/declarative-crunching-candle.md`](.claude/plans/declarative-crunching-candle.md) for complete security audit findings and remediation plan.

Critical blockers:
1. Firestore rules hardening (wildcard at firestore.rules:61-69)
2. GPS validation enabled (currently disabled at attendance_scan_screen.dart:18)
3. Secrets externalized
4. Phantom accounts cleaned
5. Password storage removed from SharedPreferences
