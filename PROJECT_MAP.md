# Project Map (Smart University System)

## 1. Folder Structure & Purpose of Main Folders
- `lib/`: Core source code for the Flutter application.
  - `lib/Screens/`: All application UI screens and views (grouped by features/roles).
  - `lib/services/`: Business logic, Firebase / Supabase integration, authentication, and global state (`DataService`).
  - `lib/theme/`: App themes (light/dark theme definitions and colors).
  - `lib/utils/`: Helper utilities (Excel parser, student data migration, upload scripts).
  - `lib/widgets/`: Reusable custom UI components (AppDrawer, modals, buttons, cards).
- `android/`: Android native configuration, Gradle build files, and app manifests.
- `ios/`: iOS native configuration, runner project, and asset definitions.
- `assets/`: Static resources such as audio assets and app icons.
- `test/`: Unit and widget test suite.
- Root scripts/configs (`firebase.json`, `firestore.rules`, python migration scripts, etc.).

---

## 2. List of All Screens Grouped by Role

### A. Authentication & General / Shared Screens
1. `splash_screen.dart` - App initialization and splash loader.
2. `start_screen.dart` - Welcome / entry point screen with language switcher and developer info.
3. `college_selection_screen.dart` - Institute / College selection screen.
4. `unified_login_screen.dart` - Unified login screen for all user roles.
5. `admin_login_screen.dart` - Dedicated staff/admin login.
6. `doctor_login_screen.dart` - Dedicated doctor login.
7. `student_login_screen.dart` - Dedicated student login.
8. `notifications_screen.dart` - Notifications and system alerts center.
9. `settings_screen.dart` - App settings (Dark mode, language, etc.).
10. `edit_profile_screen.dart` - User profile editor (avatar, phone, personal email, privacy).
11. `password_management_screen.dart` - Password reset/change screen.

### B. Student Portal
12. `student_home_screen.dart` - Main student dashboard (Home, Schedule, Research, Results, Attendance).
13. `attendance_scan_screen.dart` - QR code scanner with GPS validation for attendance & sections.
14. `research_upload_screen.dart` - File picker and uploader for student research papers.
15. `research_list_screen.dart` - History and status tracker of uploaded research papers.
16. `student_results_screen.dart` - Exam results and grades view.
17. `student_profile_screen.dart` - Detailed student profile modal / view.
18. `student_doctors_list_screen.dart` - Directory of Faculty, TAs, and Managers with chat & WhatsApp integration.
19. `send_research_screen.dart` - Research submission flow helper.
20. `course_details_screen.dart` - Detailed view of enrolled courses and lectures.

### C. Doctor & TA (Teaching Assistant) Portal
21. `doctor_home_screen.dart` - Staff dashboard for Doctors and TAs (Courses, attendance, research review).
22. `attendance_management_screen.dart` - Attendance management & dynamic QR code generator (Lecture vs. Section attendance).
23. `research_submissions_screen.dart` - Review, grade, and comment on student research submissions.
24. `doctor_students_list_screen.dart` - Student roster and communication list.
25. `exam_results_management_screen.dart` - Coursework, final exam grade entry, and GPA calculation.
26. `grades_management_screen.dart` - Grade management interface.
27. `discussion_forum_screen.dart` - Real-time discussion forum per course (moderation, banning, locking).
28. `private_chat_screen.dart` - 1-to-1 secure private messaging between users (Student <-> Doctor/TA).

### D. Year Manager & Super Admin Dashboards
29. `super_admin_dashboard.dart` - Super Admin console (Levels, Sections, Students, Doctors, TAs, Managers, Semesters management).
30. `manager_dashboard.dart` - Year Manager dashboard (manage students, courses, doctors, TAs, and attendance per level).
31. `admin_home_screen.dart` - Student Affairs Admin home.
32. `bulk_upload_results_screen.dart` - Excel batch importer for exam results and student data.
33. `subjects_groups_screen.dart` - Subject and group management view.

---

## 3. Services & Repositories Communicating with Firebase & Supabase
- **`DataService` (`lib/services/data_service.dart`)**:
  - The central service singleton managing all backend interactions:
    - **Firebase Auth**: User sign-in, session creation, password updates.
    - **Cloud Firestore**: Collation of institutes (`colleges`), students, doctors, TAs (`tas`), managers, super admins, levels, courses, lectures, attendance, submissions, exam results, and private/forum chats.
    - **Firebase Storage**: Avatar & document handling.
    - **Supabase Storage**: Large PDF research paper uploads and public URL retrieval (`supabase.storage.from('research-pdfs')`).
    - **Local Notifications**: Scheduled notifications for lectures/sections using `flutter_local_notifications`.
- **`NotificationService` (`lib/services/notification_service.dart`)**:
  - Handles push notifications and local alert triggers.
- **`ExcelHelper` (`lib/utils/excel_helper.dart`)**:
  - Parses Excel files (.xlsx) for bulk importing students, doctors, TAs, and exporting attendance sheets.

---

## 4. State Management Approach Used
- **`ChangeNotifier` & `ListenableBuilder`**:
  - `DataService` extends `ChangeNotifier`. Throughout the widget tree, `ListenableBuilder` (and occasionally `AnimatedBuilder` / `Provider`-like patterns) is used to listen to changes in `DataService` (such as theme switching, language toggle, and authentication/user state updates).
- **`setState`**:
  - Used extensively within individual stateful screens for local UI state (search queries, tab indices, form controllers, loading flags, scanning state).

---

## 5. The 10 Riskiest Files (Complexity, Size, or Bug Prone)
1. **`lib/services/data_service.dart` (~1370+ lines)**:
   - *Risk*: Massive monolithic service handling auth fallbacks, Firestore queries for multiple collections, Supabase uploads, local notifications, and state management. Any breaking change here impacts the entire app.
2. **`lib/Screens/super_admin_dashboard.dart` (~1860+ lines)**:
   - *Risk*: Contains multiple complex management views (Levels, Sections, Students, Doctors, TAs, Managers, Semesters) with heavy StreamBuilders and form validations in a single file.
3. **`lib/Screens/attendance_management_screen.dart` (~1100+ lines)**:
   - *Risk*: Complex logic combining dynamic QR code generation, expiration countdown timers, geolocation distance calculation, manual check-in lists, and Excel attendance export.
4. **`lib/Screens/student_home_screen.dart` (~1160+ lines)**:
5. **`lib/Screens/manager_dashboard.dart` (~970+ lines)**:
6. **`lib/Screens/grades_management_screen.dart` (~645+ lines)**:
7. **`lib/Screens/discussion_forum_screen.dart` (~529+ lines)**:
8. **`lib/Screens/settings_screen.dart` (~454+ lines)**:
9. **`lib/Screens/research_submissions_screen.dart` (~415+ lines)**:
10. **`lib/Screens/unified_login_screen.dart` (~448+ lines)**:
