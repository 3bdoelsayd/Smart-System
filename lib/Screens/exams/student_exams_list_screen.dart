import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';
import 'take_exam_screen.dart';
import 'exam_result_screen.dart';

class StudentExamsListScreen extends StatefulWidget {
  const StudentExamsListScreen({super.key});

  @override
  State<StudentExamsListScreen> createState() => _StudentExamsListScreenState();
}

class _StudentExamsListScreenState extends State<StudentExamsListScreen> with SingleTickerProviderStateMixin {
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _studentLevel => _ds.currentStudent?['level']?.toString() ?? '1';
  String get _studentSection => _ds.currentStudent?['division']?.toString() ?? 'all';
  String get _studentUid => _ds.currentStudent?['uid'] ?? _ds.currentStudent?['id'] ?? '';
  String get _studentId => _ds.currentStudent?['id']?.toString() ?? '';

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
            isAr ? 'الاختبارات والكويزات' : 'Exams & Quizzes',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: isDark ? primaryColor : Colors.white,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.cairo(),
            labelColor: isDark ? primaryColor : Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.white70,
            tabs: [
              Tab(text: isAr ? 'المتاحة الآن' : 'Open Now'),
              Tab(text: isAr ? 'القادمة' : 'Upcoming'),
              Tab(text: isAr ? 'المكتملة' : 'Completed'),
              Tab(text: isAr ? 'المغلقة' : 'Closed'),
            ],
          ),
        ),
        body: StreamBuilder<List<ExamModel>>(
          stream: _examService.getExamsStreamForStudent(_studentLevel, _studentSection),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allExams = snapshot.data ?? [];

            return FutureBuilder<List<ExamSubmissionModel>>(
              future: Future.wait(
                allExams.map((e) => _examService.getStudentSubmission(e.id, _studentUid, studentId: _studentId)),
              ).then((list) => list.whereType<ExamSubmissionModel>().toList()),
              builder: (context, subSnap) {
                if (subSnap.connectionState == ConnectionState.waiting && !subSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final submissions = subSnap.data ?? [];
                final submittedExamIds = submissions.map((s) => s.examId).toSet();
                final subMap = {for (var s in submissions) s.examId: s};
                final now = DateTime.now();

                final openExams = allExams.where((e) =>
                    !submittedExamIds.contains(e.id) &&
                    now.isAfter(e.startTime) &&
                    now.isBefore(e.endTime)).toList();

                final upcomingExams = allExams.where((e) =>
                    !submittedExamIds.contains(e.id) &&
                    now.isBefore(e.startTime)).toList();

                final completedExams = allExams.where((e) =>
                    submittedExamIds.contains(e.id)).toList();

                final closedExams = allExams.where((e) =>
                    !submittedExamIds.contains(e.id) &&
                    now.isAfter(e.endTime)).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExamsList(openExams, subMap, 'open', isAr, isDark, primaryColor),
                    _buildExamsList(upcomingExams, subMap, 'upcoming', isAr, isDark, primaryColor),
                    _buildExamsList(completedExams, subMap, 'completed', isAr, isDark, primaryColor),
                    _buildExamsList(closedExams, subMap, 'closed', isAr, isDark, primaryColor),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildExamsList(
    List<ExamModel> list,
    Map<String, ExamSubmissionModel> subMap,
    String category,
    bool isAr,
    bool isDark,
    Color primaryColor,
  ) {
    if (list.isEmpty) {
      String msg = '';
      IconData icon = Icons.assignment_outlined;

      if (category == 'open') {
        msg = isAr ? 'لا توجد اختبارات متاحة لك حالياً' : 'No open exams right now';
        icon = Icons.alarm_off_rounded;
      } else if (category == 'upcoming') {
        msg = isAr ? 'لا توجد اختبارات قادمة محددة' : 'No upcoming exams';
        icon = Icons.event_available_rounded;
      } else if (category == 'completed') {
        msg = isAr ? 'لم تقم بإكمال أي اختبار بعد' : 'No completed exams yet';
        icon = Icons.check_circle_outline_rounded;
      } else {
        msg = isAr ? 'لا توجد اختبارات مغلقة' : 'No closed exams';
        icon = Icons.lock_clock_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: isDark ? Colors.white24 : Colors.grey.withAlpha(80)),
            const SizedBox(height: 16),
            Text(
              msg,
              style: GoogleFonts.cairo(fontSize: 16, color: isDark ? Colors.white54 : Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final exam = list[index];
        final submission = subMap[exam.id];
        return _buildExamCard(exam, submission, category, isAr, isDark, primaryColor);
      },
    );
  }

  Widget _buildExamCard(
    ExamModel exam,
    ExamSubmissionModel? submission,
    String category,
    bool isAr,
    bool isDark,
    Color primaryColor,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');

    Color statusColor = Colors.green;
    String statusLabel = isAr ? 'متاح الآن' : 'Open Now';

    if (category == 'upcoming') {
      statusColor = Colors.orange;
      statusLabel = isAr ? 'قادم' : 'Upcoming';
    } else if (category == 'open') {
      statusColor = Colors.green;
      statusLabel = isAr ? 'متاح الآن' : 'Open Now';
    } else if (category == 'completed') {
      statusColor = Colors.blue;
      statusLabel = isAr ? 'تم التسليم' : 'Submitted';
    } else {
      statusColor = Colors.red;
      statusLabel = isAr ? 'مغلق' : 'Closed';
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
                    statusLabel,
                    style: GoogleFonts.cairo(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                Icon(Icons.timer_rounded, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  "${exam.durationMinutes} ${isAr ? 'دقيقة' : 'min'}",
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),

            if (category == 'upcoming') ...[
              const SizedBox(height: 8),
              ExamCountdownTimer(
                targetTime: exam.startTime,
                isOpening: true,
                isAr: isAr,
                color: statusColor,
              ),
            ] else if (category == 'open') ...[
              const SizedBox(height: 8),
              ExamCountdownTimer(
                targetTime: exam.endTime,
                isOpening: false,
                isAr: isAr,
                color: statusColor,
              ),
            ],

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
                  "${isAr ? 'الدرجة' : 'Total Score'}: ${exam.totalScore.toStringAsFixed(1)}",
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action Buttons
            if (submission != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'لقد قمت بأداء هذا الاختبار' : 'You have completed this exam',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          ),
                          Text(
                            submission.isGraded
                                ? "${isAr ? 'النتيجة النهائية' : 'Final Score'}: ${submission.finalScore.toStringAsFixed(1)} / ${submission.maxScore.toStringAsFixed(1)}"
                                : (isAr ? 'النتيجة الأولية متوفرة، وفي انتظار التقييم المقالي' : 'Auto score ready, essay grading pending'),
                            style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => ExamResultScreen(
                              exam: exam,
                              submission: submission,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isAr ? 'عرض النتيجة' : 'View Score', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else if (category == 'open') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _confirmStartExam(exam);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    isAr ? 'بدء الاختبار الآن' : 'Start Exam Now',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else if (category == 'upcoming') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isAr ? 'سوف ينطلق الاختبار في الموعد الموضح أعلاه' : 'Exam will open at scheduled time',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isAr ? 'انتهى موعد الاختبار ولم يعد متاحاً' : 'Exam is closed',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmStartExam(ExamModel exam) {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          isAr ? 'بدء الاختبار' : 'Start Exam',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'هل أنت مستعد لبدء اختبار "${exam.title}"؟'
                  : 'Are you ready to start "${exam.title}"?',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              isAr
                  ? '• مدة الاختبار: ${exam.durationMinutes} دقيقة.\n• لديك فرصة واحدة فقط للأداء والتسليم.\n• لا تقم بالخروج أو غلق التطبيق أثناء الاختبار.'
                  : '• Duration: ${exam.durationMinutes} min.\n• Single attempt allowed.\n• Do not exit the app during the exam.',
              style: GoogleFonts.cairo(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => TakeExamScreen(exam: exam),
                ),
              );
            },
            child: Text(isAr ? 'بدء الآن' : 'Start Now', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Isolated Countdown Timer Widget to prevent parent screen flickering
class ExamCountdownTimer extends StatefulWidget {
  final DateTime targetTime;
  final bool isOpening;
  final bool isAr;
  final Color color;

  const ExamCountdownTimer({
    super.key,
    required this.targetTime,
    required this.isOpening,
    required this.isAr,
    required this.color,
  });

  @override
  State<ExamCountdownTimer> createState() => _ExamCountdownTimerState();
}

class _ExamCountdownTimerState extends State<ExamCountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateRemaining();
        });
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    _remaining = widget.targetTime.difference(now);
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    String label = widget.isOpening
        ? (widget.isAr ? 'يبدأ خلال' : 'Starts in')
        : (widget.isAr ? 'ينتهي خلال' : 'Closes in');

    String timeStr = "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 16, color: widget.color),
          const SizedBox(width: 6),
          Text(
            "$label: $timeStr",
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
