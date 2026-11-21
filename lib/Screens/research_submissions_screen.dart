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
  String? _selectedTopicId; // ✅ NEW: Selected topic to view researches
  String? _selectedTopicTitle; // ✅ NEW: Topic title
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 0: لم تُراجع, 1: تحت المراجعة (مسودة), 2: تمت المراجعة والنشر, 3: المقيّمة
  int _selectedCategoryIndex = 0;

  // ✅ NEW: For moving researches between topics
  Set<String> _selectedResearchIds = {};
  bool _isSelectionMode = false;

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

  String _formatTimestamp(dynamic timestamp, bool isAr) {
    if (timestamp == null) return isAr ? "غير محدد" : "N/A";
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else if (timestamp is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      dt = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    }

    String year = dt.year.toString();
    String month = dt.month.toString().padLeft(2, '0');
    String day = dt.day.toString().padLeft(2, '0');
    int hour = dt.hour;
    String minute = dt.minute.toString().padLeft(2, '0');
    String period = hour >= 12 ? (isAr ? "م" : "PM") : (isAr ? "ص" : "AM");
    int hour12 = hour % 12;
    if (hour12 == 0) hour12 = 12;

    return "$year/$month/$day - ${hour12.toString().padLeft(2, '0')}:$minute $period";
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
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF673AB7),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if (_selectedTopicId != null) {
                    // Back from topic view to topics list
                    setState(() {
                      _selectedTopicId = null;
                      _selectedTopicTitle = null;
                      _isSelectionMode = false;
                      _selectedResearchIds.clear();
                    });
                  } else if (_selectedSubject != null) {
                    // Back from subject to subject selection
                    setState(() {
                      _selectedSubject = null;
                      _searchQuery = "";
                      _searchController.clear();
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              actions: _selectedTopicId != null && !_isSelectionMode
                  ? [
                      IconButton(
                        icon: const Icon(Icons.checklist),
                        tooltip: isAr ? 'تحديد أبحاث' : 'Select researches',
                        onPressed: () => setState(() => _isSelectionMode = true),
                      ),
                    ]
                  : _isSelectionMode
                      ? [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSelectionMode = false;
                                _selectedResearchIds.clear();
                              });
                            },
                            child: Text(
                              isAr ? 'إلغاء' : 'Cancel',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (_selectedResearchIds.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.drive_file_move),
                              tooltip: isAr ? 'نقل إلى عنوان آخر' : 'Move to another topic',
                              onPressed: () => _showMoveToTopicDialog(primaryColor, isDark),
                            ),
                        ]
                      : null,
            ),
            body: _ds.currentDoctor == null
                ? Center(child: Text(isAr ? 'يرجى تسجيل الدخول' : 'Please login', style: GoogleFonts.cairo()))
                : _selectedSubject == null
                    ? _buildSubjectSelection(primaryColor, isDark)
                    : _selectedTopicId == null
                        ? _buildTopicsList(primaryColor, isDark)
                        : _buildMainContent(primaryColor, isDark),
            floatingActionButton: _selectedSubject != null && _selectedTopicId == null && _ds.currentDoctor != null
                ? FloatingActionButton.extended(
                    onPressed: () => _showManageTopicsDialog(primaryColor, isDark),
                    backgroundColor: primaryColor,
                    icon: const Icon(Icons.topic_rounded, color: Colors.white),
                    label: Text(isAr ? 'إدارة العناوين' : 'Manage Topics',
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                : null,
          ),
        );
      }
    );
  }

  Widget _buildSubjectSelection(Color color, bool isDark) {
    final doctorUid = _ds.currentDoctor?['uid'] ?? '';
    final doctorId = _ds.currentDoctor?['id'] ?? '';
    final doctorSubjects = List<String>.from(_ds.currentDoctor?['subjects'] ?? []);
    final teachingLevels = List<String>.from(_ds.currentDoctor?['teachingLevels'] ?? ['level_1', 'level_2', 'level_3', 'level_4']);

    if (teachingLevels.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_ds.isArabic ? "لم يتم إسناد فرق دراسية لك بعد" : "No levels assigned", style: GoogleFonts.cairo())));
    }

    return StreamBuilder<List<QuerySnapshot>>(
      stream: Stream.fromFuture(Future.wait(
        teachingLevels.map((lvlId) => 
          _ds.getInstituteCoursesColl(lvlId.startsWith('level_') ? lvlId : 'level_$lvlId').get()
        )
      )),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allDocs = snapshot.data?.expand((qs) => qs.docs).where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final docDoctorId = d['doctor_id']?.toString() ?? '';
          final docTaId = d['ta_id']?.toString() ?? '';
          final docName = d['name']?.toString().trim() ?? '';
          
          bool isMyDoctorId = (docDoctorId.isNotEmpty && (docDoctorId == doctorUid || docDoctorId == doctorId));
          bool isMyTaId = (docTaId.isNotEmpty && (docTaId == doctorUid || docTaId == doctorId));
          bool isMySubject = doctorSubjects.any((s) => s.trim().toLowerCase() == docName.toLowerCase());
          
          return isMyDoctorId || isMyTaId || isMySubject;
        }).toList() ?? [];
        
        if (allDocs.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_ds.translate('no_subjects_assigned'), style: GoogleFonts.cairo())));
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
                title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text("${_ds.isArabic ? 'الفرقة:' : 'Lvl:'} $level", style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.grey)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
                onTap: () => setState(() => _selectedSubject = name),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopicsList(Color color, bool isDark) {
    bool isAr = _ds.isArabic;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.topic, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'عناوين الأبحاث' : 'Research Topics',
                  style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _ds.getResearchTopics(subject: _selectedSubject, onlyActive: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.topic_outlined, size: 80, color: Colors.grey.withAlpha(128)),
                      const SizedBox(height: 20),
                      Text(
                        isAr ? 'لا توجد عناوين بعد' : 'No topics yet',
                        style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final topics = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: topics.length + 1, // +1 for "No Topic" section
                itemBuilder: (context, index) {
                  // First item: "No Topic" (old researches)
                  if (index == 0) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: _ds.instituteRef
                          .collection('researches')
                          .where('subject', isEqualTo: _selectedSubject)
                          .where('researchTopicId', isEqualTo: null)
                          .snapshots(),
                      builder: (context, researchSnapshot) {
                        final researchCount = researchSnapshot.hasData ? researchSnapshot.data!.docs.length : 0;

                        if (researchCount == 0) return const SizedBox.shrink(); // Hide if no old researches

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: isDark ? 0 : 3,
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setState(() {
                                _selectedTopicId = 'no_topic';
                                _selectedTopicTitle = isAr ? 'بدون عنوان' : 'No Topic';
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(26),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$researchCount',
                                          style: GoogleFonts.cairo(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          isAr ? 'بحث' : 'papers',
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.folder_open, size: 20, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                isAr ? 'بدون عنوان' : 'No Topic',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isAr ? 'أبحاث قديمة غير مصنفة' : 'Old uncategorized researches',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Regular topics (index - 1 because of "No Topic" item)
                  final topic = topics[index - 1];
                  final topicId = topic['id'] ?? '';
                  final title = topic['title'] ?? '';
                  final isActive = topic['isActive'] ?? true;
                  final deadline = topic['deadline'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(topic['deadline'])
                      : null;
                  final remainingDays = topic['remainingDays'];
                  final isExpired = topic['isExpired'] ?? false;

                  // Count researches for this topic
                  return StreamBuilder<QuerySnapshot>(
                    stream: _ds.instituteRef
                        .collection('researches')
                        .where('subject', isEqualTo: _selectedSubject)
                        .where('researchTopicId', isEqualTo: topicId)
                        .snapshots(),
                    builder: (context, researchSnapshot) {
                      final researchCount = researchSnapshot.hasData ? researchSnapshot.data!.docs.length : 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: isDark ? 0 : 3,
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            setState(() {
                              _selectedTopicId = topicId;
                              _selectedTopicTitle = title;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: (isActive && !isExpired ? color : Colors.grey).withAlpha(26),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$researchCount',
                                        style: GoogleFonts.cairo(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isActive && !isExpired ? color : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        isAr ? 'بحث' : 'papers',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (!isActive)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withAlpha(26),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isAr ? 'مخفي' : 'Hidden',
                                                style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (deadline != null) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              isExpired ? Icons.event_busy : Icons.event,
                                              size: 14,
                                              color: isExpired ? Colors.red : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${deadline.year}/${deadline.month}/${deadline.day}',
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                color: isExpired ? Colors.red : Colors.grey,
                                              ),
                                            ),
                                            if (remainingDays != null && remainingDays > 0) ...[
                                              Text(
                                                ' • ',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                              Text(
                                                isAr ? 'متبقي $remainingDays يوم' : '$remainingDays days left',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  color: remainingDays <= 3 ? Colors.red : Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: color),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(Color color, bool isDark) {
    bool isAr = _ds.isArabic;

    // Handle "No Topic" section
    final isNoTopicSection = _selectedTopicId == 'no_topic';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: isAr ? "ابحث باسم الطالب..." : "Search by student name...",
              hintStyle: GoogleFonts.cairo(color: isDark ? Colors.white38 : Colors.grey),
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
        _buildCategoryTabs(color, isDark),
        Expanded(child: _buildSubmissionsList(_selectedSubject!, color, isDark)),
      ],
    );
  }

  Widget _buildCategoryTabs(Color primaryColor, bool isDark) {
    bool isAr = _ds.isArabic;
    final List<Map<String, dynamic>> categories = [
      {'title': isAr ? 'لم تُراجع' : 'Unreviewed', 'icon': Icons.pending_actions_rounded},
      {'title': isAr ? 'تحت المراجعة (مسودة)' : 'Under Review', 'icon': Icons.edit_note_rounded},
      {'title': isAr ? 'تمت المراجعة والنشر' : 'Published', 'icon': Icons.published_with_changes_rounded},
      {'title': isAr ? 'المقيّمة (الكل)' : 'All Evaluated', 'icon': Icons.grading_rounded},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                categories[index]['icon'],
                size: 18,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
              label: Text(
                categories[index]['title'],
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF673AB7),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF673AB7) : (isDark ? Colors.white12 : Colors.grey.shade300),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategoryIndex = index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmissionsList(String subject, Color color, bool isDark) {
    bool isAr = _ds.isArabic;
    final doctorUid = _ds.currentDoctor?['uid'] ?? '';
    final doctorId = _ds.currentDoctor?['id'] ?? '';

    // ✅ Handle "No Topic" section (old researches without topicId)
    final isNoTopicSection = _selectedTopicId == 'no_topic';

    return StreamBuilder<QuerySnapshot>(
      stream: _ds.submissionsColl
          .where('subject', isEqualTo: subject)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        var filteredSubmissions = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docDocId = data['doctorId']?.toString();
          final recType = data['recipientType']?.toString();

          // ✅ Filter by topic
          final researchTopicId = data['researchTopicId'];
          if (isNoTopicSection) {
            // Show only researches without topic
            if (researchTopicId != null && researchTopicId.toString().isNotEmpty) return false;
          } else {
            // Show only researches matching selected topic
            if (researchTopicId != _selectedTopicId) return false;
          }

          if (docDocId != null && docDocId.isNotEmpty) {
            if (docDocId == doctorUid || docDocId == doctorId) return true;
          }
          if (recType != null && recType.isNotEmpty) {
            return recType == _ds.userRole;
          }
          return true;
        }).toList();

        if (filteredSubmissions.isEmpty) {
          return Center(
            child: Text(
              isAr ? 'لا توجد أبحاث مرفوعة لهذه المادة' : 'No submissions',
              style: GoogleFonts.cairo(color: isDark ? Colors.white38 : Colors.grey),
            ),
          );
        }

        // TERTIB: الترتيب بحسب وقت الاستلام (من الأحدث للأقدم)
        filteredSubmissions.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          dynamic tA = dataA['date'] ?? dataA['timestamp'];
          dynamic tB = dataB['date'] ?? dataB['timestamp'];

          int msA = 0;
          int msB = 0;
          if (tA is Timestamp) msA = tA.millisecondsSinceEpoch;
          else if (tA is int) msA = tA;

          if (tB is Timestamp) msB = tB.millisecondsSinceEpoch;
          else if (tB is int) msB = tB;

          return msB.compareTo(msA);
        });

        // FILTER: التصفية بحسب التبويب المختار (الخانات الأربع)
        List<QueryDocumentSnapshot> submissions = filteredSubmissions.where((doc) {
          final r = doc.data() as Map<String, dynamic>;
          bool isPublished = r['isPublished'] == true;
          bool isDraft = r['isDraft'] == true;
          bool hasGrade = r['grade'] != null && r['grade'].toString().trim().isNotEmpty;

          if (_selectedCategoryIndex == 0) {
            // 0: لم تُراجع (ليس لها درجة وليست مسودة وليست منشورة)
            return !isPublished && !isDraft && !hasGrade;
          } else if (_selectedCategoryIndex == 1) {
            // 1: تحت المراجعة (مسودة) (لها درجة/تعليق لكن لم تُنشر للطالب بعد)
            return isDraft || (!isPublished && hasGrade);
          } else if (_selectedCategoryIndex == 2) {
            // 2: تمت المراجعة والنشر للطالب
            return isPublished;
          } else {
            // 3: المقيّمة (جميع الأبحاث المقيّمة سواء مسودة أو منشورة)
            return hasGrade || isDraft || isPublished;
          }
        }).toList();

        // SEARCH: التصفية بالاسم
        if (_searchQuery.isNotEmpty) {
          String q = _normalizeArabic(_searchQuery);
          submissions = submissions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String name = _normalizeArabic(data['studentName'] ?? '');
            return name.contains(q);
          }).toList();
        }

        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.withAlpha(80)),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'لا توجد أبحاث في هذه الخانة حالياً' : 'No submissions in this category',
                  style: GoogleFonts.cairo(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                children: [
                  _statCard(
                    _getCategoryTitle(_selectedCategoryIndex, isAr),
                    submissions.length,
                    color,
                    isDark,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(15, 4, 15, 20),
                itemCount: submissions.length,
                itemBuilder: (ctx, i) {
                  final String docId = submissions[i].id;
                  final r = submissions[i].data() as Map<String, dynamic>;
                  final fileUrl = r['fileUrl'] ?? "";

                  if (r['isSeen'] == false) {
                    _ds.updateResearchStatus(docId, r['status'], markAsSeen: true);
                  }

                  bool isPublished = r['isPublished'] == true;
                  bool isDraft = r['isDraft'] == true;
                  bool hasGrade = r['grade'] != null && r['grade'].toString().trim().isNotEmpty;

                  String statusBadgeText = isAr ? "لم تُراجع بعد" : "Unreviewed";
                  Color statusBadgeColor = Colors.grey;

                  if (isPublished) {
                    statusBadgeText = isAr ? "تمت المراجعة والنشر 🟢" : "Published 🟢";
                    statusBadgeColor = Colors.green;
                  } else if (isDraft || hasGrade) {
                    statusBadgeText = isAr ? "قيد المراجعة (مسودة)" : "Under Review (Draft)";
                    statusBadgeColor = Colors.orange;
                  }

                  String dateFormatted = _formatTimestamp(r['date'] ?? r['timestamp'], isAr);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black.withAlpha(8), blurRadius: 10)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: color.withAlpha(26),
                                backgroundImage: _ds.getAvatarImageProvider(r['photoUrl']),
                                child: (r['photoUrl'] ?? '').toString().isEmpty
                                    ? Icon(Icons.picture_as_pdf_rounded, color: color, size: 22)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['studentName'] ?? 'Student',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                                    ),
                                    Text(
                                      r['fileName'] ?? 'file',
                                      style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBadgeColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: statusBadgeColor.withAlpha(80)),
                                ),
                                child: Text(
                                  statusBadgeText,
                                  style: GoogleFonts.cairo(color: statusBadgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                "${isAr ? 'وقت الاستلام:' : 'Submitted:'} $dateFormatted",
                                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          if (hasGrade) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isPublished ? Colors.green : Colors.orange).withAlpha(15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: (isPublished ? Colors.green : Colors.orange).withAlpha(40)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPublished ? Icons.check_circle_outline_rounded : Icons.edit_note_rounded,
                                    size: 18,
                                    color: isPublished ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${isAr ? 'الدرجة:' : 'Grade:'} ${r['grade']}",
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: isPublished ? Colors.green : Colors.orange),
                                  ),
                                  if ((r['comment'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "${isAr ? 'الملاحظات:' : 'Notes:'} ${r['comment']}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF673AB7),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: const Icon(Icons.rate_review_rounded, size: 18),
                                  label: Text(
                                    hasGrade ? (isAr ? 'تعديل التقييم' : 'Edit Evaluation') : (isAr ? 'تقييم البحث' : 'Evaluate Research'),
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: () => _showEvaluationDialog(docId, r),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                label: Text(isAr ? 'فتح الملف' : 'Open', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _launchURL(fileUrl),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                tooltip: isAr ? 'حذف' : 'Delete',
                                onPressed: () => _ds.deleteResearch(docId),
                              ),
                            ],
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

  String _getCategoryTitle(int index, bool isAr) {
    switch (index) {
      case 0:
        return isAr ? "الأبحاث غير المراجعة" : "Unreviewed Submissions";
      case 1:
        return isAr ? "الأبحاث تحت المراجعة (مسودات)" : "Under Review (Drafts)";
      case 2:
        return isAr ? "الأبحاث المنشورة للطلاب" : "Published Submissions";
      case 3:
      default:
        return isAr ? "جميع الأبحاث المقيّمة" : "All Evaluated Submissions";
    }
  }

  void _showEvaluationDialog(String docId, Map<String, dynamic> data) {
    final gradeController = TextEditingController(text: data['grade']?.toString() ?? '');
    final commentController = TextEditingController(text: data['comment']?.toString() ?? '');
    bool publishToStudent = data['isPublished'] == true;
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.rate_review_rounded, color: Color(0xFF673AB7)),
              const SizedBox(width: 10),
              Text(isAr ? "تقييم وتقويم البحث" : "Evaluate Research", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${isAr ? 'الطالب:' : 'Student:'} ${data['studentName'] ?? ''}",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gradeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? "الدرجة / التقييم" : "Grade / Score",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.grade_rounded, color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isAr ? "ملاحظات وتوجيهات الدكتور" : "Doctor Feedback / Notes",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.comment_outlined, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (publishToStudent ? Colors.green : Colors.orange).withAlpha(15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: (publishToStudent ? Colors.green : Colors.orange).withAlpha(40)),
                  ),
                  child: CheckboxListTile(
                    activeColor: Colors.green,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      isAr ? "نشر التقييم والنتيجة للطالب" : "Publish result to student",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: publishToStudent ? Colors.green : Colors.orange),
                    ),
                    subtitle: Text(
                      publishToStudent
                          ? (isAr ? "سيتم إظهار التقييم للطالب وإرسال إشعار له" : "Grade will be published to student")
                          : (isAr ? "حفظ كمسودة خاصة تحت المراجعة (لن يراها الطالب بعد)" : "Save as draft (Hidden from student)"),
                      style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                    ),
                    value: publishToStudent,
                    onChanged: (val) {
                      setDialogState(() => publishToStudent = val ?? false);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? "إلغاء" : "Cancel", style: GoogleFonts.cairo()),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: publishToStudent ? Colors.green : const Color(0xFF673AB7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: Icon(publishToStudent ? Icons.send_rounded : Icons.save_rounded, size: 18),
              label: Text(
                publishToStudent ? (isAr ? "نشر للطالب" : "Publish") : (isAr ? "حفظ كمسودة" : "Save Draft"),
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                bool isDraft = !publishToStudent;
                String statusName = publishToStudent ? 'Reviewed' : 'Under Review';

                await _ds.updateResearchStatus(
                  docId, 
                  statusName, 
                  grade: gradeController.text.trim(), 
                  comment: commentController.text.trim(),
                  isPublished: publishToStudent,
                  isDraft: isDraft,
                );

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        publishToStudent
                            ? (isAr ? "تم نشر تقييم البحث للطالب بنجاح 🎉" : "Evaluation published 🎉")
                            : (isAr ? "تم حفظ التقييم كمسودة خاصة تحت المراجعة 📝" : "Saved as draft 📝"),
                        style: GoogleFonts.cairo(),
                      ),
                      backgroundColor: publishToStudent ? Colors.green : Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.cairo(color: isDark ? Colors.white70 : color, fontSize: 13, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Text("$count", style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageTopicsDialog(Color primaryColor, bool isDark) {
    bool isAr = _ds.isArabic;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(26),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'إدارة عناوين الأبحاث' : 'Manage Research Topics',
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: primaryColor, size: 30),
                      onPressed: () => _showAddTopicDialog(primaryColor, isDark),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _ds.getResearchTopics(
                    subject: _selectedSubject,
                    onlyActive: false,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.topic_outlined, size: 80, color: Colors.grey.withAlpha(128)),
                            const SizedBox(height: 20),
                            Text(
                              isAr ? 'لا توجد عناوين بعد' : 'No topics yet',
                              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isAr ? 'اضغط + لإضافة عنوان جديد' : 'Press + to add a topic',
                              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final topics = snapshot.data!;

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(15),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final data = topics[index];
                        final topicId = data['id'] ?? '';
                        final title = data['title'] ?? '';
                        final isActive = data['isActive'] ?? true;
                        final deadline = data['deadline'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(data['deadline'])
                            : null;

                        final isExpired = deadline != null && DateTime.now().isAfter(deadline);
                        final remainingDays = deadline?.difference(DateTime.now()).inDays;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isDark ? 0 : 2,
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isActive && !isExpired
                                  ? Colors.green.withAlpha(26)
                                  : Colors.grey.withAlpha(26),
                              child: Icon(
                                isActive && !isExpired ? Icons.check_circle : Icons.cancel,
                                color: isActive && !isExpired ? Colors.green : Colors.grey,
                              ),
                            ),
                            title: Text(
                              title,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (deadline != null)
                                  Text(
                                    isAr
                                        ? 'آخر موعد: ${deadline.year}/${deadline.month}/${deadline.day}'
                                        : 'Deadline: ${deadline.year}/${deadline.month}/${deadline.day}',
                                    style: GoogleFonts.cairo(fontSize: 12, color: isExpired ? Colors.red : Colors.grey),
                                  ),
                                if (remainingDays != null && remainingDays > 0)
                                  Text(
                                    isAr ? 'متبقي $remainingDays يوم' : '$remainingDays days left',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: remainingDays < 7 ? Colors.orange : Colors.grey,
                                    ),
                                  ),
                                if (isExpired)
                                  Text(
                                    isAr ? 'انتهى الموعد' : 'Expired',
                                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.red),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit, size: 20),
                                      const SizedBox(width: 10),
                                      Text(isAr ? 'تعديل' : 'Edit', style: GoogleFonts.cairo()),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        isActive ? (isAr ? 'إخفاء' : 'Hide') : (isAr ? 'إظهار' : 'Show'),
                                        style: GoogleFonts.cairo(),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete, size: 20, color: Colors.red),
                                      const SizedBox(width: 10),
                                      Text(isAr ? 'حذف' : 'Delete',
                                          style: GoogleFonts.cairo(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditTopicDialog(topicId, data, primaryColor, isDark);
                                } else if (value == 'toggle') {
                                  _ds.updateResearchTopic(topicId, isActive: !isActive);
                                } else if (value == 'delete') {
                                  _confirmDeleteTopic(topicId, title, primaryColor, isDark);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTopicDialog(Color primaryColor, bool isDark) {
    bool isAr = _ds.isArabic;
    final titleController = TextEditingController();
    DateTime? selectedDeadline;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAr ? 'إضافة عنوان بحث جديد' : 'Add New Research Topic',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    style: GoogleFonts.cairo(),
                    decoration: InputDecoration(
                      labelText: isAr ? 'عنوان البحث' : 'Topic Title',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (isAr ? 'مطلوب' : 'Required')
                        : null,
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.withAlpha(77)),
                    ),
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedDeadline == null
                          ? (isAr ? 'اختر آخر موعد (اختياري)' : 'Select Deadline (optional)')
                          : '${selectedDeadline!.year}/${selectedDeadline!.month}/${selectedDeadline!.day}',
                      style: GoogleFonts.cairo(),
                    ),
                    trailing: selectedDeadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setDialogState(() => selectedDeadline = null),
                          )
                        : null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDeadline = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // ✅ Add debugging
                    debugPrint('Creating topic: ${titleController.text.trim()}');
                    debugPrint('Subject: $_selectedSubject');
                    debugPrint('College ID: ${_ds.selectedInstituteId}');
                    debugPrint('Doctor: ${_ds.currentDoctor?['name']}');

                    await _ds.createResearchTopic(
                      title: titleController.text.trim(),
                      subject: _selectedSubject!,
                      deadline: selectedDeadline,
                    );

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr ? 'تم إضافة العنوان بنجاح ✓' : 'Topic added successfully ✓',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('❌ Error creating topic: $e');
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${isAr ? "خطأ" : "Error"}: $e',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: Text(isAr ? 'إضافة' : 'Add', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTopicDialog(String topicId, Map<String, dynamic> data, Color primaryColor, bool isDark) {
    bool isAr = _ds.isArabic;
    final titleController = TextEditingController(text: data['title']);
    DateTime? selectedDeadline = data['deadline'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['deadline'])
        : null;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAr ? 'تعديل عنوان البحث' : 'Edit Research Topic',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    style: GoogleFonts.cairo(),
                    decoration: InputDecoration(
                      labelText: isAr ? 'عنوان البحث' : 'Topic Title',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (isAr ? 'مطلوب' : 'Required')
                        : null,
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.withAlpha(77)),
                    ),
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedDeadline == null
                          ? (isAr ? 'اختر آخر موعد (اختياري)' : 'Select Deadline (optional)')
                          : '${selectedDeadline!.year}/${selectedDeadline!.month}/${selectedDeadline!.day}',
                      style: GoogleFonts.cairo(),
                    ),
                    trailing: selectedDeadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setDialogState(() => selectedDeadline = null),
                          )
                        : null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDeadline = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _ds.updateResearchTopic(
                    topicId,
                    title: titleController.text.trim(),
                    deadline: selectedDeadline,
                  );

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr ? 'تم التعديل بنجاح ✓' : 'Updated successfully ✓',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: Text(isAr ? 'حفظ' : 'Save', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTopic(String topicId, String title, Color primaryColor, bool isDark) {
    bool isAr = _ds.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'تأكيد الحذف' : 'Confirm Delete',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAr ? 'هل تريد حذف العنوان "$title"؟' : 'Delete topic "$title"?',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await _ds.deleteResearchTopic(topicId);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr ? 'تم الحذف' : 'Deleted',
                      style: GoogleFonts.cairo(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isAr ? 'حذف' : 'Delete', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMoveToTopicDialog(Color primaryColor, bool isDark) {
    bool isAr = _ds.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'نقل إلى عنوان آخر' : 'Move to Another Topic',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _ds.getResearchTopics(subject: _selectedSubject, onlyActive: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(
                isAr ? 'لا توجد عناوين أخرى' : 'No other topics',
                style: GoogleFonts.cairo(),
              );
            }

            // Filter out current topic
            final topics = snapshot.data!.where((t) => t['id'] != _selectedTopicId).toList();

            if (topics.isEmpty) {
              return Text(
                isAr ? 'لا توجد عناوين أخرى' : 'No other topics',
                style: GoogleFonts.cairo(),
              );
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  final title = topic['title'] ?? '';
                  final topicId = topic['id'] ?? '';

                  return ListTile(
                    leading: Icon(Icons.topic, color: primaryColor),
                    title: Text(title, style: GoogleFonts.cairo()),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _moveResearchesToTopic(topicId, title);
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Future<void> _moveResearchesToTopic(String newTopicId, String newTopicTitle) async {
    bool isAr = _ds.isArabic;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final researchId in _selectedResearchIds) {
        final docRef = _ds.instituteRef.collection('researches').doc(researchId);
        batch.update(docRef, {
          'researchTopicId': newTopicId,
          'title': newTopicTitle,
        });
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedResearchIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم نقل ${_selectedResearchIds.length} بحث بنجاح'
                  : '${_selectedResearchIds.length} research(es) moved successfully',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'فشل النقل' : 'Move failed',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
