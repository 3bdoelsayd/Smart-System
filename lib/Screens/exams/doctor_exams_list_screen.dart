import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';
import 'exam_editor_screen.dart';
import 'question_editor_screen.dart';
import 'exam_results_doctor_screen.dart';

class DoctorExamsListScreen extends StatefulWidget {
  const DoctorExamsListScreen({super.key});

  @override
  State<DoctorExamsListScreen> createState() => _DoctorExamsListScreenState();
}

class _DoctorExamsListScreenState extends State<DoctorExamsListScreen> with SingleTickerProviderStateMixin {
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _doctorUid => _ds.currentDoctor?['uid'] ?? _ds.currentDoctor?['id'] ?? '';

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
            isAr ? 'إدارة الاختبارات والكويزات' : 'Exams & Quizzes',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: isDark ? primaryColor : Colors.white,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.cairo(),
            labelColor: isDark ? primaryColor : Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.white70,
            tabs: [
              Tab(text: isAr ? 'المنشورة' : 'Published'),
              Tab(text: isAr ? 'المسودات' : 'Drafts'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const ExamEditorScreen()),
            );
          },
          backgroundColor: primaryColor,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            isAr ? 'إنشاء اختبار جديد' : 'Create Exam',
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: StreamBuilder<List<ExamModel>>(
          stream: _examService.getExamsStreamForDoctor(_doctorUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final exams = snapshot.data ?? [];
            final publishedExams = exams.where((e) => e.isPublished).toList();
            final draftExams = exams.where((e) => !e.isPublished).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildExamsList(publishedExams, isAr, isDark, primaryColor, isPublishedTab: true),
                _buildExamsList(draftExams, isAr, isDark, primaryColor, isPublishedTab: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExamsList(List<ExamModel> list, bool isAr, bool isDark, Color primaryColor, {required bool isPublishedTab}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPublishedTab ? Icons.assignment_outlined : Icons.drafts_outlined,
              size: 80,
              color: isDark ? Colors.white24 : Colors.grey.withAlpha(80),
            ),
            const SizedBox(height: 16),
            Text(
              isPublishedTab
                  ? (isAr ? 'لا توجد اختبارات منشورة حالياً' : 'No published exams')
                  : (isAr ? 'لا توجد مسودات اختبارات' : 'No draft exams'),
              style: GoogleFonts.cairo(fontSize: 16, color: isDark ? Colors.white54 : Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final exam = list[index];
        return _buildExamCard(exam, isAr, isDark, primaryColor);
      },
    );
  }

  Widget _buildExamCard(ExamModel exam, bool isAr, bool isDark, Color primaryColor) {
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

    final isEditable = !exam.isPublished || now.isBefore(exam.startTime);

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isAr ? 'المدة' : 'Duration'}: ${exam.durationMinutes} ${isAr ? 'دقيقة' : 'min'}",
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    Text(
                      "${isAr ? 'الدرجة الكلية' : 'Total Score'}: ${exam.totalScore.toStringAsFixed(1)}",
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isEditable) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => QuestionEditorScreen(exam: exam),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.quiz_rounded, size: 18),
                      label: Text(
                        isAr ? 'الأسئلة' : 'Questions',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ExamEditorScreen(exam: exam),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                    tooltip: isAr ? 'تعديل البيانات' : 'Edit Exam',
                  ),
                ],
                Expanded(
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
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.analytics_rounded, size: 18),
                    label: Text(
                      isAr ? 'النتائج والتقارير' : 'Results',
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDeleteExam(exam),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: isAr ? 'حذف الاختبار' : 'Delete Exam',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExam(ExamModel exam) {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          isAr ? 'حذف الاختبار' : 'Delete Exam',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من حذف هذا الاختبار بالكامل وبجميع الأسئلة والإجابات المسجلة به؟'
              : 'Are you sure you want to delete this exam and all its questions and submissions?',
          style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _examService.deleteExam(exam.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr ? 'تم حذف الاختبار بنجاح' : 'Exam deleted successfully',
                      style: GoogleFonts.cairo(),
                    ),
                  ),
                );
              }
            },
            child: Text(isAr ? 'حذف' : 'Delete', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
