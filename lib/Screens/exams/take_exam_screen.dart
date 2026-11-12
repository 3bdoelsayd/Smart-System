import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';
import 'exam_result_screen.dart';

class TakeExamScreen extends StatefulWidget {
  final ExamModel exam;

  const TakeExamScreen({super.key, required this.exam});

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();
  final PageController _pageController = PageController();

  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  int _currentIndex = 0;

  // Map qId -> student answer (int index for MCQ, bool for T/F, String for Essay)
  final Map<String, dynamic> _answers = {};

  // For storing shuffled option mapping per MCQ question: qId -> List<String> shuffledOptions
  final Map<String, List<String>> _shuffledMcqOptions = {};

  // Countdown Timer
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  String get _studentUid => _ds.currentStudent?['uid'] ?? _ds.currentStudent?['id'] ?? '';
  String get _studentName => _ds.currentStudent?['name'] ?? 'طالب';
  String get _studentId => _ds.currentStudent?['id']?.toString() ?? '';
  String get _studentLevel => _ds.currentStudent?['level']?.toString() ?? '1';
  String get _studentSection => _ds.currentStudent?['division']?.toString() ?? 'all';

  String get _cacheKey => 'exam_answers_${widget.exam.id}_$_studentUid';

  @override
  void initState() {
    super.initState();
    _initExam();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initExam() async {
    setState(() => _isLoading = true);

    try {
      // 0. Check if student already submitted
      final existingSub = await _examService.getStudentSubmission(widget.exam.id, _studentUid, studentId: _studentId);
      if (existingSub != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => ExamResultScreen(
              exam: widget.exam,
              submission: existingSub,
            ),
          ),
        );
        return;
      }

      // 1. Fetch questions from Firestore
      final rawQuestions = await _examService.getExamQuestions(widget.exam.id);

      // 2. Shuffle questions randomly per student
      final shuffledList = List<QuestionModel>.from(rawQuestions)..shuffle();

      // 3. Shuffle MCQ options per question for this student
      for (var q in shuffledList) {
        if (q.type == QuestionType.mcq && q.options.isNotEmpty) {
          final opts = List<String>.from(q.options)..shuffle();
          _shuffledMcqOptions[q.id] = opts;
        }
      }

      // 4. Restore any locally cached answers from offline storage
      await _restoreCachedAnswers();

      // 5. Calculate remaining time based on server start time or duration
      final serverNow = await _examService.getServerTime();
      final totalSeconds = widget.exam.durationMinutes * 60;
      final elapsed = serverNow.difference(widget.exam.startTime).inSeconds;

      int remaining = totalSeconds;
      if (elapsed > 0) {
        remaining = totalSeconds - elapsed;
      }
      if (remaining <= 0) {
        remaining = 5; // minimum safety fallback if exam is expiring
      }

      _remainingSeconds = remaining;

      _startTimer();

      if (mounted) {
        setState(() {
          _questions = shuffledList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Init exam error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
        _autoSubmitOnTimeout();
      }
    });
  }

