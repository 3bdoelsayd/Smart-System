import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io' as io;

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  bool isDarkMode = false;
  bool isArabic = true;
  bool isChangingTheme = false;

  static const Color primaryColor = Color(0xFF673AB7);
  static const String _salt = "SystemSalt2026";
  static const String _domain = "@smart.com";

  final String companyNameAr = "A.SHERBINY";
  final String companyNameEn = "A.SHERBINY";
  final String devPhone = "+201001404112";
  final String devAccountUrl = "https://www.facebook.com/share/1E9Xcnirqs/";

  final String affairsPhone = "01092720053";
  final String affairsEmail = "dean@himsb.edu.eg";

  String? selectedInstituteId;
  Map<String, dynamic>? instituteData;

  Map<String, dynamic>? currentStudent;
  Map<String, dynamic>? currentDoctor;
  Map<String, dynamic>? currentAdmin;
  int studentTabIndex = 0;
  int managerTabIndex = 0;
  String? userRole;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // نغير دي عشان متبدأش غير لما نحتاجها فعلاً
  SupabaseClient get supabase => Supabase.instance.client;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  List<String> studentSubjects = [];

  Future<void> playClickSound() async {
    debugPrint("Action triggered");
  }

  String translate(String key) {
    final Map<String, Map<String, String>> localizedValues = {
      'ar': {
        'app_name': 'نظام الجامعة الذكي',
        'app_title': instituteData?['nameAr'] ?? 'نظام الجامعة الذكي',
        'home': 'الرئيسية', 'attendance': 'تسجيل الحضور',
        'upload_research': 'رفع بحث', 'research_history': 'سجل الأبحاث', 'results': 'النتائج الدراسية',
        'my_researches': 'أبحاثي', 'schedule': 'جدولي', 'profile': 'الملف الشخصي',
        'settings': 'الإعدادات', 'logout': 'تسجيل الخروج', 'language': 'اللغة',
        'dark_mode': 'الوضع ليلي', 'welcome': 'أهلاً بك،', 'doctor_portal': 'بوابة المحاضرين',
        'student_portal': 'دخول الطلاب', 'admin_portal': 'بوابة الإدارة',
        'select_institute': 'اختر المعهد / الكلية',
        'contact_affairs': 'تواصل مع شؤون الطلاب',
        'developed_by': 'تطوير: ',
        'system_dashboard': 'لوحة تحكم النظام',
        'manage_levels': 'إدارة الفرق',
        'manage_sections': 'إدارة الشعب',
        'manage_students': 'إدارة الطلاب',
        'manage_doctors': 'إدارة الدكاترة',
        'manage_managers': 'إدارة المديرين',
        'semesters': 'الفصول الدراسية',
        'super_admin': 'سوبر أدمن',
        'select_subject': 'اختر المادة',
        'pick_file': 'اختر الملف',
        'research_review': 'مراجعة الأبحاث',
        'attendance_mng': 'إدارة الحضور',
        'forum': 'ساحة النقاش',
        'my_courses': 'موادي الدراسية',
        'level': 'الفرقة',
        'no_subjects_assigned': 'لم يتم العثور على مواد مسجلة',
        'faculty_member': 'عضو هيئة التدريس',
        'already_recorded': 'لقد قمت بتسجيل الحضور مسبقاً لهذه المحاضرة',
        'ok': 'حسناً',
        'cancel': 'إلغاء',
        'lec_no': 'محاضرة رقم',
      },
      'en': {
        'app_name': 'Smart System',
        'app_title': instituteData?['nameEn'] ?? 'Higher Institute for Administrative Sciences',
        'home': 'Home', 'attendance': 'Attendance',
        'upload_research': 'Upload Research', 'research_history': 'History', 'results': 'Exam Results',
        'my_researches': 'My Researches', 'schedule': 'Schedule', 'profile': 'Profile',
        'settings': 'Settings', 'logout': 'Logout', 'language': 'Language',
        'dark_mode': 'Dark Mode', 'welcome': 'Welcome,', 'doctor_portal': 'Staff Portal',
        'student_portal': 'Student Entry', 'admin_portal': 'Staff Portal',
        'select_institute': 'Select Institute / College',
        'system_dashboard': 'System Dashboard',
        'manage_levels': 'Levels Management',
        'manage_sections': 'Sections Management',
        'manage_students': 'Students Management',
        'manage_doctors': 'Doctors Management',
        'manage_managers': 'Managers Management',
        'semesters': 'Academic Semesters',
        'super_admin': 'Super Admin',
        'select_subject': 'Select Subject',
        'pick_file': 'Pick File',
        'research_review': 'Research Review',
        'attendance_mng': 'Attendance Management',
        'forum': 'Discussion Forum',
        'my_courses': 'My Courses',
        'level': 'Level',
        'no_subjects_assigned': 'No subjects assigned',
        'faculty_member': 'Faculty Member',
        'already_recorded': 'You have already recorded attendance for this lecture',
        'ok': 'OK',
        'cancel': 'Cancel',
        'lec_no': 'Lecture No.',
      },
    };
    return localizedValues[isArabic ? 'ar' : 'en']?[key] ?? key;
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password + _salt);
    return sha256.convert(bytes).toString();
  }

  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> setInstitute(String id) async {
    selectedInstituteId = id.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_institute_id', selectedInstituteId!);

    var doc = await _firestore.collection('colleges').doc(selectedInstituteId!).get();
    if (doc.exists) {
      instituteData = doc.data() != null ? Map<String, dynamic>.from(doc.data() as Map) : {};
      debugPrint("✅ Institute Set: $selectedInstituteId");
    } else {
      debugPrint("❌ CRITICAL: Institute ID '$id' not found in Firestore!");
      selectedInstituteId = null;
      instituteData = null;
    }
    notifyListeners();
  }

  Future<bool> loginStudent(String code, String pass) async { try { String? role = await unifiedLogin(code, pass); return role == 'student'; } catch(_) { return false; } }
  Future<bool> loginDoctor(String code, String pass) async { try { String? role = await unifiedLogin(code, pass); return role == 'doctor' || role == 'ta'; } catch(_) { return false; } }
  Future<bool> loginAdmin(String code, String pass) async { try { String? role = await unifiedLogin(code, pass); return role == 'super_admin' || role == 'manager'; } catch(_) { return false; } }

  Future<String?> unifiedLogin(String loginInput, String password) async {
    try {
      if (selectedInstituteId == null) {
        throw isArabic ? "يرجى اختيار الكلية أولاً" : "Please select college first";
      }

      String input = loginInput.trim().toLowerCase();
      String cleanCode = input
          .replaceAll('std_', '')
          .replaceAll('doc_', '')
          .replaceAll('.college@smart.com', '')
          .replaceAll('@smart.edu', '')
          .replaceAll('@smart.com', '')
          .trim();

      String email = input.contains('@') && !input.endsWith('@smart.edu') ? input : _formatEmail(cleanCode);
      debugPrint("Login Attempt: Code=$cleanCode | Email=$email");

      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password.trim()
        );
      } catch (authError) {
        debugPrint("Auth sign-in error: $authError. Attempting Firestore fallback...");
        String hashedPass = hashPassword(password.trim());
        var collegeRef = _firestore.collection('colleges').doc(selectedInstituteId!);

        var studentQuery = await collegeRef.collection('students')
            .where('id', isEqualTo: cleanCode)
            .get();

        if (studentQuery.docs.isEmpty) {
          studentQuery = await collegeRef.collection('students')
              .where('email', isEqualTo: email)
              .get();
        }

        if (studentQuery.docs.isNotEmpty) {
          var studData = studentQuery.docs.first.data();
          String docPass = studData['password']?.toString() ?? '';
          if (docPass == hashedPass || docPass == password.trim()) {
            // Firestore password matches! Try creating or updating Auth user
            try {
              userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password.trim());
            } catch (_) {
              try {
                await _secureCreateUser(email, password.trim());
                userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password.trim());
              } catch (_) {
                // Ignore if auth creation fails due to existing user with different pass
              }
            }
          } else {
            throw isArabic ? "كلمة المرور غير صحيحة" : "Incorrect password";
          }
        } else {
          rethrow;
        }
      }

      String uid = userCredential?.user?.uid ?? "STD_$cleanCode";
      String? userEmail = userCredential?.user?.email ?? email;
      
      // --- نظام الأمان المحسن: بصمة داتئمة للهاتف/المتصفح نفسه ---
      final prefs = await SharedPreferences.getInstance();
      String? localDeviceId = prefs.getString('app_device_fingerprint');
      if (localDeviceId == null || localDeviceId.isEmpty) {
        localDeviceId = "DEVICE-${DateTime.now().millisecondsSinceEpoch}-${(uid.hashCode.abs() + 1000)}";
        await prefs.setString('app_device_fingerprint', localDeviceId);
      }
      // --------------------------------------------------------

      String? role = await _findAndLoadUser(uid, userEmail: userEmail);

      if (role == null) {
        // Search by clean code directly
        role = await _checkUserInCollege(selectedInstituteId!, cleanCode, userEmail: userEmail);
      }

      if (role != null) {
        // التحقق من ربط الجهاز للطلاب فقط لزيادة الأمان ومنع تبادل الحسابات
        if (role == 'student' && currentStudent != null) {
          String? storedDeviceId = currentStudent!['deviceId'];
          String firestoreDocId = currentStudent!['uid'] ?? uid;
          if (storedDeviceId == null || storedDeviceId.isEmpty) {
            // ربط الجهاز لأول مرة بهذا الهاتف
            try {
              await studentsColl.doc(firestoreDocId).update({'deviceId': localDeviceId});
            } catch (_) {
              try {
                await getCommerceStudentsColl('level_' + (currentStudent!['level'] ?? '1')).doc(firestoreDocId).update({'deviceId': localDeviceId});
              } catch (_) {}
            }
            currentStudent!['deviceId'] = localDeviceId;
          } else if (storedDeviceId != localDeviceId) {
            await _auth.signOut();
            throw isArabic 
              ? "عذراً، هذا الحساب مرتبط بجهاز آخر. يرجى مراجعة شؤون الطلاب لإعادة ضبط الجهاز." 
              : "Account bound to another device. Contact Student Affairs.";
          }
        }

        await saveSession(uid, role);
        notifyListeners();
        return role;
      } else {
        await _auth.signOut();
        throw isArabic
            ? "تم الدخول بنجاح، ولكن حسابك غير مسجل في بيانات هذه الكلية"
            : "Login success, but your account is not registered in this college";
      }
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    }
  }

  Future<String?> _findAndLoadUser(String uid, {String? userEmail}) async {
    debugPrint("🕵️ Checking user UID: $uid (Email: $userEmail) in current college: $selectedInstituteId");

    String? role = await _checkUserInCollege(selectedInstituteId!, uid, userEmail: userEmail);
    if (role != null) return role;

    try {
      var colleges = await _firestore.collection('colleges').get();
      for (var colDoc in colleges.docs) {
        if (colDoc.id == selectedInstituteId) continue;
        role = await _checkUserInCollege(colDoc.id, uid, userEmail: userEmail);
        if (role != null) {
          await setInstitute(colDoc.id);
          return role;
        }
      }
    } catch (e) {
      debugPrint("Global search error: $e");
    }

    return null;
  }

  Future<String?> _checkUserInCollege(String collegeId, String uid, {String? userEmail}) async {
    var collegeRef = _firestore.collection('colleges').doc(collegeId);
    String cleanCode = uid
        .replaceAll('doc_', '')
        .replaceAll('DOC_', '')
        .replaceAll('std_', '')
        .replaceAll('STD_', '')
        .replaceAll('.college@smart.com', '')
        .replaceAll('@smart.edu', '')
        .replaceAll('@smart.com', '')
        .trim();

    // 1. فحص الطلاب أولاً لسرعة البرق (95% من مستخدمي النظام طلاب)
    try {
      var doc = await collegeRef.collection('students').doc(uid).get();
      if (!doc.exists) doc = await collegeRef.collection('students').doc("STD_$cleanCode").get();
      if (!doc.exists) doc = await collegeRef.collection('students').doc(cleanCode).get();
      if (!doc.exists && userEmail != null) {
        var q = await collegeRef.collection('students').where('email', isEqualTo: userEmail).get();
        if (q.docs.isNotEmpty) doc = q.docs.first;
      }
      if (!doc.exists && cleanCode.isNotEmpty) {
        var qId = await collegeRef.collection('students').where('id', isEqualTo: cleanCode).get();
        if (qId.docs.isNotEmpty) doc = qId.docs.first;
      }

      if (doc.exists && doc.data() != null) {
        currentStudent = Map<String, dynamic>.from(doc.data() as Map);
        currentStudent!['uid'] = doc.id;
        userRole = 'student';
        String studentLvl = normalizeLevel(currentStudent!['level']?.toString() ?? '1');
        await fetchSubjectsForLevel(studentLvl, currentStudent!['division']?.toString() ?? 'ALL');
        return 'student';
      }

      var lvls = await collegeRef.collection('levels').get();
      for (var l in lvls.docs) {
        var sDoc = await l.reference.collection('students').doc(uid).get();
        if (!sDoc.exists) sDoc = await l.reference.collection('students').doc("STD_$cleanCode").get();
        if (!sDoc.exists) sDoc = await l.reference.collection('students').doc(cleanCode).get();
        if (!sDoc.exists && userEmail != null) {
          var q = await l.reference.collection('students').where('email', isEqualTo: userEmail).get();
          if (q.docs.isNotEmpty) sDoc = q.docs.first;
        }
        if (!sDoc.exists && cleanCode.isNotEmpty) {
          var qId = await l.reference.collection('students').where('id', isEqualTo: cleanCode).get();
          if (qId.docs.isNotEmpty) sDoc = qId.docs.first;
        }

        if (sDoc.exists && sDoc.data() != null) {
          currentStudent = Map<String, dynamic>.from(sDoc.data() as Map);
          currentStudent!['uid'] = sDoc.id;
          userRole = 'student';
          String studentLvl = normalizeLevel(currentStudent!['level']?.toString() ?? l.id.replaceAll('level_', ''));
          await fetchSubjectsForLevel(studentLvl, currentStudent!['division']?.toString() ?? 'ALL');
          return 'student';
        }
      }
    } catch (_) {}

    // 2. فحص الدكاترة
    try {
      String code = uid.replaceAll('doc_', '').replaceAll('std_', '').replaceAll('.college@smart.com', '').trim();
      var doc = await collegeRef.collection('doctors').doc(uid).get();
      if (!doc.exists) doc = await collegeRef.collection('doctors').doc("DOC_$code").get();
      if (!doc.exists && userEmail != null) {
        var q = await collegeRef.collection('doctors').where('email', isEqualTo: userEmail).get();
        if (q.docs.isNotEmpty) doc = q.docs.first;
      }
      if (!doc.exists) {
        var q2 = await collegeRef.collection('doctors').where('id', isEqualTo: code).get();
        if (q2.docs.isNotEmpty) doc = q2.docs.first;
      }
      if (doc.exists && doc.data() != null) {
        currentDoctor = Map<String, dynamic>.from(doc.data() as Map);
        currentDoctor!['uid'] = doc.id;
        userRole = 'doctor';
        return 'doctor';
      }
    } catch (_) {}

    // 2.5. فحص المعيدين
    try {
      String code = uid.replaceAll('ta_', '').replaceAll('TA_', '').replaceAll('doc_', '').replaceAll('std_', '').replaceAll('.college@smart.com', '').trim();
      var doc = await collegeRef.collection('tas').doc(uid).get();
      if (!doc.exists) doc = await collegeRef.collection('tas').doc("TA_$code").get();
      if (!doc.exists && userEmail != null) {
        var q = await collegeRef.collection('tas').where('email', isEqualTo: userEmail).get();
        if (q.docs.isNotEmpty) doc = q.docs.first;
      }
      if (!doc.exists && code.isNotEmpty) {
        var q2 = await collegeRef.collection('tas').where('id', isEqualTo: code).get();
        if (q2.docs.isNotEmpty) doc = q2.docs.first;
      }
      if (doc.exists && doc.data() != null) {
        currentDoctor = Map<String, dynamic>.from(doc.data() as Map);
        currentDoctor!['uid'] = doc.id;
        userRole = 'ta';
        return 'ta';
      }
    } catch (_) {}

    // 3. فحص الإدارة والمديرين
    List<String> adminColls = ['managers', 'manager', 'super_admins', 'super_admin'];
    for (var c in adminColls) {
      try {
        var doc = await collegeRef.collection(c).doc(uid).get();
        if (!doc.exists && userEmail != null) {
          var q = await collegeRef.collection(c).where('email', isEqualTo: userEmail).get();
          if (q.docs.isNotEmpty) doc = q.docs.first;
        }
        if (doc.exists && doc.data() != null) {
          var data = Map<String, dynamic>.from(doc.data() as Map);
          currentAdmin = data;
          currentAdmin!['uid'] = doc.id;
          userRole = data['role'] ?? (c.contains('manager') ? 'manager' : 'super_admin');
          return userRole;
        }
      } catch (_) {}
    }

    return null;
  }

  DocumentReference get instituteRef {
    if (selectedInstituteId == null) {
      throw Exception("Institute not selected");
    }
    return _firestore.collection('colleges').doc(selectedInstituteId);
  }

  CollectionReference get studentsColl => instituteRef.collection('students');
  CollectionReference get doctorsColl => _firestore.collection('doctors');
  CollectionReference get attendanceColl => _firestore.collection('attendance');
  CollectionReference get submissionsColl => _firestore.collection('submissions');
  CollectionReference get gradesColl => _firestore.collection('grades');
  CollectionReference get examResultsColl => _firestore.collection('exam_results');
  CollectionReference get notificationsColl => _firestore.collection('notifications');

  CollectionReference get commerceDoctorsColl => instituteRef.collection('doctors');
  CollectionReference get commerceTasColl => instituteRef.collection('tas');
  CollectionReference get commerceManagersColl => instituteRef.collection('managers');
  CollectionReference get commerceSuperAdminsColl => instituteRef.collection('super_admins');
  CollectionReference get commerceLevelsColl => instituteRef.collection('levels');
  CollectionReference get commerceSemestersColl => instituteRef.collection('semesters');

  CollectionReference getCommerceStudentsColl(String levelId) => commerceLevelsColl.doc(levelId).collection('students');
  CollectionReference getCommerceCoursesColl(String levelId) => commerceLevelsColl.doc(levelId).collection('courses');
  CollectionReference getCommerceSectionsColl(String levelId) => commerceLevelsColl.doc(levelId).collection('sections');
  CollectionReference getCommerceLecturesColl(String levelId, String courseId) => getCommerceCoursesColl(levelId).doc(courseId).collection('lectures');

  Future<void> addLevel(String id, String name, String? mId) async { await commerceLevelsColl.doc(id).set({'id': id, 'name': name, 'managerId': mId, 'createdAt': FieldValue.serverTimestamp()}); notifyListeners(); }
  Future<void> deleteLevel(String id) async { await commerceLevelsColl.doc(id).delete(); notifyListeners(); }
  Future<void> addSection(String levelId, String name) async { String sid = _firestore.collection('tmp').doc().id; await getCommerceSectionsColl(levelId).doc(sid).set({'id': sid, 'name': name, 'isActive': true, 'createdAt': FieldValue.serverTimestamp()}); notifyListeners(); }

  Future<void> addStudentManual(String levelId, String studentCode, String name, String emailInput, String division, String password, {bool notify = true}) async {
    try {
      if (selectedInstituteId == null) throw "Please select institute first";

      String email = _formatEmail(studentCode);
      String finalPass = password.trim().isEmpty ? "123456" : password.trim();
      String uid = "STD_${studentCode.trim()}";

      Map<String, dynamic> studentData = {
        'uid': uid, 'name': name, 'id': studentCode.trim(), 'email': email,
        'level': levelId.replaceAll('level_', ''), 'division': division,
        'password': hashPassword(finalPass), 'createdAt': FieldValue.serverTimestamp(),
        'instituteId': selectedInstituteId
      };

      await studentsColl.doc(uid).set(studentData);
      await getCommerceStudentsColl(levelId).doc(uid).set(studentData);

      if (notify) notifyListeners();
    } catch (e) {
      debugPrint("Add student error: $e");
      rethrow;
    }
  }

  Future<void> addDoctor(String id, String name, String emailInput, List<String> teachingLevels, List<String> subjects, [String? password]) async {
    String email = _formatEmail(id);
    String uid = await _secureCreateUser(email, password ?? "123456");
    await commerceDoctorsColl.doc(uid).set({'uid': uid, 'id': id, 'name': name, 'email': email, 'teachingLevels': teachingLevels, 'subjects': subjects, 'isActive': true, 'role': 'doctor', 'password': hashPassword(password ?? "123456"), 'instituteId': selectedInstituteId});
    notifyListeners();
  }

  Future<void> addTA(String id, String name, String emailInput, List<String> teachingLevels, List<String> subjects, [String? password]) async {
    String email = _formatEmail(id);
    String uid = await _secureCreateUser(email, password ?? "123456");
    await commerceTasColl.doc(uid).set({'uid': uid, 'id': id, 'name': name, 'email': email, 'teachingLevels': teachingLevels, 'subjects': subjects, 'isActive': true, 'role': 'ta', 'password': hashPassword(password ?? "123456"), 'instituteId': selectedInstituteId});
    notifyListeners();
  }

  Future<void> addManager(String name, String emailInput, String password, {List<String> managedLevels = const []}) async {
    String email = _formatEmail(emailInput);
    String uid = await _secureCreateUser(email, password);
    await commerceManagersColl.doc(uid).set({'uid': uid, 'name': name, 'email': email, 'managedLevels': managedLevels, 'isActive': true, 'role': 'manager', 'password': hashPassword(password), 'instituteId': selectedInstituteId});
    notifyListeners();
  }

  Future<void> addCourseToLevel(String levelId, String name, String division, String semesterId, String doctorId, {int lecturesCount = 12, String? taId}) async {
    String cid = _firestore.collection('tmp').doc().id;
    await getCommerceCoursesColl(levelId).doc(cid).set({
      'id': cid,
      'name': name,
      'division': division,
      'semester_id': semesterId,
      'doctor_id': doctorId,
      'ta_id': taId,
      'level_id': levelId,
      'lecturesCount': lecturesCount,
      'createdAt': FieldValue.serverTimestamp(),
      'instituteId': selectedInstituteId
    });
    notifyListeners();
  }

  Future<void> addLectureToCourse(String levelId, String courseId, String title, int number) async { String lecId = _firestore.collection('tmp').doc().id; await getCommerceLecturesColl(levelId, courseId).doc(lecId).set({'id': lecId, 'title': title, 'number': number, 'createdAt': FieldValue.serverTimestamp()}); notifyListeners(); }

  Future<void> deleteStudent(String uid, String level) async {
    try {
      final studentDoc = await studentsColl.doc(uid).get();
      final data = studentDoc.data() as Map<String, dynamic>?;
      final String? studentId = data?['id']?.toString();

      await studentsColl.doc(uid).delete();
      await getCommerceStudentsColl('level_$level').doc(uid).delete();

      if (studentId != null) {
        final attDocs = await attendanceColl.where('studentId', isEqualTo: studentId).get();
        for (var d in attDocs.docs) { await d.reference.delete(); }
        final subDocs = await submissionsColl.where('studentId', isEqualTo: studentId).get();
        for (var d in subDocs.docs) { await d.reference.delete(); }
        final resDocs = await examResultsColl.where('studentId', isEqualTo: studentId).get();
        for (var d in resDocs.docs) { await d.reference.delete(); }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Comprehensive delete error: $e");
    }
  }

  Future<void> resetStudentDevice(String uid) async {
    await studentsColl.doc(uid).update({'deviceId': FieldValue.delete()});
    notifyListeners();
  }

  Future<void> deleteAllStudents() async {
    try {
      var groupSnap = await _firestore.collectionGroup('students').get();
      var batch = _firestore.batch();
      int count = 0;
      for (var doc in groupSnap.docs) {
        batch.delete(doc.reference);
        count++;
        if (count % 400 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }
      await batch.commit();

      var colleges = await _firestore.collection('colleges').get();
      for (var colDoc in colleges.docs) {
        var rootSnap = await colDoc.reference.collection('students').get();
        var b2 = _firestore.batch();
        for (var rd in rootSnap.docs) {
          b2.delete(rd.reference);
        }
        await b2.commit();

        var levels = await colDoc.reference.collection('levels').get();
        for (var lvl in levels.docs) {
          var lvlSnap = await lvl.reference.collection('students').get();
          var b3 = _firestore.batch();
          for (var ld in lvlSnap.docs) {
            b3.delete(ld.reference);
          }
          await b3.commit();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Delete all students error: $e");
      rethrow;
    }
  }

  Future<void> deleteDoctor(String uid) async { await commerceDoctorsColl.doc(uid).delete(); notifyListeners(); }
  Future<void> deleteTA(String uid) async { await commerceTasColl.doc(uid).delete(); notifyListeners(); }
  Future<void> deleteManager(String uid) async { await commerceManagersColl.doc(uid).delete(); notifyListeners(); }

  Future<void> clearAllNotifications(String type) async {
    var snap = await notificationsColl.where('targetType', isEqualTo: type).get();
    for (var d in snap.docs) { await d.reference.delete(); }
    notifyListeners();
  }

  Future<void> addSemester(String id, String name, int order) async { await commerceSemestersColl.doc(id).set({'id': id, 'name': name, 'order': order, 'isActive': false, 'createdAt': FieldValue.serverTimestamp()}); notifyListeners(); }
  Future<void> toggleSemesterStatus(String id, bool isActive) async { if (isActive) { var query = await commerceSemestersColl.get(); for (var doc in query.docs) { if (doc.id != id) { await doc.reference.update({'isActive': false}); } } } await commerceSemestersColl.doc(id).update({'isActive': isActive}); notifyListeners(); }
  Future<void> deleteSemester(String id) async { await commerceSemestersColl.doc(id).delete(); notifyListeners(); }

  Future<void> recordAttendanceCloud({
    required String subject,
    required String level,
    required int lectureNumber,
    required String division,
    String? studentLocation,
    String sessionType = 'lecture',
  }) async {
    if (currentStudent == null) throw "يجب تسجيل الدخول كطالب أولاً";
    String sId = currentStudent!['id'].toString();

    // 1. تحديد تلقائي لنوع الجلسة (محاضرة أم سكشن) بناءً على إسناد المادة في الكلية
    String resolvedSessionType = sessionType;
    try {
      String cleanLvl = level.replaceAll('level_', '');
      var coursesSnap = await getCommerceCoursesColl("level_$cleanLvl")
          .where('name', isEqualTo: subject.trim())
          .get();
      if (coursesSnap.docs.isNotEmpty) {
        var courseData = coursesSnap.docs.first.data() as Map<String, dynamic>;
        if (courseData['ta_id'] != null && courseData['ta_id'].toString().isNotEmpty) {
          resolvedSessionType = 'section';
        } else {
          resolvedSessionType = 'lecture';
        }
      }
    } catch (e) {
      debugPrint("Error resolving sessionType from course: $e");
    }

    var existing = await attendanceColl
        .where('studentId', isEqualTo: sId)
        .where('subject', isEqualTo: subject.trim())
        .where('lectureNumber', isEqualTo: lectureNumber.toString())
        .get();

    var docs = existing.docs.where((d) {
      var data = d.data() as Map<String, dynamic>;
      String st = data['sessionType']?.toString() ?? 'lecture';
      return st == resolvedSessionType;
    }).toList();

    if (docs.isNotEmpty) {
      throw resolvedSessionType == 'section'
          ? (isArabic ? "لقد قمت بتسجيل الحضور مسبقاً لهذا السكشن" : "You have already recorded attendance for this section")
          : translate('already_recorded');
    }

    await attendanceColl.add({
      'studentId': sId,
      'studentName': currentStudent!['name'],
      'subject': subject.trim(),
      'level': level.trim(),
      'division': division,
      'lectureNumber': lectureNumber.toString(),
      'sessionType': resolvedSessionType,
      'time': FieldValue.serverTimestamp(),
      'gps': studentLocation,
      'instituteId': selectedInstituteId
    });
  }

  Future<void> manualRecordAttendance({
    required String studentId, 
    required String studentName, 
    required String subject, 
    required String level, 
    required String lectureNumber,
    String sessionType = 'lecture',
  }) async {
    // تنظيف البيانات قبل الحفظ لضمان النجاح
    String cleanSub = subject.trim();
    String cleanLvl = level.replaceAll('level_', '').trim();
    
    await attendanceColl.add({
      'studentId': studentId.trim(), 
      'studentName': studentName.trim(), 
      'subject': cleanSub, 
      'lectureNumber': lectureNumber.trim(), 
      'sessionType': sessionType,
      'level': cleanLvl, 
      'time': FieldValue.serverTimestamp(), 
      'instituteId': selectedInstituteId, 
      'manual': true
    });
  }

  Future<void> deleteAttendanceRecord(String sub, String sId, String lNum, {String sessionType = 'lecture'}) async {
    var q = await attendanceColl.where('subject', isEqualTo: sub.trim()).where('studentId', isEqualTo: sId.trim()).where('lectureNumber', isEqualTo: lNum.trim()).get();
    for (var d in q.docs) {
      var data = d.data() as Map<String, dynamic>;
      String st = data['sessionType']?.toString() ?? 'lecture';
      if (st == sessionType) {
        await d.reference.delete();
      }
    }
  }

  Future<void> uploadResearchToRemote({required String subject, required PlatformFile file, String title = ''}) async {
    if (currentStudent == null) throw "Action not allowed";
    String studentId = currentStudent!['id'].toString();
    String studentName = currentStudent!['name'] ?? '';

    String? doctorId;
    try {
      String studentLvl = currentStudent?['level']?.toString() ?? '1';
      var coursesSnap = await getCommerceCoursesColl("level_$studentLvl")
          .where('name', isEqualTo: subject.trim())
          .get();
      if (coursesSnap.docs.isNotEmpty) {
        doctorId = (coursesSnap.docs.first.data() as Map<String, dynamic>)['doctor_id']?.toString();
      }
    } catch (_) {}

    try {
      String fileName = 'research_${studentId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        await supabase.storage.from('research-pdfs').uploadBinary(fileName, file.bytes!);
      } else {
        await supabase.storage.from('research-pdfs').upload(fileName, io.File(file.path!));
      }

      final String publicUrl = supabase.storage.from('research-pdfs').getPublicUrl(fileName);

      await submissionsColl.add({
        'studentId': studentId, 
        'studentName': studentName, 
        'subject': subject, 
        'doctorId': doctorId,
        'fileName': file.name, 
        'fileUrl': publicUrl, 
        'title': title, 
        'date': FieldValue.serverTimestamp(), 
        'status': 'Submitted', 
        'isSeen': false, 
        'instituteId': selectedInstituteId,
        'level': currentStudent?['level']?.toString() ?? '1',
      });

      // إضافة إشعار للدكتور
      await notificationsColl.add({
        'title': isArabic ? 'بحث جديد مرفوع' : 'New Research Uploaded',
        'body': isArabic ? 'قام الطالب $studentName برفع بحث في مادة $subject' : 'Student $studentName uploaded a research in $subject',
        'targetType': 'doctor',
        'targetDoctorId': doctorId,
        'subject': subject,
        'timestamp': FieldValue.serverTimestamp(),
        'instituteId': selectedInstituteId,
        'isRead': false,
      });

      debugPrint("✅ Research uploaded & Doctor notified");
    } catch (e) {
      debugPrint("❌ Error uploading research: $e");
      rethrow;
    }
  }

  Future<void> updateResearchStatus(String id, String stat, {bool markAsSeen = false, String? grade, String? comment}) async {
    Map<String, dynamic> data = {'status': stat};
    if (markAsSeen) data['isSeen'] = true;
    if (grade != null) data['grade'] = grade;
    if (comment != null) data['comment'] = comment;
    
    if (grade != null || comment != null) {
      data['evaluatedAt'] = FieldValue.serverTimestamp();
      data['evaluatedBy'] = currentDoctor?['name'] ?? 'Doctor';

      // جلب بيانات البحث لإرسال إشعار للطالب
      var doc = await submissionsColl.doc(id).get();
      var subData = doc.data() as Map<String, dynamic>?;

      if (subData != null) {
        await notificationsColl.add({
          'title': isArabic ? 'تم تقييم بحثك' : 'Research Evaluated',
          'body': isArabic 
              ? 'قام الدكتور بتقييم بحثك في مادة ${subData['subject']}. الدرجة: $grade' 
              : 'Doctor evaluated your research in ${subData['subject']}. Grade: $grade',
          'targetType': 'student',
          'targetId': subData['studentId'],
          'timestamp': FieldValue.serverTimestamp(),
          'instituteId': selectedInstituteId,
          'isRead': false,
        });
      }
    }
    await submissionsColl.doc(id).update(data);
    notifyListeners();
  }
  Future<bool> deleteResearch(String id) async { await submissionsColl.doc(id).delete(); notifyListeners(); return true; }

  Future<void> saveExamResult(String sId, String sub, double cw, double fin) async { double tot = cw + fin; await examResultsColl.doc('${sId}_$sub').set({'studentId': sId, 'subject': sub, 'coursework': cw, 'final': fin, 'total': tot, 'grade': calculateGrade(tot), 'doctorName': currentDoctor?['name'] ?? 'System', 'date': FieldValue.serverTimestamp(), 'instituteId': selectedInstituteId}); }
  Future<void> bulkUploadExamResults(List<Map<String, dynamic>> list) async { for (var item in list) { await saveExamResult(item['studentId'].toString(), item['subject'].toString(), (item['coursework'] ?? 0).toDouble(), (item['final'] ?? 0).toDouble()); } }

  String calculateGrade(double tot) { if (tot >= 90) return 'A+'; if (tot >= 85) return 'A'; if (tot >= 80) return 'B+'; if (tot >= 75) return 'B'; if (tot >= 70) return 'C+'; if (tot >= 65) return 'C'; if (tot >= 60) return 'D+'; if (tot >= 50) return 'D'; return 'F'; }
  String getGradeLabel(String g) { if (!isArabic) return g; switch (g.toUpperCase()) { case 'A+': return 'امتياز مرتفع'; case 'A': return 'امتياز'; case 'B+': return 'جيد جداً مرتفع'; case 'B': return 'جيد جداً'; case 'C+': return 'جيد مرتفع'; case 'C': return 'جيد'; case 'D+': return 'مقبول مرتفع'; case 'D': return 'مقبول'; case 'F': return 'راسب'; default: return g; } }

  Stream<QuerySnapshot> getStudentExamResultsStream(String sId) => examResultsColl.where('studentId', isEqualTo: sId).snapshots();
  Stream<QuerySnapshot> getStudentGradesStream(String sId) => gradesColl.where('studentId', isEqualTo: sId).snapshots();

  Future<void> initNotifications() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    // ضبط المنطقة الزمنية الافتراضية للقاهرة كمثال لو فشل التعرف التلقائي
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    } catch (e) {
      debugPrint("Timezone error: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Check for exact alarm permission on Android 13+
    if (io.Platform.isAndroid) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  Future<void> scheduleLectureNotification({
    required String docId,
    required String subject,
    required String dayName,
    required String timeStr,
    required String type,
  }) async {
    try {
      // 1. حساب الوقت القادم للمحاضرة
      final now = DateTime.now();
      
      // تحويل الوقت من String (مثلاً "10:00 AM") إلى DateTime
      // ملاحظة: فورمات الوقت في المشروع هو d['time']
      final timeParts = _parseTime(timeStr);
      if (timeParts == null) return;

      int dayOfWeek = _getDayOfWeek(dayName);
      if (dayOfWeek == -1) return;

      DateTime scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        timeParts.hour,
        timeParts.minute,
      );

      // ضبط اليوم
      while (scheduledDate.weekday != dayOfWeek) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // لو الوقت فات النهاردة، نخليها الأسبوع الجاي
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      // 2. جدولة الإشعار
      int notificationId = docId.hashCode.abs();
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        isArabic ? "حان موعد $type" : "Time for $type",
        isArabic ? "تبدأ الآن محاضرة: $subject" : "$type starts now: $subject",
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'lecture_reminders',
            'Lectures Reminders',
            channelDescription: 'Notifications for your university schedule',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // تكرار أسبوعي
      );
      debugPrint("📅 Scheduled $type: $subject at $scheduledDate");
    } catch (e) {
      debugPrint("❌ Error scheduling notification: $e");
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      // "10:00 AM" or "22:00"
      final parts = timeStr.split(' ');
      final time = parts[0].split(':');
      int hour = int.parse(time[0]);
      int minute = int.parse(time[1]);

      if (parts.length > 1) {
        final ampm = parts[1].toUpperCase();
        if (ampm == "PM" && hour < 12) hour += 12;
        if (ampm == "AM" && hour == 12) hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  int _getDayOfWeek(String dayName) {
    final Map<String, int> days = {
      'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
      'Friday': 5, 'Saturday': 6, 'Sunday': 7,
      'الاثنين': 1, 'الثلاثاء': 2, 'الأربعاء': 3, 'الخميس': 4,
      'الجمعة': 5, 'السبت': 6, 'الأحد': 7,
    };
    return days[dayName] ?? -1;
  }

  Future<void> saveScheduleItem(Map<String, dynamic> item) async {
    if (currentStudent == null) return;
    var docRef = await studentsColl.doc(currentStudent!['uid']).collection('my_schedule').add({
      ...item,
      'instituteId': selectedInstituteId
    });
    
    // جدولة الإشعار فور الإضافة
    await scheduleLectureNotification(
      docId: docRef.id,
      subject: item['subject'],
      dayName: item['dayName'],
      timeStr: item['time'],
      type: item['type'],
    );
  }

  Future<void> deleteScheduleItem(String id) async {
    if (currentStudent == null) return;
    await studentsColl.doc(currentStudent!['uid']).collection('my_schedule').doc(id).delete();
    // إلغاء الإشعار
    await flutterLocalNotificationsPlugin.cancel(id.hashCode.abs());
  }

  Stream<QuerySnapshot> getStudentScheduleStream() {
    if (currentStudent == null) return const Stream.empty();
    return studentsColl.doc(currentStudent!['uid']).collection('my_schedule').snapshots();
  }

  Future<void> changeUserPassword(String id, String newPass, bool isStud) async {
    if (isStud) {
      var q = await studentsColl.where('id', isEqualTo: id).get();
      for (var d in q.docs) { await d.reference.update({'password': hashPassword(newPass)}); }
    } else {
      await commerceDoctorsColl.doc(id).update({'password': hashPassword(newPass)}).catchError((_){});
      await commerceManagersColl.doc(id).update({'password': hashPassword(newPass)}).catchError((_){});
    }

    if (_auth.currentUser != null) {
      await _auth.currentUser?.updatePassword(newPass);
    }
  }

  Future<bool> updatePassword(String newPass) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPass);
        String uid = user.uid;
        if (currentStudent != null) {
          await studentsColl.doc(uid).update({'password': hashPassword(newPass)});
        } else if (currentDoctor != null) {
          await commerceDoctorsColl.doc(uid).update({'password': hashPassword(newPass)});
        } else if (currentAdmin != null) {
          await commerceManagersColl.doc(uid).update({'password': hashPassword(newPass)}).catchError((_){});
        }
      }
      return true;
    } catch (e) {
      debugPrint("Update password error: $e");
      return false;
    }
  }

  Future<void> syncScheduleNotifications() async {
    if (kIsWeb || currentStudent == null) return;
    try {
      // إلغاء كل الإشعارات القديمة لتجنب التكرار
      await flutterLocalNotificationsPlugin.cancelAll();
      
      var snap = await studentsColl.doc(currentStudent!['uid']).collection('my_schedule').get();
      for (var doc in snap.docs) {
        final item = doc.data();
        await scheduleLectureNotification(
          docId: doc.id,
          subject: item['subject'] ?? '',
          dayName: item['dayName'] ?? '',
          timeStr: item['time'] ?? '',
          type: item['type'] ?? '',
        );
      }
      debugPrint("🔄 Synced ${snap.docs.length} schedule notifications");
    } catch (e) {
      debugPrint("❌ Sync notifications error: $e");
    }
  }

  Future<void> loadUserData(String uid, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      selectedInstituteId = prefs.getString('selected_institute_id');
      userRole = role;
      await _findAndLoadUser(uid);
      
      // مزامنة الإشعارات بعد تحميل البيانات
      if (!kIsWeb) {
        syncScheduleNotifications();
      }

      notifyListeners();
    } catch (e) { debugPrint("Load error: $e"); }
  }

  Future<String?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('selected_institute_id');
    if (storedId != null) {
      await setInstitute(storedId);
    }

    if (selectedInstituteId == null) return null;

    String? id = prefs.getString('session_id');
    String? type = prefs.getString('session_type');
    if (id != null && type != null) { await loadUserData(id, type); return type; }
    return null;
  }

  Future<void> clearSession() async { await _auth.signOut(); final prefs = await SharedPreferences.getInstance(); await prefs.remove('session_id'); await prefs.remove('session_type'); currentStudent = null; currentDoctor = null; currentAdmin = null; userRole = null; notifyListeners(); }
  Future<void> saveSession(String id, String type) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString('session_id', id); await prefs.setString('session_type', type); }
  Future<void> loadSettings() async { final prefs = await SharedPreferences.getInstance(); isArabic = prefs.getBool('persist_v3_arabic') ?? true; isDarkMode = prefs.getBool('persist_v3_dark') ?? false; notifyListeners(); }
  Future<void> toggleLanguage(bool v) async { isArabic = v; final prefs = await SharedPreferences.getInstance(); await prefs.setBool('persist_v3_arabic', v); notifyListeners(); }

  Future<void> toggleDarkMode(bool v) async {
    isDarkMode = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('persist_v3_dark', v);
  }

  String normalize(String text) { if (text.isEmpty) return ""; String n = text.toLowerCase().trim(); return n.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ال', '').replaceAll(' ', '').trim(); }

  String normalizeDivision(String div) {
    if (div.isEmpty) return "all";
    String n = div.toLowerCase().trim();
    if (n == 'is' || n.contains('نظم')) return 'نظم معلومات الاعمال';
    if (n == 'acc' || n.contains('محاسبه') || n.contains('محاسبة')) return 'محاسبه';
    return n;
  }

  String normalizeLevel(String lvl) {
    String n = normalize(lvl.toLowerCase().replaceAll('level_', ''));
    if (n.contains('اول') || n == '1') return '1';
    if (n.contains('ثان') || n == '2') return '2';
    if (n.contains('ثالث') || n == '3') return '3';
    if (n.contains('رابع') || n == '4') return '4';
    return n;
  }

  List<String> get allSubjects => studentSubjects;

  Future<void> fetchSubjectsForLevel(String level, String division) async {
    try {
      studentSubjects = [];
      if (selectedInstituteId == null) return;

      String normLevel = normalizeLevel(level);
      debugPrint("📚 START fetchSubjectsForLevel - Lvl: $normLevel, Div: $division");

      // 1. محاولة تحديد الفصل الدراسي النشط
      String? activeSemesterId;
      try {
        var semSnap = await commerceSemestersColl.where('isActive', isEqualTo: true).get();
        if (semSnap.docs.isNotEmpty) {
          activeSemesterId = semSnap.docs.first.id;
          debugPrint("⏳ Active Semester Detected: $activeSemesterId");
        }
      } catch (e) {
        debugPrint("⚠️ No active semester doc found");
      }

      Set<String> subjectsSet = {};
      String cleanLevel = normLevel.contains('level_') ? normLevel : 'level_$normLevel';
      var coursesRef = instituteRef.collection('levels').doc(cleanLevel).collection('courses');

      debugPrint("🔍 Querying Path: ${coursesRef.path}");

      var query = await coursesRef.get();
      debugPrint("📂 Found ${query.docs.length} courses total in this level");

      String normStudDiv = normalizeDivision(division);

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String itemName = data['name']?.toString() ?? 'Unknown';
        String itemDiv = normalizeDivision(data['division']?.toString() ?? 'all');
        String itemSemester = data['semester_id']?.toString() ?? '';

        // تصفية الفصل الدراسي: لو فيه فصل نشط والمادة تابعة لفصل تاني، نتخطاها
        // ملحوظة: لو مفيش فصل نشط (activeSemesterId == null) هنعرض كل المواد
        if (activeSemesterId != null && itemSemester.isNotEmpty && itemSemester != activeSemesterId) {
          debugPrint("⏩ Skipped $itemName (Semester mismatch: $itemSemester != $activeSemesterId)");
          continue;
        }

        // تصفية الشعبة
        if (itemDiv == 'all' || normStudDiv == 'all' || itemDiv == normStudDiv) {
          subjectsSet.add(itemName);
          debugPrint("✅ Added: $itemName");
        } else {
          debugPrint("⏩ Skipped $itemName (Division mismatch: $itemDiv != $normStudDiv)");
        }
      }

      studentSubjects = subjectsSet.toList()..sort();
      debugPrint("🎯 Final List for UI: $studentSubjects");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ CRITICAL Error in fetchSubjectsForLevel: $e");
    }
  }

  String _formatEmail(String input) {
    String trimmed = input.trim().toLowerCase();
    if (trimmed.contains('@')) return trimmed;

    // لضمان دخول المديرين بالكود فقط، سنقوم ببناء إيميل افتراضي يتبعه النظام
    // التنسيق المطلوب بناءً على طلبك هو: [كود].college@smart.com
    return "$trimmed.college$_domain";
  }

  Future<String> _secureCreateUser(String email, String password) async {
    String name = 'Creator_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp tempApp = await Firebase.initializeApp(name: name, options: Firebase.app().options);
    try {
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim()
      );
      String uid = userCred.user!.uid;
      await tempApp.delete();
      return uid;
    } catch (e) {
      await tempApp.delete();
      rethrow;
    }
  }

  Future<void> updateDoctorProfile({
    String? phone, 
    String? email, 
    String? personalEmail, 
    String? photoUrl, 
    Map<String, dynamic>? preferences,
    bool? hidePhone,
    bool? hideEmail,
    bool? hidePhoto,
  }) async {
    if (currentDoctor == null) return;
    String uid = (currentDoctor!['uid'] ?? currentDoctor!['id'] ?? '').toString();
    if (uid.isEmpty) return;

    Map<String, dynamic> updateData = {};
    if (phone != null) updateData['phone'] = phone;
    if (email != null) updateData['email'] = email;
    if (personalEmail != null) updateData['personalEmail'] = personalEmail;
    if (photoUrl != null) updateData['photoUrl'] = photoUrl;
    if (preferences != null) updateData['preferences'] = preferences;

    Map<String, dynamic> currentPrivacy = Map<String, dynamic>.from(currentDoctor!['privacy'] ?? {});
    if (hidePhone != null) currentPrivacy['hidePhone'] = hidePhone;
    if (hideEmail != null) currentPrivacy['hideEmail'] = hideEmail;
    if (hidePhoto != null) currentPrivacy['hidePhoto'] = hidePhoto;
    updateData['privacy'] = currentPrivacy;

    try {
      await commerceDoctorsColl.doc(uid).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Update doctor failed: $e");
    }

    currentDoctor!.addAll(updateData);
    if (photoUrl == "") currentDoctor!['photoUrl'] = "";
    notifyListeners();
  }

  Future<void> updateStudentProfile({String? phone, String? personalEmail, String? photoUrl}) async {
    if (currentStudent == null) return;
    String uid = (currentStudent!['uid'] ?? currentStudent!['id'] ?? '').toString();
    if (uid.isEmpty) return;

    Map<String, dynamic> updateData = {};
    if (phone != null) updateData['phone'] = phone;
    if (personalEmail != null) updateData['personalEmail'] = personalEmail;
    if (photoUrl != null) updateData['photoUrl'] = photoUrl;

    try {
      await studentsColl.doc(uid).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Update student doc failed: $e");
    }

    currentStudent!.addAll(updateData);
    if (photoUrl == "") currentStudent!['photoUrl'] = "";

    try {
      String sId = (currentStudent!['id'] ?? '').toString().trim();
      if (sId.isNotEmpty) {
        var snap = await studentsColl.where('id', isEqualTo: sId).get();
        for (var doc in snap.docs) {
          await doc.reference.set(updateData, SetOptions(merge: true));
        }
        if (int.tryParse(sId) != null) {
          var intSnap = await studentsColl.where('id', isEqualTo: int.parse(sId)).get();
          for (var doc in intSnap.docs) {
            await doc.reference.set(updateData, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      debugPrint("Error syncing student profile update: $e");
    }

    notifyListeners();
  }

  Uint8List? getBytesFromPhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      if (photoUrl.startsWith('data:image')) {
        final base64String = photoUrl.split(',').last;
        return base64Decode(base64String);
      }
    } catch (e) {
      debugPrint("Error decoding base64 photo: $e");
    }
    return null;
  }

  ImageProvider? getAvatarImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    final bytes = getBytesFromPhotoUrl(photoUrl);
    if (bytes != null) {
      return MemoryImage(bytes);
    } else if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }
    return null;
  }

  Future<String?> uploadAvatarFile(PlatformFile file) async {
    try {
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        io.File f = io.File(file.path!);
        bytes = await f.readAsBytes();
      }
      if (bytes == null) return null;

      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 300, targetHeight: 300);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..isAntiAlias = true;

      double size = 300.0;
      double imgW = image.width.toDouble();
      double imgH = image.height.toDouble();

      Rect srcRect;
      if (imgW > imgH) {
        double diff = (imgW - imgH) / 2;
        srcRect = Rect.fromLTWH(diff, 0, imgH, imgH);
      } else if (imgH > imgW) {
        double diff = (imgH - imgW) / 2;
        srcRect = Rect.fromLTWH(0, diff, imgW, imgW);
      } else {
        srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      }

      Rect dstRect = Rect.fromLTWH(0, 0, size, size);
      canvas.drawImageRect(image, srcRect, dstRect, paint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        String base64Str = base64Encode(pngBytes);
        return 'data:image/png;base64,$base64Str';
      }

      String ext = file.extension?.toLowerCase() ?? 'jpeg';
      if (ext == 'jpg') ext = 'jpeg';
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint("Convert avatar error: $e");
      if (file.bytes != null) {
        return 'data:image/jpeg;base64,${base64Encode(file.bytes!)}';
      }
      return null;
    }
  }

  Future<void> launchWhatsApp(String phoneNumber) async {
    String cleanNum = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNum.startsWith('0')) {
      cleanNum = '+2$cleanNum';
    }
    final Uri uri = Uri.parse("https://wa.me/$cleanNum");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("WhatsApp launch error: $e");
    }
  }
}
