import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../utils/excel_helper.dart';
import '../widgets/student_profile_modal.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});
  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  final DataService _ds = DataService();
  String? _selectedSubject;
  dynamic _selectedLevel;
  String? _selectedDivision;
  int? _selectedLecture;
  int _lecturesCount = 12;
  bool _viewingSheet = false;
  bool _isExporting = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  int _qrValidityMinutes = 2; 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _clean(String? text) {
    if (text == null) return "";
    String t = text.trim().toLowerCase();
    if (t == 'is' || t.contains('نظم')) return "نظممعلوماتالاعمال";
    if (t == 'acc' || t.contains('محاسب')) return "محاسبه";
    return t.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ال', '').replaceAll(' ', '');
  }

  String _displayName(String? div) {
    String c = _clean(div);
    if (c == "نظممعلوماتالاعمال") return "نظم معلومات الأعمال";
    if (c == "محاسبه") return "محاسبة";
    return (div == null || div.toUpperCase() == 'ALL') ? "عام" : div;
  }

  void _exportAttendance() async {
    setState(() => _isExporting = true);
    try {
      final snap = await _ds.studentsColl.get();
      final students = snap.docs.where((doc) {
        final d = doc.data() as Map<String, dynamic>;
        bool lvlMatch = d['level'].toString().trim() == _selectedLevel.toString().trim();
        String studentDiv = _clean(d['division']);
        String selectedDiv = _clean(_selectedDivision);
        return lvlMatch && (selectedDiv == 'all' || studentDiv == selectedDiv || studentDiv == 'all');
      }).map((e) => e.data() as Map<String, dynamic>).toList();

      await ExcelHelper.exportAttendanceToExcel(
        subject: _selectedSubject!.trim(),
        level: _selectedLevel.toString(),
        division: _displayName(_selectedDivision),
        students: students,
        isArabic: _ds.isArabic,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            _selectedSubject != null 
              ? _selectedSubject!.trim()
              : (_selectedLevel != null 
                 ? (isAr ? 'مواد الفرقة $_selectedLevel' : 'Level $_selectedLevel Subjects')
                 : (isAr ? 'إدارة الحضور' : 'Attendance Management')),
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (_viewingSheet) {
                setState(() { _viewingSheet = false; _searchQuery = ""; _searchController.clear(); });
              } else if (_selectedLecture != null) {
                setState(() { _selectedLecture = null; });
              } else if (_selectedSubject != null) {
                setState(() { _selectedSubject = null; });
              } else if (_selectedLevel != null) {
                setState(() { _selectedLevel = null; });
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: (_ds.currentDoctor == null && _ds.currentAdmin == null)
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : _selectedLevel == null
            ? _buildLevelsList()
            : _selectedSubject == null
              ? _buildSubjectsList()
              : (_selectedLecture == null ? _buildLectures() : _buildContent()),
      ),
    );
  }

  Widget _buildLevelsList() {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;
    final color = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final doctorLevels = List<String>.from(_ds.currentDoctor?['teachingLevels'] ?? []);
    final isDoctor = _ds.userRole == 'doctor';

    return StreamBuilder<QuerySnapshot>(
      stream: _ds.commerceLevelsColl.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data?.docs ?? [];
        if (isDoctor) {
          docs = docs.where((doc) => doctorLevels.contains(doc.id)).toList();
        }

        if (docs.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(isAr ? "لا توجد فرق دراسية متاحة" : "No levels available")));
        }

        docs.sort((a, b) => a.id.compareTo(b.id));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final name = data['name'] ?? (isAr ? "الفرقة ${docs[i].id.replaceAll('level_', '')}" : "Level ${docs[i].id.replaceAll('level_', '')}");
            final levelId = docs[i].id.replaceAll('level_', '');

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                  child: Icon(Icons.school_rounded, color: color, size: 28),
                ),
                title: Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : Colors.black87)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
                onTap: () => setState(() {
                  _selectedLevel = levelId;
                }),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectsList() {
    final isAr = _ds.isArabic;
    final isDark = _ds.isDarkMode;
    final color = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final doctorId = _ds.currentDoctor?['uid'] ?? '';
    final isDoctor = _ds.userRole == 'doctor';
    
    final levelDocId = 'level_$_selectedLevel';

    Query query = _ds.getCommerceCoursesColl(levelDocId);
    if (isDoctor) {
      query = query.where('doctor_id', isEqualTo: doctorId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allDocs = snapshot.data?.docs ?? [];
        
        if (allDocs.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_ds.translate('no_subjects_assigned'))));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: allDocs.length,
          itemBuilder: (ctx, i) {
            final data = allDocs[i].data() as Map<String, dynamic>;
            final name = data['name']?.toString() ?? 'Unknown';

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                  child: Icon(Icons.menu_book_rounded, color: color, size: 28),
                ),
                title: Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text("${isAr ? 'فرقة' : 'Lvl'} $_selectedLevel | ${_displayName(data['division'])}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
                onTap: () => setState(() {
                  _selectedSubject = name.trim();
                  _selectedDivision = data['division'];
                  _lecturesCount = data['lecturesCount'] ?? 12;
                }),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLectures() {
    final color = _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
          decoration: BoxDecoration(
            color: _ds.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_ds.isArabic ? "اختر رقم المحاضرة:" : "Select Lecture:", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15
            ),
            itemCount: _lecturesCount,
            itemBuilder: (ctx, i) => InkWell(
              onTap: () => setState(() => _selectedLecture = i + 1),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                    color: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(_ds.isDarkMode ? 50 : 13), blurRadius: 10)],
                    border: Border.all(color: color.withAlpha(51))
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${i + 1}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                      Text(_ds.isArabic ? "محاضرة" : "Lec", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    final color = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    if (!_viewingSheet) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. بطاقة معلومات المحاضرة (Header Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF232323), const Color(0xFF1A1A1A)] 
                      : [color, color.withBlue(200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : color.withAlpha(60),
                      blurRadius: 20,
                      offset: const Offset(0, 10)
                    )
                  ],
                  border: isDark ? Border.all(color: Colors.white10, width: 1) : null,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100,
                        child: Icon(Icons.school_rounded, color: color, size: 35),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(_selectedSubject!.trim(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text("${_ds.translate('level')} $_selectedLevel | ${_displayName(_selectedDivision)}",
                      style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider(color: Colors.white24, thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(isAr ? "المحاضرة رقم $_selectedLecture" : "Lecture #$_selectedLecture",
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // 2. بطاقة توليد الـ QR (Main Action Card)
              _buildModernActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: isAr ? "تحضير عبر الـ QR" : "Generate Dynamic QR",
                subtitle: isAr ? "توليد كود مؤقت للتحضير التلقائي" : "Create a time-limited QR code",
                color: color,
                onTap: () => _showSettingsBeforeQR(),
              ),

              const SizedBox(height: 20),

              // 3. بطاقة عرض الكشف (Sheet Action Card)
              _buildModernActionCard(
                icon: Icons.list_alt_rounded,
                title: isAr ? "كشف حضور الطلاب" : "Attendance Sheet",
                subtitle: isAr ? "مراجعة القائمة والتحضير اليدوي" : "Review list & manual check-in",
                color: const Color(0xFF455A64),
                onTap: () => setState(() => _viewingSheet = true),
              ),

              const SizedBox(height: 40),

              // تنبيه بسيط
              Text(
                isAr ? "تأكد من تواجدك داخل القاعة عند توليد الكود" : "Ensure you are inside the hall to generate QR",
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
          decoration: BoxDecoration(
            color: _ds.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _ds.isDarkMode ? Colors.black.withAlpha(50) : const Color(0xFFF1F3F8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: _ds.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: isAr ? "بحث باسم الطالب..." : "Search...",
                      hintStyle: TextStyle(color: _ds.isDarkMode ? Colors.white38 : Colors.grey),
                      prefixIcon: Icon(Icons.search_rounded, color: color),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isExporting ? null : _exportAttendance,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.withAlpha(50)),
                  ),
                  child: _isExporting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                    : const Icon(Icons.file_download_rounded, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildModernActionCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    bool isDark = _ds.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black45 : Colors.black.withAlpha(6), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(20)),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                      Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color.withAlpha(100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsBeforeQR() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: Text(_ds.isArabic ? "إعدادات الحضور" : "Attendance Settings", 
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _settingRow(_ds.isArabic ? "صلاحية الرمز (دقائق):" : "QR Validity (min):", _qrValidityMinutes, (v) => setDialogState(() => _qrValidityMinutes = v), [1, 2, 5, 10]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_ds.translate('cancel'), style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF673AB7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showQR();
              },
              child: Text(_ds.isArabic ? "توليد الرمز" : "Generate", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _settingRow(String label, int value, Function(int) onChanged, List<int> options) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: _ds.isDarkMode ? Colors.black26 : Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: DropdownButton<int>(
            value: value,
            underline: const SizedBox(),
            dropdownColor: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            items: options.map((e) => DropdownMenuItem(value: e, child: Text("$e", style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        )
      ],
    );
  }

  Widget _buildList() {
    bool isAr = _ds.isArabic;
    final color = _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.studentsColl.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        
        final students = snap.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          bool lvlMatch = d['level'].toString().trim() == _selectedLevel.toString().trim();
          String studentDiv = _clean(d['division']);
          String selectedDiv = _clean(_selectedDivision);
          return lvlMatch && (selectedDiv == 'all' || studentDiv == selectedDiv || studentDiv == 'all');
        }).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: _ds.attendanceColl
              .where('subject', isEqualTo: _selectedSubject?.trim())
              .where('lectureNumber', isEqualTo: _selectedLecture.toString())
              .snapshots(),
          builder: (context, attSnap) {
            final presentIds = (attSnap.data?.docs ?? []).map((doc) => (doc.data() as Map<String, dynamic>)['studentId'].toString().trim()).toSet();
            List<Map<String, dynamic>> list = students.map((doc) => doc.data() as Map<String, dynamic>).toList();
            
            if (_searchQuery.isNotEmpty) {
              String q = _clean(_searchQuery);
              list = list.where((s) => _clean(s['name']).contains(q) || _clean(s['id']).contains(q)).toList();
            }

            list.sort((a, b) {
              bool pA = presentIds.contains(a['id']?.toString().trim());
              bool pB = presentIds.contains(b['id']?.toString().trim());
              if (pA != pB) return pA ? -1 : 1;
              return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
            });

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      _statCard(isAr ? "الحاضرين" : "Present", presentIds.length, Colors.green),
                      const SizedBox(width: 15),
                      _statCard(isAr ? "الغائبين" : "Absent", list.length - presentIds.length, Colors.red),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final s = list[i];
                      final id = s['id']?.toString().trim() ?? '';
                      final isP = presentIds.contains(id);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _ds.isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: _ds.isDarkMode ? Colors.black54 : Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                decoration: BoxDecoration(
                                  color: isP ? Colors.green : Colors.red.withAlpha(150),
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  onTap: () => _showStudentProfile(s),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  leading: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: isP ? Colors.green.withAlpha(20) : Colors.grey.shade200,
                                        backgroundImage: _ds.getAvatarImageProvider(s['photoUrl']),
                                        child: (s['photoUrl'] ?? '').toString().isEmpty
                                            ? Icon(Icons.person_rounded, color: isP ? Colors.green : Colors.grey, size: 22)
                                            : null,
                                      ),
                                      if (isP)
                                        const Positioned(
                                          bottom: -2,
                                          right: -2,
                                          child: CircleAvatar(
                                            radius: 8,
                                            backgroundColor: Colors.green,
                                            child: Icon(Icons.check, size: 10, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(s['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ds.isDarkMode ? Colors.white : Colors.black87)),
                                  subtitle: Text("ID: $id | ${_displayName(s['division'])}", style: TextStyle(color: _ds.isDarkMode ? Colors.white38 : Colors.grey, fontSize: 11)),
                                  trailing: isP
                                    ? IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red), onPressed: () => _ds.deleteAttendanceRecord(_selectedSubject!.trim(), id, _selectedLecture.toString()))
                                    : IconButton(
                                        icon: Icon(Icons.add_circle_outline_rounded, color: color),
                                        onPressed: () async {
                                          try {
                                            await _ds.manualRecordAttendance(
                                              studentId: id.trim(),
                                              studentName: s['name'].toString().trim(),
                                              subject: _selectedSubject!.trim(),
                                              level: _selectedLevel.toString().trim(),
                                              lectureNumber: _selectedLecture.toString().trim()
                                            );
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ds.isArabic ? "تم تحضير الطالب بنجاح" : "Student marked present")));
                                          } catch (e) {
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                                          }
                                        }
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
          }
        );
      },
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color.withAlpha(200), fontSize: 11, fontWeight: FontWeight.w700)),
            Text("$count", style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  void _showStudentProfile(Map<String, dynamic> studentData) {
    String id = studentData['id']?.toString().trim() ?? '';
    String name = studentData['name']?.toString() ?? 'Student';
    showRichStudentProfileModal(
      context: context,
      studentIdOrUid: id,
      studentName: name,
      subject: _selectedSubject,
      initialStudentData: studentData,
    );
  }

  Widget _profileDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(color: _ds.isDarkMode ? Colors.black26 : const Color(0xFFF8F9FE), borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Icon(icon, size: 20, color: _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7)), const SizedBox(width: 10), Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: _ds.isDarkMode ? Colors.white70 : Colors.black87))]),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: _ds.isDarkMode ? Colors.white : const Color(0xFF2D3142)))
      ]),
    );
  }

  void _showQR() async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint("Error getting location: $e");
    }

    String locationData = position != null ? "${position.latitude},${position.longitude}" : "0,0";
    String data = "${_selectedSubject!.trim()}|$_selectedLevel|$_selectedDivision|$_selectedLecture|$locationData|${DateTime.now().millisecondsSinceEpoch}|$_qrValidityMinutes";

    if (!mounted) return;

    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_selectedSubject!.trim(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _ds.isDarkMode ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${_ds.translate('lec_no')} $_selectedLecture - ${_displayName(_selectedDivision)}", style: TextStyle(color: _ds.isDarkMode ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 20),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: SizedBox(width: 200, height: 200, child: QrImageView(data: data)),
            ),
            const SizedBox(height: 15),
            Text(
              _ds.isArabic ? "صلاحية هذا الرمز: $_qrValidityMinutes دقائق" : "This QR valid for: $_qrValidityMinutes min",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_ds.translate('cancel'), style: TextStyle(color: _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7))))],
      )
    );
  }
}