  Future<void> _restoreCachedAnswers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        _answers.addAll(decoded);
      }
    } catch (e) {
      debugPrint("Error restoring cached answers: $e");
    }
  }

  Future<void> _cacheAnswersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_answers));
    } catch (e) {
      debugPrint("Error caching answers: $e");
    }
  }

  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }

  void _autoSubmitOnTimeout() {
    if (_isSubmitting) return;
    _submitExam(isAutoSubmit: true);
  }

  Future<void> _submitExam({bool isAutoSubmit = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _countdownTimer?.cancel();

    try {
      // Clean answers: for MCQ, convert student's selected option text back to original option index
      final Map<String, dynamic> processedAnswers = {};

      for (var q in _questions) {
        final ans = _answers[q.id];
        if (ans != null) {
          if (q.type == QuestionType.mcq) {
            // ans is selected option string text
            final originalIndex = q.options.indexOf(ans.toString());
            processedAnswers[q.id] = originalIndex >= 0 ? originalIndex : ans;
          } else {
            processedAnswers[q.id] = ans;
          }
        }
      }

      final submission = await _examService.submitStudentExam(
        examId: widget.exam.id,
        studentUid: _studentUid,
        studentName: _studentName,
        studentId: _studentId,
        level: _studentLevel,
        section: _studentSection,
        answers: processedAnswers,
        questions: _questions,
        maxScore: widget.exam.totalScore,
      );

      await _clearLocalCache();

      if (mounted) {
        if (isAutoSubmit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _ds.isArabic ? 'انتهى الوقت المحدد! تم تسليم إجاباتك تلقائياً.' : 'Time is up! Your exam was auto-submitted.',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => ExamResultScreen(
              exam: widget.exam,
              submission: submission,
              justSubmitted: true,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Submit exam error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_ds.isArabic ? 'حدث خطأ أثناء التسليم. حاول مرة أخرى.' : 'Submission error. Please retry.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return false;

    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          isAr ? 'تنبيه: الخروج من الاختبار' : 'Warning: Leaving Exam',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من رغبتك في الخروج؟ خروجك سيؤدي إلى تسليم إجاباتك الحالية فوراً ولن تتمكن من إعادة دخول الاختبار.'
              : 'Are you sure you want to exit? Exiting will auto-submit your current answers and you cannot re-enter.',
          style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'متابعة الاختبار' : 'Continue Exam', style: GoogleFonts.cairo(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx, true);
              _submitExam();
            },
            child: Text(isAr ? 'تسليم والخروج' : 'Submit & Exit', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _confirmSubmit() {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;

    final answeredCount = _answers.length;
    final totalCount = _questions.length;
    final unansweredCount = totalCount - answeredCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          isAr ? 'تاكيد تسليم الاختبار' : 'Confirm Submission',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'هل أنت متأكد من أنهاء وتسليم الإجابات؟' : 'Are you sure you want to submit your answers?',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  "${isAr ? 'الأسئلة المجابة' : 'Answered'}: $answeredCount / $totalCount",
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "${isAr ? 'أسئلة بدون إجابة' : 'Unanswered'}: $unansweredCount",
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'مراجعة الأسئلة' : 'Review Questions', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam();
            },
            child: Text(isAr ? 'تأكيد التسليم النهائي' : 'Final Submit', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;
    final primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.exam.title,
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remainingSeconds < 180 ? Colors.red.withOpacity(0.2) : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        color: _remainingSeconds < 180 ? Colors.redAccent : Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimer(_remainingSeconds),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _remainingSeconds < 180 ? Colors.redAccent : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _questions.isEmpty
                  ? Center(child: Text(isAr ? 'لا توجد أسئلة في هذا الاختبار' : 'No questions found'))
                  : Column(
                      children: [
                        // Progress Bar
                        LinearProgressIndicator(
                          value: (_currentIndex + 1) / _questions.length,
                          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                          color: Colors.green,
                          minHeight: 6,
                        ),

                        // Header Question Count & Score
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${isAr ? 'السؤال' : 'Question'} ${_currentIndex + 1} ${isAr ? 'من' : 'of'} ${_questions.length}",
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${_questions[_currentIndex].points} ${isAr ? 'درجات' : 'pts'}",
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // PageView with Single Question Card per screen
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _questions.length,
                            physics: const NeverScrollableScrollPhysics(), // Control via Next/Prev buttons
                            onPageChanged: (idx) {
                              setState(() => _currentIndex = idx);
                            },
                            itemBuilder: (context, index) {
                              final q = _questions[index];
                              return _buildSingleQuestionCard(q, isAr, isDark, primaryColor);
                            },
                          ),
                        ),

                        // Bottom Navigation Bar (Previous, Next, Submit)
                        Container(
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentIndex > 0)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: Text(isAr ? 'السابق' : 'Previous', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                )
                              else
                                const SizedBox.shrink(),

                              if (_currentIndex < _questions.length - 1)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  label: Text(isAr ? 'التالي' : 'Next', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _confirmSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 2,
                                  ),
                                  icon: _isSubmitting
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.check_circle_rounded),
                                  label: Text(
                                    isAr ? 'إنهاء وتسليم' : 'Submit Exam',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildSingleQuestionCard(QuestionModel q, bool isAr, bool isDark, Color primaryColor) {
    final currentAnswer = _answers[q.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text
            Text(
              q.questionText,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // MCQ Options
            if (q.type == QuestionType.mcq) ...[
              Builder(builder: (context) {
                final options = _shuffledMcqOptions[q.id] ?? q.options;
                return Column(
                  children: options.map((optText) {
                    final isSelected = currentAnswer == optText;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _answers[q.id] = optText;
                          });
                          _cacheAnswersLocally();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withOpacity(0.15)
                                : (isDark ? Colors.black26 : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.grey.shade300),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? primaryColor : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.grey),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  optText,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? primaryColor : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ] else if (q.type == QuestionType.trueFalse) ...[
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _answers[q.id] = true;
                        });
                        _cacheAnswersLocally();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: currentAnswer == true
                              ? Colors.green.withOpacity(0.2)
                              : (isDark ? Colors.black26 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: currentAnswer == true ? Colors.green : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 36, color: currentAnswer == true ? Colors.green : Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              isAr ? 'صح (True)' : 'True',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: currentAnswer == true ? Colors.green : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _answers[q.id] = false;
                        });
                        _cacheAnswersLocally();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: currentAnswer == false
                              ? Colors.red.withOpacity(0.2)
                              : (isDark ? Colors.black26 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: currentAnswer == false ? Colors.red : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.cancel_rounded, size: 36, color: currentAnswer == false ? Colors.red : Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              isAr ? 'خطأ (False)' : 'False',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: currentAnswer == false ? Colors.red : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Essay question text field
              TextFormField(
                initialValue: (currentAnswer ?? '').toString(),
                maxLines: 6,
                style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: isAr ? 'اكتب إجابتك هنا بشكل مفصل...' : 'Type your detailed answer here...',
                  hintStyle: GoogleFonts.cairo(color: isDark ? Colors.white38 : Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
                onChanged: (val) {
                  _answers[q.id] = val;
                  _cacheAnswersLocally();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
