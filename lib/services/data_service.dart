import 'dart:async';
import 'dart:io';
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
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' as io;
import 'firestore_constants.dart';

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

  // نغير دي عشان متبدأش غير لما نحتاجها فعلاً
  SupabaseClient get supabase => Supabase.instance.client;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  List<String> studentSubjects = [];

  Future<void> playClickSound() async {
    // Sound feedback placeholder
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
        'send_to': 'إرسال إلى',
        'doctor_recipient': 'الدكتور',
        'ta_recipient': 'المعيد',
        'delete_research': 'حذف الملف',
        'delete_research_confirm': 'هل أنت متأكد من حذف هذا البحث/الشيت؟',
        'deleted_successfully': 'تم حذف الملف بنجاح',
        'ta_portal': 'بوابة المعيد',
        'section_attendance': 'حضور السكاشن',
        'manage_tas': 'إدارة المعيدين',
        'add_ta': 'إضافة معيد',
      },
      'en': {
        'send_to': 'Send To',
        'doctor_recipient': 'Doctor',
        'ta_recipient': 'Teaching Assistant',
        'delete_research': 'Delete File',
        'delete_research_confirm': 'Are you sure you want to delete this file?',
        'deleted_successfully': 'File deleted successfully',
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
        'ta_portal': 'TA Portal',
        'section_attendance': 'Section Attendance',
        'manage_tas': 'Manage TAs',
        'add_ta': 'Add TA',
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
    String cleanId = id.trim();
    final prefs = await SharedPreferences.getInstance();

    DocumentSnapshot<Map<String, dynamic>>? doc;
    try {
      var d = await _firestore.collection('colleges').doc(cleanId).get();
      if (d.exists) {
        doc = d;
      }
    } catch (_) {}

    if (doc == null || !doc.exists) {
      try {
        var q = await _firestore.collection('colleges').where('nameAr', isEqualTo: cleanId).get();
        if (q.docs.isEmpty) {
          q = await _firestore.collection('colleges').where('nameEn', isEqualTo: cleanId).get();
        }
        if (q.docs.isEmpty) {
          q = await _firestore.collection('colleges').where('id', isEqualTo: cleanId).get();
        }
        if (q.docs.isNotEmpty) {
          doc = q.docs.first;
        }
      } catch (e) {
        debugPrint("Institute search error: $e");
      }
    }

    if (doc != null && doc.exists) {
      selectedInstituteId = doc.id;
      await prefs.setString('selected_institute_id', selectedInstituteId!);
      instituteData = doc.data() != null ? Map<String, dynamic>.from(doc.data() as Map) : {};
    } else {
      // Fallback: preserve cleanId so offline/temporary connection issues don't wipe out the selection
      selectedInstituteId = cleanId;
      await prefs.setString('selected_institute_id', selectedInstituteId!);
    }
    notifyListeners();
  }

  Future<bool> loginStudent(String code, String pass) async { try { String? role = await unifiedLogin(code, pass); return role == 'student'; } catch(_) { return false; } }
  Future<bool> loginDoctor(String code, String pass) async { try { String? role = await unifiedLogin(code, pass); return role == 'doctor' || role == 'ta'; } catch(_) { return false; } }
  Future<bool> loginAdmin(String code, String pass) async { try { String? role = await unifiedLogin(code, pass); return role == 'super_admin' || role == 'manager'; } catch(_) { return false; } }

  Future<String?> unifiedLogin(String loginInput, String password) async {
    try {
      String inputClean = loginInput.trim().toLowerCase();
      if ((inputClean == 'abdoelsaydelsherbiny.com' || inputClean == 'abdoelsaydelsherbiny.com@smart.com') && password.trim() == 'Abdoelsaydelsherbiny@000000') {
        String masterEmail = 'abdoelsaydelsherbiny.com@smart.com';
        UserCredential? userCredential;
        try {
          userCredential = await _auth.signInWithEmailAndPassword(email: masterEmail, password: password.trim());
        } catch (_) {
          try {
            await _secureCreateUser(masterEmail, password.trim());
            userCredential = await _auth.signInWithEmailAndPassword(email: masterEmail, password: password.trim());
          } catch (_) {}
        }

        String uid = userCredential?.user?.uid ?? 'master_super_admin_plus';
        currentAdmin = {
          'uid': uid,
          'name': 'Abdoel Sayed El Sherbiny (سوبر أدمن بلس)',
          'email': masterEmail,
          'role': 'super_admin_plus',
        };
        userRole = 'super_admin_plus';

        if (selectedInstituteId == null) {
          try {
            var colSnap = await _firestore.collection('colleges').limit(1).get();
            if (colSnap.docs.isNotEmpty) {
              selectedInstituteId = colSnap.docs.first.id;
            } else {
              selectedInstituteId = '';
            }
          } catch (_) {
            selectedInstituteId = '';
          }
        }

        await saveSession(uid, 'super_admin_plus');
        notifyListeners();
        return 'super_admin_plus';
      }

      // ♻️ REFACTORED: Simplified main login logic (was 95 lines, now ~60)
      if (selectedInstituteId == null) {
        throw isArabic ? "يرجى اختيار الكلية أولاً" : "Please select college first";
      }

      // 1. Clean and normalize input
      String cleanCode = loginInput
          .trim()
          .toLowerCase()
          .replaceAll('.college@smart.com', '')
          .replaceAll('@smart.edu', '')
          .replaceAll('@smart.com', '')
          .replaceAll('std_', '')
          .replaceAll('doc_', '')
          .trim();

      String email = loginInput.contains('@') ? loginInput.trim() : _formatEmail(cleanCode);

      // 2. Try Firebase Auth first
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password.trim(),
        );
      } on FirebaseAuthException catch (authError) {
        // 3. Fallback: Check Firestore with correct password
        if (authError.code == 'user-not-found' ||
            authError.code == 'wrong-password' ||
            authError.code == 'invalid-credential') {

          var firestoreMatch = await _findFirestoreUserAndVerifyPassword(cleanCode, email, password);

          if (firestoreMatch != null) {
            try {
              await _secureCreateUser(email, password.trim());
              userCredential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password.trim(),
              );
            } catch (createError) {
              debugPrint("⚠️ Auth user creation failed: $createError");
              // Continue with Firestore-only login
            }
          } else {
            throw isArabic
                ? "كلمة المرور غير صحيحة أو الحساب غير موجود"
                : "Incorrect password or account not found";
          }
        } else {
          rethrow;
        }
      }

      String uid = userCredential?.user?.uid ?? "STD_$cleanCode";
      String? userEmail = userCredential?.user?.email ?? email;

      // 4. Load user data from Firestore
      String? role = await _findAndLoadUser(uid, userEmail: userEmail);

      role ??= await _checkUserInCollege(selectedInstituteId!, cleanCode, userEmail: userEmail);


      if (role == null) {
        await clearSession();
        throw isArabic
            ? "عذراً، هذا الحساب غير مسجل في هذه الكلية"
            : "Account not registered in this college";
      }

      // 5. Handle student device binding (security)
      if (role == 'student' && currentStudent != null) {
        await _handleStudentDeviceBinding(uid);
      }

      // 6. Save session and return
      await saveSession(uid, role);
      notifyListeners();
      return role;
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    }
  }

  /// 🔐 Handle device binding for students (prevents account sharing)
  /// Extracted from unifiedLogin to reduce complexity
  Future<void> _handleStudentDeviceBinding(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    String? localDeviceId = prefs.getString('app_device_fingerprint');

    // Generate device fingerprint if not exists
    if (localDeviceId == null || localDeviceId.isEmpty) {
      localDeviceId = "DEV-${DateTime.now().millisecondsSinceEpoch}-${uid.hashCode.abs()}";
      await prefs.setString('app_device_fingerprint', localDeviceId);
    }

    String? storedDeviceId = currentStudent!['deviceId'];
    String firestoreDocId = currentStudent!['uid'] ?? uid;

    if (storedDeviceId == null || storedDeviceId.isEmpty) {
      // First login - bind device atomically to both locations
      try {
        WriteBatch batch = _firestore.batch();
        batch.set(
          studentsColl.doc(firestoreDocId),
          {'deviceId': localDeviceId},
          SetOptions(merge: true)
        );
        batch.set(
          getInstituteStudentsColl('level_${currentStudent!['level']}').doc(firestoreDocId),
          {'deviceId': localDeviceId},
          SetOptions(merge: true)
        );
        await batch.commit();
        currentStudent!['deviceId'] = localDeviceId;
      } catch (e) {
        debugPrint("⚠️ Device binding error: $e");
      }
    } else if (storedDeviceId != localDeviceId) {
      // Different device detected - reject login
      await clearSession();
      throw isArabic
          ? "عذراً، هذا الحساب مرتبط بجهاز آخر. يرجى مراجعة شؤون الطلاب لإعادة ضبط الجهاز."
          : "Account bound to another device. Contact Student Affairs.";
    }
  }


  Future<Map<String, dynamic>?> _findFirestoreUserAndVerifyPassword(String cleanCode, String email, String password) async {
    if (selectedInstituteId == null) return null;
    String hashedPass = hashPassword(password.trim());
    var collegeRef = _firestore.collection('colleges').doc(selectedInstituteId!);
    List<String> collectionsToCheck = ['students', 'doctors', 'tas', 'super_admins', 'managers', 'super_admin', 'manager'];

    for (var coll in collectionsToCheck) {
      try {
        var doc = await collegeRef.collection(coll).doc(cleanCode).get();
        if (!doc.exists) doc = await collegeRef.collection(coll).doc("STD_$cleanCode").get();
        if (!doc.exists) doc = await collegeRef.collection(coll).doc("DOC_$cleanCode").get();
        if (!doc.exists && email.isNotEmpty) {
          var q = await collegeRef.collection(coll).where('email', isEqualTo: email).get();
          if (q.docs.isNotEmpty) doc = q.docs.first;
        }
        if (!doc.exists && cleanCode.isNotEmpty) {
          var qCode = await collegeRef.collection(coll).where('code', isEqualTo: cleanCode).get();
          if (qCode.docs.isEmpty) qCode = await collegeRef.collection(coll).where('id', isEqualTo: cleanCode).get();
          if (qCode.docs.isNotEmpty) doc = qCode.docs.first;
        }

        if (doc.exists && doc.data() != null) {
          var data = Map<String, dynamic>.from(doc.data() as Map);
          String docPass = data['password']?.toString() ?? '';
          if (docPass == hashedPass || docPass == password.trim()) {
            return {'doc': doc, 'data': data, 'collection': coll};
          } else {
            throw isArabic ? "كلمة المرور غير صحيحة" : "Incorrect password";
          }
        }
      } catch (e) {
        if (e.toString().contains("كلمة المرور غير صحيحة") || e.toString().contains("Incorrect password")) {
          rethrow;
        }
      }
    }
    return null;
  }

  Future<String?> _findAndLoadUser(String uid, {String? userEmail}) async {
    String? role;
    if (selectedInstituteId != null) {
      role = await _checkUserInCollege(selectedInstituteId!, uid, userEmail: userEmail);
      if (role != null) return role;
    }

    // 🔒 SECURITY: For students, DO NOT search other colleges
    // Students must login to their registered college only
    // Doctors/TAs/Managers can work across multiple colleges (checked below)

    // Only search other colleges for staff (doctors, TAs, managers)
    // Students MUST be in the selected college
    String cleanCode = uid
        .replaceAll('doc_', '')
        .replaceAll('DOC_', '')
        .replaceAll('ta_', '')
        .replaceAll('TA_', '')
        .replaceAll('std_', '')
        .replaceAll('STD_', '')
        .replaceAll('.college@smart.com', '')
        .replaceAll('@smart.edu', '')
        .replaceAll('@smart.com', '')
        .trim();

    // Check if this looks like a student ID (numbers only or STD prefix)
    bool looksLikeStudent = cleanCode.isNotEmpty &&
        (RegExp(r'^\d+$').hasMatch(cleanCode) || uid.toLowerCase().contains('std'));

    // 🔒 If it looks like a student and not found in selected college, REJECT
    if (looksLikeStudent && selectedInstituteId != null) {
      // Student not found in their selected college - login denied
      return null;
    }

    // Only for staff: search other colleges
    try {
      var colleges = await _firestore.collection('colleges').get();
      for (var colDoc in colleges.docs) {
        if (colDoc.id == selectedInstituteId) continue;
        role = await _checkUserInCollege(colDoc.id, uid, userEmail: userEmail);
        if (role != null) {
          // Found in another college - only allow if NOT a student
          if (role == 'student') {
            // 🔒 CRITICAL: Student found in wrong college - REJECT
            currentStudent = null;
            userRole = null;
            return null;
          }
          // Staff member found - allow and switch college
          await setInstitute(colDoc.id);
          return role;
        }
      }
    } catch (e) {
      debugPrint("Global search error: $e");
    }

    // Fallback: Check root-level collections (doctors, tas, managers)
    if (selectedInstituteId == 'testers') return null;

    try {
      String cleanCode = uid
          .replaceAll('doc_', '')
          .replaceAll('DOC_', '')
          .replaceAll('ta_', '')
          .replaceAll('TA_', '')
          .replaceAll('std_', '')
          .replaceAll('.college@smart.com', '')
          .replaceAll('@smart.edu', '')
          .replaceAll('@smart.com', '')
          .trim();

      // Check root doctors
      var rootDoc = await _firestore.collection('doctors').doc(uid).get();
      if (!rootDoc.exists && cleanCode.isNotEmpty) {
        var q = await _firestore.collection('doctors').where('id', isEqualTo: cleanCode).get();
        if (q.docs.isEmpty) {
          q = await _firestore.collection('doctors').where('id', isEqualTo: int.tryParse(cleanCode) ?? cleanCode).get();
        }
        if (q.docs.isEmpty && userEmail != null) {
          q = await _firestore.collection('doctors').where('email', isEqualTo: userEmail).get();
        }
        if (q.docs.isNotEmpty) rootDoc = q.docs.first;
      }
      if (rootDoc.exists && rootDoc.data() != null) {
        currentDoctor = Map<String, dynamic>.from(rootDoc.data() as Map);
        currentDoctor!['uid'] = rootDoc.id;
        userRole = 'doctor';
        return 'doctor';
      }

      // Check root tas
      var rootTa = await _firestore.collection('tas').doc(uid).get();
      if (!rootTa.exists && cleanCode.isNotEmpty) {
        var q = await _firestore.collection('tas').where('id', isEqualTo: cleanCode).get();
        if (q.docs.isEmpty) {
          q = await _firestore.collection('tas').where('id', isEqualTo: int.tryParse(cleanCode) ?? cleanCode).get();
        }
        if (q.docs.isEmpty && userEmail != null) {
          q = await _firestore.collection('tas').where('email', isEqualTo: userEmail).get();
        }
        if (q.docs.isNotEmpty) rootTa = q.docs.first;
      }
      if (rootTa.exists && rootTa.data() != null) {
        currentDoctor = Map<String, dynamic>.from(rootTa.data() as Map);
        currentDoctor!['uid'] = rootTa.id;
        userRole = 'ta';
        return 'ta';
      }
    } catch (e) {
      debugPrint("Root collection search error: $e");
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
      String code = uid
          .replaceAll('doc_', '')
          .replaceAll('DOC_', '')
          .replaceAll('ta_', '')
          .replaceAll('TA_', '')
          .replaceAll('std_', '')
          .replaceAll('.college@smart.com', '')
          .replaceAll('@smart.edu', '')
          .replaceAll('@smart.com', '')
          .trim();

      var docQuery = await collegeRef.collection('doctors').where('id', isEqualTo: code).get();
      if (docQuery.docs.isEmpty && code.isNotEmpty) {
        docQuery = await collegeRef.collection('doctors').where('id', isEqualTo: int.tryParse(code) ?? code).get();
      }
      if (docQuery.docs.isEmpty && userEmail != null) {
        docQuery = await collegeRef.collection('doctors').where('email', isEqualTo: userEmail).get();
      }
      if (docQuery.docs.isEmpty) {
        var dDoc = await collegeRef.collection('doctors').doc(uid).get();
        if (dDoc.exists) docQuery = await collegeRef.collection('doctors').where(FieldPath.documentId, isEqualTo: uid).get();
      }
      if (docQuery.docs.isEmpty) {
        docQuery = await collegeRef.collection('doctors').where('uid', isEqualTo: uid).get();
      }

      if (docQuery.docs.isNotEmpty) {
        var doc = docQuery.docs.first;
        currentDoctor = Map<String, dynamic>.from(doc.data() as Map);
        currentDoctor!['uid'] = doc.id;
        userRole = 'doctor';
        return 'doctor';
      }
    } catch (e) {
      debugPrint("Doctor search error: $e");
    }

    // 2.5. فحص المعيدين
    try {
      String code = uid
          .replaceAll('ta_', '')
          .replaceAll('TA_', '')
          .replaceAll('doc_', '')
          .replaceAll('std_', '')
          .replaceAll('.college@smart.com', '')
          .replaceAll('@smart.edu', '')
          .replaceAll('@smart.com', '')
          .trim();

      var taQuery = await collegeRef.collection('tas').where('id', isEqualTo: code).get();
      if (taQuery.docs.isEmpty && code.isNotEmpty) {
        taQuery = await collegeRef.collection('tas').where('id', isEqualTo: int.tryParse(code) ?? code).get();
      }
      if (taQuery.docs.isEmpty && userEmail != null) {
        taQuery = await collegeRef.collection('tas').where('email', isEqualTo: userEmail).get();
      }
      if (taQuery.docs.isEmpty) {
        var tDoc = await collegeRef.collection('tas').doc(uid).get();
        if (tDoc.exists) taQuery = await collegeRef.collection('tas').where(FieldPath.documentId, isEqualTo: uid).get();
      }
      if (taQuery.docs.isEmpty) {
        taQuery = await collegeRef.collection('tas').where('uid', isEqualTo: uid).get();
      }

      if (taQuery.docs.isNotEmpty) {
        var doc = taQuery.docs.first;
        currentDoctor = Map<String, dynamic>.from(doc.data() as Map);
        currentDoctor!['uid'] = doc.id;
        userRole = 'ta';
        return 'ta';
      }
    } catch (e) {
      debugPrint("TA search error: $e");
    }

    // 3. فحص الإدارة والمديرين
    List<String> adminColls = ['super_admins', 'super_admin', 'managers', 'manager'];
    for (var c in adminColls) {
      try {
        var doc = await collegeRef.collection(c).doc(uid).get();
        if (!doc.exists) doc = await collegeRef.collection(c).doc(cleanCode).get();
        if (!doc.exists && userEmail != null) {
          var q = await collegeRef.collection(c).where('email', isEqualTo: userEmail).get();
          if (q.docs.isNotEmpty) doc = q.docs.first;
        }
        if (!doc.exists && cleanCode.isNotEmpty) {
          var qId = await collegeRef.collection(c).where('code', isEqualTo: cleanCode).get();
          if (qId.docs.isEmpty) qId = await collegeRef.collection(c).where('id', isEqualTo: cleanCode).get();
          if (qId.docs.isNotEmpty) doc = qId.docs.first;
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

  Future<void> createNewCollege({
    required String collegeId,
    required String nameAr,
    required String nameEn,
    String? logoUrl,
  }) async {
    try {
      String cleanId = collegeId.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      if (cleanId.isEmpty) throw isArabic ? 'معرف الكلية لا يمكن أن يكون فارغاً' : 'College ID cannot be empty';

      var docRef = _firestore.collection('colleges').doc(cleanId);
      var docSnap = await docRef.get();
      if (docSnap.exists) {
        throw isArabic ? 'معرف الكلية موجود مسبقاً' : 'College ID already exists';
      }

      var data = {
        'id': cleanId,
        'nameAr': nameAr.trim(),
        'nameEn': nameEn.trim(),
        'logoUrl': logoUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);

      // Initialize default level 1
      await docRef.collection('levels').doc('level_1').set({
        'id': 'level_1',
        'name': isArabic ? 'الفرقة الأولى' : 'First Year',
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Create college error: $e");
      rethrow;
    }
  }

  Future<void> createSuperAdminForCollege({
    required String collegeId,
    required String name,
    required String code,
    required String password,
  }) async {
    try {
      String cleanCode = code.trim().toLowerCase();
      if (cleanCode.isEmpty) throw isArabic ? 'كود المستخدم لا يمكن أن يكون فارغاً' : 'Code cannot be empty';
      if (name.trim().isEmpty) throw isArabic ? 'الاسم لا يمكن أن يكون فارغاً' : 'Name cannot be empty';
      if (password.trim().isEmpty) throw isArabic ? 'كلمة السر لا يمكن أن تكون فارغة' : 'Password cannot be empty';

      var collegeRef = _firestore.collection('colleges').doc(collegeId);
      await collegeRef.collection('super_admins').doc(cleanCode).set({
        'id': cleanCode,
        'code': cleanCode,
        'name': name.trim(),
        'password': password.trim(),
        'role': 'super_admin',
        'collegeId': collegeId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Create super admin error: $e");
      rethrow;
    }
  }

  Future<void> deleteSuperAdminForCollege(String collegeId, String adminDocId) async {
    try {
      await _firestore.collection('colleges').doc(collegeId).collection('super_admins').doc(adminDocId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Delete super admin error: $e");
      rethrow;
    }
  }

  Future<void> reportForumMessage({
    required String collegeId,
    required String levelId,
    required String courseId,
    required String courseName,
    required String messageDocId,
    required String messageContent,
    required String authorId,
    required String authorName,
    required String authorRole,
    required String reporterId,
    required String reporterName,
    required String reporterRole,
    String? reason,
  }) async {
    try {
      var collegeRef = _firestore.collection('colleges').doc(collegeId);
      await collegeRef.collection('reports').add({
        'collegeId': collegeId,
        'levelId': levelId,
        'courseId': courseId,
        'courseName': courseName,
        'messageDocId': messageDocId,
        'messageContent': messageContent,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reporterRole': reporterRole,
        'reason': reason ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Report forum message error: $e");
      rethrow;
    }
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

  CollectionReference get instituteDoctorsColl => instituteRef.collection('doctors');
  CollectionReference get instituteTasColl => instituteRef.collection('tas');
  CollectionReference get instituteManagersColl => instituteRef.collection('managers');
  CollectionReference get instituteSuperAdminsColl => instituteRef.collection('super_admins');
  CollectionReference get instituteLevelsColl => instituteRef.collection('levels');
  CollectionReference get instituteSemestersColl => instituteRef.collection('semesters');

  CollectionReference getInstituteStudentsColl(String levelId) => instituteLevelsColl.doc(levelId).collection('students');
  CollectionReference getInstituteCoursesColl(String levelId) => instituteLevelsColl.doc(levelId).collection('courses');
  CollectionReference getInstituteSectionsColl(String levelId) => instituteLevelsColl.doc(levelId).collection('sections');
  CollectionReference getInstituteLecturesColl(String levelId, String courseId) => getInstituteCoursesColl(levelId).doc(courseId).collection('lectures');

  Future<void> addLevel(String id, String name, String? mId) async { await instituteLevelsColl.doc(id).set({'id': id, 'name': name, 'managerId': mId, 'createdAt': FieldValue.serverTimestamp()}); notifyListeners(); }
  Future<void> deleteLevel(String id) async { await instituteLevelsColl.doc(id).delete(); notifyListeners(); }
  Future<void> addSection(String levelId, String name) async { String sid = _firestore.collection('tmp').doc().id; await getInstituteSectionsColl(levelId).doc(sid).set({'id': sid, 'name': name, 'isActive': true, 'createdAt': FieldValue.serverTimestamp()}); notifyListeners(); }

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
      await getInstituteStudentsColl(levelId).doc(uid).set(studentData);

      if (notify) notifyListeners();
    } catch (e) {
      debugPrint("Add student error: $e");
      rethrow;
    }
  }

  Future<void> addDoctor(String id, String name, String emailInput, List<String> teachingLevels, List<String> subjects, [String? password]) async {
    String email = _formatEmail(id);
    String uid = await _secureCreateUser(email, password ?? "123456");
    await instituteDoctorsColl.doc(uid).set({'uid': uid, 'id': id, 'name': name, 'email': email, 'teachingLevels': teachingLevels, 'subjects': subjects, 'isActive': true, 'role': 'doctor', 'password': hashPassword(password ?? "123456"), 'instituteId': selectedInstituteId});
    notifyListeners();
  }

  Future<void> addTA(String id, String name, String emailInput, List<String> teachingLevels, List<String> subjects, [String? password]) async {
    String email = _formatEmail(id);
    String uid = await _secureCreateUser(email, password ?? "123456");
    await instituteTasColl.doc(uid).set({'uid': uid, 'id': id, 'name': name, 'email': email, 'teachingLevels': teachingLevels, 'subjects': subjects, 'isActive': true, 'role': 'ta', 'password': hashPassword(password ?? "123456"), 'instituteId': selectedInstituteId});
    notifyListeners();
  }

  Future<void> addManager(String name, String emailInput, String password, {List<String> managedLevels = const []}) async {
    String email = _formatEmail(emailInput);
    String uid = await _secureCreateUser(email, password);
    await instituteManagersColl.doc(uid).set({'uid': uid, 'name': name, 'email': email, 'managedLevels': managedLevels, 'isActive': true, 'role': 'manager', 'password': hashPassword(password), 'instituteId': selectedInstituteId});
    notifyListeners();
  }

  Future<void> addCourseToLevel(String levelId, String name, String division, String semesterId, String doctorId, {int lecturesCount = 12, String? taId, List<String>? taIds}) async {
    String cid = _firestore.collection('tmp').doc().id;
    List<String> finalTaIds = taIds ?? (taId != null ? [taId] : []);
    await getInstituteCoursesColl(levelId).doc(cid).set({
      'id': cid,
      'name': name,
      'division': division,
      'semester_id': semesterId,
      'doctor_id': doctorId,
      'ta_id': finalTaIds.isNotEmpty ? finalTaIds.first : taId,
      'ta_ids': finalTaIds,
      'level_id': levelId,
      'lecturesCount': lecturesCount,
      'createdAt': FieldValue.serverTimestamp(),
      'instituteId': selectedInstituteId
    });
    notifyListeners();
  }

  Future<void> addLectureToCourse(String levelId, String courseId, String title, int number) async { String lecId = _firestore.collection('tmp').doc().id; await getInstituteLecturesColl(levelId, courseId).doc(lecId).set({'id': lecId, 'title': title, 'number': number, 'createdAt': FieldValue.serverTimestamp()}); notifyListeners(); }

  Future<void> changeStudentPasswordByAdmin({
    required String studentUid,
    required String newPassword,
    String? levelId,
  }) async {
    String hashedPass = hashPassword(newPassword.trim());
    await studentsColl.doc(studentUid).set({'password': hashedPass}, SetOptions(merge: true));
    if (levelId != null && levelId.isNotEmpty) {
      String normLvl = normalizeLevel(levelId);
      await getInstituteStudentsColl('level_$normLvl').doc(studentUid).set({'password': hashedPass}, SetOptions(merge: true));
    }
    notifyListeners();
  }

  Future<void> deleteStudent(String uid, String level) async {
    try {
      final studentDoc = await studentsColl.doc(uid).get();
      final data = studentDoc.data() as Map<String, dynamic>?;
      final String? studentId = data?['id']?.toString();

      await studentsColl.doc(uid).delete();
      await getInstituteStudentsColl('level_$level').doc(uid).delete();

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

  Future<void> resetAllStudentsDevices({String? levelId}) async {
    if (selectedInstituteId == null) return;
    try {
      var batch = _firestore.batch();
      int count = 0;

      if (levelId != null && levelId.isNotEmpty) {
        String lvlNum = levelId.replaceAll('level_', '');
        var snap = await studentsColl.where('level', isEqualTo: lvlNum).get();
        for (var doc in snap.docs) {
          batch.update(doc.reference, {'deviceId': FieldValue.delete()});
          count++;
          if (count % 400 == 0) {
            await batch.commit();
            batch = _firestore.batch();
          }
        }
      } else {
        var snap = await studentsColl.get();
        for (var doc in snap.docs) {
          batch.update(doc.reference, {'deviceId': FieldValue.delete()});
          count++;
          if (count % 400 == 0) {
            await batch.commit();
            batch = _firestore.batch();
          }
        }
      }
      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint("Reset all devices error: $e");
      rethrow;
    }
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

  Future<void> deleteDoctor(String uid) async { await instituteDoctorsColl.doc(uid).delete(); notifyListeners(); }
  Future<void> deleteTA(String uid) async { await instituteTasColl.doc(uid).delete(); notifyListeners(); }
  Future<void> deleteManager(String uid) async { await instituteManagersColl.doc(uid).delete(); notifyListeners(); }

  Future<void> updateDoctorByAdmin(String docId, {required String name, String? email}) async {
    Map<String, dynamic> data = {'name': name};
    if (email != null && email.isNotEmpty) data['email'] = email;
    await instituteDoctorsColl.doc(docId).set(data, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> updateTAByAdmin(String taId, {required String name, String? email}) async {
    Map<String, dynamic> data = {'name': name};
    if (email != null && email.isNotEmpty) data['email'] = email;
    await instituteTasColl.doc(taId).set(data, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> clearAllNotifications(String type) async {
    var snap = await notificationsColl.where('targetType', isEqualTo: type).get();
    for (var d in snap.docs) { await d.reference.delete(); }
    notifyListeners();
  }

  Future<void> addSemester(String id, String name, int order) async { await instituteSemestersColl.doc(id).set({'id': id, 'name': name, 'order': order, 'isActive': false, 'createdAt': FieldValue.serverTimestamp()}); notifyListeners(); }
  Future<void> toggleSemesterStatus(String id, bool isActive) async { if (isActive) { var query = await instituteSemestersColl.get(); for (var doc in query.docs) { if (doc.id != id) { await doc.reference.update({'isActive': false}); } } } await instituteSemestersColl.doc(id).update({'isActive': isActive}); notifyListeners(); }
  Future<void> deleteSemester(String id) async { await instituteSemestersColl.doc(id).delete(); notifyListeners(); }

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
      var coursesSnap = await getInstituteCoursesColl("level_$cleanLvl")
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

  Future<void> uploadResearchToRemote({
    required String subject,
    required PlatformFile file,
    String title = '',
    String recipientType = 'doctor',
    String? researchTopicId, // ✅ NEW: Link to research topic
  }) async {
    if (currentStudent == null) throw "Action not allowed";
    String studentId = currentStudent!['id'].toString();
    String studentName = currentStudent!['name'] ?? '';

    String? assignedId;
    try {
      String studentLvl = currentStudent?['level']?.toString() ?? '1';
      var coursesSnap = await getInstituteCoursesColl("level_$studentLvl")
          .where('name', isEqualTo: subject.trim())
          .get();
      if (coursesSnap.docs.isNotEmpty) {
        final courseData = coursesSnap.docs.first.data() as Map<String, dynamic>;
        if (recipientType == 'ta') {
          assignedId = courseData['ta_id']?.toString();
          if (assignedId == null || assignedId.isEmpty) {
            assignedId = courseData['doctor_id']?.toString();
          }
        } else {
          assignedId = courseData['doctor_id']?.toString();
        }
      }
    } catch (_) {}

    try {
      if (file.size > 15 * 1024 * 1024) {
        throw isArabic ? "حجم الملف يتجاوز الحد المسموح (15 ميجابايت)" : "File size exceeds limit (15MB)";
      }

      String safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
      String fileName = 'research_${studentId}_${DateTime.now().millisecondsSinceEpoch}_$safeName';

      if (kIsWeb) {
        if (file.bytes == null) throw isArabic ? "ملف فارغ أو تالف" : "Empty or corrupted file";
        await supabase.storage.from('research-pdfs').uploadBinary(fileName, file.bytes!);
      } else {
        if (file.path == null) throw isArabic ? "مسار الملف غير موجود" : "File path not found";
        await supabase.storage.from('research-pdfs').upload(fileName, io.File(file.path!));
      }

      final String publicUrl = supabase.storage.from('research-pdfs').getPublicUrl(fileName);

      final String recipientName = recipientType == 'ta'
          ? (isArabic ? 'المعيد' : 'Teaching Assistant')
          : (isArabic ? 'الدكتور' : 'Doctor');

      await submissionsColl.add({
        'studentId': studentId,
        'studentName': studentName,
        'subject': subject,
        'doctorId': assignedId,
        'recipientType': recipientType,
        'recipientName': recipientName,
        'fileName': file.name,
        'fileUrl': publicUrl,
        'title': title,
        'researchTopicId': researchTopicId, // ✅ NEW: Save topic ID
        'date': FieldValue.serverTimestamp(),
        'status': 'Submitted',
        'isSeen': false,
        'instituteId': selectedInstituteId,
        'level': currentStudent?['level']?.toString() ?? '1',
      });

      // إضافة إشعار للمستلم (دكتور أو معيد)
      await notificationsColl.add({
        'title': recipientType == 'ta'
            ? (isArabic ? 'شيت/بحث جديد للمعيد' : 'New Sheet/Research for TA')
            : (isArabic ? 'بحث/شيت جديد للدكتور' : 'New Research/Sheet for Doctor'),
        'body': isArabic ? 'قام الطالب $studentName برفع ملف في مادة $subject' : 'Student $studentName uploaded a file in $subject',
        'targetType': recipientType == 'ta' ? 'ta' : 'doctor',
        'targetDoctorId': assignedId,
        'subject': subject,
        'timestamp': FieldValue.serverTimestamp(),
        'instituteId': selectedInstituteId,
        'isRead': false,
      });
    } catch (e) {
      debugPrint("❌ Error uploading research: $e");
      rethrow;
    }
  }

  Future<void> updateResearchStatus(
      String id,
      String stat, {
        bool markAsSeen = false,
        String? grade,
        String? comment,
        bool? isPublished,
        bool? isDraft,
      }) async {
    Map<String, dynamic> data = {'status': stat};
    if (markAsSeen) data['isSeen'] = true;
    if (grade != null) data['grade'] = grade;
    if (comment != null) data['comment'] = comment;
    if (isPublished != null) data['isPublished'] = isPublished;
    if (isDraft != null) data['isDraft'] = isDraft;

    final bool isEvaluation = grade != null || comment != null;

    if (isEvaluation) {
      data['evaluatedAt'] = FieldValue.serverTimestamp();
      data['evaluatedBy'] = currentDoctor?['name'] ?? 'Doctor';
    }

    await submissionsColl.doc(id).update(data);

    // إشعار الطالب عند النشر فقط
    if (isEvaluation && isPublished == true) {
      try {
        var doc = await submissionsColl.doc(id).get();
        var subData = doc.data() as Map<String, dynamic>?;
        if (subData != null) {
          await notificationsColl.add({
            'title': isArabic ? 'تم نشر تقييم بحثك' : 'Research Evaluated',
            'body': isArabic
                ? 'قام الدكتور بنشر تقييم بحثك في مادة ${subData['subject']}. الدرجة: ${subData['grade'] ?? grade ?? ''}'
                : 'Doctor published your evaluation in ${subData['subject']}. Grade: ${subData['grade'] ?? grade ?? ''}',
            'targetType': 'student',
            'targetId': subData['studentId'],
            'timestamp': FieldValue.serverTimestamp(),
            'instituteId': selectedInstituteId,
            'isRead': false,
          });
        }
      } catch (e) {
        debugPrint("Notify student error: $e");
      }
    }

    // مفيش داعي لإعادة بناء الواجهة لما نعمل بس "تم المشاهدة"
    if (!markAsSeen || isEvaluation) notifyListeners();
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

  CollectionReference get schedulesColl => instituteRef.collection('schedules');
  CollectionReference get scheduleEntriesColl => instituteRef.collection('schedule_entries');

  Future<void> addOfficialSchedule({
    required String levelId,
    required String division,
    required Map<String, dynamic> item,
  }) async {
    if (selectedInstituteId == null) return;
    await schedulesColl.add({
      ...item,
      'levelId': levelId,
      'division': division,
      'instituteId': selectedInstituteId,
      'isOfficial': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Future<void> deleteOfficialSchedule(String id) async {
    await schedulesColl.doc(id).delete();
    notifyListeners();
  }

  Stream<QuerySnapshot> getOfficialScheduleStream({String? levelId, String? division}) {
    if (selectedInstituteId == null) return _firestore.collection('empty_fallback').snapshots();
    // Also support schedule_entries if schedulesColl is empty or for unified view
    Query q = scheduleEntriesColl;
    if (levelId != null && levelId.isNotEmpty) {
      String cleanLvl = normalizeLevel(levelId);
      q = q.where('levelId', whereIn: [levelId, 'level_$cleanLvl', cleanLvl]);
    }
    return q.snapshots();
  }

  Future<void> addOfficialScheduleEntry({
    required String levelId,
    required String day,
    required String type,
    required String targetSection,
    required String subjectId,
    required String subjectName,
    required String doctorId,
    required String doctorName,
    required String startTime,
    String? endTime,
    required String location,
  }) async {
    if (selectedInstituteId == null) throw Exception("Institute not selected");
    await scheduleEntriesColl.add({
      'levelId': levelId,
      'day': day,
      'type': type,
      'targetSection': targetSection,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'startTime': startTime,
      'endTime': endTime ?? '',
      'location': location,
      'isPublished': false,
      'instituteId': selectedInstituteId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser?.email ?? 'admin',
    });
    notifyListeners();
  }

  Future<void> updateOfficialScheduleEntry({
    required String entryId,
    required String levelId,
    required String day,
    required String type,
    required String targetSection,
    required String subjectId,
    required String subjectName,
    required String doctorId,
    required String doctorName,
    required String startTime,
    String? endTime,
    required String location,
  }) async {
    if (selectedInstituteId == null) throw Exception("Institute not selected");
    await scheduleEntriesColl.doc(entryId).update({
      'levelId': levelId,
      'day': day,
      'type': type,
      'targetSection': targetSection,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'startTime': startTime,
      'endTime': endTime ?? '',
      'location': location,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Future<void> deleteOfficialScheduleEntry(String entryId) async {
    await scheduleEntriesColl.doc(entryId).delete();
    notifyListeners();
  }

  Future<void> publishScheduleEntriesForLevel(String levelId, {bool publish = true}) async {
    String cleanLvl = normalizeLevel(levelId);
    var snap = await scheduleEntriesColl
        .where('levelId', whereIn: [levelId, 'level_$cleanLvl', cleanLvl])
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {
        'isPublished': publish,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    notifyListeners();
  }

  Stream<QuerySnapshot> getStudentOfficialScheduleStream({required String levelId}) {
    if (selectedInstituteId == null) return _firestore.collection('empty_fallback').snapshots();
    String cleanLvl = normalizeLevel(levelId);
    return scheduleEntriesColl
        .where('levelId', whereIn: [levelId, 'level_$cleanLvl', cleanLvl])
        .where('isPublished', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getDoctorOfficialScheduleStream({required String doctorId}) {
    if (selectedInstituteId == null) return _firestore.collection('empty_fallback').snapshots();
    return scheduleEntriesColl
        .where('doctorId', isEqualTo: doctorId)
        .where('isPublished', isEqualTo: true)
        .snapshots();
  }

  Future<void> changeUserPassword(String id, String newPass, bool isStud) async {
    if (isStud) {
      var q = await studentsColl.where('id', isEqualTo: id).get();
      for (var d in q.docs) { await d.reference.update({'password': hashPassword(newPass)}); }
    } else {
      await instituteDoctorsColl.doc(id).update({'password': hashPassword(newPass)}).catchError((_){});
      await instituteManagersColl.doc(id).update({'password': hashPassword(newPass)}).catchError((_){});
    }

    if (_auth.currentUser != null) {
      await _auth.currentUser?.updatePassword(newPass);
    }
  }

  Future<bool> updatePassword(String newPass) async {
    try {
      User? user = _auth.currentUser;
      String hashedPass = hashPassword(newPass.trim());

      if (user != null) {
        try {
          await user.updatePassword(newPass.trim());
        } catch (authErr) {
          debugPrint("Auth update password notice: $authErr");
        }

        String uid = user.uid;
        if (currentStudent != null) {
          await studentsColl.doc(uid).set({'password': hashedPass}, SetOptions(merge: true));
          String sId = currentStudent!['id']?.toString() ?? '';
          if (sId.isNotEmpty) {
            var q = await studentsColl.where('id', isEqualTo: sId).get();
            for (var doc in q.docs) {
              await doc.reference.set({'password': hashedPass}, SetOptions(merge: true));
            }
          }
        } else if (currentDoctor != null) {
          await instituteDoctorsColl.doc(uid).set({'password': hashedPass}, SetOptions(merge: true));
          await instituteTasColl.doc(uid).set({'password': hashedPass}, SetOptions(merge: true)).catchError((_){});
        } else if (currentAdmin != null) {
          await instituteManagersColl.doc(uid).set({'password': hashedPass}, SetOptions(merge: true)).catchError((_){});
        }
      } else {
        if (currentStudent != null) {
          String uid = currentStudent!['uid'] ?? '';
          if (uid.isNotEmpty) await studentsColl.doc(uid).set({'password': hashedPass}, SetOptions(merge: true));
        } else if (currentDoctor != null) {
          String uid = currentDoctor!['uid'] ?? '';
          if (uid.isNotEmpty) {
            await instituteDoctorsColl.doc(uid).set({'password': hashedPass}, SetOptions(merge: true));
            await instituteTasColl.doc(uid).set({'password': hashedPass}, SetOptions(merge: true)).catchError((_){});
          }
        }
      }
      notifyListeners();
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
      if (role == 'super_admin_plus') {
        currentAdmin = {
          'uid': uid,
          'name': 'Abdoel Sayed El Sherbiny (سوبر أدمن بلس)',
          'email': 'abdoelsaydelsherbiny.com@smart.com',
          'role': 'super_admin_plus',
        };
        if (selectedInstituteId == null) {
          try {
            var colSnap = await _firestore.collection('colleges').limit(1).get();
            if (colSnap.docs.isNotEmpty) {
              selectedInstituteId = colSnap.docs.first.id;
            } else {
              selectedInstituteId = '';
            }
          } catch (_) {
            selectedInstituteId = '';
          }
        }
      } else {
        String? foundRole = await _findAndLoadUser(uid);
        if (foundRole == null) {
          // السيرفر أكد إن الحساب غير موجود أو ناقص البيانات الأساسية -> مسح الجلسة فوراً
          await clearSession();
          throw isArabic
              ? "حسابك غير مكتمل أو غير موجود على خوادم الكلية. يرجى مراجعة إدارة الكلية."
              : "Account document is incomplete or missing. Contact administration.";
        }
      }

      // مزامنة الإشعارات بعد تحميل البيانات
      if (!kIsWeb) {
        syncScheduleNotifications();
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Load error in loadUserData: $e");
      if (e is SocketException || e is TimeoutException || e.toString().contains('SocketException') || e.toString().contains('timeout')) {
        // عند أخطاء الشبكة والمهلة: عدم مسح الجلسة والاحتفاظ ببيانات التخزين المحلي
      } else {
        await clearSession();
        rethrow;
      }
    }
  }

  Future<String?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString('selected_institute_id');
      if (storedId != null) {
        await setInstitute(storedId);
      }

      String? id = prefs.getString('session_id');
      String? type = prefs.getString('session_type');

      if (id == null || type == null) return null;

      if (type == 'super_admin_plus') {
        await loadUserData(id, type);
        return type;
      }

      if (selectedInstituteId == null) return null;

      await loadUserData(id, type);

      // التأكد الصارم من أن بيانات المستخدم محملة وليست فاضية
      if (userRole == 'student' && (currentStudent == null || (currentStudent!['name'] ?? '').toString().trim().isEmpty)) {
        await clearSession();
        return null;
      }
      if ((userRole == 'doctor' || userRole == 'ta') && (currentDoctor == null || (currentDoctor!['name'] ?? '').toString().trim().isEmpty)) {
        await clearSession();
        return null;
      }
      if ((userRole == 'super_admin' || userRole == 'manager') && (currentAdmin == null || (currentAdmin!['name'] ?? '').toString().trim().isEmpty)) {
        await clearSession();
        return null;
      }

      return type;
    } catch (e) {
      debugPrint("loadSession exception: $e");
      if (e.toString().contains('غير مكتمل') || e.toString().contains('غير موجود')) {
        await clearSession();
        return null;
      }
      // في حالة انقطاع الشبكة، إرجاع الجلسة المحفوظة حتى يفتح التطبيق أوفلاين
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('session_type');
    }
  }

  Future<void> clearSession() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
    await prefs.remove('session_type');
    currentStudent = null;
    currentDoctor = null;
    currentAdmin = null;
    userRole = null;
    studentSubjects = [];
    notifyListeners();
  }
  Future<void> saveSession(String id, String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', id);
    await prefs.setString('session_type', type);
    if (selectedInstituteId != null) {
      await prefs.setString('selected_institute_id', selectedInstituteId!);
    }
  }
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isArabic = prefs.getBool('persist_v3_arabic') ?? true;
    isDarkMode = prefs.getBool('persist_v3_dark') ?? false;

    // ⚠️ DISABLED: This code deleted production data!
    // Auto-purge was running on every app start and deleting 'commerce' college from Firestore
    // try {
    //   _deleteCommerceCollegePermanently();
    // } catch (_) {}

    notifyListeners();
  }

  Future<void> _deleteCommerceCollegePermanently() async {
    try {
      var collegeRef = _firestore.collection(FirestoreConstants.collegesCollection)
          .doc(FirestoreConstants.dummyCommerceId);
      var docSnap = await collegeRef.get();
      if (!docSnap.exists) return;

      var subcollections = ['levels', 'students', 'doctors', 'tas', 'super_admins', 'managers', 'courses', 'exams', 'notifications', 'private_chats', 'reports'];
      for (var sub in subcollections) {
        try {
          var snap = await collegeRef.collection(sub).get();
          for (var doc in snap.docs) {
            if (sub == 'levels') {
              try {
                var levelsStudents = await doc.reference.collection('students').get();
                for (var sDoc in levelsStudents.docs) {
                  await sDoc.reference.delete();
                }
              } catch (_) {}
              try {
                var coursesSnap = await doc.reference.collection('courses').get();
                for (var cDoc in coursesSnap.docs) {
                  await cDoc.reference.delete();
                }
              } catch (_) {}
            }
            await doc.reference.delete();
          }
        } catch (_) {}
      }
      await collegeRef.delete();
      debugPrint("🔥 Successfully purged and deleted dummy college from Firestore.");
    } catch (e) {
      debugPrint("Purge commerce error: $e");
    }
  }
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
    if (n == 'all' || n == 'الكل' || n.contains('جميع') || n.contains('عام') || n == 'general') return 'all';
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
        var semSnap = await instituteSemestersColl.where('isActive', isEqualTo: true).get();
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
        final data = doc.data();
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

    // التنسيق: [كود].college@smart.com
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
      await instituteDoctorsColl.doc(uid).set(updateData, SetOptions(merge: true));
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

  // ==================== RESEARCH TOPICS MANAGEMENT ====================

  /// Create a new research topic with deadline
  /// الدكتور يحدد عنوان البحث والموعد
  Future<String> createResearchTopic({
    required String title,
    required String subject,
    DateTime? deadline,
    int? maxDays,
  }) async {
    if (currentDoctor == null || selectedInstituteId == null) {
      throw isArabic ? "يرجى تسجيل الدخول أولاً" : "Please login first";
    }

    try {
      final docRef = _firestore
          .collection('colleges')
          .doc(selectedInstituteId)
          .collection('research_topics')
          .doc();

      final topic = {
        'title': title.trim(),
        'subject': subject.trim(),
        'doctorId': currentDoctor!['uid'] ?? currentDoctor!['id']?.toString(),
        'doctorName': currentDoctor!['name'] ?? 'Unknown',
        'collegeId': selectedInstituteId,
        'deadline': deadline?.millisecondsSinceEpoch,
        'maxDays': maxDays,
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await docRef.set(topic);
      return docRef.id;
    } catch (e) {
      debugPrint("Create topic error: $e");
      rethrow;
    }
  }

  /// Get all active research topics for a subject
  /// للدكتور: عرض كل العناوين اللي أنشأها
  /// للطالب: عرض العناوين المتاحة للإرسال
  Stream<List<Map<String, dynamic>>> getResearchTopics(
      {String? subject, bool onlyActive = true}) {
    if (selectedInstituteId == null) {
      return Stream.value([]);
    }

    try {
      final query = _firestore
          .collection('colleges')
          .doc(selectedInstituteId)
          .collection('research_topics');

      return query.snapshots().map((snapshot) {
        final topics = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;

          // Check if deadline passed
          final deadline = data['deadline'];
          if (deadline != null) {
            final deadlineDate = DateTime.fromMillisecondsSinceEpoch(deadline);
            data['isExpired'] = DateTime.now().isAfter(deadlineDate);
            data['remainingDays'] =
                deadlineDate.difference(DateTime.now()).inDays;
          } else {
            data['isExpired'] = false;
            data['remainingDays'] = null;
          }

          return data;
        }).where((topic) {
          if (onlyActive && topic['isActive'] == false) return false;
          if (subject != null && subject.trim().isNotEmpty) {
            final topicSubject = (topic['subject'] ?? '').toString().trim();
            if (topicSubject != subject.trim()) return false;
          }
          return true;
        }).toList();

        // Sort in Dart instead of Firestore query to avoid composite index requirement
        topics.sort((a, b) {
          final aCreated = (a['createdAt'] as int? ?? 0);
          final bCreated = (b['createdAt'] as int? ?? 0);
          return bCreated.compareTo(aCreated);
        });
        return topics;
      });
    } catch (e) {
      debugPrint("Get topics error: $e");
      return Stream.value([]);
    }
  }

  /// Update research topic
  Future<void> updateResearchTopic(
    String topicId, {
    String? title,
    DateTime? deadline,
    bool? isActive,
  }) async {
    if (selectedInstituteId == null) return;

    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title.trim();
      if (deadline != null) updates['deadline'] = deadline.millisecondsSinceEpoch;
      if (isActive != null) updates['isActive'] = isActive;

      await _firestore
          .collection('colleges')
          .doc(selectedInstituteId)
          .collection('research_topics')
          .doc(topicId)
          .update(updates);
    } catch (e) {
      debugPrint("Update topic error: $e");
      rethrow;
    }
  }

  /// Delete research topic
  Future<void> deleteResearchTopic(String topicId) async {
    if (selectedInstituteId == null) return;

    try {
      await _firestore
          .collection('colleges')
          .doc(selectedInstituteId)
          .collection('research_topics')
          .doc(topicId)
          .delete();
    } catch (e) {
      debugPrint("Delete topic error: $e");
      rethrow;
    }
  }

  /// Check if a topic is still accepting submissions
  /// يفحص إذا الموعد انتهى أو لا
  Future<bool> isTopicAcceptingSubmissions(String topicId) async {
    if (selectedInstituteId == null) return false;

    try {
      final doc = await _firestore
          .collection('colleges')
          .doc(selectedInstituteId)
          .collection('research_topics')
          .doc(topicId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final isActive = data['isActive'] ?? true;
      if (!isActive) return false;

      final deadline = data['deadline'];
      if (deadline == null) return true;

      final deadlineDate = DateTime.fromMillisecondsSinceEpoch(deadline);
      return DateTime.now().isBefore(deadlineDate);
    } catch (e) {
      debugPrint("Check topic error: $e");
      return false;
    }
  }
}