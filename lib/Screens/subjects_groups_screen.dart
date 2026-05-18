import 'package:flutter/material.dart';
import '../services/data_service.dart';

class SubjectsGroupsScreen extends StatelessWidget {
  const SubjectsGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;
    Color primaryColor = const Color(0xFF673AB7);

    // استخدام مواد الطالب الحقيقية من Firebase
    final List<String> subjects = ds.studentSubjects;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          title: Text(isAr ? 'مقرراتي الدراسية' : 'My Courses'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: subjects.isEmpty
            ? Center(
                child: Text(
                  isAr ? 'لم يتم إضافة مواد لفرقتك بعد' : 'No subjects for your level yet',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                itemBuilder: (ctx, i) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.menu_book_rounded, color: primaryColor),
                      ),
                      title: Text(
                        subjects[i],
                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      ),
                      subtitle: Text(isAr ? 'مقرر دراسي معتمد' : 'Official Course'),
                      trailing: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
