import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/data_service.dart';
import '../utils/excel_helper.dart';
import '../utils/fourth_year_bis_students_data.dart';
import '../utils/fourth_year_general_students_data.dart';
import '../utils/first_year_nuzum_students_data.dart';
import '../utils/first_year_general_students_data.dart';
import '../utils/second_year_nuzum_students_data.dart';
import '../utils/second_year_general_students_data.dart';
import '../utils/third_year_nuzum_students_data.dart';
import '../utils/third_year_general_students_data.dart';
import '../widgets/app_drawer.dart';
import '../widgets/student_profile_modal.dart';
import '../widgets/sub_page_wrapper.dart';
import 'attendance_management_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final DataService _ds = DataService();

  @override
  Widget build(BuildContext context) {
    if (_ds.userRole != 'super_admin' || _ds.currentAdmin == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/start', (r) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        bool isAr = _ds.isArabic;
        bool isDark = _ds.isDarkMode;
        final adminName = _ds.currentAdmin?['name'] ?? _ds.translate('super_admin');

        final List<Map<String, dynamic>> cards = [
          {'icon': Icons.layers_rounded, 'title': _ds.translate('manage_levels'), 'widget': const LevelsManagementView(), 'color': const Color(0xFF673AB7), 'subtitle': isAr ? 'إدارة الفرق الدراسية' : 'Manage academic levels'},
          {'icon': Icons.grid_view_rounded, 'title': _ds.translate('manage_sections'), 'widget': const SectionsManagementView(), 'color': const Color(0xFF00BCD4), 'subtitle': isAr ? 'توزيع الطلاب والشعب' : 'Distribute sections'},
          {'icon': Icons.school_rounded, 'title': _ds.translate('manage_students'), 'widget': const StudentsManagementView(), 'color': const Color(0xFF4CAF50), 'subtitle': isAr ? 'قاعدة بيانات الطلاب' : 'Students database'},
          {'icon': Icons.person_search_rounded, 'title': _ds.translate('manage_doctors'), 'widget': const DoctorsManagementView(), 'color': const Color(0xFFE91E63), 'subtitle': isAr ? 'أعضاء هيئة التدريس' : 'Faculty members'},
          {'icon': Icons.badge_rounded, 'title': isAr ? 'إدارة المعيدين' : 'Manage TAs', 'widget': const TAsManagementView(), 'color': Colors.teal, 'subtitle': isAr ? 'معيدو السكاشن والهيئة' : 'Teaching assistants'},
          {'icon': Icons.admin_panel_settings_rounded, 'title': _ds.translate('manage_managers'), 'widget': const ManagersManagementView(), 'color': const Color(0xFFFF9800), 'subtitle': isAr ? 'صلاحيات المديرين' : 'Managers roles'},
          {'icon': Icons.calendar_month_rounded, 'title': _ds.translate('semesters'), 'widget': const SemestersManagementView(), 'color': const Color(0xFF607D8B), 'subtitle': isAr ? 'الفصول والتقويم' : 'Academic calendar'},
          {'icon': Icons.calendar_today_rounded, 'title': isAr ? 'إدارة الجدول الدراسي' : 'Timetable Management', 'widget': const ScheduleManagementView(), 'color': Colors.indigo, 'subtitle': isAr ? 'جداول المحاضرات الرسمية' : 'Official lecture timetables'},
        ];

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8F9FE),
        drawer: AppDrawer(name: adminName, role: _ds.translate('super_admin')),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(25, 60, 25, 35),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [const Color(0xFF2E1A47), const Color(0xFF121212)] 
                      : [const Color(0xFF673AB7), const Color(0xFF512DA8)],
                  ),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(45), bottomRight: Radius.circular(45)),
                  boxShadow: [
                    BoxShadow(color: (isDark ? Colors.black : const Color(0xFF673AB7)).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(builder: (context) => Container(
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                          child: IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28), onPressed: () => Scaffold.of(context).openDrawer()),
                        )),
                        Text(isAr ? 'نظام الإدارة' : 'Admin System', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                        )
                      ],
                    ),
                    const SizedBox(height: 35),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_ds.translate('welcome'), style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                              Text(adminName, style: GoogleFonts.cairo(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2)),
                            ],
                          ),
                        ),
                        _buildQuickStat(isAr ? "الحالة" : "Status", isAr ? "نشط" : "Online", Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  isAr ? "لوحة التحكم الرئيسية" : "Main Dashboard",
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  mainAxisExtent: 155, // جعل الكروت أكثر تناسقاً
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildModernAdminCard(
                    context: context,
                    icon: cards[i]['icon'] as IconData,
                    title: cards[i]['title'] as String,
                    subtitle: cards[i]['subtitle'] as String,
                    color: cards[i]['color'] as Color,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SubPageWrapper(title: cards[i]['title'], child: cards[i]['widget']))),
                    isDark: isDark,
                  ),
                  childCount: cards.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.cairo(color: Colors.white60, fontSize: 10)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)])),
              const SizedBox(width: 6),
              Text(value, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernAdminCard({required BuildContext context, required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade100, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Shared Helper Methods ---
void _confirmGeneralDelete(BuildContext context, String title, String content, VoidCallback onConfirm) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 50),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.orange.shade900)),
        ],
      ),
      content: Text(
        content,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('تراجع', style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: () {
                  onConfirm();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم الحذف بنجاح', style: GoogleFonts.cairo()),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text('تأكيد الحذف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}



Widget _buildListItem({required bool isDarkMode, required String title, required String subtitle, required IconData icon, required Color color, String? photoUrl, VoidCallback? onTap, VoidCallback? onDelete, VoidCallback? onEdit, VoidCallback? onAttendance, VoidCallback? onResetDevice}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
          blurRadius: 15,
          offset: const Offset(0, 8),
        )
      ],
      border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
    ),
    child: Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
          leading: Builder(
            builder: (ctx) => GestureDetector(
              onTap: () {
                if (photoUrl != null && photoUrl.isNotEmpty) {
                  showFullScreenImageViewer(ctx, photoUrl, title);
                } else if (onTap != null) {
                  onTap();
                }
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? DataService().getAvatarImageProvider(photoUrl) : null,
                child: (photoUrl ?? '').isEmpty
                    ? Text(
                        title.isNotEmpty ? title[0] : 'ط',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18),
                      )
                    : null,
              ),
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15, height: 1.2),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onResetDevice != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: InkWell(
                    onTap: onResetDevice,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phonelink_erase_rounded, color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "ضبط الجهاز",
                            style: GoogleFonts.cairo(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (onAttendance != null)
                _buildActionCircle(Icons.how_to_reg_rounded, Colors.indigo, onAttendance),
              if (onEdit != null)
                _buildActionCircle(Icons.edit_rounded, Colors.blue, onEdit),
              if (onDelete != null)
                _buildActionCircle(Icons.delete_rounded, Colors.redAccent, onDelete),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionCircle(IconData icon, Color color, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    ),
  );
}

Widget _buildActionHeader({
  required BuildContext context, 
  required bool isDarkMode, 
  required VoidCallback onAddManual, 
  required VoidCallback onAddExcel, 
  VoidCallback? onAutoUpload,
  required Function(String) onSearch, 
  bool showExcel = true, 
  String addLabel = "إضافة يدوي", 
  String type = 'student', 
  required DataService ds
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
    decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 5))]),
    child: Column(children: [
      Row(children: [
        Expanded(child: Container(height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF512DA8)])), child: ElevatedButton.icon(onPressed: onAddManual, icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20), label: Text(addLabel, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent)))),
        if (showExcel) ...[
          const SizedBox(width: 12), 
          Expanded(
            child: Container(
              height: 50, 
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF388E3C)])), 
              child: ElevatedButton.icon(
                onPressed: () => _showExcelOptions(context, isDarkMode, type, onAddExcel, ds, onAutoUpload: onAutoUpload), 
                icon: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 20), 
                label: Text('خيارات Excel', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent)
              )
            )
          )
        ],
      ]),
      const SizedBox(height: 15),
      Container(height: 45, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: isDarkMode ? Colors.black26 : Colors.grey.shade100, borderRadius: BorderRadius.circular(15)), child: TextField(onChanged: onSearch, style: GoogleFonts.cairo(fontSize: 13), decoration: InputDecoration(hintText: 'ابحث بالاسم...', hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13), border: InputBorder.none, icon: const Icon(Icons.search_rounded, color: Color(0xFF673AB7), size: 20)))),
    ]),
  );
}

