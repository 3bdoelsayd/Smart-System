import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';

class ExamResultsManagementScreen extends StatefulWidget {
  const ExamResultsManagementScreen({super.key});

  @override
  State<ExamResultsManagementScreen> createState() => _ExamResultsManagementScreenState();
}

class _ExamResultsManagementScreenState extends State<ExamResultsManagementScreen> {
  final DataService _ds = DataService();
  final TextEditingController _finalController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedSubject;
  dynamic _selectedLevel;
  String? _selectedDivision;
  String _searchQuery = "";

  @override
  void dispose() {
    _finalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    String n = text.toLowerCase().trim();
    if (n == 'is' || n.contains('نظم')) n = 'نظم معلومات الاعمال';
    if (n == 'acc' || n.contains('محاسب')) n = 'محاسبه';
    return n.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ال', '').replaceAll(' ', '').trim();
  }

  String _getDivisionName(String? code) {
    String c = _normalize(code ?? 'ALL');
    if (c == "نظممعلوماتالاعمال") return _ds.isArabic ? "نظم معلومات الأعمال" : "Business Info Systems";
    if (c == "محاسبه") return _ds.isArabic ? "محاسبة" : "Accounting";
    return (code == null || code.toUpperCase() == 'ALL') ? (_ds.isArabic ? "عام" : "General") : code;
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    Color color = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(isAr ? 'رصد نتائج الامتحانات' : 'Exam Results Entry'),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
        ),
        body: _selectedSubject == null ? _buildSubjectSelection(color, isDark) : _buildManagementList(color, isDark),
      ),
    );
  }

  Widget _buildSubjectSelection(Color color, bool isDark) {
    final subjects = _ds.currentDoctor?['subjects'] as List? ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: subjects.length,
      itemBuilder: (ctx, i) {
        final s = subjects[i];
        final name = s is Map ? (s['name'] ?? 'Unknown') : s.toString();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${_ds.isArabic ? 'الفرقة:' : 'Level:'} ${s['level']} • ${_getDivisionName(s['division'])}"),
            trailing: Icon(Icons.arrow_forward_ios_rounded, color: color),
            onTap: () {
              setState(() {
                _selectedSubject = name;
                _selectedLevel = s['level'];
                _selectedDivision = s['division'];
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildManagementList(Color color, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: _ds.translate('search_student'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.studentsColl.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var students = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                bool levelMatch = data['level'].toString() == _selectedLevel.toString();
                String studentDiv = _normalize(data['division']?.toString() ?? 'ALL');
                String selectedDiv = _normalize(_selectedDivision ?? 'ALL');
                bool divMatch = selectedDiv == 'all' || studentDiv == selectedDiv || studentDiv == 'all';
                bool searchMatch = _searchQuery.isEmpty || _normalize(data['name'] ?? '').contains(_normalize(_searchQuery));
                return levelMatch && divMatch && searchMatch;
              }).toList();

              return StreamBuilder<QuerySnapshot>(
                stream: _ds.gradesColl.where('subject', isEqualTo: _selectedSubject).snapshots(),
                builder: (context, courseworkSnap) {
                  Map<String, double> courseworkMap = {};
                  if (courseworkSnap.hasData) {
                    for (var doc in courseworkSnap.data!.docs) {
                      final d = doc.data() as Map<String, dynamic>;
                      courseworkMap[d['studentId'].toString().trim()] = (d['grade'] as num).toDouble();
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _ds.examResultsColl.where('subject', isEqualTo: _selectedSubject).snapshots(),
                    builder: (context, resultSnap) {
                      Map<String, dynamic> resultsMap = {};
                      if (resultSnap.hasData) {
                        for (var doc in resultSnap.data!.docs) {
                          final d = doc.data() as Map<String, dynamic>;
                          resultsMap[d['studentId']] = d;
                        }
                      }

                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (ctx, i) {
                          final student = students[i].data() as Map<String, dynamic>;
                          final studentId = student['id'].toString().trim();
                          final courseworkGrade = courseworkMap[studentId] ?? 0.0;
                          final hasResult = resultsMap.containsKey(studentId);
                          final result = resultsMap[studentId];

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(student['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text("ID: $studentId | ${_ds.isArabic ? 'أعمال السنة:' : 'CW:'} $courseworkGrade", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      if (hasResult)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            "${_ds.isArabic ? 'المجموع:' : 'Total:'} ${result['total']} - ${_ds.getGradeLabel(result['grade'])}",
                                            style: TextStyle(color: courseworkGrade + (result['final'] ?? 0) >= 50 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(hasResult ? Icons.edit_note : Icons.add_circle_outline, color: color),
                                  onPressed: () => _showResultDialog(studentId, student['name'], courseworkGrade, result),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  );
                }
              );
            },
          ),
        ),
      ],
    );
  }

  void _showResultDialog(String studentId, String name, double courseworkGrade, dynamic existingResult) {
    if (existingResult != null) {
      _finalController.text = existingResult['final']?.toString() ?? '';
    } else {
      _finalController.clear();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(name, style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_ds.isArabic ? 'أعمال السنة (مسجلة):' : 'Coursework (Saved):'),
                  Text("$courseworkGrade / 40", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _finalController,
              decoration: InputDecoration(
                labelText: _ds.isArabic ? 'درجة الامتحان (من 60)' : 'Exam Score (Max 60)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: null,
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 10),
            Text(
              _ds.isArabic ? "* التقدير سيحسب تلقائياً من 100" : "* Grade calculated automatically from 100",
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_ds.translate('cancel'))),
          ElevatedButton(
            onPressed: () async {
              double? finalScore = double.tryParse(_finalController.text);
              
              if (finalScore == null || finalScore < 0 || finalScore > 60) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(_ds.isArabic ? "خطأ: الدرجة يجب أن تكون بين 0 و 60 فقط" : "Error: Grade must be between 0 and 60"),
                  )
                );
                return;
              }
              
              await _ds.saveExamResult(
                studentId,
                _selectedSubject!,
                courseworkGrade,
                finalScore,
              );
              Navigator.pop(ctx);
            },
            child: Text(_ds.isArabic ? 'حفظ النتيجة' : 'Save Result'),
          ),
        ],
      ),
    );
  }
}
