import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';
import 'exam_results_doctor_screen.dart';

class ManagerExamsScreen extends StatefulWidget {
  final List<String>? managedLevels;

  const ManagerExamsScreen({super.key, this.managedLevels});

  @override
  State<ManagerExamsScreen> createState() => _ManagerExamsScreenState();
}

class _ManagerExamsScreenState extends State<ManagerExamsScreen> {
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();

  List<String> get _levels {
    if (widget.managedLevels != null && widget.managedLevels!.isNotEmpty) {
      return widget.managedLevels!;
    }
    final admin = _ds.currentAdmin;
    final List<String> list = List<String>.from(admin?['managedLevels'] ?? ['level_1', 'level_2', 'level_3', 'level_4']);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;
    final primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            isAr ? 'مراقبة الكويزات والاختبارات' : 'Exams Monitoring (Read Only)',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: StreamBuilder<List<ExamModel>>(
          stream: _examService.getExamsStreamForManager(_levels),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final exams = snapshot.data ?? [];

            if (exams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 80, color: isDark ? Colors.white24 : Colors.grey.withAlpha(80)),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? 'لا توجد اختبارات منشورة للفرق المسندة إليك' : 'No published exams found',
                      style: GoogleFonts.cairo(fontSize: 16, color: isDark ? Colors.white54 : Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return _buildManagerExamCard(exam, isAr, isDark, primaryColor);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildManagerExamCard(ExamModel exam, bool isAr, bool isDark, Color primaryColor) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final now = DateTime.now();

    Color statusColor = Colors.grey;
    String statusText = isAr ? 'مسودة' : 'Draft';

    if (exam.isPublished) {
      if (now.isBefore(exam.startTime)) {
        statusColor = Colors.orange;
        statusText = isAr ? 'قادم' : 'Upcoming';
      } else if (now.isAfter(exam.endTime)) {
        statusColor = Colors.red;
        statusText = isAr ? 'مغلق' : 'Closed';
      } else {
        statusColor = Colors.green;
        statusText = isAr ? 'متاح الآن' : 'Open Now';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.cairo(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  exam.subject,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(Icons.layers_rounded, size: 16, color: Colors.indigo),
                const SizedBox(width: 4),
                Text(
                  "${isAr ? 'الفرقة' : 'Level'} ${exam.targetLevel.replaceAll('level_', '')}",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "${isAr ? 'بواسطة المحاضر' : 'Created by'}: ${exam.createdByName}",
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${isAr ? 'من' : 'From'}: ${dateFormat.format(exam.startTime)}",
                      style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                    Text(
                      "${isAr ? 'إلى' : 'To'}: ${dateFormat.format(exam.endTime)}",
                      style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                  ],
                ),
                Text(
                  "${isAr ? 'الدرجة الكلية' : 'Total Score'}: ${exam.totalScore.toStringAsFixed(1)}",
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ExamResultsDoctorScreen(exam: exam),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.analytics_rounded, size: 18),
                label: Text(
                  isAr ? 'عرض درجات ونتائج الطلاب' : 'View Student Results',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