void _showExcelOptions(BuildContext context, bool isDark, String type, VoidCallback onUpload, DataService ds, {VoidCallback? onAutoUpload}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        child: ListView(
          controller: scrollController,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Center(child: Text('خيارات الإكسيل والرفع السريع', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.file_upload_rounded, color: Colors.white)),
              title: Text('رفع ملف إكسيل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              subtitle: Text('اختر ملف إكسيل من جهازك لرفعه مباشرة', style: GoogleFonts.cairo(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                onUpload();
              },
            ),
            if (onAutoUpload != null) ...[
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF673AB7), child: Icon(Icons.flash_on_rounded, color: Colors.white)),
                title: Text('رفع طلاب وهميين بنقرة واحدة ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF673AB7))),
                subtitle: Text('رفع دفعة طلاب تجريبية تلقائياً لكل الفرق والشعب دون ملف إكسيل', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  onAutoUpload();
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.file_download_rounded, color: Colors.white)),
              title: Text('تحميل نموذج الإكسيل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              subtitle: Text('حمل النموذج واعرف الترتيب الصحيح للأعمدة لتجنب الأخطاء', style: GoogleFonts.cairo(fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                if (type == 'student') {
                  await ExcelHelper.downloadStudentTemplate(ds.isArabic);
                } else if (type == 'doctor') {
                  await ExcelHelper.downloadDoctorTemplate(ds.isArabic);
                }
              },
            ),
            if (type == 'student') ...[
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF673AB7), child: Icon(Icons.cloud_upload_rounded, color: Colors.white)),
                title: Text('رفع طلاب الفرقة الأولى (نظم معلومات) تلقائياً ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF673AB7))),
                subtitle: Text('رفع 605 طالباً للفرقة الأولى (نظم) بكلمة مرور 123456', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoUploadFirstYearNuzumStudents(context, ds);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF3F51B5), child: Icon(Icons.cloud_upload_rounded, color: Colors.white)),
                title: Text('رفع طلاب الفرقة الأولى (محاسبة ومراجعة) تلقائياً ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF3F51B5))),
                subtitle: Text('رفع 812 طالباً للفرقة الأولى (عام) بكلمة مرور 123456', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoUploadFirstYearGeneralStudents(context, ds);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF009688), child: Icon(Icons.cloud_upload_rounded, color: Colors.white)),
                title: Text('رفع طلاب الفرقة الثانية (نظم معلومات) تلقائياً ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF009688))),
                subtitle: Text('رفع 582 طالباً للفرقة الثانية (نظم) بكلمة مرور 123456', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoUploadSecondYearNuzumStudents(context, ds);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF00BCD4), child: Icon(Icons.cloud_upload_rounded, color: Colors.white)),
                title: Text('رفع طلاب الفرقة الثانية (محاسبة ومراجعة) تلقائياً ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF00BCD4))),
                subtitle: Text('رفع 412 طالباً للفرقة الثانية (عام) بكلمة مرور 123456', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoUploadSecondYearGeneralStudents(context, ds);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFF9800), child: Icon(Icons.cloud_upload_rounded, color: Colors.white)),
                title: Text('رفع طلاب الفرقة الثالثة (نظم معلومات) تلقائياً ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFFFF9800))),
                subtitle: Text('رفع 292 طالباً للفرقة الثالثة (نظم) بكلمة مرور 123456', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoUploadThirdYearNuzumStudents(context, ds);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE91E63), child: Icon(Icons.cloud_upload_rounded, color: Colors.white)),
                title: Text('رفع طلاب الفرقة الثالثة (محاسبة ومراجعة) تلقائياً ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFFE91E63))),
                subtitle: Text('رفع 350 طالباً للفرقة الثالثة (عام) بكلمة مرور 123456', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoUploadThirdYearGeneralStudents(context, ds);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF673AB7), child: Icon(Icons.cloud_upload_rounded, color: Colors.white)),
                title: Text('رفع طلاب الفرقة الرابعة (نظم معلومات) تلقائياً ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF673AB7))),
                subtitle: Text('رفع 249 طالباً للفرقة الرابعة بكلمة مرور 123456 بضغطة زر واحدة', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoUploadFourthYearStudents(context, ds);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF9C27B0), child: Icon(Icons.cloud_upload_rounded, color: Colors.white)),
                title: Text('رفع طلاب الفرقة الرابعة (محاسبة ومراجعة) تلقائياً ⚡', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF9C27B0))),
                subtitle: Text('رفع 334 طالباً للفرقة الرابعة (عام) بكلمة مرور 123456', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoUploadFourthYearGeneralStudents(context, ds);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.delete_sweep_rounded, color: Colors.white)),
                title: Text('حذف جميع الطلاب نهائياً 🗑️', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: Text('مسح كل بيانات الطلاب من قاعدة البيانات لإضافة بيانات حقيقية', style: GoogleFonts.cairo(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: Text('تحذير خطير', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.red)),
                      content: Text('هل أنت متأكد من حذف جميع الطلاب من قاعدة البيانات؟ لا يمكن التراجع عن هذا الإجراء.', style: GoogleFonts.cairo()),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('إلغاء')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ds.deleteAllStudents();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف جميع الطلاب نهائياً من فايربيس بنجاح 🗑️'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red));
                      }
                    }
                  }
                },
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}

void _autoUploadFirstYearNuzumStudents(BuildContext context, DataService ds) async {
  if (ds.selectedInstituteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final studentsList = FirstYearNuzumStudents.list;
  int totalStudents = studentsList.length;
  int progressCount = 0;
  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setS) {
        dialogSetState = setS;
        return AlertDialog(
          backgroundColor: ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF673AB7)),
                const SizedBox(height: 20),
                Text(
                  "جاري رفع $totalStudents طالباً للفرقة الأولى (نظم معلومات الأعمال)...",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: totalStudents > 0 ? progressCount / totalStudents : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withAlpha(40),
                    color: const Color(0xFF673AB7),
                  ),
                ),
                const SizedBox(height: 12),
                Text("$progressCount من $totalStudents", style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    ),
  );

  for (var s in studentsList) {
    String sId = s['id'] ?? '';
    String sName = s['name'] ?? '';
    String sDivision = s['division'] ?? 'نظم معلومات الأعمال';

    if (sId.isNotEmpty && sName.isNotEmpty) {
      try {
        await ds.addStudentManual('level_1', sId, sName, "", sDivision, "123456", notify: false);
        progressCount++;
        if (dialogSetState != null) dialogSetState!(() {});
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        debugPrint("Error uploading student $sId: $e");
      }
    }
  }

  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم رفع جميع طلاب الفرقة الأولى (نظم) بنجاح ($progressCount طالب)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

void _autoUploadFirstYearGeneralStudents(BuildContext context, DataService ds) async {
  if (ds.selectedInstituteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final studentsList = FirstYearGeneralStudents.list;
  int totalStudents = studentsList.length;
  int progressCount = 0;
  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setS) {
        dialogSetState = setS;
        return AlertDialog(
          backgroundColor: ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF3F51B5)),
                const SizedBox(height: 20),
                Text(
                  "جاري رفع $totalStudents طالباً للفرقة الأولى (المحاسبة والمراجعة)...",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: totalStudents > 0 ? progressCount / totalStudents : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withAlpha(40),
                    color: const Color(0xFF3F51B5),
                  ),
                ),
                const SizedBox(height: 12),
                Text("$progressCount من $totalStudents", style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    ),
  );

  for (var s in studentsList) {
    String sId = s['id'] ?? '';
    String sName = s['name'] ?? '';
    String sDivision = s['division'] ?? 'المحاسبة والمراجعة';

    if (sId.isNotEmpty && sName.isNotEmpty) {
      try {
        await ds.addStudentManual('level_1', sId, sName, "", sDivision, "123456", notify: false);
        progressCount++;
        if (dialogSetState != null) dialogSetState!(() {});
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        debugPrint("Error uploading student $sId: $e");
      }
    }
  }

  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم رفع جميع طلاب الفرقة الأولى (عام) بنجاح ($progressCount طالب)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

