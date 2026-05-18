// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/data_service.dart';
// import '../utils/excel_helper.dart';
//
// class GradesManagementScreen extends StatelessWidget {
//   const GradesManagementScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const _GradesManagementContent();
//   }
// }
//
// class _GradesManagementContent extends StatefulWidget {
//   const _GradesManagementContent();
//
//   @override
//   State<_GradesManagementContent> createState() => _GradesManagementContentState();
// }
//
// class _GradesManagementContentState extends State<_GradesManagementContent> {
//   final DataService _ds = DataService();
//   final TextEditingController _gradeController = TextEditingController();
//   final TextEditingController _allGradesController = TextEditingController();
//   final TextEditingController _searchController = TextEditingController();
//
//   String? _selectedSubject;
//   dynamic _selectedLevel;
//   String? _selectedDivision;
//   String _searchQuery = "";
//   bool _isExporting = false;
//
//   @override
//   void dispose() {
//     _gradeController.dispose();
//     _allGradesController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   String _normalize(String text) {
//     String n = text.toLowerCase().trim();
//     if (n == 'is' || n.contains('نظم')) n = 'نظم معلومات الاعمال';
//     if (n == 'acc' || n.contains('محاسب')) n = 'محاسبه';
//     return n.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ال', '').replaceAll(' ', '').trim();
//   }
//
//   String _getDivisionName(String? code) {
//     String c = _normalize(code ?? 'ALL');
//     if (c == "نظممعلوماتالاعمال") return _ds.isArabic ? "نظم معلومات الأعمال" : "Business Info Systems";
//     if (c == "محاسبه") return _ds.isArabic ? "محاسبة" : "Accounting";
//     return (code == null || code.toUpperCase() == 'ALL') ? (_ds.isArabic ? "عام" : "General") : code!;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _ds,
//       builder: (context, _) {
//         bool isAr = _ds.isArabic;
//         bool isDark = _ds.isDarkMode;
//         Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
//
//         return Directionality(
//           textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
//           child: WillPopScope(
//             onWillPop: () async {
//               if (_selectedSubject != null) {
//                 setState(() {
//                   _selectedSubject = null;
//                   _searchQuery = "";
//                   _searchController.clear();
//                 });
//                 return false;
//               }
//               return true;
//             },
//             child: Scaffold(
//               backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
//               appBar: AppBar(
//                 elevation: 0,
//                 centerTitle: true,
//                 title: Text(
//                     _selectedSubject == null ? _ds.translate('grades_mng') : _selectedSubject!,
//                     style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)
//                 ),
//                 backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
//                 foregroundColor: isDark ? Colors.white : Colors.black,
//                 leading: _selectedSubject != null
//                     ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => setState(() { _selectedSubject = null; _searchQuery = ""; _searchController.clear(); }))
//                     : null,
//               ),
//               body: _ds.currentDoctor == null
//                   ? Center(child: Text(_ds.isArabic ? 'الرجاء تسجيل الدخول' : 'Please Log In'))
//                   : _selectedSubject == null ? _buildSubjectSelection(primaryColor, isDark) : _buildMainContent(primaryColor, isDark),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildMainContent(Color color, bool isDark) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
//             borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: isDark ? Colors.black.withAlpha(50) : const Color(0xFFF1F3F8),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: (v) => setState(() => _searchQuery = v),
//                     style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                     decoration: InputDecoration(
//                       hintText: _ds.translate('search_student'),
//                       hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
//                       prefixIcon: Icon(Icons.search_rounded, color: color),
//                       border: InputBorder.none,
//                       contentPadding: const EdgeInsets.symmetric(vertical: 15),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               GestureDetector(
//                 onTap: _isExporting ? null : _exportData,
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withAlpha(30),
//                     borderRadius: BorderRadius.circular(15),
//                     border: Border.all(color: Colors.green.withAlpha(50)),
//                   ),
//                   child: _isExporting
//                     ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
//                     : const Icon(Icons.file_download_rounded, color: Colors.green),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               GestureDetector(
//                 onTap: () => _showClearAllGradesDialog(color),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.red.withAlpha(30),
//                     borderRadius: BorderRadius.circular(15),
//                     border: Border.all(color: Colors.red.withAlpha(50)),
//                   ),
//                   child: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               GestureDetector(
//                 onTap: () => _showBulkGradeDialog(color),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: color,
//                     borderRadius: BorderRadius.circular(15),
//                     boxShadow: [BoxShadow(color: color.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4))]
//                   ),
//                   child: Icon(Icons.group_add_rounded, color: isDark ? Colors.black : Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Expanded(child: _buildStudentList(color, isDark)),
//       ],
//     );
//   }
//
//   void _exportData() async {
//     setState(() => _isExporting = true);
//     try {
//       final studentsSnapshot = await _ds.studentsColl.get();
//       final filteredStudents = studentsSnapshot.docs.where((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         bool levelMatch = data['level'].toString().trim() == _selectedLevel.toString().trim();
//         String studentDiv = _normalize(data['division']?.toString() ?? 'ALL');
//         String selectedDiv = _normalize(_selectedDivision ?? 'ALL');
//         return levelMatch && (selectedDiv == 'all' || studentDiv == selectedDiv || studentDiv == 'all');
//       }).map((e) => e.data() as Map<String, dynamic>).toList();
//
//       final gradeSnap = await _ds.gradesColl
//           .where('subject', isEqualTo: _selectedSubject?.trim())
//           .get();
//
//       Map<String, double> gradesMap = {};
//       for (var doc in gradeSnap.docs) {
//         final d = doc.data() as Map<String, dynamic>;
//         gradesMap[d['studentId'].toString().trim()] = (d['grade'] as num).toDouble();
//       }
//
//       await ExcelHelper.exportGradesToExcel(
//         subject: _selectedSubject!,
//         level: _selectedLevel.toString(),
//         division: _getDivisionName(_selectedDivision),
//         doctorName: _ds.currentDoctor?['name'] ?? 'Doctor',
//         students: filteredStudents,
//         gradesMap: gradesMap,
//         isArabic: _ds.isArabic,
//       );
//
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//     setState(() => _isExporting = false);
//   }
//
//   Widget _buildSubjectSelection(Color color, bool isDark) {
//     final subjects = _ds.currentDoctor?['subjects'] as List? ?? [];
//     return ListView.builder(
//       padding: const EdgeInsets.all(20),
//       itemCount: subjects.length,
//       itemBuilder: (ctx, i) {
//         final s = subjects[i];
//         final name = s is Map ? (s['name'] ?? 'Unknown') : s.toString();
//         return Container(
//           margin: const EdgeInsets.only(bottom: 15),
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//             borderRadius: BorderRadius.circular(25),
//             boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 8))],
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             leading: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
//               child: Icon(Icons.menu_book_rounded, color: color, size: 28),
//             ),
//             title: Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : Colors.black87)),
//             subtitle: Text("${_ds.isArabic ? 'الفرقة:' : 'Level:'} ${s['level']} • ${_getDivisionName(s['division'])}", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
//             trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
//             onTap: () { _ds.playClickSound(); setState(() { _selectedSubject = name; _selectedLevel = s['level']; _selectedDivision = s['division']; }); },
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildStudentList(Color color, bool isDark) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _ds.studentsColl.snapshots(),
//       builder: (context, studentSnapshot) {
//         if (!studentSnapshot.hasData) return const Center(child: CircularProgressIndicator());
//
//         final studentsDocs = studentSnapshot.data!.docs.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           bool levelMatch = data['level'].toString().trim() == _selectedLevel.toString().trim();
//           String studentDiv = _normalize(data['division']?.toString() ?? 'ALL');
//           String selectedDiv = _normalize(_selectedDivision ?? 'ALL');
//           return levelMatch && (selectedDiv == 'all' || studentDiv == selectedDiv || studentDiv == 'all');
//         }).toList();
//
//         return StreamBuilder<QuerySnapshot>(
//           stream: _ds.gradesColl.where('subject', isEqualTo: _selectedSubject?.trim()).snapshots(),
//           builder: (context, gradeSnap) {
//             final gradeDocs = gradeSnap.data?.docs ?? [];
//             Map<String, double> gradesMap = {};
//             int gradedCount = 0;
//             for (var doc in gradeDocs) {
//               final d = doc.data() as Map<String, dynamic>;
//               gradesMap[d['studentId'].toString().trim()] = (d['grade'] as num).toDouble();
//             }
//
//             List<Map<String, dynamic>> list = studentsDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//             for (var student in list) { if (gradesMap.containsKey(student['id']?.toString().trim())) gradedCount++; }
//             int ungradedCount = list.length - gradedCount;
//
//             if (_searchQuery.isNotEmpty) {
//               String q = _normalize(_searchQuery);
//               list = list.where((s) => _normalize(s['name'] ?? '').contains(q) || s['id'].toString().contains(q)).toList();
//             }
//
//             list.sort((a, b) {
//               double gradeA = gradesMap[a['id']?.toString().trim()] ?? -1.0;
//               double gradeB = gradesMap[b['id']?.toString().trim()] ?? -1.0;
//               if (gradeA != gradeB) return gradeB.compareTo(gradeA);
//               return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
//             });
//
//             return Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//                   child: Row(
//                     children: [
//                       _statCard(_ds.translate('graded'), gradedCount, Colors.green, Icons.emoji_events_rounded, isDark),
//                       const SizedBox(width: 15),
//                       _statCard(_ds.translate('pending'), ungradedCount, Colors.orange, Icons.timer_rounded, isDark),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//                     itemCount: list.length,
//                     itemBuilder: (ctx, i) {
//                       final studentData = list[i];
//                       final studentId = (studentData['id']?.toString() ?? '').trim();
//                       double? grade = gradesMap[studentId];
//                       bool hasGrade = grade != null;
//
//                       return Container(
//                         margin: const EdgeInsets.only(bottom: 12),
//                         decoration: BoxDecoration(
//                           color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
//                         ),
//                         child: IntrinsicHeight(
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 6,
//                                 decoration: BoxDecoration(
//                                   color: hasGrade ? Colors.green : Colors.grey.withAlpha(100),
//                                   borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: ListTile(
//                                   onTap: () => _showStudentProfile(studentId, studentData['name'], studentData['division']),
//                                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                   leading: CircleAvatar(
//                                     radius: 22,
//                                     backgroundColor: hasGrade ? Colors.green.withAlpha(20) : (isDark ? Colors.black26 : const Color(0xFFF1F3F8)),
//                                     child: Icon(hasGrade ? Icons.verified_rounded : Icons.person_search_rounded, color: hasGrade ? Colors.green : Colors.grey, size: 20),
//                                   ),
//                                   title: Text(
//                                     studentData['name'] ?? 'Unknown',
//                                     style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   subtitle: Text(
//                                     "ID: $studentId • ${_getDivisionName(studentData['division'])}",
//                                     style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   trailing: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                                         decoration: BoxDecoration(color: hasGrade ? color.withAlpha(15) : (isDark ? Colors.black26 : const Color(0xFFF1F3F8)), borderRadius: BorderRadius.circular(10)),
//                                         child: Text(hasGrade ? grade.toString() : "--", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: hasGrade ? color : Colors.grey)),
//                                       ),
//                                       const SizedBox(width: 4),
//                                       IconButton(
//                                         visualDensity: VisualDensity.compact,
//                                         icon: Icon(Icons.edit_note_rounded, color: isDark ? color : const Color(0xFF673AB7), size: 26),
//                                         onPressed: () => _showGradeDialog(studentId, studentData['name']),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _statCard(String label, int count, Color color, IconData icon, bool isDark) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(15),
//         decoration: BoxDecoration(
//           color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 10, offset: const Offset(0, 5))],
//           border: Border.all(color: color.withAlpha(30)),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: color, size: 24),
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w700)),
//                 Text("$count", style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showStudentProfile(String studentId, String studentName, String? division) async {
//     _ds.playClickSound();
//     bool isAr = _ds.isArabic;
//     bool isDark = _ds.isDarkMode;
//     Color color = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
//     final attQuery = await _ds.attendanceColl.where('studentId', isEqualTo: studentId.trim()).where('subject', isEqualTo: _selectedSubject?.trim()).get();
//     final subQuery = await _ds.submissionsColl.where('studentId', isEqualTo: studentId.trim()).where('subject', isEqualTo: _selectedSubject?.trim()).get();
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//           backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//           title: Column(children: [
//             CircleAvatar(radius: 40, backgroundColor: color.withAlpha(20), child: Icon(Icons.person, size: 45, color: color)),
//             const SizedBox(height: 15),
//             Text(studentName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center)
//           ]),
//           content: Column(mainAxisSize: MainAxisSize.min, children: [
//             _profileDetailRow(Icons.account_tree_rounded, isAr ? "الشعبة:" : "Division:", _getDivisionName(division), isDark),
//             _profileDetailRow(Icons.fact_check_rounded, isAr ? "حضور المادة:" : "Attendance:", "${attQuery.docs.length}", isDark),
//             _profileDetailRow(Icons.cloud_done_rounded, isAr ? "أبحاث مرفوعة:" : "Researches:", "${subQuery.docs.length}", isDark),
//           ]),
//           actions: [Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? "فهمت" : "Close", style: TextStyle(fontWeight: FontWeight.w900, color: color))))]
//       ),
//     );
//   }
//
//   Widget _profileDetailRow(IconData icon, String label, String value, bool isDark) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//       decoration: BoxDecoration(color: isDark ? Colors.black26 : const Color(0xFFF8F9FE), borderRadius: BorderRadius.circular(15)),
//       child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         Row(children: [Icon(icon, size: 20, color: isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7)), const SizedBox(width: 10), Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87))]),
//         Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF2D3142)))
//       ]),
//     );
//   }
//
//   void _showGradeDialog(String studentId, String studentName) {
//     _ds.playClickSound();
//     bool isAr = _ds.isArabic;
//     bool isDark = _ds.isDarkMode;
//     Color color = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
//     _gradeController.clear();
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//         title: Text(isAr ? 'رصد درجة الطالب' : 'Assign Grade', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(studentName, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
//             const SizedBox(height: 20),
//             TextField(
//                 controller: _gradeController,
//                 keyboardType: TextInputType.number,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
//                 decoration: InputDecoration(
//                   labelText: isAr ? 'الدرجة من 40' : 'Grade (Max 40)',
//                   labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
//                   filled: true, fillColor: isDark ? Colors.black26 : const Color(0xFFF8F9FE),
//                 )
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey))),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: isDark ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//             onPressed: () async {
//               _ds.playClickSound();
//               final gradeText = _gradeController.text;
//               final grade = double.tryParse(gradeText);
//               if (grade == null || grade < 0 || grade > 40) {
//                 if (!mounted) return;
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(isAr ? 'الدرجة يجب أن تكون بين 0 و 40' : 'Grade must be between 0 and 40')));
//                 return;
//               }
//               await _ds.assignGrade(studentId.trim(), _selectedSubject!.trim(), grade);
//               if (!mounted) return;
//               _gradeController.clear();
//               Navigator.pop(ctx);
//               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم الحفظ بنجاح' : 'Saved Successfully')));
//             },
//             child: Text(isAr ? 'حفظ' : 'Save'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showBulkGradeDialog(Color color) {
//     _ds.playClickSound();
//     bool isAr = _ds.isArabic;
//     bool isDark = _ds.isDarkMode;
//     _allGradesController.clear();
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//         title: Text(isAr ? 'رصد درجة لجميع الطلاب' : 'Grade All Students', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(isAr ? 'سيتم تطبيق هذه الدرجة على كل الطلاب في هذه القائمة' : 'This grade will be applied to all students in this list', style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
//             const SizedBox(height: 20),
//             TextField(
//                 controller: _allGradesController,
//                 keyboardType: TextInputType.number,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
//                 decoration: InputDecoration(
//                   labelText: isAr ? 'الدرجة الموحدة (من 40)' : 'Bulk Grade (Max 40)',
//                   labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
//                   filled: true, fillColor: isDark ? Colors.black26 : const Color(0xFFF8F9FE),
//                 )
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey))),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: isDark ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//             onPressed: () async {
//               _ds.playClickSound();
//               final gradeText = _allGradesController.text;
//               final grade = double.tryParse(gradeText);
//               if (grade == null || grade < 0 || grade > 40) {
//                 if (!mounted) return;
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(isAr ? 'الدرجة يجب أن تكون بين 0 و 40' : 'Grade must be between 0 and 40')));
//                 return;
//               }
//
//               final studentsSnapshot = await _ds.studentsColl.get();
//               final studentsToGrade = studentsSnapshot.docs.where((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 bool levelMatch = data['level'].toString().trim() == _selectedLevel.toString().trim();
//                 String studentDiv = _normalize(data['division']?.toString() ?? 'ALL');
//                 String selectedDiv = _normalize(_selectedDivision ?? 'ALL');
//                 return levelMatch && (selectedDiv == 'all' || studentDiv == selectedDiv || studentDiv == 'all');
//               }).toList();
//
//               WriteBatch batch = FirebaseFirestore.instance.batch();
//               for (var studentDoc in studentsToGrade) {
//                 String sId = (studentDoc.data() as Map<String, dynamic>)['id'].toString().trim();
//                 DocumentReference gradeRef = _ds.gradesColl.doc('${sId}_${_selectedSubject!.trim()}');
//                 batch.set(gradeRef, {
//                   'studentId': sId,
//                   'subject': _selectedSubject!.trim(),
//                   'grade': grade,
//                   'doctorName': _ds.currentDoctor?['name'] ?? 'Doctor',
//                   'date': FieldValue.serverTimestamp(),
//                 });
//               }
//
//               await batch.commit();
//
//               if (!mounted) return;
//               _allGradesController.clear();
//               Navigator.pop(ctx);
//               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم رصد الدرجة للجميع بنجاح' : 'Bulk Grades Saved Successfully')));
//             },
//             child: Text(isAr ? 'رصد للكل' : 'Apply to All'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showClearAllGradesDialog(Color color) {
//     _ds.playClickSound();
//     bool isAr = _ds.isArabic;
//     bool isDark = _ds.isDarkMode;
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//         title: Text(isAr ? 'حذف جميع الدرجات' : 'Clear All Grades', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.red)),
//         content: Text(
//           isAr
//             ? 'هل أنت متأكد من حذف جميع الدرجات المرصودة لهذه المادة في هذه القائمة؟ لا يمكن التراجع عن هذا الإجراء.'
//             : 'Are you sure you want to delete all recorded grades for this subject in this list? This action cannot be undone.',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey))),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//             onPressed: () async {
//               _ds.playClickSound();
//
//               final studentsSnapshot = await _ds.studentsColl.get();
//               final studentsToClear = studentsSnapshot.docs.where((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 bool levelMatch = data['level'].toString().trim() == _selectedLevel.toString().trim();
//                 String studentDiv = _normalize(data['division']?.toString() ?? 'ALL');
//                 String selectedDiv = _normalize(_selectedDivision ?? 'ALL');
//                 return levelMatch && (selectedDiv == 'all' || studentDiv == selectedDiv || studentDiv == 'all');
//               }).toList();
//
//               WriteBatch batch = FirebaseFirestore.instance.batch();
//               for (var studentDoc in studentsToClear) {
//                 String sId = (studentDoc.data() as Map<String, dynamic>)['id'].toString().trim();
//                 DocumentReference gradeRef = _ds.gradesColl.doc('${sId}_${_selectedSubject!.trim()}');
//                 batch.delete(gradeRef);
//               }
//
//               await batch.commit();
//
//               if (!mounted) return;
//               Navigator.pop(ctx);
//               ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(isAr ? 'تم حذف جميع الدرجات بنجاح' : 'All Grades Cleared Successfully')));
//             },
//             child: Text(isAr ? 'حذف الكل' : 'Clear All'),
//           ),
//         ],
//       ),
//     );
//   }
// }
