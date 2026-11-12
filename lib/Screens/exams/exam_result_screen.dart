import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';

class ExamResultScreen extends StatefulWidget {
  final ExamModel exam;
  final ExamSubmissionModel submission;
  final bool justSubmitted;

  const ExamResultScreen({
    super.key,
    required this.exam,
    required this.submission,
    this.justSubmitted = false,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();

  List<QuestionModel> _questions = [];
  bool _isLoadingQuestions = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final qList = await _examService.getExamQuestions(widget.exam.id);
    if (mounted) {
      setState(() {
        _questions = qList;
        _isLoadingQuestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;
    final primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final sub = widget.submission;

    final double scoreToDisplay = sub.isGraded ? sub.finalScore : sub.autoScore;
    final double maxScore = sub.maxScore > 0 ? sub.maxScore : widget.exam.totalScore;
    final double percentage = maxScore > 0 ? (scoreToDisplay / maxScore) * 100 : 0.0;

    int correctCount = 0;
    int wrongCount = 0;
    int pendingEssayCount = 0;

    for (var q in _questions) {
      final ans = sub.answers[q.id];
      if (q.type == QuestionType.essay) {
        if (!sub.isGraded) pendingEssayCount++;
      } else if (q.type == QuestionType.mcq) {
        if (ans != null && ans.toString() == q.correctAnswer?.toString()) {
          correctCount++;
        } else {
          wrongCount++;
        }
      } else if (q.type == QuestionType.trueFalse) {
        if (ans != null && ans.toString().toLowerCase() == q.correctAnswer?.toString().toLowerCase()) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            isAr ? 'نتيجة الاختبار' : 'Exam Result',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Summary Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (widget.justSubmitted) ...[
                      const Icon(Icons.stars_rounded, size: 50, color: Colors.amber),
                      const SizedBox(height: 8),
                      Text(
                        isAr ? 'تم تسليم الاختبار بنجاح!' : 'Exam Submitted Successfully!',
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      widget.exam.title,
                      style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${scoreToDisplay.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(1)}",
                      style: GoogleFonts.cairo(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "${percentage.toStringAsFixed(1)}%",
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sub.isGraded
                            ? (isAr ? 'النتيجة نهائية ومكتملة' : 'Final Score')
                            : (isAr ? 'درجة أولية (في انتظار تقييم الأسئلة المقالية)' : 'Auto score (Essay grading pending)'),
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: isAr ? 'إجابات صحيحة' : 'Correct',
                      value: "$correctCount",
                      color: Colors.green,
                      icon: Icons.check_circle_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: isAr ? 'إجابات خاطئة' : 'Wrong',
                      value: "$wrongCount",
                      color: Colors.red,
                      icon: Icons.cancel_rounded,
                      isDark: isDark,
                    ),
                  ),
                  if (pendingEssayCount > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: isAr ? 'أسئلة مقالية' : 'Essay Pending',
                        value: "$pendingEssayCount",
                        color: Colors.orange,
                        icon: Icons.hourglass_top_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 25),

              // Detailed Questions Review Header
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isAr ? 'مراجعة التفاصيل والأسئلة:' : 'Questions Breakdown:',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _isLoadingQuestions
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: List.generate(_questions.length, (index) {
                        final q = _questions[index];
                        return _buildQuestionReviewCard(q, index, sub, isAr, isDark);
                      }),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(QuestionModel q, int index, ExamSubmissionModel sub, bool isAr, bool isDark) {
    final studentAns = sub.answers[q.id];
    bool? isCorrect;
    String statusText = '';
    Color statusColor = Colors.grey;

    if (q.type == QuestionType.essay) {
      final essayGrade = sub.essayGrades[q.id];
      if (sub.isGraded && essayGrade != null) {
        final pts = (essayGrade['points'] ?? 0.0).toDouble();
        statusText = "${isAr ? 'درجتك' : 'Score'}: $pts / ${q.points}";
        statusColor = pts > 0 ? Colors.green : Colors.red;
      } else {
        statusText = isAr ? 'في انتظار تصحيح المحاضر' : 'Pending Doctor Grading';
        statusColor = Colors.orange;
      }
    } else if (q.type == QuestionType.mcq) {
      final correctOptIndex = q.correctAnswer;
      final studentOptIndex = studentAns;

      isCorrect = studentOptIndex != null && studentOptIndex.toString() == correctOptIndex.toString();
      statusColor = isCorrect ? Colors.green : Colors.red;
      statusText = isCorrect ? (isAr ? 'صحيحة (+${q.points})' : 'Correct (+${q.points})') : (isAr ? 'خاطئة (0)' : 'Wrong (0)');
    } else if (q.type == QuestionType.trueFalse) {
      isCorrect = studentAns != null && studentAns.toString().toLowerCase() == q.correctAnswer?.toString().toLowerCase();
      statusColor = isCorrect ? Colors.green : Colors.red;
      statusText = isCorrect ? (isAr ? 'صحيحة (+${q.points})' : 'Correct (+${q.points})') : (isAr ? 'خاطئة (0)' : 'Wrong (0)');
    }

    String getMcqOptionText(dynamic optIndex) {
      if (optIndex == null) return isAr ? 'لم تتم الإجابة' : 'No Answer';
      final idx = int.tryParse(optIndex.toString());
      if (idx != null && idx >= 0 && idx < q.options.length) {
        return q.options[idx];
      }
      return optIndex.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${isAr ? 'سؤال' : 'Q'}${index + 1}",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: statusColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.questionText,
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          if (q.type == QuestionType.mcq) ...[
            Text(
              "${isAr ? 'إجابتك' : 'Your Answer'}: ${getMcqOptionText(studentAns)}",
              style: GoogleFonts.cairo(fontSize: 13, color: isCorrect == true ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
            if (isCorrect == false) ...[
              const SizedBox(height: 4),
              Text(
                "${isAr ? 'الإجابة الصحيحة' : 'Correct Answer'}: ${getMcqOptionText(q.correctAnswer)}",
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ],
          if (q.type == QuestionType.trueFalse) ...[
            Text(
              "${isAr ? 'إجابتك' : 'Your Answer'}: ${studentAns == true ? (isAr ? 'صح' : 'True') : studentAns == false ? (isAr ? 'خطأ' : 'False') : (isAr ? 'بدون إجابة' : 'No Answer')}",
              style: GoogleFonts.cairo(fontSize: 13, color: isCorrect == true ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
            if (isCorrect == false) ...[
              const SizedBox(height: 4),
              Text(
                "${isAr ? 'الإجابة الصحيحة' : 'Correct Answer'}: ${q.correctAnswer == true ? (isAr ? 'صح' : 'True') : (isAr ? 'خطأ' : 'False')}",
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ],
          if (q.type == QuestionType.essay) ...[
            Text(
              "${isAr ? 'إجابتك المكتوبة' : 'Your Written Answer'}:",
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                (studentAns ?? (isAr ? 'لا توجد إجابة' : 'No answer written')).toString(),
                style: GoogleFonts.cairo(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (sub.isGraded && sub.essayGrades[q.id]?['comment'] != null) ...[
              const SizedBox(height: 8),
              Text(
                "${isAr ? 'ملاحظة الدكتور' : 'Doctor Comment'}: ${sub.essayGrades[q.id]['comment']}",
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
