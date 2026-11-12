import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';
import '../private_chat_screen.dart';

class StudentSubmissionDetailScreen extends StatefulWidget {
  final ExamModel exam;
  final ExamSubmissionModel submission;

  const StudentSubmissionDetailScreen({
    super.key,
    required this.exam,
    required this.submission,
  });

  @override
  State<StudentSubmissionDetailScreen> createState() => _StudentSubmissionDetailScreenState();
}

class _StudentSubmissionDetailScreenState extends State<StudentSubmissionDetailScreen> {
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();

  List<QuestionModel> _questions = [];
  bool _isLoadingQuestions = true;
  bool _isSavingGrade = false;

  // Store essay grades: qId -> {'points': TextEditingController, 'comment': TextEditingController}
  final Map<String, TextEditingController> _essayPointsControllers = {};
  final Map<String, TextEditingController> _essayCommentControllers = {};

  @override
  void initState() {
    super.initState();
    _loadQuestionsAndGrades();
  }

  @override
  void dispose() {
    for (var c in _essayPointsControllers.values) {
      c.dispose();
    }
    for (var c in _essayCommentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuestionsAndGrades() async {
    final qList = await _examService.getExamQuestions(widget.exam.id);

    for (var q in qList) {
      if (q.type == QuestionType.essay) {
        final existingGrade = widget.submission.essayGrades[q.id];
        final pts = existingGrade != null ? (existingGrade['points'] ?? 0.0).toString() : '0.0';
        final comment = existingGrade != null ? (existingGrade['comment'] ?? '').toString() : '';

        _essayPointsControllers[q.id] = TextEditingController(text: pts);
        _essayCommentControllers[q.id] = TextEditingController(text: comment);
      }
    }

    if (mounted) {
      setState(() {
        _questions = qList;
        _isLoadingQuestions = false;
      });
    }
  }

  Future<void> _saveEssayGrades() async {
    setState(() => _isSavingGrade = true);

    try {
      final Map<String, Map<String, dynamic>> essayGrades = {};

      for (var q in _questions) {
        if (q.type == QuestionType.essay) {
          final ptsText = _essayPointsControllers[q.id]?.text.trim() ?? '0';
          final commentText = _essayCommentControllers[q.id]?.text.trim() ?? '';
          final double pts = double.tryParse(ptsText) ?? 0.0;

          essayGrades[q.id] = {
            'points': pts > q.points ? q.points : pts,
            'comment': commentText,
          };
        }
      }

      await _examService.gradeEssaySubmission(
        examId: widget.exam.id,
        studentUid: widget.submission.studentUid,
        essayGrades: essayGrades,
        autoScore: widget.submission.autoScore,
        maxScore: widget.exam.totalScore,
        examTitle: widget.exam.title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _ds.isArabic ? 'تم حفظ الدرجات وإرسال الإشعار للطالب بنجاح' : 'Grade saved and student notified!',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Save essay grade error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingGrade = false);
    }
  }

  void _openChatWithStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PrivateChatScreen(
          otherUserId: widget.submission.studentUid,
          otherUserName: widget.submission.studentName,
          otherUserRole: 'student',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;
    final primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final sub = widget.submission;
    final dateFormat = DateFormat('yyyy-MM-dd  hh:mm a');

    final bool hasEssayQuestions = _questions.any((q) => q.type == QuestionType.essay);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            isAr ? 'تفاصيل إجابة الطالب' : 'Student Submission Details',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_rounded),
              onPressed: _openChatWithStudent,
              tooltip: isAr ? 'مراسلة الطالب' : 'Message Student',
            ),
          ],
        ),
        bottomNavigationBar: hasEssayQuestions
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black54 : Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingGrade ? null : _saveEssayGrades,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isSavingGrade
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      isAr ? 'حفظ تصحيح الأسئلة المقالية وإرسال إشعار' : 'Save Essay Grade & Notify',
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: primaryColor.withOpacity(0.15),
                          child: Icon(Icons.person_rounded, size: 30, color: primaryColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.studentName,
                                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                              ),
                              Text(
                                "${isAr ? 'الرقم الجامعي' : 'ID'}: ${sub.studentId}",
                                style: GoogleFonts.cairo(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _openChatWithStudent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.15),
                            foregroundColor: Colors.blue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: Text(isAr ? 'شات' : 'Chat', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'تاريخ التسليم:' : 'Submitted At:',
                              style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                            ),
                            Text(
                              sub.submittedAt != null ? dateFormat.format(sub.submittedAt!) : '--',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isAr ? 'الدرجة المحسوبة:' : 'Total Score:',
                              style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                            ),
                            Text(
                              "${sub.finalScore.toStringAsFixed(1)} / ${widget.exam.totalScore.toStringAsFixed(1)}",
                              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Text(
                isAr ? 'تفاصيل الإجابات والتصحيح:' : 'Answers & Grading Breakdown:',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),

              _isLoadingQuestions
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: List.generate(_questions.length, (index) {
                        final q = _questions[index];
                        return _buildGradingQuestionCard(q, index, sub, isAr, isDark);
                      }),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradingQuestionCard(QuestionModel q, int index, ExamSubmissionModel sub, bool isAr, bool isDark) {
    final studentAns = sub.answers[q.id];

    if (q.type == QuestionType.essay) {
      final pointsController = _essayPointsControllers[q.id];
      final commentController = _essayCommentControllers[q.id];

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${isAr ? 'سؤال مقالي' : 'Essay Q'}${index + 1}",
                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                  ),
                ),
                Text(
                  "${isAr ? 'الدرجة العظمى' : 'Max Points'}: ${q.points}",
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.questionText,
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 12),

            Text(
              isAr ? 'إجابة الطالب المكتوبة:' : 'Student Written Answer:',
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                (studentAns ?? (isAr ? 'لم يكتب الطالب إجابة' : 'No written answer')).toString(),
                style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
              ),
            ),

            const SizedBox(height: 16),

            // Points input & comment input
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: pointsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "${isAr ? 'الدرجة الممنوحة' : 'Awarded Grade'} (max ${q.points})",
                      labelStyle: GoogleFonts.cairo(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: commentController,
                    style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: isAr ? 'ملاحظة للطالب (اختياري)' : 'Comment (Optional)',
                      labelStyle: GoogleFonts.cairo(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // MCQ or True/False question
      bool isCorrect = false;
      if (q.type == QuestionType.mcq) {
        isCorrect = studentAns != null && studentAns.toString() == q.correctAnswer?.toString();
      } else {
        isCorrect = studentAns != null && studentAns.toString().toLowerCase() == q.correctAnswer?.toString().toLowerCase();
      }

      final statusColor = isCorrect ? Colors.green : Colors.red;

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
                  "${isAr ? 'سؤال' : 'Q'}${index + 1} (${q.type == QuestionType.mcq ? 'اختيار متعدد' : 'صح/خطأ'})",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: statusColor),
                ),
                Text(
                  isCorrect ? "+${q.points}" : "0 / ${q.points}",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              q.questionText,
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 8),

            if (q.type == QuestionType.mcq) ...[
              Text(
                "${isAr ? 'إجابة الطالب' : 'Student Answer'}: ${_getMcqText(q, studentAns, isAr)}",
                style: GoogleFonts.cairo(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
              ),
              if (!isCorrect) ...[
                const SizedBox(height: 2),
                Text(
                  "${isAr ? 'الإجابة الصحيحة' : 'Correct Answer'}: ${_getMcqText(q, q.correctAnswer, isAr)}",
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ] else ...[
              Text(
                "${isAr ? 'إجابة الطالب' : 'Student Answer'}: ${studentAns == true ? (isAr ? 'صح' : 'True') : studentAns == false ? (isAr ? 'خطأ' : 'False') : (isAr ? 'بدون إجابة' : 'No answer')}",
                style: GoogleFonts.cairo(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
              ),
              if (!isCorrect) ...[
                const SizedBox(height: 2),
                Text(
                  "${isAr ? 'الإجابة الصحيحة' : 'Correct Answer'}: ${q.correctAnswer == true ? (isAr ? 'صح' : 'True') : (isAr ? 'خطأ' : 'False')}",
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ],
        ),
      );
    }
  }

  String _getMcqText(QuestionModel q, dynamic optIndex, bool isAr) {
    if (optIndex == null) return isAr ? 'لم يمرر إجابة' : 'No answer';
    final idx = int.tryParse(optIndex.toString());
    if (idx != null && idx >= 0 && idx < q.options.length) {
      return q.options[idx];
    }
    return optIndex.toString();
  }
}
