import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'firebase_options.dart';
import 'services/data_service.dart';
import 'theme/app_theme.dart';
import 'Screens/splash_screen.dart';
import 'Screens/start_screen.dart';
import 'Screens/unified_login_screen.dart';
import 'Screens/student_home_screen.dart';
import 'Screens/doctor_home_screen.dart';
import 'Screens/admin_home_screen.dart';
import 'Screens/research_upload_screen.dart';
import 'Screens/research_list_screen.dart';
import 'Screens/student_results_screen.dart';
import 'Screens/attendance_scan_screen.dart';
import 'Screens/attendance_management_screen.dart';
import 'Screens/research_submissions_screen.dart';
import 'Screens/exam_results_management_screen.dart';
import 'Screens/notifications_screen.dart';
import 'Screens/settings_screen.dart';
import 'Screens/password_management_screen.dart';
import 'Screens/bulk_upload_results_screen.dart';
import 'Screens/super_admin_dashboard.dart';
import 'Screens/manager_dashboard.dart';
import 'Screens/college_selection_screen.dart';
import 'Screens/doctor_students_list_screen.dart';
import 'Screens/student_doctors_list_screen.dart';
import 'Screens/edit_profile_screen.dart';
import 'Screens/exams/doctor_exams_list_screen.dart';
import 'Screens/exams/student_exams_list_screen.dart';
import 'Screens/exams/manager_exams_screen.dart';

void main() async {
  final sw = Stopwatch()..start();
  void log(String s) => debugPrint('[${sw.elapsedMilliseconds}ms] $s');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    log('1 binding');

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 15));
    log('2 firebase done');

    // إعدادات Firestore للويب: Long Polling ومن غير persistence
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        webExperimentalForceLongPolling: true,
        persistenceEnabled: false,
      );
      log('2.5 firestore settings');
    }

    // Supabase مع timeout
    try {
      await Supabase.initialize(
        url: 'https://dwkbyhyzkjzmynznilta.supabase.co',
        publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3a2J5aHl6a2p6bXluem5pbHRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0NDc0MzEsImV4cCI6MjA5OTAyMzQzMX0.s_si7MkVvB9SuLWHQQMmoUbOOes5enaAW2Jq7oaTcNw',
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      log('supabase error: $e');
    }
    log('3 supabase done');

    final ds = DataService();

    try {
      await ds.loadSettings().timeout(const Duration(seconds: 10));
    } catch (e) {
      log('loadSettings error/timeout: $e');
    }
    log('4 settings done');

    String? savedRole;
    try {
      savedRole = await ds.loadSession().timeout(const Duration(seconds: 10));
    } catch (e) {
      log('loadSession error/timeout: $e');
    }
    log('5 session done');

    String initialRoute = '/start';

    // على الويب: استنى حالة الـ Auth تتحمّل بشكل صحيح
    final User? currentUser = kIsWeb
        ? await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 8), onTimeout: () => null)
        : FirebaseAuth.instance.currentUser;
    log('5.5 auth state: ${currentUser?.uid}');

    if (currentUser != null && savedRole != null) {
      // متستناش loadUserData: خليها تشتغل في الخلفية
      ds.loadUserData(currentUser.uid, savedRole).then((_) {
        log('6 userData done (background)');
      }).catchError((e) {
        log('loadUserData error: $e');
      });

      if (savedRole == 'student') {
        initialRoute = '/student/home';
      } else if (savedRole == 'doctor' || savedRole == 'ta') {
        initialRoute = '/doctor/home';
      } else if (savedRole == 'super_admin' || savedRole == 'super_admin_plus') {
        initialRoute = '/super-admin/dashboard';
      } else if (savedRole == 'manager') {
        initialRoute = '/manager/dashboard';
      }
    }

    if (!kIsWeb) {
      try {
        await ds.initNotifications().timeout(const Duration(seconds: 10));
      } catch (e) {
        log('Notifications Init Error: $e');
      }
    }

    runApp(UniversityApp(initialRoute: initialRoute));
    log('7 runApp');
  } catch (e) {
    debugPrint("CRITICAL STARTUP ERROR: $e");
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: SelectableText("Startup Failed: $e")),
      ),
    ));
  }
}

class UniversityApp extends StatelessWidget {
  final String? initialRoute;
  const UniversityApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final ds = DataService();

    return ListenableBuilder(
      listenable: ds,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: ds.translate('app_title'),
          themeMode: ds.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: initialRoute ?? '/',
          // إضافة الـ locale لضمان قلب الواجهة (RTL/LTR)
          locale: ds.isArabic ? const Locale('ar') : const Locale('en'),
          routes: {
            '/': (context) => const SplashScreen(),
            '/start': (context) => const StartScreen(),
            '/college-selection': (context) => const CollegeSelectionScreen(),
            '/login': (context) => const UnifiedLoginScreen(),
            '/student/home': (context) => const StudentHomeScreen(),
            '/doctor/home': (context) => const DoctorHomeScreen(),
            '/admin/home': (context) => const AdminHomeScreen(),
            '/super-admin/dashboard': (context) => const SuperAdminDashboard(),
            '/manager/dashboard': (context) => const ManagerDashboard(),
            '/admin/password-management': (context) => const PasswordManagementScreen(),
            '/admin/bulk-upload': (context) => const BulkUploadResultsScreen(),
            '/student/research-upload': (context) => const ResearchUploadScreen(),
            '/student/research-list': (context) => const ResearchListScreen(),
            '/student/results': (context) => const StudentResultsScreen(),
            '/student/attendance-scan': (context) => const AttendanceScanScreen(),
            '/doctor/attendance': (context) => const AttendanceManagementScreen(),
            '/doctor/researches': (context) => const ResearchSubmissionsScreen(),
            '/doctor/students-chat': (context) => const DoctorStudentsListScreen(),
            '/doctor/exam-results': (context) => const ExamResultsManagementScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
            '/student/doctors-chat': (context) => const StudentDoctorsListScreen(),
            '/doctor/exams': (context) => const DoctorExamsListScreen(),
            '/student/exams': (context) => const StudentExamsListScreen(),
            '/manager/exams': (context) => const ManagerExamsScreen(),
          },
        );
      },
    );
  }
}