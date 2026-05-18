import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
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
    await ds.initNotifications();
  }
  
  runApp(UniversityApp(initialRoute: initialRoute));
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
          key: ValueKey("${ds.isDarkMode}${ds.isArabic}"),
          debugShowCheckedModeBanner: false,
          title: ds.translate('app_title'),
          themeMode: ds.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: initialRoute ?? '/',
          // إضافة الـ locale لضمان قلب الواجهة (RTL/LTR)
          locale: ds.isArabic ? const Locale('ar') : const Locale('en'),
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                if (ds.isChangingTheme)
                  Positioned.fill(
                    child: Directionality(
                      textDirection: ds.isArabic ? TextDirection.rtl : TextDirection.ltr,
                      child: Container(
                        color: ds.isDarkMode ? Colors.black : Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Color(0xFF673AB7)),
                              const SizedBox(height: 20),
                              Material(
                                color: Colors.transparent,
                                child: Text(
                                  ds.isArabic ? "جاري تحديث النظام..." : "Updating System...",
                                  style: GoogleFonts.cairo(
                                    color: ds.isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
