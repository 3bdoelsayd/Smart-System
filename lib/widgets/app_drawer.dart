// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../Screens/super_admin_dashboard.dart';
import 'sub_page_wrapper.dart';

class AppDrawer extends StatelessWidget {
  final String name;
  final String role;
  const AppDrawer({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final ds = DataService();

    return ListenableBuilder(
        listenable: ds,
        builder: (context, _) {
          bool isAr = ds.isArabic;
          bool isDark = ds.isDarkMode;

          bool isDoctor = ds.userRole == 'doctor';
          bool isSuperAdmin = ds.userRole == 'super_admin';
          bool isManager = ds.userRole == 'manager';

          // Modernized Colors for Drawer
          Color primaryColor = Theme.of(context).primaryColor;
          
          final bgColor = isDark ? const Color(0xFF1C1C23) : Colors.white;
          final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
          final iconColor = isDark ? primaryColor : primaryColor.withOpacity(0.8);

          return Drawer(
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  accountEmail: Text(role, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                  currentAccountPicture: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                          name.isNotEmpty ? name[0] : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark 
                          ? [const Color(0xFF2E1A47), const Color(0xFF1A1A2E)]
                          : [const Color(0xFF673AB7), const Color(0xFF512DA8)]
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.dashboard_rounded,
                        title: isAr ? 'اللوحة الرئيسية' : 'Main Dashboard',
                        textColor: textColor, iconColor: iconColor,
                        onTap: () {
                          if (isSuperAdmin) Navigator.pushReplacementNamed(context, '/super-admin/dashboard');
                          else if (isManager) Navigator.pushReplacementNamed(context, '/manager/dashboard');
                          else if (isDoctor) Navigator.pushReplacementNamed(context, '/doctor/home');
                          else { ds.studentTabIndex = 0; Navigator.pushReplacementNamed(context, '/student/home'); }
                        },
                      ),

                      if (isSuperAdmin) ...[
                        const Divider(indent: 20, endIndent: 20),
                        _buildDrawerItem(
                          icon: Icons.layers_rounded,
                          title: isAr ? 'إدارة الفرق' : 'Manage Levels',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SubPageWrapper(title: 'إدارة الفرق', child: LevelsManagementView()))); },
                        ),
                        _buildDrawerItem(
                          icon: Icons.grid_view_rounded,
                          title: isAr ? 'إدارة الشعب' : 'Manage Sections',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SubPageWrapper(title: 'إدارة الشعب', child: SectionsManagementView()))); },
                        ),
                        _buildDrawerItem(
                          icon: Icons.school_rounded,
                          title: isAr ? 'إدارة الطلاب' : 'Manage Students',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SubPageWrapper(title: 'إدارة الطلاب', child: StudentsManagementView()))); },
                        ),
                        _buildDrawerItem(
                          icon: Icons.person_search_rounded,
                          title: isAr ? 'إدارة الدكاترة' : 'Manage Doctors',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SubPageWrapper(title: 'إدارة الدكاترة', child: DoctorsManagementView()))); },
                        ),
                        _buildDrawerItem(
                          icon: Icons.admin_panel_settings_rounded,
                          title: isAr ? 'إدارة المديرين' : 'Manage Managers',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SubPageWrapper(title: 'إدارة المديرين', child: ManagersManagementView()))); },
                        ),
                        _buildDrawerItem(
                          icon: Icons.calendar_month_rounded,
                          title: isAr ? 'إدارة الفصول' : 'Manage Semesters',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SubPageWrapper(title: 'إدارة الفصول الدراسية', child: SemestersManagementView()))); },
                        ),
                      ],

                      if (isManager) ...[
                        const Divider(indent: 20, endIndent: 20),
                        _buildDrawerItem(
                          icon: Icons.school_rounded,
                          title: isAr ? 'إدارة الطلاب' : 'Manage Students',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { 
                            Navigator.pop(context); 
                            ds.managerTabIndex = 0;
                            Navigator.pushReplacementNamed(context, '/manager/dashboard'); 
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.book_rounded,
                          title: isAr ? 'إدارة المواد' : 'Manage Courses',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { 
                            Navigator.pop(context); 
                            ds.managerTabIndex = 1;
                            Navigator.pushReplacementNamed(context, '/manager/dashboard'); 
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.person_search_rounded,
                          title: isAr ? 'إدارة الدكاترة' : 'Manage Doctors',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { 
                            Navigator.pop(context); 
                            ds.managerTabIndex = 2;
                            Navigator.pushReplacementNamed(context, '/manager/dashboard'); 
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.how_to_reg_rounded,
                          title: isAr ? 'سجلات الحضور' : 'Attendance Records',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { 
                            Navigator.pop(context); 
                            ds.managerTabIndex = 3;
                            Navigator.pushReplacementNamed(context, '/manager/dashboard'); 
                          },
                        ),
                      ],

                      if (isDoctor) ...[
                        const Divider(indent: 20, endIndent: 20),
                        _buildDrawerItem(
                          icon: Icons.group_rounded,
                          title: isAr ? 'إدارة الحضور' : 'Attendance Management',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/doctor/attendance'); },
                        ),
                        _buildDrawerItem(
                          icon: Icons.upload_file_rounded,
                          title: isAr ? 'أبحاث الطلاب' : 'Student Research',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/doctor/researches'); },
                        ),
                      ],

                      if (!isSuperAdmin && !isManager && !isDoctor) ...[
                        const Divider(indent: 20, endIndent: 20),
                        _buildDrawerItem(
                          icon: Icons.assignment_rounded,
                          title: isAr ? 'أبحاثي المرفوعة' : 'My Submissions',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { ds.studentTabIndex = 1; Navigator.pushReplacementNamed(context, '/student/home'); },
                        ),
                        _buildDrawerItem(
                          icon: Icons.calendar_today_rounded,
                          title: isAr ? 'جدول المحاضرات' : 'Lecture Schedule',
                          textColor: textColor, iconColor: iconColor,
                          onTap: () { ds.studentTabIndex = 2; Navigator.pushReplacementNamed(context, '/student/home'); },
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: isAr ? 'الإعدادات' : 'Settings',
                  textColor: textColor, iconColor: iconColor,
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/settings'); },
                ),
                _buildDrawerItem(
                  icon: Icons.exit_to_app_rounded,
                  title: isAr ? 'تسجيل الخروج' : 'Logout',
                  textColor: textColor, iconColor: Colors.redAccent.withOpacity(0.8),
                  onTap: () async { await ds.clearSession(); Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false); },
                  isLogout: true,
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, required Color textColor, required Color iconColor, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: isLogout ? FontWeight.bold : FontWeight.w500, fontSize: 15)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