void _autoUploadSecondYearNuzumStudents(BuildContext context, DataService ds) async {
  if (ds.selectedInstituteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()), backgroundColor: Colors.orange));
    return;
  }
  final studentsList = SecondYearNuzumStudents.list;
  int totalStudents = studentsList.length;
  int progressCount = 0;
  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setS) {
        dialogSetState = setS;
        return AlertDialog(
          backgroundColor: ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF009688)),
                const SizedBox(height: 20),
                Text("جاري رفع $totalStudents طالباً للفرقة الثانية (نظم معلومات الأعمال)...", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: totalStudents > 0 ? progressCount / totalStudents : 0, minHeight: 8, backgroundColor: Colors.grey.withAlpha(40), color: const Color(0xFF009688)),
                ),
                const SizedBox(height: 12),
                Text("$progressCount من $totalStudents", style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    ),
  );

  for (var s in studentsList) {
    String sId = s['id'] ?? '';
    String sName = s['name'] ?? '';
    String sDivision = s['division'] ?? 'نظم معلومات الأعمال';
    if (sId.isNotEmpty && sName.isNotEmpty) {
      try {
        await ds.addStudentManual('level_2', sId, sName, "", sDivision, "123456", notify: false);
        progressCount++;
        if (dialogSetState != null) dialogSetState!(() {});
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        debugPrint("Error uploading student $sId: $e");
      }
    }
  }

  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم رفع جميع طلاب الفرقة الثانية (نظم) بنجاح ($progressCount طالب)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
    );
  }
}

void _autoUploadSecondYearGeneralStudents(BuildContext context, DataService ds) async {
  if (ds.selectedInstituteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()), backgroundColor: Colors.orange));
    return;
  }
  final studentsList = SecondYearGeneralStudents.list;
  int totalStudents = studentsList.length;
  int progressCount = 0;
  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setS) {
        dialogSetState = setS;
        return AlertDialog(
          backgroundColor: ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00BCD4)),
                const SizedBox(height: 20),
                Text("جاري رفع $totalStudents طالباً للفرقة الثانية (المحاسبة والمراجعة)...", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: totalStudents > 0 ? progressCount / totalStudents : 0, minHeight: 8, backgroundColor: Colors.grey.withAlpha(40), color: const Color(0xFF00BCD4)),
                ),
                const SizedBox(height: 12),
                Text("$progressCount من $totalStudents", style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    ),
  );

  for (var s in studentsList) {
    String sId = s['id'] ?? '';
    String sName = s['name'] ?? '';
    String sDivision = s['division'] ?? 'المحاسبة والمراجعة';
    if (sId.isNotEmpty && sName.isNotEmpty) {
      try {
        await ds.addStudentManual('level_2', sId, sName, "", sDivision, "123456", notify: false);
        progressCount++;
        if (dialogSetState != null) dialogSetState!(() {});
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        debugPrint("Error uploading student $sId: $e");
      }
    }
  }

  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم رفع جميع طلاب الفرقة الثانية (عام) بنجاح ($progressCount طالب)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
    );
  }
}

void _autoUploadThirdYearNuzumStudents(BuildContext context, DataService ds) async {
  if (ds.selectedInstituteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()), backgroundColor: Colors.orange));
    return;
  }
  final studentsList = ThirdYearNuzumStudents.list;
  int totalStudents = studentsList.length;
  int progressCount = 0;
  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setS) {
        dialogSetState = setS;
        return AlertDialog(
          backgroundColor: ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFFF9800)),
                const SizedBox(height: 20),
                Text("جاري رفع $totalStudents طالباً للفرقة الثالثة (نظم معلومات الأعمال)...", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: totalStudents > 0 ? progressCount / totalStudents : 0, minHeight: 8, backgroundColor: Colors.grey.withAlpha(40), color: const Color(0xFFFF9800)),
                ),
                const SizedBox(height: 12),
                Text("$progressCount من $totalStudents", style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    ),
  );

  for (var s in studentsList) {
    String sId = s['id'] ?? '';
    String sName = s['name'] ?? '';
    String sDivision = s['division'] ?? 'نظم معلومات الأعمال';
    if (sId.isNotEmpty && sName.isNotEmpty) {
      try {
        await ds.addStudentManual('level_3', sId, sName, "", sDivision, "123456", notify: false);
        progressCount++;
        if (dialogSetState != null) dialogSetState!(() {});
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        debugPrint("Error uploading student $sId: $e");
      }
    }
  }

  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم رفع جميع طلاب الفرقة الثالثة (نظم) بنجاح ($progressCount طالب)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
    );
  }
}

void _autoUploadThirdYearGeneralStudents(BuildContext context, DataService ds) async {
  if (ds.selectedInstituteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()), backgroundColor: Colors.orange));
    return;
  }
  final studentsList = ThirdYearGeneralStudents.list;
  int totalStudents = studentsList.length;
  int progressCount = 0;
  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setS) {
        dialogSetState = setS;
        return AlertDialog(
          backgroundColor: ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFE91E63)),
                const SizedBox(height: 20),
                Text("جاري رفع $totalStudents طالباً للفرقة الثالثة (المحاسبة والمراجعة)...", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: totalStudents > 0 ? progressCount / totalStudents : 0, minHeight: 8, backgroundColor: Colors.grey.withAlpha(40), color: const Color(0xFFE91E63)),
                ),
                const SizedBox(height: 12),
                Text("$progressCount من $totalStudents", style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    ),
  );

  for (var s in studentsList) {
    String sId = s['id'] ?? '';
    String sName = s['name'] ?? '';
    String sDivision = s['division'] ?? 'المحاسبة والمراجعة';
    if (sId.isNotEmpty && sName.isNotEmpty) {
      try {
        await ds.addStudentManual('level_3', sId, sName, "", sDivision, "123456", notify: false);
        progressCount++;
        if (dialogSetState != null) dialogSetState!(() {});
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        debugPrint("Error uploading student $sId: $e");
      }
    }
  }

  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم رفع جميع طلاب الفرقة الثالثة (عام) بنجاح ($progressCount طالب)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
    );
  }
}

void _autoUploadFourthYearGeneralStudents(BuildContext context, DataService ds) async {
  if (ds.selectedInstituteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()), backgroundColor: Colors.orange));
    return;
  }
  final studentsList = FourthYearGeneralStudents.list;
  int totalStudents = studentsList.length;
  int progressCount = 0;
  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setS) {
        dialogSetState = setS;
        return AlertDialog(
          backgroundColor: ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF9C27B0)),
                const SizedBox(height: 20),
                Text("جاري رفع $totalStudents طالباً للفرقة الرابعة (المحاسبة والمراجعة)...", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: totalStudents > 0 ? progressCount / totalStudents : 0, minHeight: 8, backgroundColor: Colors.grey.withAlpha(40), color: const Color(0xFF9C27B0)),
                ),
                const SizedBox(height: 12),
                Text("$progressCount من $totalStudents", style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    ),
  );

  for (var s in studentsList) {
    String sId = s['id'] ?? '';
    String sName = s['name'] ?? '';
    String sDivision = s['division'] ?? 'المحاسبة والمراجعة';
    if (sId.isNotEmpty && sName.isNotEmpty) {
      try {
        await ds.addStudentManual('level_4', sId, sName, "", sDivision, "123456", notify: false);
        progressCount++;
        if (dialogSetState != null) dialogSetState!(() {});
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        debugPrint("Error uploading student $sId: $e");
      }
    }
  }

  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم رفع جميع طلاب الفرقة الرابعة (عام) بنجاح ($progressCount طالب)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
    );
  }
}

