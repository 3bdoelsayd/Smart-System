# University Smart System - Official Timetable Implementation Plan

This plan addresses the timetable management system for the University Smart System app, specifically fixing course and doctor loading, enabling robust CRUD operations for official lectures and sections, conflict detection, publishing for students, and real-time updates.

## Proposed Changes

### [Data Service]
#### [MODIFY] [data_service.dart](file:///C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/services/data_service.dart)
- Add methods to fetch courses (`getCommerceCoursesColl`), doctors (`commerceDoctorsColl`), and sections (`getCommerceSectionsColl`) for a given level with proper error handling and debugging logs.
- Add `scheduleEntriesColl` referencing `instituteRef.collection('schedule_entries')`.
- Add methods:
  - `addOfficialScheduleEntry(...)`
  - `updateOfficialScheduleEntry(...)`
  - `deleteOfficialScheduleEntry(...)`
  - `publishScheduleEntriesForLevel(String levelId)`
  - `getOfficialScheduleStream(String levelId)`
  - `getStudentScheduleStream(String levelId, String division)`
  - `getDoctorScheduleStream(String doctorId)`
  - `checkScheduleConflict(...)`

### [Manager Dashboard]
#### [MODIFY] [manager_dashboard.dart](file:///C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/Screens/manager_dashboard.dart)
- Update `_buildScheduleTab()` to:
  - Show a list of schedule entries grouped/sorted by day and time.
  - Show status badges (Draft / Published).
  - Provide a "نشر الجدول للطلاب" button showing unpublished count.
  - Provide Edit and Delete buttons for each card.
- Update `_showAddScheduleModal(context, levelStr, {Map<String, dynamic>? existingEntry, String? existingId})` to:
  - Fetch real courses, doctors, and sections from Firestore with error handling & loading states.
  - Support selecting Course (storing `subjectId` & `subjectName`).
  - Support selecting Doctor (storing `doctorId` & `doctorName`).
  - Support selecting Target Section (`all` or specific section).
  - Time Picker with 24-hour format string ("09:00") and optional end time/duration.
  - Free text hall/location.
  - Validation (Subject, Doctor, Time, Location required).
  - Conflict detection warning (same day, time, hall or doctor).
  - Handle both Create and Update operations.

### [Student & Doctor Screens]
#### [MODIFY] [student_home_screen.dart](file:///C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/Screens/student_home_screen.dart)
- Update `_StudentSchedulePage` to fetch published official schedule entries (`isPublished == true`) matching the student's level and section (`targetSection == 'all'` or student's division/section).
#### [MODIFY] [doctor_home_screen.dart](file:///C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/Screens/doctor_home_screen.dart)
- Update doctor schedule view to display official lectures assigned to the logged-in doctor.

## Verification Plan

### Automated Tests
- Run `gradle_build` to ensure code compiles successfully without syntax or type errors.

### Manual Verification
- Deploy the app to device/emulator.
- Log in as Admin for Level 4.
- Go to "الجدول" tab, click "إضافة محاضرة رسمية للفرقة". Verify that courses and doctors load correctly from Firestore.
- Add a lecture and verify it appears immediately in the schedule tab as a draft.
- Edit the lecture and verify updates are reflected.
- Click "نشر الجدول للطلاب" and verify status changes to published.
- Log in as a Student in Level 4 and verify the schedule appears in real-time.
- Log in as a Doctor and verify their schedule appears.
