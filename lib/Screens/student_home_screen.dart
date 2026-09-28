import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/app_drawer.dart';
import 'discussion_forum_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudentHomeScreenContent();
  }
}

class _StudentHomeScreenContent extends StatefulWidget {
  const _StudentHomeScreenContent();

  @override
  State<_StudentHomeScreenContent> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<_StudentHomeScreenContent> {
  final DataService _ds = DataService();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _StudentDashboardPage(),
      const _StudentResearchsPage(),
      const _StudentSchedulePage(),
      const _StudentProfilePage(),
    ];
  }

  void _onTap(int idx) {
    setState(() {
      _ds.studentTabIndex = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        bool isAr = _ds.isArabic;
        bool isDark = _ds.isDarkMode;
        
        Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
        final studentName = _ds.currentStudent?['name'] ?? _ds.translate('welcome');
        final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            extendBody: true,
            backgroundColor: scaffoldBg,
            drawer: AppDrawer(name: studentName, role: isAr ? 'طالب جامعي' : 'University Student'),
            body: IndexedStack(index: _ds.studentTabIndex, children: _pages),
            bottomNavigationBar: _buildGlassBottomBar(primaryColor, isDark, isAr),
          ),
        );
      }
    );
  }

  Widget _buildGlassBottomBar(Color primaryColor, bool isDark, bool isAr) {
    return Container(
      height: 75,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E).withAlpha(180) : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : primaryColor.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : Colors.white.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, _ds.translate('home'), primaryColor, isDark),
                _buildNavItem(1, Icons.assignment_rounded, _ds.translate('my_researches'), primaryColor, isDark),
                _buildNavItem(2, Icons.calendar_month_rounded, _ds.translate('schedule'), primaryColor, isDark),
                _buildNavItem(3, Icons.person_rounded, _ds.translate('profile'), primaryColor, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color primaryColor, bool isDark) {
    bool isSelected = _ds.studentTabIndex == index;
    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.grey.shade500),
              size: isSelected ? 26 : 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentDashboardPage extends StatelessWidget {
  const _StudentDashboardPage();

  void _showSubjectPicker(BuildContext context, DataService ds) {
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;
    final levelRaw = ds.currentStudent?['level']?.toString() ?? '1';
    final levelId = 'level_${ds.normalizeLevel(levelRaw)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text(isAr ? "اختر المادة للدخول للنقاش" : "Select Course Forum", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: ds.instituteRef
                  .collection('levels')
                  .doc(levelId)
                  .collection('courses')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String studentDiv = ds.normalizeDivision(ds.currentStudent?['division'] ?? 'all');
                  String itemDiv = ds.normalizeDivision(data['division'] ?? 'all');
                  return itemDiv == 'all' || itemDiv == studentDiv;
                }).toList();

                if (docs.isEmpty) return Padding(padding: const EdgeInsets.all(20), child: Text(ds.translate('no_subjects_assigned')));

                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.forum_rounded)),
                        title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (ctx) => DiscussionForumScreen(
                            levelId: levelId, 
                            courseId: doc.id, 
                            courseName: name
                          )));
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;

    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    List<Color> headerGradient = isDark
        ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
        : [const Color(0xFF673AB7), const Color(0xFF512DA8)];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: headerGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withAlpha(100) : Colors.black12,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Builder(builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer()
                  )),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.notifications_none, color: isDark ? primaryColor : Colors.white),
                      onPressed: () => Navigator.pushNamed(context, '/notifications', arguments: 'student')
                    ),
                  ),
                ]),
                const SizedBox(height: 25),
                Text(ds.translate('welcome'), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                Text(ds.currentStudent?['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
            child: Text(
              isAr ? "الخدمات الطلابية" : "Services",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              mainAxisExtent: 160,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final cards = [
                  {'icon': Icons.qr_code_scanner_rounded, 'title': ds.translate('attendance'), 'route': '/student/attendance-scan', 'color': Colors.blue},
                  {'icon': Icons.cloud_upload_rounded, 'title': ds.translate('upload_research'), 'route': '/student/research-upload', 'color': Colors.orange},
                  {'icon': Icons.history_rounded, 'title': ds.translate('research_history'), 'route': '/student/research-list', 'color': Colors.teal},
                  {'icon': Icons.forum_rounded, 'title': isAr ? 'ساحة النقاش' : 'Forum', 'color': Colors.cyan, 'action': 'open_picker'},
                ];
                return DashboardCard(
                  icon: cards[i]['icon'] as IconData, 
                  title: cards[i]['title'] as String, 
                  color: cards[i]['color'] as Color, 
                  onTap: () {
                    if (cards[i].containsKey('route')) {
                      Navigator.pushNamed(context, cards[i]['route'] as String);
                    } else if (cards[i]['action'] == 'open_picker') {
                      _showSubjectPicker(context, ds);
                    }
                  }
                );
              }, 
              childCount: 4
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
            child: Text(
              isAr ? "ساحة نقاش المواد" : "Course Forums",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: ds.instituteRef
              .collection('levels')
              .doc('level_${ds.normalizeLevel(ds.currentStudent?['level']?.toString() ?? "1")}')
              .collection('courses')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox());
            
            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String studentDiv = ds.normalizeDivision(ds.currentStudent?['division'] ?? 'all');
              String itemDiv = ds.normalizeDivision(data['division'] ?? 'all');
              return itemDiv == 'all' || itemDiv == studentDiv;
            }).toList();

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: primaryColor.withAlpha(20), child: Icon(Icons.forum_rounded, color: primaryColor, size: 20)),
                      title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(isAr ? "اضغط للدخول للنقاش" : "Tap to join forum", style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => DiscussionForumScreen(
                          levelId: 'level_${ds.normalizeLevel(ds.currentStudent?['level']?.toString() ?? "1")}', 
                          courseId: doc.id, 
                          courseName: data['name'] ?? ''
                        )));
                      },
                    ),
                  );
                },
                childCount: docs.length,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _StudentResearchsPage extends StatelessWidget {
  const _StudentResearchsPage();
  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;
    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(ds.translate('my_researches'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ds.submissionsColl.where('studentId', isEqualTo: ds.currentStudent?['id']?.toString()).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey.withAlpha(50)),
                  const SizedBox(height: 15),
                  Text(isAr ? 'لا توجد أبحاث مرفوعة' : 'No research uploaded', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: primaryColor.withAlpha(isDark ? 60 : 30)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isAr ? "إجمالي الأبحاث: " : "Total Researches: ",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : primaryColor)),
                      Text("${docs.length}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : primaryColor)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 120),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final r = docs[i].data() as Map<String, dynamic>;
                    bool isSeen = r['isSeen'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black.withAlpha(8), blurRadius: 10)],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: isSeen ? Colors.blue : (isDark ? Colors.white10 : Colors.grey.shade300),
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
                                  radius: 25,
                                  backgroundColor: Colors.red.withAlpha(20),
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
                                ),
                                title: Text(r['subject'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    if (r['grade'] != null || (r['comment'] != null && r['comment'].toString().isNotEmpty))
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (r['grade'] != null)
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.stars_rounded, color: Colors.green, size: 16),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          "${isAr ? 'الدرجة:' : 'Grade:'} ${r['grade']}",
                                                          style: GoogleFonts.cairo(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w900),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (r['grade'] != null && r['comment'] != null && r['comment'].toString().isNotEmpty)
                                              const SizedBox(height: 10),
                                            if (r['comment'] != null && r['comment'].toString().isNotEmpty)
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.orange, size: 14),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      r['comment'].toString(),
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 12, 
                                                        color: isDark ? Colors.white70 : Colors.black87,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          isSeen ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                          size: 14,
                                          color: isSeen ? Colors.blue : Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isSeen ? (isAr ? "تمت المشاهدة" : "Seen") : (isAr ? "في انتظار المراجعة" : "Pending"),
                                          style: GoogleFonts.cairo(
                                            fontSize: 10, 
                                            color: isSeen ? Colors.blue : Colors.grey, 
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Icon(isSeen ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                    color: isSeen ? Colors.blue : (isDark ? Colors.white10 : Colors.grey.shade400)),
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
      ),
    );
  }
}