void _autoUploadFourthYearStudents(BuildContext context, DataService ds) async {
  if (ds.selectedInstituteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final studentsList = FourthYearBisStudents.list;
  int totalStudents = studentsList.length;
  int progressCount = 0;
  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setS) {
        dialogSetState = setS;
        return AlertDialog(
          backgroundColor: ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF673AB7)),
                const SizedBox(height: 20),
                Text(
                  "جاري رفع $totalStudents طالباً للفرقة الرابعة (نظم معلومات الاعمال)...",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: totalStudents > 0 ? progressCount / totalStudents : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withAlpha(40),
                    color: const Color(0xFF673AB7),
                  ),
                ),
                const SizedBox(height: 12),
                Text("$progressCount من $totalStudents", style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    ),
  );

  for (var s in studentsList) {
    String sId = s['id'] ?? '';
    String sName = s['name'] ?? '';

    if (sId.isNotEmpty && sName.isNotEmpty) {
      try {
        await ds.addStudentManual('level_4', sId, sName, "", "نظم معلومات الأعمال", "123456", notify: false);
        progressCount++;
        if (dialogSetState != null) dialogSetState!(() {});
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint("Error uploading student $sId: $e");
      }
    }
  }

  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم رفع جميع طلاب الفرقة الرابعة بنجاح ($progressCount طالب)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

void _showStyledBS({required BuildContext context, required bool isDarkMode, required String title, required IconData icon, required Color color, required List<Widget> children, required VoidCallback onSave}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 25, right: 25, top: 15),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 25),
          CircleAvatar(radius: 35, backgroundColor: color.withAlpha(30), child: Icon(icon, color: color, size: 35)),
          const SizedBox(height: 15),
          Text(title, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ...children,
          const SizedBox(height: 30),
          Container(
            width: double.infinity, height: 55,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [color, color.withAlpha(200)]), boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 15, offset: const Offset(0, 8))]),
            child: ElevatedButton(onPressed: onSave, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text('حفظ البيانات', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    ),
  );
}

Widget _buildInputField(bool isDarkMode, TextEditingController c, String label, IconData icon, {bool isPass = false, bool isNumber = false, bool enabled = true}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(color: isDarkMode ? Colors.black26 : Colors.grey.shade100, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.withAlpha(30))),
    child: TextField(
      controller: c, obscureText: isPass, style: GoogleFonts.cairo(fontSize: 13),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      enabled: enabled,
      decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13), prefixIcon: Icon(icon, color: const Color(0xFF673AB7), size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
    ),
  );
}

Widget _buildDropdown(bool isDarkMode, String hint, IconData icon, List<DropdownMenuItem<String>> items, Function(String?) onChange, {String? value}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: isDarkMode ? Colors.black26 : Colors.grey.shade100, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.withAlpha(30))),
    child: DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: GoogleFonts.cairo(fontSize: 13)),
      decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(icon, color: const Color(0xFF673AB7), size: 20)),
      items: items, onChanged: onChange,
    ),
  );
}

// --- Specific Management Views ---

class ManagersManagementView extends StatefulWidget {
  const ManagersManagementView({super.key});
  @override
  State<ManagersManagementView> createState() => _ManagersManagementViewState();
}

class _ManagersManagementViewState extends State<ManagersManagementView> {
  final DataService _ds = DataService();
  String _searchQuery = "";

