import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final DataService _ds = DataService();

  void _showEditProfileDialog(BuildContext context, bool isDark) {
    final phoneController = TextEditingController(text: _ds.currentStudent?['phone'] ?? '');
    final photoController = TextEditingController(text: _ds.currentStudent?['photoUrl'] ?? '');
    bool isAr = _ds.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isAr ? "تعديل البيانات والصورة الشخصية" : "Edit Profile", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: isAr ? "رقم الهاتف" : "Phone Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: photoController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: isAr ? "رابط الصورة الشخصية (URL)" : "Photo URL",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? "إلغاء" : "Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF673AB7)),
            onPressed: () async {
              await _ds.updateStudentProfile(
                phone: phoneController.text.trim(),
                photoUrl: photoController.text.trim(),
              );
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: Text(isAr ? "حفظ" : "Save", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;
    
    // الألوان الجديدة للوضع الداكن (رمادي غامق وفيروزي)
    final Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.grey.shade50;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final student = ds.currentStudent;
    final name = student?['name'] ?? (isAr ? 'غير معروف' : 'Unknown');
    final id = student?['id'] ?? '---';
    final level = student?['level'] ?? '---';
    final group = student?['group'] ?? '---';
    final division = student?['division'] ?? '---';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(isAr ? 'الملف الشخصي' : 'Profile'),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: isAr ? 'تعديل البيانات' : 'Edit Profile',
              onPressed: () => _showEditProfileDialog(context, isDark),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- كارت الهوية الرقمي الجديد ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF232323), const Color(0xFF1A1A1A)] 
                      : [primaryColor, primaryColor.withBlue(200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(isDark ? 0.2 : 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (student?['photoUrl'] ?? '').toString().isNotEmpty ? NetworkImage(student!['photoUrl']) : null,
                            child: (student?['photoUrl'] ?? '').toString().isEmpty ? Icon(Icons.person, size: 50, color: primaryColor) : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'ID: $id',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 40),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider(color: Colors.white24, thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCardInfoItem(isAr ? 'المستوى' : 'Level', level.toString()),
                        _buildCardInfoItem(isAr ? 'الفرقة' : 'Division', division.toString()),
                        _buildCardInfoItem(isAr ? 'المجموعة' : 'Group', group.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- معلومات إضافية ---
              _buildInfoCard(
                icon: Icons.email_rounded,
                title: isAr ? 'البريد الأكاديمي' : 'Academic Email',
                value: '$id@university.edu.eg',
                isDark: isDark,
                color: isDark ? const Color(0xFF03DAC6) : Colors.orange,
                surfaceColor: cardColor,
              ),
              const SizedBox(height: 15),
              _buildInfoCard(
                icon: Icons.verified_user_rounded,
                title: isAr ? 'حالة الحساب' : 'Account Status',
                value: isAr ? 'نشط' : 'Active',
                isDark: isDark,
                color: Colors.green,
                surfaceColor: cardColor,
              ),
              const SizedBox(height: 15),
              _buildInfoCard(
                icon: Icons.phone_rounded,
                title: isAr ? 'رقم الهاتف' : 'Phone Number',
                value: student?['phone'] ?? (isAr ? 'غير مسجل (اضغط تعديل)' : 'Not registered'),
                isDark: isDark,
                color: Colors.blue,
                surfaceColor: cardColor,
              ),
              
              const SizedBox(height: 40),
              
              // زر عرض النتائج بتصميم متناسق
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/student/results'),
                  icon: const Icon(Icons.assessment_rounded),
                  label: Text(isAr ? 'عرض النتائج والدرجات' : 'View Results & Grades'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required Color color,
    required Color surfaceColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
