import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/exam_model.dart';
import '../../services/data_service.dart';
import '../../services/exam_service.dart';
import '../../utils/excel_helper.dart';
import '../private_chat_screen.dart';
import 'student_submission_detail_screen.dart';

class ExamResultsDoctorScreen extends StatefulWidget {
  final ExamModel exam;

  const ExamResultsDoctorScreen({super.key, required this.exam});

  @override
  State<ExamResultsDoctorScreen> createState() => _ExamResultsDoctorScreenState();
}

class _ExamResultsDoctorScreenState extends State<ExamResultsDoctorScreen> with SingleTickerProviderStateMixin {
  final DataService _ds = DataService();
  final ExamService _examService = ExamService();

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  List<Map<String, dynamic>> _absentStudents = [];
  bool _isLoadingAbsent = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAbsentStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAbsentStudents() async {
    setState(() => _isLoadingAbsent = true);
    final absent = await _examService.getAbsentStudents(
      examId: widget.exam.id,
      level: widget.exam.targetLevel,
      section: widget.exam.targetSection,
    );
    if (mounted) {
      setState(() {
        _absentStudents = absent;
        _isLoadingAbsent = false;
      });
    }
  }

  Future<void> _exportToExcel(List<ExamSubmissionModel> submissions) async {
    final isAr = _ds.isArabic;
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');

    final List<Map<String, dynamic>> exportData = submissions.map((sub) {
      final score = sub.isGraded ? sub.finalScore : sub.autoScore;
      final statusStr = sub.isGraded
          ? (isAr ? 'مكتمل المصحح' : 'Graded')
          : (isAr ? 'مقالي معلق' : 'Essay Pending');

      return {
        'studentName': sub.studentName,
        'studentId': sub.studentId,
        'statusText': statusStr,
        'finalScore': score,
        'autoScore': sub.autoScore,
        'maxScore': sub.maxScore > 0 ? sub.maxScore : widget.exam.totalScore,
        'submittedAt': sub.submittedAt != null ? dateFormat.format(sub.submittedAt!) : '--',
      };
    }).toList();

    await ExcelHelper.exportExamResultsToExcel(
      examTitle: widget.exam.title,
      subject: widget.exam.subject,
      level: widget.exam.targetLevel,
      totalScore: widget.exam.totalScore,
      results: exportData,
      isArabic: isAr,
    );
  }

