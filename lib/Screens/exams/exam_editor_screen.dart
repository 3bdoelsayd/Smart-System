import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';
import 'question_editor_screen.dart';

class ExamEditorScreen extends StatefulWidget {
  final ExamModel? exam;

  const ExamEditorScreen({super.key, this.exam});

  @override
  State<ExamEditorScreen> createState() => _ExamEditorScreenState();
}

class _ExamEditorScreenState extends State<ExamEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;

  String? _selectedSubject;
  String? _selectedCourseId;
  String _selectedLevel = '1';
  String _selectedSection = 'all';
  DateTime _startTime = DateTime.now().add(const Duration(minutes: 10));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  bool _isPublished = false;

  bool _isLoading = false;
  List<Map<String, dynamic>> _assignedCourses = [];

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;

    _titleController = TextEditingController(text: exam?.title ?? '');
    _descriptionController = TextEditingController(text: exam?.description ?? '');
    _durationController = TextEditingController(text: (exam?.durationMinutes ?? 30).toString());

    if (exam != null) {
      _selectedSubject = exam.subject;
      _selectedCourseId = exam.courseId;
      _selectedLevel = _ds.normalizeLevel(exam.targetLevel);
      _selectedSection = exam.targetSection;
      _startTime = exam.startTime;
      _endTime = exam.endTime;
      _isPublished = exam.isPublished;
    }

    _loadDoctorCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorCourses() async {
    setState(() => _isLoading = true);
    final doctorId = _ds.currentDoctor?['uid'] ?? _ds.currentDoctor?['id'] ?? '';
    final List<String> teachingLevels = List<String>.from(_ds.currentDoctor?['teachingLevels'] ?? ['level_1']);

    final List<Map<String, dynamic>> courses = [];

    for (var lvlId in teachingLevels) {
      final snap = await _ds.getCommerceCoursesColl(lvlId)
          .where(_ds.userRole == 'ta' ? 'ta_id' : 'doctor_id', isEqualTo: doctorId)
          .get();

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        courses.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'level_id': data['level_id'] ?? lvlId,
        });
      }
    }

    if (mounted) {
      setState(() {
        _assignedCourses = courses;
        if (_selectedSubject == null && _assignedCourses.isNotEmpty) {
          _selectedSubject = _assignedCourses.first['name'];
          _selectedCourseId = _assignedCourses.first['id'];
          _selectedLevel = _ds.normalizeLevel(_assignedCourses.first['level_id']);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final current = isStart ? _startTime : _endTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (pickedTime == null || !mounted) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = result;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(Duration(minutes: int.tryParse(_durationController.text) ?? 30));
        }
      } else {
        _endTime = result;
      }
    });
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ds.isArabic ? 'يرجى اختيار المادة الدراسية' : 'Please select a subject')),
      );
      return;
    }

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ds.isArabic ? 'تاريخ الانتهاء يجب أن يكون بعد تاريخ البدء' : 'End time must be after start time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doctorUid = _ds.currentDoctor?['uid'] ?? _ds.currentDoctor?['id'] ?? '';
      final doctorName = _ds.currentDoctor?['name'] ?? 'عضو هيئة تدريس';

      final exam = ExamModel(
        id: widget.exam?.id ?? '',
        title: _titleController.text.trim(),
        subject: _selectedSubject!,
        courseId: _selectedCourseId ?? '',
        targetLevel: _selectedLevel,
        targetSection: _selectedSection,
        description: _descriptionController.text.trim(),
        durationMinutes: int.tryParse(_durationController.text.trim()) ?? 30,
        startTime: _startTime,
        endTime: _endTime,
        isPublished: _isPublished,
        totalScore: widget.exam?.totalScore ?? 0.0,
        createdByUid: doctorUid,
        createdByName: doctorName,
        createdByRole: _ds.userRole ?? 'doctor',
        createdAt: widget.exam?.createdAt ?? DateTime.now(),
      );

      final examId = await _examService.createOrUpdateExam(exam);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ds.isArabic ? 'تم حفظ بيانات الاختبار بنجاح' : 'Exam saved successfully')),
        );

        if (widget.exam == null) {
          // If creating new exam, go directly to question editor
          final savedExam = exam.copyWith(id: examId);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (ctx) => QuestionEditorScreen(exam: savedExam),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;
    final primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final dateFormat = DateFormat('yyyy-MM-dd   hh:mm a');

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            widget.exam == null
                ? (isAr ? 'إنشاء اختبار جديد' : 'Create New Exam')
                : (isAr ? 'تعديل بيانات الاختبار' : 'Edit Exam Details'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course / Subject selection
                      _buildSectionTitle(isAr ? 'المادة الدراسية والفرقة' : 'Course & Level', primaryColor, isDark),
                      const SizedBox(height: 10),
                      _assignedCourses.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isAr ? 'لم يتم إسناد مواد لك، يرجى التواصل مع الإدارة' : 'No courses assigned',
                                style: GoogleFonts.cairo(color: Colors.orange),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedCourseId,
                              decoration: _buildInputDecoration(
                                label: isAr ? 'اختر المادة' : 'Select Subject',
                                icon: Icons.book_rounded,
                                isDark: isDark,
                                primaryColor: primaryColor,
                              ),
                              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                              items: _assignedCourses.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['id'],
                                  child: Text("${c['name']} (${isAr ? 'الفرقة' : 'Level'} ${c['level_id'].toString().replaceAll('level_', '')})"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                final selected = _assignedCourses.firstWhere((c) => c['id'] == val);
                                setState(() {
                                  _selectedCourseId = val;
                                  _selectedSubject = selected['name'];
                                  _selectedLevel = _ds.normalizeLevel(selected['level_id']);
                                });
                              },
                              validator: (val) => val == null ? (isAr ? 'حقل مطلوب' : 'Required') : null,
                            ),

                      const SizedBox(height: 15),

                      // Section / Division selection
                      DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: _buildInputDecoration(
                          label: isAr ? 'الشعبة المستهدفة' : 'Target Section / Division',
                          icon: Icons.group_rounded,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(isAr ? 'جميع الشعب (الكل)' : 'All Sections')),
                          DropdownMenuItem(value: 'نظم معلومات الأعمال', child: Text(isAr ? 'نظم معلومات الأعمال (BIS)' : 'Business Info Systems')),
                          DropdownMenuItem(value: 'المحاسبة والمراجعة', child: Text(isAr ? 'المحاسبة والمراجعة (Accounting)' : 'Accounting & Auditing')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSection = val);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Title
                      _buildSectionTitle(isAr ? 'عنوان ومواصفات الاختبار' : 'Exam Metadata', primaryColor, isDark),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                        decoration: _buildInputDecoration(
                          label: isAr ? 'عنوان الاختبار (مثال: كويز الميدتيرم)' : 'Exam Title',
                          icon: Icons.subtitles_rounded,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? (isAr ? 'يرجى كتابة عنوان الاختبار' : 'Title is required') : null,
                      ),
                      const SizedBox(height: 15),

                      // Description (Optional)
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                        decoration: _buildInputDecoration(
                          label: isAr ? 'تعليمات/وصف الاختبار (اختياري)' : 'Instructions/Description (Optional)',
                          icon: Icons.description_rounded,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Duration in minutes
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                        decoration: _buildInputDecoration(
                          label: isAr ? 'مدة الاختبار بالدقائق (مثال: 30)' : 'Duration in minutes',
                          icon: Icons.timer_rounded,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return isAr ? 'حقل مطلوب' : 'Required';
                          final n = int.tryParse(val.trim());
                          if (n == null || n <= 0) return isAr ? 'أدخل رقماً صحيحاً أكبر من صفر' : 'Invalid duration';
                          return null;
                        },
                      ),

                      const SizedBox(height: 25),

                      // Start & End date pickers
                      _buildSectionTitle(isAr ? 'توقيت بدء وانتهائه الاختبار' : 'Exam Timing', primaryColor, isDark),
                      const SizedBox(height: 10),

                      _buildDateTimeTile(
                        title: isAr ? 'تاريخ ووقت البدء (افتتاح الاختبار)' : 'Start Date & Time',
                        dateTimeStr: dateFormat.format(_startTime),
                        icon: Icons.play_circle_outline_rounded,
                        color: Colors.green,
                        isDark: isDark,
                        onTap: () => _pickDateTime(true),
                      ),
                      const SizedBox(height: 12),
                      _buildDateTimeTile(
                        title: isAr ? 'تاريخ ووقت الانتهاء (غلق الاختبار)' : 'End Date & Time',
                        dateTimeStr: dateFormat.format(_endTime),
                        icon: Icons.stop_circle_outlined,
                        color: Colors.red,
                        isDark: isDark,
                        onTap: () => _pickDateTime(false),
                      ),

                      const SizedBox(height: 25),

                      // Publish switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isPublished ? Colors.green : (isDark ? Colors.white12 : Colors.grey.shade300),
                            width: 1.5,
                          ),
                        ),
                        child: SwitchListTile(
                          value: _isPublished,
                          onChanged: (val) => setState(() => _isPublished = val),
                          activeColor: Colors.green,
                          title: Text(
                            isAr ? 'نشر الاختبار فوراً للطلاب' : 'Publish Exam Immediately',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          ),
                          subtitle: Text(
                            isAr
                                ? 'إذا كانت مفعّلة سيظهر للطلاب، إذا كانت معطلة سيُحفظ كمسودة'
                                : 'If enabled, students will see it. If disabled, saved as draft.',
                            style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _saveExam,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            widget.exam == null
                                ? (isAr ? 'حفظ والمتابعة لإضافة الأسئلة' : 'Save & Add Questions')
                                : (isAr ? 'حفظ التعديلات' : 'Save Changes'),
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? primaryColor : primaryColor,
      ),
    );
  }

  Widget _buildDateTimeTile({
    required String title,
    required String dateTimeStr,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade700),
                  ),
                  Text(
                    dateTimeStr,
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_month_rounded, color: isDark ? Colors.white38 : Colors.grey),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: isDark ? Colors.white60 : Colors.grey.shade700),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
    );
  }
}