  void _showAddManagerBS() async {
    final nameC = TextEditingController();
    final idC = TextEditingController();
    final passC = TextEditingController();
    List<String> selectedLvls = [];
    var lvlsSnap = await _ds.commerceLevelsColl.get();

    _showStyledBS(
      context: context,
      isDarkMode: _ds.isDarkMode,
      title: 'إضافة مدير جديد',
      icon: Icons.admin_panel_settings_rounded,
      color: Colors.orange,
      children: [
        _buildInputField(_ds.isDarkMode, nameC, 'اسم المدير', Icons.person_rounded),
        _buildInputField(_ds.isDarkMode, idC, 'كود المدير (للدخول)', Icons.badge_rounded, isNumber: true),
        _buildInputField(_ds.isDarkMode, passC, 'كلمة المرور', Icons.lock_rounded, isPass: true),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('اختر الفرق التي يديرها:', style: TextStyle(fontWeight: FontWeight.bold))),
        StatefulBuilder(builder: (ctx, setS) => Column(children: [
          Wrap(
            spacing: 8,
            children: lvlsSnap.docs.map((l) {
              bool isSel = selectedLvls.contains(l.id);
              return FilterChip(
                label: Text(l['name'], style: GoogleFonts.cairo(fontSize: 12)),
                selected: isSel,
                selectedColor: Colors.orange.withAlpha(50),
                onSelected: (v) => setS(() => v ? selectedLvls.add(l.id) : selectedLvls.remove(l.id)),
              );
            }).toList(),
          ),
        ])),
      ],
      onSave: () async {
        if (nameC.text.isNotEmpty && idC.text.isNotEmpty) {
          await _ds.addManager(nameC.text, idC.text, passC.text, managedLevels: selectedLvls);
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _pickAndUploadManagersExcel() async {
    List<List<String>> rows = await ExcelHelper.pickAndParseExcel();
    if (rows.isNotEmpty) {
      int count = 0;
      for (var row in rows) {
        if (row.length < 2) continue;
        String mId = row[0];
        if (mId.contains('(')) mId = mId.split('(').last.split(')').first;
        
        String mName = row[1];
        String mPass = (row.length > 2) ? row[2] : '123456';
        List<String> managedLevels = [];
        for (int j = 3; j < row.length; j++) {
          String lvlText = row[j];
          if (lvlText.isNotEmpty) {
             String lvlNum = _ds.normalizeLevel(lvlText);
             managedLevels.add('level_$lvlNum');
          }
        }
        if (mId.isNotEmpty) { 
          try {
            await _ds.addManager(mName, mId, mPass, managedLevels: managedLevels); 
            count++; 
            await Future.delayed(const Duration(milliseconds: 300));
          } catch(e) { debugPrint("Error adding manager $mId: $e"); }
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع $count مدير بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionHeader(
          context: context,
          isDarkMode: _ds.isDarkMode,
          onAddManual: _showAddManagerBS,
          onAddExcel: _pickAndUploadManagersExcel,
          onSearch: (v) => setState(() => _searchQuery = v),
          showExcel: true,
          addLabel: "إضافة مدير جديد",
          ds: _ds,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.commerceManagersColl.snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snap.data!.docs.where((d) {
                var data = d.data() as Map<String, dynamic>;
                return (data['name'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.admin_panel_settings_outlined, size: 80, color: Colors.grey.withAlpha(50)), const SizedBox(height: 10), Text('لا يوجد مديرين حالياً', style: GoogleFonts.cairo(color: Colors.grey))]));

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  var docItem = docs[i];
                  var d = docItem.data() as Map<String, dynamic>;
                  return RepaintBoundary(
                    key: ValueKey<String>(docItem.id),
                    child: _buildListItem(
                      isDarkMode: _ds.isDarkMode, 
                      title: d['name'] ?? 'بدون اسم', 
                      subtitle: 'كود: ${d['email'].toString().split('@')[0]}\nيدير: ${List.from(d['managedLevels'] ?? []).join(', ')}', 
                      icon: Icons.admin_panel_settings_rounded, 
                      color: Colors.orange, 
                      onDelete: () => _confirmGeneralDelete(context, 'حذف مدير', 'هل أنت متأكد من حذف هذا المدير؟', () => _ds.deleteManager(docItem.id))
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class LevelsManagementView extends StatefulWidget {
  const LevelsManagementView({super.key});
  @override
  State<LevelsManagementView> createState() => _LevelsManagementViewState();
}

class _LevelsManagementViewState extends State<LevelsManagementView> {
  final DataService _ds = DataService();
  String _searchQuery = "";

  void _showAddLevelBS() {
    final idC = TextEditingController();
    final nameC = TextEditingController();
    _showStyledBS(
      context: context,
      isDarkMode: _ds.isDarkMode,
      title: 'إضافة فرقة جديدة',
      icon: Icons.layers_rounded,
      color: Colors.blue,
      children: [
        _buildInputField(_ds.isDarkMode, idC, 'كود الفرقة (للسيستم)', Icons.code),
        _buildInputField(_ds.isDarkMode, nameC, 'اسم الفرقة بالعربي', Icons.text_fields_rounded),
      ],
      onSave: () {
        if (idC.text.isNotEmpty && nameC.text.isNotEmpty) {
          _ds.addLevel(idC.text, nameC.text, null);
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _pickAndUploadLevelsExcel() async {
    List<List<String>> rows = await ExcelHelper.pickAndParseExcel();
    if (rows.isNotEmpty) {
      int count = 0;
      for (var row in rows) {
        if (row.length < 2) continue;
        String lId = row[0];
        String lName = row[1];
        if (lId.isNotEmpty && lName.isNotEmpty) {
          await _ds.addLevel(lId, lName, null);
          count++;
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع $count فرقة بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green));
    }
  }

  void _confirmDelete(String levelId, String levelName) {
    final passC = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text('تنبيه أمني', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('أنت على وشك حذف "$levelName" نهائياً. سيتم مسح جميع الطلاب والمواد المرتبطة بها!', 
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 20),
            _buildInputField(_ds.isDarkMode, passC, 'اكتب كلمة سر الحذف للتأكيد', Icons.lock_person_rounded, isPass: true),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: Text('تراجع', style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold))
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (passC.text.trim() == "102030") {
                      await _ds.deleteLevel(levelId);
                      if (mounted) {
                         Navigator.pop(ctx);
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('تم حذف الفرقة بنجاح'), backgroundColor: Colors.green)
                         );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('كلمة السر خاطئة!'), backgroundColor: Colors.red)
                      );
                    }
                  },
                  child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionHeader(
          context: context,
          isDarkMode: _ds.isDarkMode, 
          onAddManual: _showAddLevelBS, 
          onAddExcel: _pickAndUploadLevelsExcel, 
          onSearch: (v) => setState(() => _searchQuery = v), 
          showExcel: true, 
          addLabel: "إضافة فرقة",
          ds: _ds,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.commerceLevelsColl.orderBy('createdAt', descending: true).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: snap.data!.docs.length,
                itemBuilder: (ctx, i) {
                  var d = snap.data!.docs[i];
                  return RepaintBoundary(
                    key: ValueKey<String>(d.id),
                    child: _buildListItem(
                      isDarkMode: _ds.isDarkMode,
                      title: d['name'],
                      subtitle: 'كود: ${d.id}',
                      icon: Icons.layers_rounded,
                      color: Colors.blue,
                      onAttendance: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceManagementScreen())), 
                      onDelete: () => _confirmDelete(d.id, d['name']),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class SectionsManagementView extends StatefulWidget {
  const SectionsManagementView({super.key});
  @override
  State<SectionsManagementView> createState() => _SectionsManagementViewState();
}

class _SectionsManagementViewState extends State<SectionsManagementView> {
  final DataService _ds = DataService();

  void _showAddSectionBS(String levelId) {
    final nameC = TextEditingController();
    _showStyledBS(
      context: context,
      isDarkMode: _ds.isDarkMode,
      title: 'إضافة شعبة جديدة',
      icon: Icons.grid_view_rounded,
      color: Colors.cyan,
      children: [_buildInputField(_ds.isDarkMode, nameC, 'اسم الشعبة', Icons.grid_on_rounded)],
      onSave: () {
        if (nameC.text.isNotEmpty) {
          _ds.addSection(levelId, nameC.text);
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.commerceLevelsColl.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snap.data!.docs.length,
          itemBuilder: (ctx, i) {
            var lvl = snap.data!.docs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ExpansionTile(
                leading: CircleAvatar(backgroundColor: Colors.cyan.withAlpha(30), child: const Icon(Icons.folder_shared, color: Colors.cyan)),
                title: Text('شعب ${lvl['name']}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _ds.getCommerceSectionsColl(lvl.id).snapshots(),
                    builder: (ctx, sSnap) {
                      if (!sSnap.hasData) return const LinearProgressIndicator();
                      return Column(children: [
                        ...sSnap.data!.docs.map((s) => ListTile(
                          title: Text(s['name']), 
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red), 
                            onPressed: () => _confirmGeneralDelete(context, 'حذف شعبة', 'هل أنت متأكد من حذف هذه الشعبة؟', () => s.reference.delete())
                          )
                        )),
                        TextButton.icon(onPressed: () => _showAddSectionBS(lvl.id), icon: const Icon(Icons.add_circle_outline), label: const Text('إضافة شعبة جديدة'))
                      ]);
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class StudentsManagementView extends StatefulWidget {
  const StudentsManagementView({super.key});
  @override
  State<StudentsManagementView> createState() => _StudentsManagementViewState();
}

class _StudentsManagementViewState extends State<StudentsManagementView> {
  final DataService _ds = DataService();
  String _searchQuery = "";

  String? _selectedLevelId;
  String? _selectedLevelName;
  String? _selectedSection;

  Widget _buildStudentContent(bool isDark) {
    if (_selectedLevelId == null) {
      return FutureBuilder<QuerySnapshot>(
        future: _ds.commerceLevelsColl.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var levels = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              var lvl = levels[index];
              String lvlId = lvl.id;
              String lvlName = lvl['name'] ?? lvlId;
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 15), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: CircleAvatar(backgroundColor: const Color(0xFF4CAF50).withAlpha(30), child: const Icon(Icons.layers_rounded, color: Color(0xFF4CAF50))),
                  title: Text(lvlName, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('انقر لعرض الشعب والشصص التابعة لهذه الفرقة', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => setState(() {
                    _selectedLevelId = lvlId;
                    _selectedLevelName = lvlName;
                    _selectedSection = null;
                  }),
                ),
              );
            },
          );
        },
      );
    } else if (_selectedSection == null) {
      return StreamBuilder<QuerySnapshot>(
        stream: _ds.getCommerceSectionsColl(_selectedLevelId!).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var sections = snapshot.data!.docs;
          List<String> divisions = sections.isNotEmpty 
              ? sections.map((s) => s['name'].toString()).toList()
              : ['نظم معلومات الأعمال', 'المحاسبة والمراجعة'];

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: divisions.length,
            itemBuilder: (context, index) {
              String divName = divisions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 15), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: CircleAvatar(backgroundColor: Colors.blue.withAlpha(30), child: const Icon(Icons.grid_view_rounded, color: Colors.blue)),
                  title: Text(divName, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text('عرض طلاب شعبة $divName', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => setState(() => _selectedSection = divName),
                ),
              );
            },
          );
        },
      );
    } else {
      return StreamBuilder<QuerySnapshot>(
        stream: _ds.studentsColl.snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          
          String cleanLevel = _selectedLevelId != null ? _ds.normalizeLevel(_selectedLevelId!) : '';

          var docs = snap.data!.docs.where((d) {
            var data = d.data() as Map<String, dynamic>;
            String sLvl = _ds.normalizeLevel(data['level']?.toString() ?? '');
            String sDiv = (data['division'] ?? '').toString().trim();
            String targetDiv = (_selectedSection ?? '').trim();

            bool levelMatch = _selectedLevelId == null ||
                (sLvl == cleanLevel) ||
                (data['level']?.toString() == _selectedLevelId || data['level']?.toString() == _selectedLevelId!.replaceAll('level_', ''));

            String normSDiv = sDiv.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').toLowerCase();
            String normTargetDiv = targetDiv.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').toLowerCase();

            bool divMatch = targetDiv.isEmpty ||
                normSDiv == normTargetDiv ||
                normSDiv.contains(normTargetDiv) ||
                normTargetDiv.contains(normSDiv);

            String sName = (data['name'] ?? '').toString().toLowerCase();
            String sId = (data['id'] ?? '').toString();
            bool searchMatch = _searchQuery.isEmpty || sName.contains(_searchQuery.toLowerCase()) || sId.contains(_searchQuery);

            return levelMatch && divMatch && searchMatch;
          }).toList();

          docs.sort((a, b) => (a.data() as Map<String, dynamic>)['name'].toString().compareTo((b.data() as Map<String, dynamic>)['name'].toString()));

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("إجمالي الطلاب للشعبة:", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                      child: Text("${docs.length} طالب", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  ],
                ),
              ),
              if (docs.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 80, color: Colors.grey.withAlpha(50)),
                        const SizedBox(height: 10),
                        Text('لا يوجد طلاب في هذه الشعبة حالياً', style: GoogleFonts.cairo(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      var d = docs[i].data() as Map<String, dynamic>;
                      return _buildListItem(
                        isDarkMode: isDark, 
                        title: d['name'] ?? 'بدون اسم', 
                        subtitle: 'ID: ${d['id']} | الفرقة ${d['level']} | ${d['division']}', 
                        icon: Icons.school_rounded, 
                        color: Colors.green, 
                        photoUrl: d['photoUrl'],
                        onTap: () => showRichStudentProfileModal(
                          context: context,
                          studentIdOrUid: docs[i].id,
                          studentName: d['name'],
                          initialStudentData: d,
                        ),
                        onResetDevice: () => _confirmGeneralDelete(
                          context,
                          'إعادة ضبط الجهاز',
                          'هل أنت متأكد من فك ربط جهاز الطالب (${d['name']})؟',
                          () => _ds.resetStudentDevice(docs[i].id),
                        ),
                        onDelete: () => _confirmGeneralDelete(
                          context,
                          'حذف طالب',
                          'هل أنت متأكد من حذف هذا الطالب؟',
                          () => _ds.deleteStudent(docs[i].id, d['level']?.toString() ?? '1'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      );
    }
  }

  void _showAddStudentBS() async {
    final nameC = TextEditingController();
    final idC = TextEditingController();
    final passC = TextEditingController();
    String? selLvl = _selectedLevelId;
    String? selDiv = _selectedSection;
    List<String> divs = [];
    
    if (selLvl != null) {
      var sSnap = await _ds.getCommerceSectionsColl(selLvl).get();
      divs = sSnap.docs.map((d) => d['name'].toString()).toList();
    }
    
    var lvls = await _ds.commerceLevelsColl.get();

    if (!mounted) return;

    _showStyledBS(
      context: context,
      isDarkMode: _ds.isDarkMode,
      title: 'تسجيل طالب جديد',
      icon: Icons.person_add_alt_1_rounded,
      color: const Color(0xFF4CAF50),
      children: [
        StatefulBuilder(builder: (ctx, setS) => Column(children: [
          if (_selectedLevelId == null) ...[
            _buildDropdown(_ds.isDarkMode, 'اختر الفرقة الدراسية', Icons.layers_outlined, lvls.docs.map((l) => DropdownMenuItem(value: l.id, child: Text(l['name']))).toList(), (v) async {
              setS(() => selLvl = v);
              var sSnap = await _ds.getCommerceSectionsColl(v!).get();
              setS(() => divs = sSnap.docs.map((d) => d['name'].toString()).toList());
            }, value: selLvl),
            const SizedBox(height: 15),
          ],
          if (_selectedSection == null) ...[
            _buildDropdown(_ds.isDarkMode, 'اختر الشعبة', Icons.grid_view_rounded, divs.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), (v) => setS(() => selDiv = v), value: selDiv),
            const SizedBox(height: 15),
          ],
        ])),
        _buildInputField(_ds.isDarkMode, nameC, 'اسم الطالب الرباعي', Icons.person_outline_rounded),
        _buildInputField(_ds.isDarkMode, idC, 'كود الطالب (ID)', Icons.badge_outlined, isNumber: true),
        _buildInputField(_ds.isDarkMode, passC, 'كلمة المرور', Icons.lock_outline_rounded, isPass: true),
      ],
      onSave: () async {
        if (selLvl != null && selDiv != null && nameC.text.isNotEmpty && idC.text.isNotEmpty) {
          await _ds.addStudentManual(selLvl!, idC.text, nameC.text, "", selDiv!, passC.text.isEmpty ? "123456" : passC.text);
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _pickAndUploadStudentsExcel() async {
    List<List<String>> rows = await ExcelHelper.pickAndParseExcel();
    if (rows.isNotEmpty) {
      int count = 0;
      for (var row in rows) {
        if (row.length < 2) continue;
        
        String sId = row[0];
        if (sId.contains('(')) sId = sId.split('(').last.split(')').first;

        String sName = row[1];
        String sLevel = (row.length > 2) ? row[2] : '1';
        String sDiv = (row.length > 3) ? row[3] : 'عام';
        String sPass = (row.length > 4) ? row[4] : '123456';
        
        if (sId.isNotEmpty && sName.isNotEmpty) { 
          try {
            String cleanLvlNum = _ds.normalizeLevel(sLevel);
            await _ds.addStudentManual('level_$cleanLvlNum', sId, sName, "", sDiv, sPass); 
            count++; 
            await Future.delayed(const Duration(milliseconds: 300));
          } catch(e) { debugPrint("Error student $sId: $e"); }
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع $count طالب بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green));
    }
  }

  Future<void> _autoUploadFakeStudents() async {
    if (_ds.selectedInstituteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار الكلية أولاً من أعلى الشاشة', style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int totalStudents = 100;
    int progressCount = 0;
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) {
          dialogSetState = setS;
          return AlertDialog(
            backgroundColor: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF673AB7)),
                  const SizedBox(height: 20),
                  Text(
                    "جاري رفع 100 طالب موزعين على جميع الفرق...",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressCount / totalStudents,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withAlpha(40),
                      color: const Color(0xFF673AB7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "تم رفع $progressCount من $totalStudents طالب",
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    List<String> firstNames = [
      "أحمد", "محمد", "محمود", "عمر", "يوسف", "علي", "مصطفى", "عبدالله", "إبراهيم", "حسن",
      "حسين", "خالد", "سعيد", "طارق", "كريم", "ياسين", "عبدالرحمن", "حمزة", "زياد", "بلال",
      "فاطمة", "مريم", "آية", "نور", "سارة", "هاجر", "سلمى", "ياسمين", "زينب", "منة الله"
    ];

    List<String> lastNames = [
      "أحمد", "محمد", "حسن", "علي", "محمود", "السيد", "إبراهيم", "مصطفى", "صلاح", "جمال",
      "منصور", "عبدالعزيز", "الشريف", "العوضي", "الشناوي", "عبدالحليم", "سليمان", "البدري", "الشيخ", "رضوان"
    ];

    List<String> divisionsList = ["نظم معلومات الاعمال", "محاسبه", "ادارة اعمال"];

    int successCount = 0;
    String lastError = "";
    int timeBase = (DateTime.now().millisecondsSinceEpoch % 800000) + 100000;

    for (int i = 0; i < totalStudents; i++) {
      String studentId = "2025${timeBase + i}";
      
      String fn = firstNames[i % firstNames.length];
      String sn = lastNames[(i * 3 + 1) % lastNames.length];
      String tn = lastNames[(i * 5 + 2) % lastNames.length];
      String fam = lastNames[(i * 7 + 3) % lastNames.length];
      String studentName = "$fn $sn $tn $fam";

      int levelNum = (i % 4) + 1;
      String levelId = "level_$levelNum";
      String div = divisionsList[i % divisionsList.length];

      try {
        await _ds.addStudentManual(levelId, studentId, studentName, "", div, "123456");
        successCount++;
      } catch (e) {
        debugPrint("Auto upload error for student $studentId: $e");
        lastError = e.toString();
      }

      progressCount++;
      if (dialogSetState != null) {
        dialogSetState!(() {});
      }
      await Future.delayed(const Duration(milliseconds: 25));
    }

    if (mounted) {
      Navigator.pop(context);
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم رفع $successCount طالب بنجاح موزعين على الفرقة 1 و 2 و 3 و 4! 🚀', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ تعذر الرفع: $lastError', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildBreadcrumb() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: _ds.isDarkMode ? Colors.white10 : Colors.blue.withAlpha(10),
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(30))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() { _selectedLevelId = null; _selectedSection = null; }),
            child: Text("إدارة الطلاب", style: GoogleFonts.cairo(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          if (_selectedLevelId != null) ...[
            const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
            InkWell(
              onTap: () => setState(() { _selectedSection = null; }),
              child: Text(_selectedLevelName ?? "", style: GoogleFonts.cairo(color: _selectedSection == null ? Colors.grey : Colors.blue)),
            ),
          ],
          if (_selectedSection != null) ...[
            const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
            Text(_selectedSection!, style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = _ds.isDarkMode;
    return Column(
      children: [
        _buildActionHeader(
          context: context,
          isDarkMode: isDark, 
          onAddManual: _showAddStudentBS, 
          onAddExcel: _pickAndUploadStudentsExcel, 
          onAutoUpload: _autoUploadFakeStudents,
          onSearch: (v) => setState(() => _searchQuery = v),
          type: 'student',
          ds: _ds,
        ),
        _buildBreadcrumb(),
        Expanded(
          child: _buildStudentContent(isDark),
        ),
      ],
    );
  }
}

class ScheduleManagementView extends StatefulWidget {
  const ScheduleManagementView({super.key});
  @override
  State<ScheduleManagementView> createState() => _ScheduleManagementViewState();
}

class _ScheduleManagementViewState extends State<ScheduleManagementView> {
  final DataService _ds = DataService();
  String? _selectedLevelId = 'level_1';
  String _selectedDivision = 'نظم معلومات الأعمال';

  void _showAddScheduleModal(BuildContext context) {
    final subjectC = TextEditingController();
    final timeC = TextEditingController(text: '09:00 ص');
    final hallC = TextEditingController();
    final doctorC = TextEditingController();
    String dayName = 'السبت';
    String type = 'محاضرة';

    _showStyledBS(
      context: context,
      isDarkMode: _ds.isDarkMode,
      title: 'إضافة محاضرة رسمية',
      icon: Icons.calendar_today_rounded,
      color: Colors.indigo,
      children: [
        _buildDropdown(_ds.isDarkMode, 'اليوم', Icons.calendar_view_day_rounded, ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), (v) => dayName = v ?? 'السبت', value: dayName),
        const SizedBox(height: 15),
        _buildDropdown(_ds.isDarkMode, 'النوع', Icons.category_rounded, ['محاضرة', 'سكشن'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), (v) => type = v ?? 'محاضرة', value: type),
        const SizedBox(height: 15),
        _buildInputField(_ds.isDarkMode, subjectC, 'اسم المادة', Icons.book_rounded),
        _buildInputField(_ds.isDarkMode, timeC, 'الوقت (مثال: 09:00 ص)', Icons.access_time_rounded),
        _buildInputField(_ds.isDarkMode, hallC, 'القاعة / المكان', Icons.room_rounded),
        _buildInputField(_ds.isDarkMode, doctorC, 'الدكتور / المحاضر', Icons.person_rounded),
      ],
      onSave: () async {
        if (subjectC.text.isNotEmpty && _selectedLevelId != null) {
          await _ds.addOfficialSchedule(
            levelId: _selectedLevelId!,
            division: _selectedDivision,
            item: {
              'subject': subjectC.text,
              'dayName': dayName,
              'time': timeC.text,
              'type': type,
              'hall': hallC.text,
              'doctor': doctorC.text,
              'isOfficial': true,
            },
          );
          if (context.mounted) Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = _ds.isDarkMode;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLevelId,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  decoration: InputDecoration(labelText: 'الفرقة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  items: const [
                    DropdownMenuItem(value: 'level_1', child: Text('الفرقة الأولى')),
                    DropdownMenuItem(value: 'level_2', child: Text('الفرقة الثانية')),
                    DropdownMenuItem(value: 'level_3', child: Text('الفرقة الثالثة')),
                    DropdownMenuItem(value: 'level_4', child: Text('الفرقة الرابعة')),
                  ],
                  onChanged: (v) => setState(() => _selectedLevelId = v),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDivision,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  decoration: InputDecoration(labelText: 'الشعبة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  items: const [
                    DropdownMenuItem(value: 'نظم معلومات الأعمال', child: Text('نظم معلومات الأعمال')),
                    DropdownMenuItem(value: 'المحاسبة والمراجعة', child: Text('المحاسبة والمراجعة')),
                    DropdownMenuItem(value: 'الكل', child: Text('جميع الشعب')),
                  ],
                  onChanged: (v) => setState(() => _selectedDivision = v ?? 'الكل'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            icon: const Icon(Icons.add),
            label: Text('إضافة محاضرة رسمية جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            onPressed: () => _showAddScheduleModal(context),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.getOfficialScheduleStream(levelId: _selectedLevelId),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snap.data!.docs.where((d) {
                var data = d.data() as Map<String, dynamic>;
                String div = (data['division'] ?? '').toString();
                return _selectedDivision == 'الكل' || div == _selectedDivision || div.isEmpty;
              }).toList();

              if (docs.isEmpty) {
                return Center(child: Text('لا توجد محاضرات مسجلة لهذه الفرقة والشعبة', style: GoogleFonts.cairo(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  var d = docs[i].data() as Map<String, dynamic>;
                  return Card(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.menu_book_rounded, color: Colors.white)),
                      title: Text(d['subject'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      subtitle: Text('${d['dayName']} - ${d['time']} | ${d['type']}\nالقاعة: ${d['hall'] ?? '--'} | د: ${d['doctor'] ?? '--'}', style: GoogleFonts.cairo(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _ds.deleteOfficialSchedule(docs[i].id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class DoctorsManagementView extends StatefulWidget {
  const DoctorsManagementView({super.key});
  @override
  State<DoctorsManagementView> createState() => _DoctorsManagementViewState();
}

class _DoctorsManagementViewState extends State<DoctorsManagementView> {
  final DataService _ds = DataService();
  String _searchQuery = "";

  void _showDoctorForm({DocumentSnapshot? doc}) async {
    final data = doc?.data() as Map<String, dynamic>?;
    final nameC = TextEditingController(text: data?['name']);
    final idC = TextEditingController(text: data?['id']);
    final passC = TextEditingController();
    List<String> selectedLvls = List<String>.from(data?['teachingLevels'] ?? []);
    var lvlsSnap = await _ds.commerceLevelsColl.get();

    _showStyledBS(
      context: context,
      isDarkMode: _ds.isDarkMode,
      title: doc == null ? 'إضافة دكتور جديد' : 'تعديل بيانات الدكتور',
      icon: Icons.person_add_rounded,
      color: Colors.pink,
      children: [
        _buildInputField(_ds.isDarkMode, nameC, 'اسم الدكتور', Icons.person_rounded),
        _buildInputField(_ds.isDarkMode, idC, 'كود الدكتور (ID)', Icons.badge_rounded, isNumber: true, enabled: doc == null),
        if (doc == null) _buildInputField(_ds.isDarkMode, passC, 'كلمة المرور', Icons.lock_rounded, isPass: true),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('اختر الفرق التي يدرس لها:', style: TextStyle(fontWeight: FontWeight.bold))),
        StatefulBuilder(builder: (ctx, setS) => Column(children: [
          Wrap(
            spacing: 8,
            children: lvlsSnap.docs.map((l) {
              bool isSel = selectedLvls.contains(l.id);
              return FilterChip(
                label: Text(l['name'], style: GoogleFonts.cairo(fontSize: 12)),
                selected: isSel,
                selectedColor: Colors.pink.withAlpha(50),
                onSelected: (v) => setS(() => v ? selectedLvls.add(l.id) : selectedLvls.remove(l.id)),
              );
            }).toList(),
          ),
        ])),
      ],
      onSave: () async {
        if (idC.text.isNotEmpty && nameC.text.isNotEmpty) {
          if (doc == null) {
            await _ds.addDoctor(idC.text, nameC.text, "", selectedLvls, [], passC.text.isEmpty ? '123456' : passC.text);
          } else {
            await doc.reference.update({
              'name': nameC.text,
              'teachingLevels': selectedLvls,
            });
          }
          if (mounted) Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _pickAndUploadDoctorsExcel() async {
    List<List<String>> rows = await ExcelHelper.pickAndParseExcel();
    if (rows.isNotEmpty) {
      int count = 0;
      for (var row in rows) {
        if (row.length < 2) continue;
        
        String dId = row[0];
        if (dId.contains('(')) dId = dId.split('(').last.split(')').first;

        String dName = row[1];
        String dPass = (row.length > 2) ? row[2] : '123456';
        
        List<String> teachingLevels = [];
        for (int j = 3; j < row.length; j++) {
          String lvlText = row[j];
          if (lvlText.isNotEmpty) {
             String lvlNum = _ds.normalizeLevel(lvlText);
             teachingLevels.add('level_$lvlNum');
          }
        }
        if (dId.isNotEmpty) { 
          try {
            await _ds.addDoctor(dId, dName, "", teachingLevels, [], dPass); 
            count++; 
            await Future.delayed(const Duration(milliseconds: 300));
          } catch(e) { debugPrint("Error adding doctor $dId: $e"); }
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع $count دكتور بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionHeader(
          context: context,
          isDarkMode: _ds.isDarkMode, 
          onAddManual: () => _showDoctorForm(), 
          onAddExcel: _pickAndUploadDoctorsExcel, 
          onSearch: (v) => setState(() => _searchQuery = v),
          type: 'doctor',
          ds: _ds,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.commerceDoctorsColl.snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snap.data!.docs.where((d) => (d.data() as Map)['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  var d = docs[i].data() as Map<String, dynamic>;
                  return _buildListItem(
                    isDarkMode: _ds.isDarkMode,
                    title: d['name'] ?? 'بدون اسم',
                    subtitle: 'كود: ${d['id']}\nيدرس لفرق: ${List.from(d['teachingLevels'] ?? []).join(', ')}',
                    icon: Icons.person_rounded,
                    color: Colors.pink,
                    onDelete: () => _confirmGeneralDelete(context, 'حذف دكتور', 'هل أنت متأكد من حذف هذا الدكتور؟', () => _ds.deleteDoctor(docs[i].id)),
                    onEdit: () => _showDoctorForm(doc: docs[i]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class SemestersManagementView extends StatefulWidget {
  const SemestersManagementView({super.key});
  @override
  State<SemestersManagementView> createState() => _SemestersManagementViewState();
}

class _SemestersManagementViewState extends State<SemestersManagementView> {
  final DataService _ds = DataService();
  String _searchQuery = "";

  void _showAddSemesterBS() {
    final nameC = TextEditingController();
    final orderC = TextEditingController();
    _showStyledBS(
      context: context,
      isDarkMode: _ds.isDarkMode,
      title: 'إضافة فصل دراسي',
      icon: Icons.calendar_month_rounded,
      color: Colors.blueGrey,
      children: [
        _buildInputField(_ds.isDarkMode, nameC, 'اسم الفصل (ترم أول 2024)', Icons.text_fields_rounded),
        _buildInputField(_ds.isDarkMode, orderC, 'الترتيب (1، 2، إلخ)', Icons.format_list_numbered_rounded, isNumber: true),
      ],
      onSave: () async {
        if (nameC.text.isNotEmpty) {
          await _ds.addSemester(DateTime.now().millisecondsSinceEpoch.toString(), nameC.text, int.tryParse(orderC.text) ?? 1);
          if (mounted) Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _pickAndUploadSemestersExcel() async {
    List<List<String>> rows = await ExcelHelper.pickAndParseExcel();
    if (rows.isNotEmpty) {
      int count = 0;
      for (var row in rows) {
        if (row.length < 2) continue;
        String sId = row[0];
        String sName = row[1];
        int sOrder = (row.length > 2) ? int.tryParse(row[2]) ?? 1 : 1;
        if (sId.isNotEmpty && sName.isNotEmpty) {
          await _ds.addSemester(sId, sName, sOrder);
          count++;
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع $count فصل دراسي بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionHeader(
          context: context,
          isDarkMode: _ds.isDarkMode, 
          onAddManual: _showAddSemesterBS, 
          onAddExcel: _pickAndUploadSemestersExcel, 
          onSearch: (v) => setState(() => _searchQuery = v), 
          showExcel: true, 
          addLabel: "إضافة فصل دراسي",
          ds: _ds,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.commerceSemestersColl.snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: snap.data!.docs.length,
                itemBuilder: (ctx, i) {
                  var d = snap.data!.docs[i].data() as Map<String, dynamic>;
                  return _buildListItem(
                    isDarkMode: _ds.isDarkMode, 
                    title: d['name'] ?? '', 
                    subtitle: 'الترتيب: ${d['order']}', 
                    icon: Icons.calendar_month_rounded, 
                    color: Colors.blueGrey, 
                    onDelete: () => _confirmGeneralDelete(context, 'حذف فصل دراسي', 'هل أنت متأكد من حذف هذا الفصل الدراسي؟', () => _ds.deleteSemester(snap.data!.docs[i].id))
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class TAsManagementView extends StatefulWidget {
  const TAsManagementView({super.key});
  @override
  State<TAsManagementView> createState() => _TAsManagementViewState();
}

class _TAsManagementViewState extends State<TAsManagementView> {
  final DataService _ds = DataService();
  String _searchQuery = "";

  void _showTAForm({DocumentSnapshot? doc}) async {
    final data = doc?.data() as Map<String, dynamic>?;
    final nameC = TextEditingController(text: data?['name']);
    final idC = TextEditingController(text: data?['id']);
    final passC = TextEditingController();
    List<String> selectedLvls = List<String>.from(data?['teachingLevels'] ?? []);
    var lvlsSnap = await _ds.commerceLevelsColl.get();

    _showStyledBS(
      context: context,
      isDarkMode: _ds.isDarkMode,
      title: doc == null ? 'إضافة معيد جديد' : 'تعديل بيانات المعيد',
      icon: Icons.person_add_alt_1_rounded,
      color: Colors.teal,
      children: [
        _buildInputField(_ds.isDarkMode, nameC, 'اسم المعيد', Icons.person_rounded),
        _buildInputField(_ds.isDarkMode, idC, 'كود المعيد (ID)', Icons.badge_rounded, isNumber: true, enabled: doc == null),
        if (doc == null) _buildInputField(_ds.isDarkMode, passC, 'كلمة المرور', Icons.lock_rounded, isPass: true),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('اختر الفرق التي يدرب فيها:', style: TextStyle(fontWeight: FontWeight.bold))),
        StatefulBuilder(builder: (ctx, setS) => Column(children: [
          Wrap(
            spacing: 8,
            children: lvlsSnap.docs.map((l) {
              bool isSel = selectedLvls.contains(l.id);
              return FilterChip(
                label: Text(l['name'], style: GoogleFonts.cairo(fontSize: 12)),
                selected: isSel,
                selectedColor: Colors.teal.withAlpha(50),
                onSelected: (v) => setS(() => v ? selectedLvls.add(l.id) : selectedLvls.remove(l.id)),
              );
            }).toList(),
          ),
        ])),
      ],
      onSave: () async {
        if (idC.text.isNotEmpty && nameC.text.isNotEmpty) {
          if (doc == null) {
            await _ds.addTA(idC.text, nameC.text, "", selectedLvls, [], passC.text.isEmpty ? '123456' : passC.text);
          } else {
            await doc.reference.update({
              'name': nameC.text,
              'teachingLevels': selectedLvls,
            });
          }
          if (mounted) Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _pickAndUploadTAsExcel() async {
    List<List<String>> rows = await ExcelHelper.pickAndParseExcel();
    if (rows.isNotEmpty) {
      int count = 0;
      for (var row in rows) {
        if (row.length < 2) continue;
        
        String dId = row[0];
        if (dId.contains('(')) dId = dId.split('(').last.split(')').first;

        String dName = row[1];
        String dPass = (row.length > 2) ? row[2] : '123456';
        
        List<String> teachingLevels = [];
        for (int j = 3; j < row.length; j++) {
          String lvlText = row[j];
          if (lvlText.isNotEmpty) {
             String lvlNum = _ds.normalizeLevel(lvlText);
             teachingLevels.add('level_$lvlNum');
          }
        }
        if (dId.isNotEmpty) { 
          try {
            await _ds.addTA(dId, dName, "", teachingLevels, [], dPass); 
            count++; 
            await Future.delayed(const Duration(milliseconds: 300));
          } catch(e) { debugPrint("Error adding TA $dId: $e"); }
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع $count معيد بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionHeader(
          context: context,
          isDarkMode: _ds.isDarkMode, 
          onAddManual: () => _showTAForm(), 
          onAddExcel: _pickAndUploadTAsExcel, 
          onSearch: (v) => setState(() => _searchQuery = v),
          type: 'doctor',
          ds: _ds,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.commerceTasColl.snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snap.data!.docs.where((d) => (d.data() as Map)['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  var d = docs[i].data() as Map<String, dynamic>;
                  return _buildListItem(
                    isDarkMode: _ds.isDarkMode,
                    title: d['name'] ?? 'بدون اسم',
                    subtitle: 'كود: ${d['id']}\nيدرب لفرق: ${List.from(d['teachingLevels'] ?? []).join(', ')}',
                    icon: Icons.person_outline_rounded,
                    color: Colors.teal,
                    onDelete: () => _confirmGeneralDelete(context, 'حذف معيد', 'هل أنت متأكد من حذف هذا المعيد؟', () => _ds.deleteTA(docs[i].id)),
                    onEdit: () => _showTAForm(doc: docs[i]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