  void _openChatWithStudent(String uid, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PrivateChatScreen(
          otherUserId: uid,
          otherUserName: name,
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
    final isReadOnlyRole = _ds.userRole == 'manager';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            isAr ? 'نتائج ومراقبة الاختبار' : 'Exam Results & Monitoring',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
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
              Tab(text: isAr ? 'الذين أدوا الاختبار' : 'Attendees'),
              Tab(text: isAr ? 'الذين لم يؤدوا الاختبار' : 'Absent Students'),
            ],
          ),
        ),
        body: StreamBuilder<List<ExamSubmissionModel>>(
          stream: _examService.getSubmissionsStream(widget.exam.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final submissions = snapshot.data ?? [];

            // Calculate statistics
            final attendeeCount = submissions.length;
            final totalTargetStudents = attendeeCount + _absentStudents.length;
            final double attendanceRate = totalTargetStudents > 0
                ? (attendeeCount / totalTargetStudents) * 100
                : 0.0;

            double avgScore = 0.0;
            double maxScoreAchieved = 0.0;
            double minScoreAchieved = widget.exam.totalScore;

            if (submissions.isNotEmpty) {
              double sum = 0.0;
              for (var s in submissions) {
                final sc = s.isGraded ? s.finalScore : s.autoScore;
                sum += sc;
                if (sc > maxScoreAchieved) maxScoreAchieved = sc;
                if (sc < minScoreAchieved) minScoreAchieved = sc;
              }
              avgScore = sum / submissions.length;
            } else {
              minScoreAchieved = 0.0;
            }

            final filteredSubmissions = submissions.where((s) {
              if (_searchQuery.isEmpty) return true;
              final q = _searchQuery.toLowerCase();
              return s.studentName.toLowerCase().contains(q) || s.studentId.contains(q);
            }).toList();
            filteredSubmissions.sort((a, b) => a.studentName.compareTo(b.studentName));

            final filteredAbsent = _absentStudents.where((s) {
              if (_searchQuery.isEmpty) return true;
              final q = _searchQuery.toLowerCase();
              return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['id'] ?? '').toString().contains(q);
            }).toList();
            filteredAbsent.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

            return Column(
              children: [
                // Statistics Summary Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.exam.title,
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "${widget.exam.subject} | ${isAr ? 'الفرقة' : 'Level'} ${widget.exam.targetLevel.replaceAll('level_', '')}",
                                  style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _exportToExcel(submissions),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text(
                              isAr ? 'تصدير إكسيل' : 'Export Excel',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              title: isAr ? 'نسبة الحضور' : 'Attendance',
                              value: "$attendeeCount / $totalTargetStudents (${attendanceRate.toStringAsFixed(0)}%)",
                              color: Colors.blue,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniStat(
                              title: isAr ? 'المتوسط' : 'Average',
                              value: "${avgScore.toStringAsFixed(1)} / ${widget.exam.totalScore}",
                              color: Colors.purple,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniStat(
                              title: isAr ? 'أعلى / أدنى' : 'Max / Min',
                              value: "${maxScoreAchieved.toStringAsFixed(1)} | ${minScoreAchieved.toStringAsFixed(1)}",
                              color: Colors.teal,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: isAr ? 'ابحث باسم الطالب أو الكود...' : 'Search student name or ID...',
                      hintStyle: GoogleFonts.cairo(color: isDark ? Colors.white38 : Colors.grey),
                      prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Attendees / Submissions List
                      _buildSubmissionsList(filteredSubmissions, isAr, isDark, primaryColor, isReadOnlyRole),

                      // Absent Students List
                      _buildAbsentList(filteredAbsent, isAr, isDark, primaryColor, isReadOnlyRole),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList(
    List<ExamSubmissionModel> list,
    bool isAr,
    bool isDark,
    Color primaryColor,
    bool isReadOnlyRole,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 70, color: isDark ? Colors.white24 : Colors.grey.withAlpha(80)),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لم يقم أي طالب بتسليم هذا الاختبار بعد' : 'No submissions found',
              style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final sub = list[index];
        return _buildSubmissionsListItem(sub, isAr, isDark, primaryColor, isReadOnlyRole);
      },
    );
  }

  Widget _buildSubmissionsListItem(ExamSubmissionModel sub, bool isAr, bool isDark, Color primaryColor, bool isReadOnlyRole) {
    final score = sub.isGraded ? sub.finalScore : sub.autoScore;
    final maxScore = sub.maxScore > 0 ? sub.maxScore : widget.exam.totalScore;
    final pct = maxScore > 0 ? (score / maxScore) * 100 : 0.0;
    final dateFormat = DateFormat('hh:mm a');

    Color scoreColor = Colors.green;
    if (pct < 50) {
      scoreColor = Colors.red;
    } else if (pct < 75) {
      scoreColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => StudentSubmissionDetailScreen(
                exam: widget.exam,
                submission: sub,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scoreColor.withOpacity(0.15),
          child: Text(
            "${pct.toStringAsFixed(0)}%",
            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: scoreColor),
          ),
        ),
        title: Text(
          sub.studentName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        subtitle: Row(
          children: [
            Text(
              "${isAr ? 'كود' : 'ID'}: ${sub.studentId}",
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
            ),
            const SizedBox(width: 10),
            Text(
              sub.submittedAt != null ? dateFormat.format(sub.submittedAt!) : '',
              style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(1)}",
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: scoreColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: sub.isGraded ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sub.isGraded ? (isAr ? 'مصحح' : 'Graded') : (isAr ? 'مقالي معلق' : 'Essay Pending'),
                    style: GoogleFonts.cairo(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: sub.isGraded ? Colors.green : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chat_rounded, color: Colors.blue, size: 20),
              onPressed: () => _openChatWithStudent(sub.studentUid, sub.studentName),
              tooltip: isAr ? 'إرسال رسالة' : 'Send Message',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsentList(
    List<Map<String, dynamic>> list,
    bool isAr,
    bool isDark,
    Color primaryColor,
    bool isReadOnlyRole,
  ) {
    if (_isLoadingAbsent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 70, color: Colors.green.withAlpha(150)),
            const SizedBox(height: 12),
            Text(
              isAr ? 'ممتاز! جميع الطلاب حضروا الاختبار' : 'Great! All students attended',
              style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final student = list[index];
        final uid = student['uid']?.toString() ?? '';
        final name = student['name']?.toString() ?? 'طالب';
        final id = student['id']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.15),
              child: const Icon(Icons.person_off_rounded, color: Colors.red, size: 20),
            ),
            title: Text(
              name,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: Text(
              "${isAr ? 'كود الطالب' : 'Student ID'}: $id",
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.chat_rounded, color: Colors.blue, size: 20),
              onPressed: () => _openChatWithStudent(uid, name),
              tooltip: isAr ? 'مراسلة الطالب الغائب' : 'Message Absent Student',
            ),
          ),
        );
      },
    );
  }
}
