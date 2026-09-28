import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import '../services/data_service.dart';

class ResearchSubmissionsScreen extends StatefulWidget {
  const ResearchSubmissionsScreen({super.key});

  @override
  State<ResearchSubmissionsScreen> createState() => _ResearchSubmissionsScreenState();
}

class _ResearchSubmissionsScreenState extends State<ResearchSubmissionsScreen> {
  final DataService _ds = DataService();
  String? _selectedSubject;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeArabic(String text) {
    String normalized = text.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا');
    normalized = normalized.replaceAll('ة', 'ه');
    normalized = normalized.replaceAll('ى', 'ي');
    return normalized;
  }

  Future<void> _launchURL(String url) async {
    if (url.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("رابط الملف غير متاح")));
      return;
    }

    try {
      if (kIsWeb) {
        html.window.open(url, '_blank');
        return;
      }

      final Uri uri = Uri.parse(url);
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تعذر فتح ملف البحث")));
      }
    } catch (e) {
      debugPrint("Launch Error: $e");
      try {
        final Uri uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في فتح الملف: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        bool isAr = _ds.isArabic;
        bool isDark = _ds.isDarkMode;
        Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              title: Text(_selectedSubject ?? _ds.translate('research_review'), 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF673AB7),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if (_selectedSubject != null) {
                    setState(() { _selectedSubject = null; _searchQuery = ""; _searchController.clear(); });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            body: _ds.currentDoctor == null
                ? const Center(child: Text('يرجى تسجيل الدخول'))
                : _selectedSubject == null
                    ? _buildSubjectSelection(primaryColor, isDark)
                    : _buildMainContent(primaryColor, isDark),
          ),
        );
      }
    );
  }

  Widget _buildSubjectSelection(Color color, bool isDark) {
    final doctorId = _ds.currentDoctor?['uid'] ?? '';
    final teachingLevels = List<String>.from(_ds.currentDoctor?['teachingLevels'] ?? []);

    if (teachingLevels.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_ds.isArabic ? "لم يتم إسناد فرق دراسية لك بعد" : "No levels assigned")));
    }

    return StreamBuilder<List<QuerySnapshot>>(
      stream: Stream.fromFuture(Future.wait(
        teachingLevels.map((lvlId) => 
          _ds.getCommerceCoursesColl(lvlId).where('doctor_id', isEqualTo: doctorId).get()
        )
      )),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allDocs = snapshot.data?.expand((qs) => qs.docs).toList() ?? [];
        
        if (allDocs.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_ds.translate('no_subjects_assigned'))));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: allDocs.length,
          itemBuilder: (ctx, i) {
            final data = allDocs[i].data() as Map<String, dynamic>;
            final name = data['name']?.toString() ?? 'Unknown';
            final level = data['level_id']?.toString().replaceAll('level_', '') ?? '';
            
            return Card(
              elevation: isDark ? 0 : 2,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(26), 
                  child: Icon(Icons.folder_shared_rounded, color: color)
                ),
                title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text("${_ds.isArabic ? 'الفرقة:' : 'Lvl:'} $level", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
                onTap: () => setState(() => _selectedSubject = name),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent(Color color, bool isDark) {
    bool isAr = _ds.isArabic;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: isAr ? "ابحث باسم الطالب..." : "Search by student name...",
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
              prefixIcon: Icon(Icons.search_rounded, color: color),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              }) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(child: _buildSubmissionsList(_selectedSubject!, color, isDark)),
      ],
    );
  }

  Widget _buildSubmissionsList(String subject, Color color, bool isDark) {
    bool isAr = _ds.isArabic;
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.submissionsColl
          .where('subject', isEqualTo: subject)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        
        if (docs.isEmpty) return Center(child: Text(isAr ? 'لا توجد أبحاث مرفوعة لهذه المادة' : 'No submissions', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)));

        List<QueryDocumentSnapshot> submissions = docs;

        if (_searchQuery.isNotEmpty) {
          String q = _normalizeArabic(_searchQuery);
          submissions = submissions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String name = _normalizeArabic(data['studentName'] ?? '');
            return name.contains(q);
          }).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  _statCard(isAr ? "إجمالي الأبحاث" : "Total", submissions.length, color, isDark),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                itemCount: submissions.length,
                itemBuilder: (ctx, i) {
                  final String docId = submissions[i].id;
                  final r = submissions[i].data() as Map<String, dynamic>;
                  final fileUrl = r['fileUrl'] ?? "";

                  if (r['isSeen'] == false) {
                    _ds.updateResearchStatus(docId, r['status'], markAsSeen: true);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black.withAlpha(8), blurRadius: 10)],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            decoration: BoxDecoration(
                              color: color.withAlpha(128),
                              borderRadius: BorderRadius.only(
                                topRight: isAr ? const Radius.circular(18) : Radius.zero,
                                bottomRight: isAr ? const Radius.circular(18) : Radius.zero,
                                topLeft: !isAr ? const Radius.circular(18) : Radius.zero,
                                bottomLeft: !isAr ? const Radius.circular(18) : Radius.zero,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.red.withAlpha(26),
                                child: const Icon(Icons.list_alt, color: Colors.red, size: 22),
                              ),
                              title: Text(r['studentName'] ?? 'Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(r['fileName'] ?? 'file', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(isAr ? "تم الرفع: ${r['subject']}" : "Uploaded for: ${r['subject']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.star_rate_rounded, color: Colors.orange, size: 22),
                                    onPressed: () => _showEvaluationDialog(docId, r),
                                    tooltip: isAr ? "تقييم" : "Evaluate",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.blue, size: 22),
                                    onPressed: () => _launchURL(fileUrl),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                                    onPressed: () => _ds.deleteResearch(docId),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEvaluationDialog(String docId, Map<String, dynamic> data) {
    final gradeController = TextEditingController(text: data['grade']?.toString() ?? '');
    final commentController = TextEditingController(text: data['comment']?.toString() ?? '');
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isAr ? "تقييم البحث" : "Evaluate Research", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isAr ? "الدرجة" : "Grade",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isAr ? "تعليقك" : "Comment",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? "إلغاء" : "Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF673AB7)),
            onPressed: () async {
              await _ds.updateResearchStatus(
                docId, 
                'Graded', 
                grade: gradeController.text, 
                comment: commentController.text
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(isAr ? "حفظ" : "Save", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withAlpha(26)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$label: ", style: TextStyle(color: isDark ? Colors.white70 : color.withAlpha(204), fontSize: 14, fontWeight: FontWeight.bold)),
            Text("$count", style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
