import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class SeedTestersUtility {
  static const String _salt = "SystemSalt2026";

  static String _hashPassword(String password) {
    var bytes = utf8.encode(password + _salt);
    return sha256.convert(bytes).toString();
  }

  /// One-time idempotent seeding function for Testers faculty and 13 dummy student accounts.
  static Future<void> seedTestersFacultyAndAccounts() async {
    final firestore = FirebaseFirestore.instance;
    final collegeRef = firestore.collection('colleges').doc('testers');

    // 1. Create/Update Testers Faculty
    await collegeRef.set({
      'id': 'testers',
      'nameAr': 'المختبرين',
      'nameEn': 'Testers Faculty',
      'isTestFaculty': true,
      'hidden': true,
      'logoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final String hashedPassword = _hashPassword("000000");

    // 2. Create 13 Dummy Student Accounts (10001 to 10013)
    for (int i = 1; i <= 13; i++) {
      String studentId = (10000 + i).toString(); // 10001 through 10013
      String uid = "STD_$studentId";
      String name = "مختبر $i";
      String email = "$studentId.college@smart.com";

      Map<String, dynamic> studentData = {
        'uid': uid,
        'id': studentId,
        'name': name,
        'email': email,
        'password': hashedPassword,
        'level': '1',
        'division': 'نظم معلومات الاعمال',
        'group': 'A',
        'role': 'student',
        'isTestStudent': true,
        'instituteId': 'testers',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save in root students collection of testers college
      await collegeRef.collection('students').doc(uid).set(studentData, SetOptions(merge: true));

      // Save in level students subcollection (level_1)
      await collegeRef.collection('levels').doc('level_1').collection('students').doc(uid).set(studentData, SetOptions(merge: true));
    }

    // 3. Add Demo Content (Subjects, Schedule, Quiz)
    // Level 1 Courses
    final List<Map<String, dynamic>> demoCourses = [
      {'name': 'البرمجة المتقدمة', 'level': '1', 'division': 'نظم معلومات الاعمال', 'instituteId': 'testers'},
      {'name': 'قواعد البيانات الحديثة', 'level': '1', 'division': 'نظم معلومات الاعمال', 'instituteId': 'testers'},
      {'name': 'أمن المعلومات', 'level': '1', 'division': 'نظم معلومات الاعمال', 'instituteId': 'testers'},
    ];

    for (var course in demoCourses) {
      String courseId = "${course['name']}_1_نظم معلومات الاعمال";
      await collegeRef.collection('levels').doc('level_1').collection('courses').doc(courseId).set(course, SetOptions(merge: true));
    }

    // Demo Schedule Entry
    await collegeRef.collection('schedule_entries').doc('demo_schedule_1').set({
      'subject': 'البرمجة المتقدمة',
      'level': '1',
      'division': 'نظم معلومات الاعمال',
      'day': 'الأحد',
      'time': '10:00 ص - 12:00 م',
      'hall': 'قاعة المختبرات 1',
      'doctorName': 'د. مختبر تجريبي',
      'instituteId': 'testers',
    }, SetOptions(merge: true));

    // Demo Exam / Quiz
    await collegeRef.collection('exams').doc('demo_quiz_1').set({
      'title': 'اختبار تجريبي قصير (Quiz)',
      'subject': 'البرمجة المتقدمة',
      'level': '1',
      'division': 'نظم معلومات الاعمال',
      'durationMinutes': 15,
      'isPublished': true,
      'instituteId': 'testers',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print("✅ Successfully seeded Testers faculty, 13 student accounts (10001-10013), and demo content!");
  }

  /// Cleanup function to remove Testers faculty and all associated test data without touching real data.
  static Future<void> cleanupTestersFacultyAndAccounts() async {
    final firestore = FirebaseFirestore.instance;
    final collegeRef = firestore.collection('colleges').doc('testers');

    // 1. Delete students
    var studentsSnap = await collegeRef.collection('students').get();
    for (var doc in studentsSnap.docs) {
      await doc.reference.delete();
    }

    var lvlStudentsSnap = await collegeRef.collection('levels').doc('level_1').collection('students').get();
    for (var doc in lvlStudentsSnap.docs) {
      await doc.reference.delete();
    }

    var coursesSnap = await collegeRef.collection('levels').doc('level_1').collection('courses').get();
    for (var doc in coursesSnap.docs) {
      await doc.reference.delete();
    }

    var schedulesSnap = await collegeRef.collection('schedule_entries').get();
    for (var doc in schedulesSnap.docs) {
      await doc.reference.delete();
    }

    var examsSnap = await collegeRef.collection('exams').get();
    for (var doc in examsSnap.docs) {
      await doc.reference.delete();
    }

    // 2. Delete college document
    await collegeRef.delete();

    print("🗑️ Successfully cleaned up Testers faculty and all test data!");
  }
}
