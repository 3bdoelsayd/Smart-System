import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';

class QuestionEditorScreen extends StatefulWidget {
  final ExamModel exam;

  const QuestionEditorScreen({super.key, required this.exam});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();

  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final qList = await _examService.getExamQuestions(widget.exam.id);
    if (mounted) {
      setState(() {
        _questions = qList;
        _isLoading = false;
      });
    }
  }

  double get _totalCalculatedScore {
    return _questions.fold(0.0, (sum, q) => sum + q.points);
  }

  Future<void> _saveAllQuestions() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ds.isArabic ? 'يرجى إضافة سؤال واحد على الأقل' : 'Please add at least one question')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _examService.saveExamQuestions(widget.exam.id, _questions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ds.isArabic ? 'تم حفظ أسئلة الاختبار بنجاح' : 'Questions saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openQuestionDialog({QuestionModel? question, int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionDialogContent(
        question: question,
        examId: widget.exam.id,
        order: editIndex ?? _questions.length,
        onSave: (newQuestion) {
          setState(() {
            if (editIndex != null) {
              _questions[editIndex] = newQuestion;
            } else {
              _questions.add(newQuestion);
            }
          });
        },
      ),
    );
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
            isAr ? 'أسئلة الاختبار (${widget.exam.title})' : 'Exam Questions (${widget.exam.title})',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBar: Container(
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
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${isAr ? 'عدد الأسئلة' : 'Total Questions'}: ${_questions.length}",
                      style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade700),
                    ),
                    Text(
                      "${isAr ? 'مجموع الدرجات' : 'Total Score'}: ${_totalCalculatedScore.toStringAsFixed(1)}",
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAllQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  isAr ? 'حفظ الأسئلة' : 'Save Questions',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openQuestionDialog(),
          backgroundColor: primaryColor,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            isAr ? 'إضافة سؤال' : 'Add Question',
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _questions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 80, color: isDark ? Colors.white24 : Colors.grey.withAlpha(80)),
                        const SizedBox(height: 16),
                        Text(
                          isAr ? 'لم تقم بإضافة أسئلة بعد لهذا الاختبار' : 'No questions added yet',
                          style: GoogleFonts.cairo(fontSize: 16, color: isDark ? Colors.white54 : Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openQuestionDialog(),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(isAr ? 'أضف أول سؤال الآن' : 'Add First Question', style: GoogleFonts.cairo(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _questions.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _questions.removeAt(oldIndex);
                        _questions.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      return _buildQuestionCard(q, index, isAr, isDark, primaryColor, key: ValueKey(q.id + index.toString()));
                    },
                  ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q, int index, bool isAr, bool isDark, Color primaryColor, {required Key key}) {
    String typeLabel = '';
    Color typeColor = Colors.blue;

    if (q.type == QuestionType.mcq) {
      typeLabel = isAr ? 'اختيار من متعدد' : 'MCQ';
      typeColor = Colors.blue;
    } else if (q.type == QuestionType.trueFalse) {
      typeLabel = isAr ? 'صح / خطأ' : 'True/False';
      typeColor = Colors.purple;
    } else {
      typeLabel = isAr ? 'سؤال مقالي' : 'Essay';
      typeColor = Colors.orange;
    }

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black54 : Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Text(
            "${index + 1}",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                typeLabel,
                style: GoogleFonts.cairo(fontSize: 10, color: typeColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${q.points} ${isAr ? 'درجات' : 'pts'}",
                style: GoogleFonts.cairo(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            q.questionText,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
              onPressed: () => _openQuestionDialog(question: q, editIndex: index),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  _questions.removeAt(index);
                });
              },
            ),
            const Icon(Icons.drag_handle_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _QuestionDialogContent extends StatefulWidget {
  final QuestionModel? question;
  final String examId;
  final int order;
  final Function(QuestionModel) onSave;

  const _QuestionDialogContent({
    this.question,
    required this.examId,
    required this.order,
    required this.onSave,
  });

  @override
  State<_QuestionDialogContent> createState() => _QuestionDialogContentState();
}

class _QuestionDialogContentState extends State<_QuestionDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final DataService _ds = DataService();

  late QuestionType _selectedType;
  late TextEditingController _questionTextController;
  late TextEditingController _pointsController;

  // MCQ Options
  List<TextEditingController> _optionControllers = [];
  int _mcqCorrectIndex = 0;

  // True / False correct answer
  bool _tfCorrectAnswer = true;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _selectedType = q?.type ?? QuestionType.mcq;
    _questionTextController = TextEditingController(text: q?.questionText ?? '');
    _pointsController = TextEditingController(text: (q?.points ?? 1.0).toString());

    if (_selectedType == QuestionType.mcq) {
      if (q != null && q.options.isNotEmpty) {
        _optionControllers = q.options.map((opt) => TextEditingController(text: opt)).toList();
        _mcqCorrectIndex = (q.correctAnswer is int) ? q.correctAnswer as int : 0;
      } else {
        _optionControllers = [
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
        ];
      }
    } else {
      _optionControllers = [
        TextEditingController(),
        TextEditingController(),
      ];
    }

    if (_selectedType == QuestionType.trueFalse) {
      if (q != null && q.correctAnswer != null) {
        _tfCorrectAnswer = (q.correctAnswer is bool)
            ? q.correctAnswer as bool
            : q.correctAnswer.toString().toLowerCase() == 'true';
      }
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _pointsController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMcqOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeMcqOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers.removeAt(index);
        if (_mcqCorrectIndex >= _optionControllers.length) {
          _mcqCorrectIndex = 0;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    List<String> options = [];
    dynamic correctAnswer;

    if (_selectedType == QuestionType.mcq) {
      options = _optionControllers.map((c) => c.text.trim()).toList();
      if (options.any((opt) => opt.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ds.isArabic ? 'يرجى ملء جميع الخيارات' : 'Please fill all options')),
        );
        return;
      }
      correctAnswer = _mcqCorrectIndex;
    } else if (_selectedType == QuestionType.trueFalse) {
      options = [_ds.isArabic ? 'صح' : 'True', _ds.isArabic ? 'خطأ' : 'False'];
      correctAnswer = _tfCorrectAnswer;
    } else {
      options = [];
      correctAnswer = null;
    }

    final qModel = QuestionModel(
      id: widget.question?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      examId: widget.examId,
      questionText: _questionTextController.text.trim(),
      type: _selectedType,
      options: options,
      correctAnswer: correctAnswer,
      points: double.tryParse(_pointsController.text.trim()) ?? 1.0,
      order: widget.order,
    );

    widget.onSave(qModel);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;
    final primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.question == null
                    ? (isAr ? 'إضافة سؤال جديد' : 'Add New Question')
                    : (isAr ? 'تعديل السؤال' : 'Edit Question'),
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 16),

              // Question Type selector
              Text(isAr ? 'نوع السؤال' : 'Question Type', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _typeChip(QuestionType.mcq, isAr ? 'اختيار متعدد' : 'MCQ', isDark, primaryColor),
                  const SizedBox(width: 8),
                  _typeChip(QuestionType.trueFalse, isAr ? 'صح/خطأ' : 'True/False', isDark, primaryColor),
                  const SizedBox(width: 8),
                  _typeChip(QuestionType.essay, isAr ? 'مقالي' : 'Essay', isDark, primaryColor),
                ],
              ),

              const SizedBox(height: 16),

              // Question Text
              TextFormField(
                controller: _questionTextController,
                maxLines: 3,
                style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: isAr ? 'نص السؤال' : 'Question Text',
                  labelStyle: GoogleFonts.cairo(color: isDark ? Colors.white60 : Colors.grey.shade700),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? (isAr ? 'يرجى كتابة نص السؤال' : 'Question text is required') : null,
              ),

              const SizedBox(height: 16),

              // Points / Grade
              TextFormField(
                controller: _pointsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: isAr ? 'درجة السؤال' : 'Points / Grade',
                  labelStyle: GoogleFonts.cairo(color: isDark ? Colors.white60 : Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.grade_rounded, color: Colors.teal),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return isAr ? 'حقل مطلوب' : 'Required';
                  final p = double.tryParse(val.trim());
                  if (p == null || p <= 0) return isAr ? 'أدخل درجة صحيحة' : 'Invalid grade';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Dynamic options based on type
              if (_selectedType == QuestionType.mcq) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'خيارات الإجابة (حدد الخيار الصحيح)' : 'Answer Options (Select correct)',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                    ),
                    if (_optionControllers.length < 6)
                      TextButton.icon(
                        onPressed: _addMcqOption,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(isAr ? 'إضافة خيار' : 'Add Option', style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(_optionControllers.length, (i) {
                    final isSelected = _mcqCorrectIndex == i;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: _mcqCorrectIndex,
                            onChanged: (val) => setState(() => _mcqCorrectIndex = val!),
                            activeColor: Colors.green,
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _optionControllers[i],
                              style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: "${isAr ? 'الخيار' : 'Option'} ${i + 1}",
                                hintStyle: GoogleFonts.cairo(color: isDark ? Colors.white38 : Colors.grey),
                                filled: true,
                                fillColor: isSelected
                                    ? Colors.green.withOpacity(isDark ? 0.2 : 0.1)
                                    : (isDark ? Colors.black26 : Colors.grey.shade100),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isSelected ? Colors.green : (isDark ? Colors.white12 : Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_optionControllers.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                              onPressed: () => _removeMcqOption(i),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ] else if (_selectedType == QuestionType.trueFalse) ...[
                Text(
                  isAr ? 'الإجابة الصحيحة:' : 'Correct Answer:',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tfCorrectAnswer = true),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _tfCorrectAnswer ? Colors.green.withOpacity(0.2) : (isDark ? Colors.black26 : Colors.grey.shade100),
                            border: Border.all(color: _tfCorrectAnswer ? Colors.green : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              isAr ? 'صح (True)' : 'True',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _tfCorrectAnswer ? Colors.green : (isDark ? Colors.white70 : Colors.black87)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tfCorrectAnswer = false),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_tfCorrectAnswer ? Colors.red.withOpacity(0.2) : (isDark ? Colors.black26 : Colors.grey.shade100),
                            border: Border.all(color: !_tfCorrectAnswer ? Colors.red : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              isAr ? 'خطأ (False)' : 'False',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: !_tfCorrectAnswer ? Colors.red : (isDark ? Colors.white70 : Colors.black87)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'السؤال المقالي يتم تقييمه يدوياً من قبل الدكتور/المعيد بعد تسليم الطلاب.'
                              : 'Essay questions require manual grading by Doctor/TA after student submission.',
                          style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isAr ? 'حفظ السؤال' : 'Save Question',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(QuestionType type, String label, bool isDark, Color primaryColor) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: FilterChip(
        selected: isSelected,
        label: Center(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
        selectedColor: primaryColor,
        backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedType = type;
            });
          }
        },
      ),
    );
  }
}
