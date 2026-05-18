import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  final DataService _ds = DataService();
  int _viewType = 0; // 0 for Midterm/CW, 1 for Final Results

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    
    final Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final String studentId = _ds.currentStudent?['id']?.toString() ?? '';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(isAr ? 'نتائجي' : 'My Results'),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // تبويب للتنقل بين أعمال السنة والنتيجة النهائية
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  _buildTab(0, isAr ? 'أعمال السنة' : 'Coursework', isDark, primaryColor),
                  _buildTab(1, isAr ? 'النتيجة النهائية' : 'Final Exam', isDark, primaryColor),
                ],
              ),
            ),
            
            Expanded(
              child: studentId.isEmpty
                ? Center(child: Text(isAr ? 'يرجى تسجيل الدخول' : 'Please login'))
                : _viewType == 0 
                    ? _buildCWList(studentId, isAr, isDark, primaryColor)
                    : _buildFinalList(studentId, isAr, isDark, primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, bool isDark, Color primaryColor) {
    bool isSelected = _viewType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // قائمة أعمال السنة (Coursework)
  Widget _buildCWList(String studentId, bool isAr, bool isDark, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.getStudentGradesStream(studentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return _emptyState(isAr, isDark);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _resultCard(
              title: data['subject'] ?? '',
              score: (data['grade'] ?? 0).toDouble(),
              max: 40,
              label: isAr ? 'درجة أعمال السنة' : 'Coursework Score',
              isDark: isDark,
              primaryColor: primaryColor,
            );
          },
        );
      },
    );
  }

  // قائمة النتيجة النهائية (Final Exams)
  Widget _buildFinalList(String studentId, bool isAr, bool isDark, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.getStudentExamResultsStream(studentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return _emptyState(isAr, isDark, isFinal: true);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            double cw = (data['coursework'] ?? 0).toDouble();
            double fin = (data['final'] ?? 0).toDouble();
            double total = cw + fin;
            String gradeCode = data['grade'] ?? _ds.calculateGrade(total);

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data['subject'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: total >= 50 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _ds.getGradeLabel(gradeCode),
                          style: TextStyle(color: total >= 50 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniScore(isAr ? 'أعمال سنة' : 'CW', cw, 40),
                      _miniScore(isAr ? 'امتحان' : 'Exam', fin, 60),
                      _miniScore(isAr ? 'المجموع' : 'Total', total, 100, isMain: true, color: primaryColor),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _resultCard({required String title, required double score, required int max, required String label, required bool isDark, required Color primaryColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(Icons.bookmark_added_rounded, color: primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Text('$score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryColor)),
              Text('/$max', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniScore(String label, double val, int max, {bool isMain = false, Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 5),
        Text(
          '${val.toStringAsFixed(0)}/$max',
          style: TextStyle(
            fontSize: isMain ? 18 : 14,
            fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isMain ? Colors.blue : null),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(bool isAr, bool isDark, {bool isFinal = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 60, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 15),
          Text(
            isFinal 
              ? (isAr ? 'لم يتم إعلان النتائج النهائية بعد' : 'Final results not ready')
              : (isAr ? 'لم يتم رصد درجات أعمال السنة بعد' : 'No coursework grades yet'),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