class _StudentSchedulePage extends StatefulWidget {
  const _StudentSchedulePage();
  @override
  State<_StudentSchedulePage> createState() => _StudentSchedulePageState();
}

class _StudentSchedulePageState extends State<_StudentSchedulePage> {
  final DataService _ds = DataService();

  final List<Color> _beautifulColors = [
    Colors.blueAccent, Colors.pinkAccent, Colors.orangeAccent,
    Colors.tealAccent.shade700, Colors.deepPurpleAccent, Colors.redAccent
  ];

  final Map<int, String> _daysMap = {
    1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
    4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday',
  };

  final Map<int, String> _daysMapAr = {
    1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء',
    4: 'الخميس', 5: 'الجمعة', 6: 'السبت', 7: 'الأحد',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ds.currentStudent != null) {
        _ds.fetchSubjectsForLevel(
          _ds.currentStudent!['level']?.toString() ?? '1',
          _ds.currentStudent!['division']?.toString() ?? 'ALL'
        );
      }
    });
  }

  // وظيفة محسنة لجلب الدكتور بذكاء
  Future<List<String>> _getFilteredDoctors(String subjectName) async {
    final student = _ds.currentStudent;
    if (student == null) return [];
    
    final levelRaw = student['level']?.toString() ?? '1';
    final normLevel = _ds.normalizeLevel(levelRaw);
    final cleanLevel = normLevel.contains('level_') ? normLevel : 'level_$normLevel';

    List<String> results = [];
    try {
      var coursesRef = _ds.instituteRef.collection('levels').doc(cleanLevel).collection('courses');
      var courseQuery = await coursesRef.get();
      
      String normSearch = _ds.normalize(subjectName);

      for (var courseDoc in courseQuery.docs) {
        var cData = courseDoc.data() as Map<String, dynamic>;
        String cName = (cData['name'] ?? '').toString();
        
        if (_ds.normalize(cName) == normSearch) {
          String? doctorId = cData['doctor_id'];
          if (doctorId != null && doctorId.isNotEmpty) {
            // بحث مزدوج
            DocumentSnapshot docSnap = await _ds.instituteRef.collection('doctors').doc(doctorId).get();
            if (!docSnap.exists) {
              docSnap = await _ds.doctorsColl.doc(doctorId).get();
            }

            if (docSnap.exists) {
              final docData = docSnap.data() as Map<String, dynamic>?;
              String? docName = docData?['name'];
              if (docName != null) results.add(docName);
            }
          }
        }
      }
    } catch (e) { 
      debugPrint("Error filtering doctors: $e"); 
    }
    return results.toSet().toList()..sort();
  }

  void _addScheduleItem() async {
    String? selectedSub;
    String type = _ds.isArabic ? 'محاضرة' : 'Lecture';
    String instructor = '';
    String sectionNum = '';
    String location = '';
    String group = '';
    int selectedDay = DateTime.now().weekday;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    List<String> filteredDoctorNames = [];
    bool isLoadingDoctors = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isLec = type == (_ds.isArabic ? 'محاضرة' : 'Lecture');

          return Container(
            decoration: BoxDecoration(
              color: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text(_ds.isArabic ? "إضافة للجدول" : "Add to Schedule", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7))),
                  const SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(_ds.isArabic ? 'محاضرة' : 'Lecture', style: const TextStyle(fontSize: 13)),
                          value: _ds.isArabic ? 'محاضرة' : 'Lecture',
                          groupValue: type,
                          activeColor: _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7),
                          onChanged: (v) async {
                            setModalState(() { type = v!; instructor = ''; });
                            if (selectedSub != null) {
                               setModalState(() => isLoadingDoctors = true);
                               filteredDoctorNames = await _getFilteredDoctors(selectedSub!);
                               setModalState(() {
                                  isLoadingDoctors = false;
                                  instructor = filteredDoctorNames.isNotEmpty ? filteredDoctorNames.first : '';
                               });
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(_ds.isArabic ? 'سكشن' : 'Section', style: const TextStyle(fontSize: 13)),
                          value: _ds.isArabic ? 'سكشن' : 'Section',
                          groupValue: type,
                          activeColor: _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7),
                          onChanged: (v) => setModalState(() { type = v!; instructor = ''; }),
                        ),
                      ),
                    ],
                  ),

                  DropdownButtonFormField<String>(
                    value: selectedSub,
                    isExpanded: true,
                    dropdownColor: _ds.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                    decoration: InputDecoration(
                      labelText: _ds.isArabic ? "المادة" : "Subject",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    items: _ds.allSubjects.map((s) => DropdownMenuItem(
                      value: s, 
                      child: Text(s, overflow: TextOverflow.ellipsis, style: TextStyle(color: _ds.isDarkMode ? Colors.white : Colors.black87))
                    )).toList(),
                    onChanged: (v) async {
                      setModalState(() { selectedSub = v; instructor = ''; isLoadingDoctors = true; });
                      if (v != null) {
                        filteredDoctorNames = await _getFilteredDoctors(v);
                        setModalState(() {
                          isLoadingDoctors = false;
                          if (isLec) instructor = filteredDoctorNames.isNotEmpty ? filteredDoctorNames.first : '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),

                  if (isLec) ...[
                    if (isLoadingDoctors)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey('doc_$selectedSub'),
                        value: filteredDoctorNames.contains(instructor) ? instructor : null,
                        isExpanded: true,
                        dropdownColor: _ds.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                        decoration: InputDecoration(
                          labelText: _ds.isArabic ? "الدكتور" : "Doctor",
                          hintText: _ds.isArabic ? "اختر المادة أولاً" : "Choose subject first",
                          helperText: filteredDoctorNames.isEmpty && selectedSub != null ? (_ds.isArabic ? "لم يتم العثور على دكتور لهذه المادة" : "No doctor found") : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        items: filteredDoctorNames.map((n) => DropdownMenuItem(
                          value: n, 
                          child: Text(n, overflow: TextOverflow.ellipsis, style: TextStyle(color: _ds.isDarkMode ? Colors.white : Colors.black87))
                        )).toList(),
                        onChanged: (v) => setModalState(() => instructor = v ?? ''),
                      ),
                  ] else ...[
                    TextField(
                      decoration: InputDecoration(
                        labelText: _ds.isArabic ? "اسم المعيد" : "Assistant Name",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onChanged: (v) => instructor = v,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(labelText: _ds.isArabic ? "رقم السكشن" : "Section No.", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                            onChanged: (v) => sectionNum = v,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(labelText: _ds.isArabic ? "المجموعة" : "Group", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                            onChanged: (v) => group = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      decoration: InputDecoration(labelText: _ds.isArabic ? "القاعة / المعمل" : "Hall / Lab", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                      onChanged: (v) => location = v,
                    ),
                  ],

                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedDay,
                          decoration: InputDecoration(labelText: _ds.isArabic ? "اليوم" : "Day", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                          items: [1,2,3,4,5,6,7].map((d) => DropdownMenuItem(value: d, child: Text(_ds.isArabic ? _daysMapAr[d]! : _daysMap[d]!))).toList(),
                          onChanged: (v) => selectedDay = v!,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: selectedTime);
                            if (time != null) setModalState(() => selectedTime = time);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(15)),
                            child: Text(selectedTime.format(context), textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      onPressed: () async {
                        if (selectedSub != null) {
                          final itemData = {
                            'subject': selectedSub,
                            'type': type,
                            'instructor': instructor,
                            'sectionNum': sectionNum,
                            'location': location,
                            'group': group,
                            'dayIndex': selectedDay,
                            'dayName': _ds.isArabic ? _daysMapAr[selectedDay] : _daysMap[selectedDay],
                            'time': selectedTime.format(context),
                          };
                          await _ds.saveScheduleItem(itemData);
                          if (mounted) Navigator.pop(ctx);
                        }
                      },
                      child: Text(_ds.isArabic ? "إضافة للجدول" : "Add to Schedule", style: TextStyle(color: _ds.isDarkMode ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(_ds.translate('schedule'), style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black,
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: FloatingActionButton.extended(
              onPressed: _addScheduleItem,
              backgroundColor: primaryColor,
              icon: Icon(Icons.add, color: isDark ? Colors.black : Colors.white),
              label: Text(isAr ? "إضافة حصة" : "Add Class", style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _ds.getStudentScheduleStream(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;

              if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey.withAlpha(77)), const SizedBox(height: 20), Text(isAr ? 'ابدأ ببناء جدولك الآن' : 'Start building your schedule', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500))]));

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 120),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final color = _beautifulColors[i % _beautifulColors.length];
                  bool isLec = d['type'] == (isAr ? 'محاضرة' : 'Lecture');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: isDark ? Colors.black54 : color.withAlpha(30), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(width: 8, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)))),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          d['subject'] ?? '', 
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                                        child: Text("${d['type'] ?? ''} ${d['sectionNum'] ?? ''}", style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  if (d['instructor'] != null && d['instructor'].toString().isNotEmpty)
                                    Text("${isAr ? (isLec ? 'الدكتور:' : 'المعيد:') : (isLec ? 'Doctor:' : 'Assistant:')} ${d['instructor']}", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                                  if (!isLec && d['location'] != null && d['location'].toString().isNotEmpty)
                                    Text("${isAr ? 'المكان:' : 'Location:'} ${d['location']}", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                                  if (d['group'] != null && d['group'].toString().isNotEmpty)
                                    Text("${isAr ? 'المجموعة:' : 'Group:'} ${d['group']}", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade600),
                                      const SizedBox(width: 5),
                                      Text(d['dayName'] ?? '', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600)),
                                      const SizedBox(width: 15),
                                      Icon(Icons.access_time, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade600),
                                      const SizedBox(width: 5),
                                      Text(d['time'] ?? '', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(icon: Icon(Icons.delete_outline, color: isDark ? Colors.redAccent.withAlpha(150) : Colors.redAccent), onPressed: () => _ds.deleteScheduleItem(docs[i].id)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      }
    );
  }
}

class _StudentProfilePage extends StatelessWidget {
  const _StudentProfilePage();
  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;
    final student = ds.currentStudent;
    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF232323), const Color(0xFF1A1A1A)] 
                    : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(Icons.person, size: 45, color: primaryColor),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student?['name'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                              child: Text('ID: ${student?['id']}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 40),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Colors.white24, thickness: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniInfo(isAr ? 'المستوى' : 'Level', student?['level']?.toString() ?? '1'),
                      _buildMiniInfo(isAr ? 'الشعبة' : 'Division', student?['division']?.toString() ?? 'IS'),
                      _buildMiniInfo(isAr ? 'المجموعة' : 'Group', student?['group']?.toString() ?? 'A'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async { await ds.clearSession(); if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/start', (r) => false); },
                icon: const Icon(Icons.logout_rounded),
                label: Text(ds.translate('logout')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withAlpha(isDark ? 40 : 20),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
