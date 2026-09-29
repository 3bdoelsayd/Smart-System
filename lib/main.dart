import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
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

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // تفعيل Supabase مع معالجة الأخطاء لضمان استمرار التشغيل
    try {
      await Supabase.initialize(
        url: 'https://dwkbyhyzkjzmynznilta.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3a2J5aHl6a2p6bXluem5pbHRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0NDc0MzEsImV4cCI6MjA5OTAyMzQzMX0.s_si7MkVvB9SuLWHQQMmoUbOOes5enaAW2Jq7oaTcNw',
      );
    } catch (e) {
      debugPrint("Supabase Init Error: $e");
    }

    final ds = DataService();
    await ds.loadSettings();

    String? initialRoute = '/';
    final String? savedRole = await ds.loadSession();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && savedRole != null) {
      await ds.loadUserData(currentUser.uid, savedRole);
      if (savedRole == 'student') initialRoute = '/student/home';
      else if (savedRole == 'doctor') initialRoute = '/doctor/home';
      else if (savedRole == 'super_admin') initialRoute = '/super-admin/dashboard';
      else if (savedRole == 'manager') initialRoute = '/manager/dashboard';
      else initialRoute = '/start';
    } else {
      initialRoute = '/start';
    }

    if (!kIsWeb) {
      try {
        await ds.initNotifications();
      } catch (e) {
        debugPrint("Notifications Init Error: $e");
      }
    }

    runApp(UniversityApp(initialRoute: initialRoute));
  } catch (e) {
    debugPrint("CRITICAL STARTUP ERROR: $e");
    // تشغيل تطبيق طوارئ لعرض رسالة الخطأ
    runApp(MaterialApp(home: Scaffold(body: Center(child: SelectableText("Startup Failed: $e")))));
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
            '/doctor/exam-results': (context) => const ExamResultsManagementScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
