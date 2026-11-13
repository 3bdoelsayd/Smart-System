import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../utils/debouncer.dart';
import '../utils/excel_helper.dart';
import '../widgets/app_drawer.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/doctor_profile_modal.dart';
import '../widgets/student_profile_modal.dart';
import 'discussion_forum_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataService _ds = DataService();
  List<String> _managedLevels = [];
  String? _selectedLevel;
  String _searchQuery = "";
  String _selectedStudentDivisionFilter = 'all';
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  // Attendance Selection State
  Map<String, dynamic>? _selectedAttCourseData;
  int? _selectedAttLecture;

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _managedLevels = List<String>.from(_ds.currentAdmin?['managedLevels'] ?? []);
    _selectedLevel = _managedLevels.isNotEmpty ? _managedLevels.first : null;
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedAttCourseData = null;
          _selectedAttLecture = null;
        });
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ds.userRole != 'manager' || _ds.currentAdmin == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/start', (r) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        final theme = Theme.of(context);
        bool isDark = _ds.isDarkMode;
        final managerName = _ds.currentAdmin?['name'] ?? 'المدير';

        if (_managedLevels.isEmpty) {
          return Scaffold(body: Center(child: Text('لا توجد فرق دراسية مسندة إليك', style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey))));
        }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: AppDrawer(name: managerName, role: _ds.isArabic ? 'مدير النظام' : 'System Manager'),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF2E1A47), const Color(0xFF121212)] 
                      : [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(isDark ? 0.2 : 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(builder: (context) => IconButton(
                          icon: const Icon(Icons.menu_open_rounded, color: Colors.white, size: 30),
                          onPressed: () => Scaffold.of(context).openDrawer()
                        )),
                        Text(_ds.isArabic ? 'لوحة تحكم المدير' : 'Manager Dashboard', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.quiz_rounded, color: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/manager/exams'),
                          tooltip: _ds.isArabic ? 'مراقبة الاختبارات' : 'Exams',
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text('${_ds.isArabic ? "مرحباً بك،" : "Welcome,"} $managerName', style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildLevelSelector(),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: isDark ? Colors.white30 : Colors.grey,
                  indicatorColor: theme.primaryColor,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'الطلاب'),
                    Tab(text: 'المواد'),
                    Tab(text: 'الدكاترة'),
                    Tab(text: 'المعيدين'),
                    Tab(text: 'المناقشات'),
                    Tab(text: 'الحضور'),
                    Tab(text: 'الفصول'),
                    Tab(text: 'الجدول'),
                    Tab(text: 'البلاغات'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildStudentsTab(),
              _buildCoursesTab(),
              _buildDoctorsTab(),
              _buildTAsTab(),
              _buildForumsTab(),
              _buildAttendanceTab(),
              _buildSemestersTab(),
              _buildScheduleTab(),
              _buildReportsTab(),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
      },
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLevel,
          dropdownColor: _ds.isDarkMode ? const Color(0xFF1C1C23) : const Color(0xFF673AB7),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          items: _managedLevels.map((lvl) => DropdownMenuItem(value: lvl, child: Text('فرقة: $lvl', style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: (v) => setState(() {
             _selectedLevel = v;
             _selectedAttCourseData = null;
             _selectedAttLecture = null;
          }),
        ),
      ),
    );
  }

  Widget? _buildFAB() {
    String label = "";
    VoidCallback? action;
    if (_tabController.index == 0) { return _buildStudentFAB(); }
    else if (_tabController.index == 1) { label = "مادة"; action = _showAddCourseBS; }
    else if (_tabController.index == 2) { label = "دكتور"; action = _showAddDoctorBS; }
    else if (_tabController.index == 3) { label = "معيد"; action = _showAddTABs; }
    else if (_tabController.index == 7) { 
      return FloatingActionButton.extended(
        onPressed: () => _showAddScheduleModal(context, _selectedLevel ?? '1'),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('إضافة محاضرة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    else { return null; }

    return FloatingActionButton.extended(
      onPressed: action,
      backgroundColor: Theme.of(context).primaryColor,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text('إضافة $label', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStudentFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          onPressed: _pickAndUploadStudentsExcel, 
          backgroundColor: Colors.green, 
          heroTag: 'excel_fab',
          child: const Icon(Icons.table_chart, color: Colors.white)
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          onPressed: _showAddStudentBS, 
          backgroundColor: Theme.of(context).primaryColor, 
          heroTag: 'manual_fab',
          icon: const Icon(Icons.person_add , color: Colors.white),
          label: const Text('إضافة يدوي' , style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        ),
      ],
    );
  }

  void _showStyledBS({required String title, required IconData icon, required Color color, required List<Widget> children, required VoidCallback onSave}) {
    final isDark = _ds.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C23) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 25),
              ...children,
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(_ds.isArabic ? 'حفظ البيانات' : 'Save Data', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController c, String label, IconData icon, {bool isPass = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        obscureText: isPass,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, IconData icon, List<DropdownMenuItem<String>> items, Function(String?) onChange, {String? value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon, size: 20),
        ),
        items: items,
        onChanged: onChange,
        dropdownColor: _ds.isDarkMode ? const Color(0xFF252530) : Colors.white,
      ),
    );
  }

  void _showAddStudentBS() {
    final nameC = TextEditingController(); final idC = TextEditingController(); final passC = TextEditingController(); String? selDiv;
    _showStyledBS(title: 'إضافة طالب', icon: Icons.person_add, color: Colors.green, children: [
      _buildInputField(nameC, 'اسم الطالب الرباعي', Icons.person),
      _buildInputField(idC, 'كود الطالب', Icons.badge, isNumber: true),
      _buildInputField(passC, 'كلمة المرور', Icons.lock, isPass: true),
      StreamBuilder<QuerySnapshot>(
        stream: _ds.getCommerceSectionsColl(_selectedLevel!).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const LinearProgressIndicator();
          return _buildDropdown('اختر الشعبة', Icons.grid_view, snap.data!.docs.map((d) => DropdownMenuItem(value: d['name'].toString(), child: Text(d['name']))).toList(), (v) => selDiv = v);
        },
      ),
    ], onSave: () async {
      if (idC.text.isNotEmpty && nameC.text.isNotEmpty && selDiv != null) {
        await _ds.addStudentManual(_selectedLevel!, idC.text, nameC.text, "", selDiv!, passC.text.isEmpty ? "123456" : passC.text);
        Navigator.pop(context);
      }
    });
  }

  void _showAddCourseBS() async {
    final nameC = TextEditingController(); 
    final lecturesC = TextEditingController(text: "12");
    String? selDiv; String? selSem; String? selDoc;
    List<String> selectedTaIds = [];
    var semSnap = await _ds.commerceSemestersColl.where('isActive', isEqualTo: true).get(); 
    var docSnap = await _ds.commerceDoctorsColl.get();
    var taSnap = await _ds.commerceTasColl.get();

    _showStyledBS(title: 'إضافة مادة ودكتور ومعيدين', icon: Icons.book, color: Colors.deepPurple, children: [
      _buildInputField(nameC, 'اسم المادة', Icons.book_outlined),
      _buildInputField(lecturesC, 'عدد المحاضرات / السكاشن', Icons.format_list_numbered, isNumber: true),
      _buildDropdown('الشعبة', Icons.groups, [const DropdownMenuItem(value: 'all', child: Text('الكل')), const DropdownMenuItem(value: 'محاسبه', child: Text('محاسبه')), const DropdownMenuItem(value: 'نظم معلومات الاعمال', child: Text('نظم معلومات الاعمال'))], (v) => selDiv = v),
      _buildDropdown('الفصل الدراسي (النشط حالياً)', Icons.calendar_today, semSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text((d.data() as Map)['name'] ?? ''))).toList(), (v) => selSem = v),
      _buildDropdown('الدكتور المسؤول', Icons.person_search, docSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text((d.data() as Map)['name'] ?? ''))).toList(), (v) => selDoc = v),
      StatefulBuilder(
        builder: (ctx, setMultiState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اختر المعيدين المسؤولين (يمكن اختيار أكثر من معيد):', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: taSnap.docs.map((d) {
                final id = d.id;
                final name = (d.data() as Map)['name'] ?? '';
                final isSelected = selectedTaIds.contains(id);
                return FilterChip(
                  label: Text('م. $name', style: GoogleFonts.cairo(fontSize: 12)),
                  selected: isSelected,
                  selectedColor: Colors.teal.shade200,
                  onSelected: (selected) {
                    setMultiState(() {
                      if (selected) {
                        selectedTaIds.add(id);
                      } else {
                        selectedTaIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ], onSave: () async {
      if (selSem != null && selDoc != null && nameC.text.isNotEmpty) {
        int count = int.tryParse(lecturesC.text) ?? 12;
        await _ds.addCourseToLevel(_selectedLevel!, nameC.text, selDiv ?? 'all', selSem!, selDoc!, lecturesCount: count, taId: selectedTaIds.isNotEmpty ? selectedTaIds.first : null, taIds: selectedTaIds);
        if (mounted) Navigator.pop(context);
      }
    });
  }

  void _showEditCourseBS(DocumentSnapshot courseDoc) async {
    final data = courseDoc.data() as Map<String, dynamic>;
    final nameC = TextEditingController(text: data['name']); 
    final lecturesC = TextEditingController(text: (data['lecturesCount'] ?? 12).toString());
    String? selDiv = data['division'];
    String? selDoc = data['doctor_id'];
    List<String> selectedTaIds = List<String>.from(data['ta_ids'] ?? (data['ta_id'] != null ? [data['ta_id']] : []));
    
    var docSnap = await _ds.commerceDoctorsColl.get();
    var taSnap = await _ds.commerceTasColl.get();

    _showStyledBS(
      title: 'تعديل بيانات المادة', 
      icon: Icons.edit_note_rounded, 
      color: Colors.blue, 
      children: [
        _buildInputField(nameC, 'اسم المادة', Icons.book_outlined),
        _buildInputField(lecturesC, 'عدد المحاضرات / السكاشن', Icons.format_list_numbered, isNumber: true),
        _buildDropdown('الشعبة', Icons.groups, [
          const DropdownMenuItem(value: 'all', child: Text('الكل')), 
          const DropdownMenuItem(value: 'محاسبه', child: Text('محاسبه')), 
          const DropdownMenuItem(value: 'نظم معلومات الاعمال', child: Text('نظم معلومات الاعمال'))
        ], (v) => selDiv = v, value: selDiv),
        _buildDropdown('الدكتور المسؤول', Icons.person_search, docSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text((d.data() as Map)['name'] ?? ''))).toList(), (v) => selDoc = v, value: selDoc),
        StatefulBuilder(
          builder: (ctx, setMultiState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر المعيدين المسؤولين (يمكن اختيار أكثر من معيد):', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: taSnap.docs.map((d) {
                  final id = d.id;
                  final name = (d.data() as Map)['name'] ?? '';
                  final isSelected = selectedTaIds.contains(id);
                  return FilterChip(
                    label: Text('م. $name', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: isSelected,
                    selectedColor: Colors.teal.shade200,
                    onSelected: (selected) {
                      setMultiState(() {
                        if (selected) {
                          selectedTaIds.add(id);
                        } else {
                          selectedTaIds.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ], 
      onSave: () async {
        if (nameC.text.isNotEmpty && selDoc != null) {
          int count = int.tryParse(lecturesC.text) ?? 12;
          await courseDoc.reference.update({
            'name': nameC.text,
            'lecturesCount': count,
            'division': selDiv ?? 'all',
            'doctor_id': selDoc,
            'ta_id': selectedTaIds.isNotEmpty ? selectedTaIds.first : null,
            'ta_ids': selectedTaIds,
          });
          if (mounted) Navigator.pop(context);
        }
      }
    );
  }

  void _showAddDoctorBS() {
    final nameC = TextEditingController(); final idC = TextEditingController(); final passC = TextEditingController();
    _showStyledBS(title: 'إضافة دكتور جديد', icon: Icons.person_add, color: Colors.pink, children: [
      _buildInputField(nameC, 'اسم الدكتور', Icons.person),
      _buildInputField(idC, 'كود الدكتور', Icons.badge, isNumber: true),
      _buildInputField(passC, 'باسورد', Icons.lock, isPass: true),
    ], onSave: () async {
      if (idC.text.isNotEmpty && nameC.text.isNotEmpty) {
        await _ds.addDoctor(idC.text, nameC.text, "", [_selectedLevel!], [], passC.text.isEmpty ? "123456" : passC.text);
        if (mounted) Navigator.pop(context);
      }
    });
  }

  void _showAddTABs() {
    final nameC = TextEditingController(); final idC = TextEditingController(); final passC = TextEditingController();
    _showStyledBS(title: 'إضافة معيد جديد', icon: Icons.person_add_alt_1, color: Colors.teal, children: [
      _buildInputField(nameC, 'اسم المعيد', Icons.person),
      _buildInputField(idC, 'كود المعيد (ID)', Icons.badge, isNumber: true),
      _buildInputField(passC, 'كلمة المرور', Icons.lock, isPass: true),
    ], onSave: () async {
      if (idC.text.isNotEmpty && nameC.text.isNotEmpty) {
        await _ds.addTA(idC.text, nameC.text, "", [_selectedLevel!], [], passC.text.isEmpty ? "123456" : passC.text);
        if (mounted) Navigator.pop(context);
      }
    });
  }

  Future<void> _pickAndUploadStudentsExcel() async {
    List<List<String>> rows = await ExcelHelper.pickAndParseExcel();
    if (rows.isNotEmpty) {
      int count = 0;
      for (var row in rows) {
        if (row.length < 4) continue;
        String sId = row[0];
        String sName = row[1];
        String sLevel = row[2];
        String sDiv = row[3];
        String sPass = row.length > 4 ? row[4] : '123456';
        if (sId.isNotEmpty) { 
          await _ds.addStudentManual('level_${_ds.normalizeLevel(sLevel)}', sId, sName, "", sDiv, sPass); 
          count++; 
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع $count طالب بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green));
    }
  }

  Widget _buildStudentsTab() {
    return Column(
      children: [
        _buildSearchField(),
        StreamBuilder<QuerySnapshot>(
          stream: _ds.getCommerceSectionsColl(_selectedLevel!).snapshots(),
          builder: (ctx, secSnap) {
            List<Map<String, String>> sectionsList = [{'id': 'all', 'name': 'جميع الشعب'}];
            if (secSnap.hasData) {
              for (var doc in secSnap.data!.docs) {
                var d = doc.data() as Map<String, dynamic>;
                sectionsList.add({'id': d['name'] ?? doc.id, 'name': d['name'] ?? 'شعبة'});
              }
            }
            if (sectionsList.length == 1) {
              sectionsList.addAll([
                {'id': 'نظم معلومات الاعمال', 'name': 'نظم معلومات الأعمال'},
                {'id': 'محاسبه', 'name': 'المحاسبة والمراجعة'},
              ]);
            }

            return Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sectionsList.length,
                itemBuilder: (ctx, i) {
                  final sec = sectionsList[i];
                  final isSelected = _selectedStudentDivisionFilter == sec['id'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(sec['name']!, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                      selected: isSelected,
                      selectedColor: Theme.of(context).primaryColor,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStudentDivisionFilter = sec['id']!);
                        }
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.studentsColl.where('level', isEqualTo: _selectedLevel!.replaceAll('level_', '')).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              
              var docs = snap.data!.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                String sName = (data['name'] ?? '').toString().toLowerCase();
                String sDiv = (data['division'] ?? '').toString();

                bool matchesSearch = sName.contains(_searchQuery.toLowerCase());
                
                bool matchesDiv = _selectedStudentDivisionFilter == 'all' || 
                                  _ds.normalizeDivision(sDiv) == _ds.normalizeDivision(_selectedStudentDivisionFilter) ||
                                  sDiv.contains(_selectedStudentDivisionFilter) ||
                                  _selectedStudentDivisionFilter.contains(sDiv);

                return matchesSearch && matchesDiv;
              }).toList();

              if (docs.isEmpty) return _buildEmptyState(Icons.group_off, 'لا يوجد طلاب لهذه الشعبة');

              return ListView.builder(
                padding: const EdgeInsets.all(15), 
                itemCount: docs.length, 
                itemBuilder: (ctx, i) {
                  var d = docs[i].data() as Map<String, dynamic>;
                  return RepaintBoundary(
                    key: ValueKey<String>(docs[i].id),
                    child: _buildListItem(
                      title: d['name'] ?? '', 
                      subtitle: 'ID: ${d['id']} | الشعبة: ${d['division']}', 
                      icon: Icons.school, 
                      color: Colors.green, 
                      photoUrl: d['photoUrl'],
                      onTap: () => showRichStudentProfileModal(
                        context: context,
                        studentIdOrUid: docs[i].id,
                        studentName: d['name'],
                        initialStudentData: d,
                      ),
                      onResetDevice: () => _confirmResetDevice(context, docs[i].id, d['name']),
                      onChangePassword: () => _showChangeStudentPasswordDialog(docs[i].id, d['name'] ?? '', _selectedLevel),
                      onDelete: () => _ds.deleteStudent(docs[i].id, _selectedLevel!.replaceAll('level_', ''))
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmResetDevice(BuildContext context, String uid, String? name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            const Icon(Icons.phonelink_erase_rounded, color: Colors.orange, size: 50),
            const SizedBox(height: 10),
            Text("إعادة ضبط الجهاز", style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.orange.shade900)),
          ],
        ),
        content: Text(
          "هل أنت متأكد من فك ربط حساب الطالب ($name) من جهازه الحالي؟",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await _ds.resetStudentDevice(uid);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إعادة ضبط الجهاز بنجاح'), backgroundColor: Colors.orangeAccent),
                      );
                    }
                  },
                  child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.getCommerceCoursesColl(_selectedLevel!).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var courses = snap.data!.docs;
        if (courses.isEmpty) return _buildEmptyState(Icons.book_outlined, 'لا توجد مواد');
        return ListView.builder(padding: const EdgeInsets.all(15), itemCount: courses.length, itemBuilder: (ctx, i) {
          var courseDoc = courses[i];
          var d = courseDoc.data() as Map<String, dynamic>;
          int count = d['lecturesCount'] ?? 12;
          return _buildListItem(
            title: d['name'] ?? '', 
            subtitle: 'الشعبة: ${d['division']} | المحاضرات: $count', 
            icon: Icons.book, 
            color: Colors.deepPurple, 
            onDelete: () => courseDoc.reference.delete(),
            onEdit: () => _showEditCourseBS(courseDoc),
          );
        });
      },
    );
  }

  Widget _buildDoctorsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.commerceDoctorsColl.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs;
        docs.sort((a, b) => (a.data() as Map<String, dynamic>)['name'].toString().compareTo((b.data() as Map<String, dynamic>)['name'].toString()));
        if (docs.isEmpty) return _buildEmptyState(Icons.person_off_outlined, 'لا يوجد دكاترة');
        return ListView.builder(padding: const EdgeInsets.all(15), itemCount: docs.length, itemBuilder: (ctx, i) {
          var d = docs[i].data() as Map<String, dynamic>;
          return _buildListItem(
            title: d['name'] ?? '', 
            subtitle: d['email'] ?? '', 
            icon: Icons.person, 
            color: Colors.pink, 
            photoUrl: d['photoUrl'],
            onTap: () => showRichDoctorProfileModal(
              context: context,
              doctorUidOrEmail: docs[i].id,
              doctorName: d['name'],
              initialDoctorData: d,
            ),
            onEdit: () => _showEditDoctorBS(docs[i]),
            onDelete: () => _ds.deleteDoctor(docs[i].id)
          );
        });
      },
    );
  }

  Widget _buildTAsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.commerceTasColl.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs;
        docs.sort((a, b) => (a.data() as Map<String, dynamic>)['name'].toString().compareTo((b.data() as Map<String, dynamic>)['name'].toString()));
        if (docs.isEmpty) return _buildEmptyState(Icons.person_off_outlined, 'لا يوجد معيدين مسجلين');
        return ListView.builder(padding: const EdgeInsets.all(15), itemCount: docs.length, itemBuilder: (ctx, i) {
          var d = docs[i].data() as Map<String, dynamic>;
          return _buildListItem(
            title: d['name'] ?? '', 
            subtitle: 'كود: ${d['id'] ?? ''} | ${d['email'] ?? ''}', 
            icon: Icons.person_outline_rounded, 
            color: Colors.teal, 
            photoUrl: d['photoUrl'],
            onTap: () => showRichDoctorProfileModal(
              context: context,
              doctorUidOrEmail: docs[i].id,
              doctorName: d['name'],
              initialDoctorData: d,
            ),
            onEdit: () => _showEditTABS(docs[i]),
            onDelete: () => _ds.deleteTA(docs[i].id)
          );
        });
      },
    );
  }

  Widget _buildForumsTab() {
    if (_selectedLevel == null) {
      return Center(child: Text('يرجى اختيار فرقة دراسية أولاً', style: GoogleFonts.cairo(color: Colors.grey)));
    }

    String levelId = _selectedLevel!;

    return StreamBuilder<QuerySnapshot>(
      stream: _ds.getCommerceCoursesColl(levelId).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var courses = snap.data!.docs;
        if (courses.isEmpty) return _buildEmptyState(Icons.forum_outlined, 'لا توجد مواد لمواضيع المناقشة');

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: courses.length,
          itemBuilder: (ctx, i) {
            var courseDoc = courses[i];
            var d = courseDoc.data() as Map<String, dynamic>;
            String courseName = d['name'] ?? 'مادة';
            String division = d['division'] ?? 'الكل';

            return Card(
              color: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.cyan.withAlpha(30),
                  child: const Icon(Icons.forum_rounded, color: Colors.cyan),
                ),
                title: Text(courseName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('الشعبة: $division | انقر لدخول شات المادة', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.cyan),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => DiscussionForumScreen(
                        levelId: levelId,
                        courseId: courseDoc.id,
                        courseName: courseName,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDoctorBS(DocumentSnapshot doc) {
    var d = doc.data() as Map<String, dynamic>;
    final nameC = TextEditingController(text: d['name'] ?? '');
    final emailC = TextEditingController(text: d['email'] ?? '');

    _showStyledBS(
      title: 'تعديل بيانات الدكتور',
      icon: Icons.edit_note_rounded,
      color: Colors.pink,
      children: [
        _buildInputField(nameC, 'اسم الدكتور', Icons.person),
        _buildInputField(emailC, 'البريد الإلكتروني', Icons.email_outlined),
      ],
      onSave: () async {
        if (nameC.text.isNotEmpty) {
          await _ds.updateDoctorByAdmin(doc.id, name: nameC.text.trim(), email: emailC.text.trim());
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل بيانات الدكتور بنجاح')));
          }
        }
      },
    );
  }

  void _showEditTABS(DocumentSnapshot doc) {
    var d = doc.data() as Map<String, dynamic>;
    final nameC = TextEditingController(text: d['name'] ?? '');
    final emailC = TextEditingController(text: d['email'] ?? '');

    _showStyledBS(
      title: 'تعديل بيانات المعيد',
      icon: Icons.edit_note_rounded,
      color: Colors.teal,
      children: [
        _buildInputField(nameC, 'اسم المعيد', Icons.person),
        _buildInputField(emailC, 'البريد الإلكتروني', Icons.email_outlined),
      ],
      onSave: () async {
        if (nameC.text.isNotEmpty) {
          await _ds.updateTAByAdmin(doc.id, name: nameC.text.trim(), email: emailC.text.trim());
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل بيانات المعيد بنجاح')));
          }
        }
      },
    );
  }

  Widget _buildAttendanceTab() {
    if (_selectedAttCourseData == null) {
      return StreamBuilder<QuerySnapshot>(
        stream: _ds.getCommerceCoursesColl(_selectedLevel!).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var courses = snap.data!.docs;
          if (courses.isEmpty) return _buildEmptyState(Icons.history_edu, 'لا توجد سجلات');
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: courses.length,
            itemBuilder: (ctx, i) {
              var d = courses[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Icon(Icons.menu_book, color: Theme.of(context).primaryColor)),
                  title: Text(d['name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  subtitle: Text('الشعبة: ${d['division']}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => setState(() => _selectedAttCourseData = d),
                ),
              );
            },
          );
        },
      );
    }

    if (_selectedAttLecture == null) {
      int count = _selectedAttCourseData!['lecturesCount'] ?? 12;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => setState(() => _selectedAttCourseData = null)),
              Text('مادة: ${_selectedAttCourseData!['name']}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: count,
              itemBuilder: (ctx, i) => InkWell(
                onTap: () => setState(() => _selectedAttLecture = i + 1),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    color: _ds.isDarkMode ? const Color(0xFF252530) : Colors.white, 
                    borderRadius: BorderRadius.circular(15), 
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
                  ),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${i + 1}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(_ds.isArabic ? 'محاضرة' : 'Lecture', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey))])),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => setState(() => _selectedAttLecture = null)),
              Expanded(child: Text('${_selectedAttCourseData!['name']} - ${_ds.isArabic ? "محاضرة" : "Lec"} $_selectedAttLecture', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14))),
              IconButton(icon: const Icon(Icons.file_download, color: Colors.green), onPressed: _exportAttendanceForManager),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.attendanceColl
                .where('subject', isEqualTo: _selectedAttCourseData!['name'])
                .where('level', isEqualTo: _selectedLevel!.replaceAll('level_', ''))
                .where('lectureNumber', isEqualTo: _selectedAttLecture.toString())
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snap.data!.docs;
              if (docs.isEmpty) return _buildEmptyState(Icons.person_off, 'لا يوجد حضور');
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  var d = docs[i].data() as Map<String, dynamic>;
                  return _buildListItem(
                    title: d['studentName'] ?? '', 
                    subtitle: 'ID: ${d['studentId']}', 
                    icon: Icons.check_circle, 
                    color: Colors.green, 
                    onDelete: () => docs[i].reference.delete()
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSemestersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.commerceSemestersColl.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs;
        docs.sort((a, b) => (a.data() as Map<String, dynamic>)['name'].toString().compareTo((b.data() as Map<String, dynamic>)['name'].toString()));
        if (docs.isEmpty) return _buildEmptyState(Icons.calendar_month, 'لا توجد فصول');
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            var d = docs[i].data() as Map<String, dynamic>;
            bool isActive = d['isActive'] ?? false;
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: (isActive ? Colors.green : Colors.grey).withOpacity(0.1), child: Icon(Icons.calendar_today, color: isActive ? Colors.green : Colors.grey)),
                title: Text(d['name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('الترتيب: ${d['order']}'),
                trailing: Switch(value: isActive, onChanged: (v) => _ds.toggleSemesterStatus(docs[i].id, v)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
      child: TextField(
        onChanged: (v) {
          _searchDebouncer.run(() {
            if (mounted) setState(() => _searchQuery = v);
          });
        },
        decoration: InputDecoration(
          hintText: _ds.isArabic ? 'ابحث بالاسم...' : 'Search by name...',
          prefixIcon: const Icon(Icons.search_rounded),
          fillColor: _ds.isDarkMode ? const Color(0xFF1C1C23) : Colors.white,
        ),
      ),
    );
  }

  void _showChangeStudentPasswordDialog(String uid, String name, String? level) {
    final passC = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تغيير كلمة المرور للطالب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('أدخل كلمة المرور الجديدة للطالب ($name):', style: GoogleFonts.cairo(fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: passC,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () async {
              if (passC.text.trim().isNotEmpty) {
                try {
                  await _ds.changeStudentPasswordByAdmin(
                    studentUid: uid,
                    newPassword: passC.text.trim(),
                    levelId: level,
                  );
                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تغيير كلمة المرور وتفعيلها فوراً بنجاح!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ أثناء تغيير كلمة المرور: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('تحديث الفوري', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({required String title, required String subtitle, required IconData icon, required Color color, String? photoUrl, VoidCallback? onTap, required VoidCallback onDelete, VoidCallback? onEdit, VoidCallback? onResetDevice, VoidCallback? onChangePassword}) {
    final isDark = _ds.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
            leading: (photoUrl != null && photoUrl.isNotEmpty)
              ? CachedAvatar(
                  photoUrl: photoUrl,
                  name: title,
                  radius: 24,
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
            title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15, height: 1.2)),
            subtitle: Text(subtitle, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onChangePassword != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: InkWell(
                      onTap: onChangePassword,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_reset_rounded, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _ds.isArabic ? "تغيير الباسورد" : "Change Pass",
                              style: GoogleFonts.cairo(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (onResetDevice != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: InkWell(
                      onTap: onResetDevice,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phonelink_erase_rounded, color: Colors.orange, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _ds.isArabic ? "ضبط الجهاز" : "Reset Device",
                              style: GoogleFonts.cairo(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (onEdit != null) _buildActionCircle(Icons.edit_note_rounded, Colors.blue, onEdit),
                _buildActionCircle(Icons.delete_outline_rounded, Colors.redAccent, onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 15),
          Text(message, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _exportAttendanceForManager() async {
    if (_selectedAttCourseData == null || _selectedAttLecture == null) return;
    
    bool isAr = _ds.isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          isAr ? "خيارات تصدير الإكسيل" : "Export Excel Options",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAr ? "اختر الفئة المراد تصديرها من القائمة:" : "Select category to export:",
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _managerExportTile(
              icon: Icons.groups_rounded,
              color: const Color(0xFF673AB7),
              title: isAr ? "جميع الطلاب (حاضرين وغائبين)" : "All Students (Present & Absent)",
              onTap: () {
                Navigator.pop(ctx);
                _processManagerExport(filterType: 'all');
              },
            ),
            const SizedBox(height: 10),
            _managerExportTile(
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              title: isAr ? "الطلاب الحاضرين فقط" : "Present Students Only",
              onTap: () {
                Navigator.pop(ctx);
                _processManagerExport(filterType: 'present');
              },
            ),
            const SizedBox(height: 10),
            _managerExportTile(
              icon: Icons.cancel_rounded,
              color: Colors.redAccent,
              title: isAr ? "الطلاب الغائبين فقط" : "Absent Students Only",
              onTap: () {
                Navigator.pop(ctx);
                _processManagerExport(filterType: 'absent');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _managerExportTile({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: _ds.isDarkMode ? Colors.black26 : color.withAlpha(15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Future<void> _processManagerExport({required String filterType}) async {
    final levelStr = _selectedLevel!.replaceAll('level_', '').trim();
    final subjectStr = _selectedAttCourseData!['name'].toString().trim();
    final lectureStr = _selectedAttLecture.toString().trim();

    var snap = await _ds.attendanceColl
        .where('subject', isEqualTo: subjectStr)
        .where('level', isEqualTo: levelStr)
        .where('lectureNumber', isEqualTo: lectureStr)
        .get();
    
    Set<String> presentIds = snap.docs
        .map((d) => (d.data() as Map<String, dynamic>)['studentId']?.toString().trim() ?? '')
        .toSet();

    var studentsSnap = await _ds.studentsColl.get();
    var students = studentsSnap.docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return d['level'].toString().trim() == levelStr;
    }).map((e) => e.data() as Map<String, dynamic>).toList();

    students.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

    await ExcelHelper.exportAttendanceToExcel(
      subject: subjectStr,
      level: levelStr,
      division: 'all',
      lectureNumber: lectureStr,
      students: students,
      presentIds: presentIds,
      filterType: filterType,
      isArabic: _ds.isArabic,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تصدير ملف الاكسيل بنجاح')));
  }

  Widget _buildReportsTab() => ReportsManagementView(filterLevelId: _selectedLevel);

  Widget _buildScheduleTab() {
    bool isDark = _ds.isDarkMode;
    if (_selectedLevel == null) {
      return Center(child: Text('يرجى اختيار فرقة دراسية أولاً', style: GoogleFonts.cairo(color: Colors.grey)));
    }

    String cleanLvl = _ds.normalizeLevel(_selectedLevel!);
    String levelId = 'level_$cleanLvl';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: Text('إضافة محاضرة رسمية للجدول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () => _showAddScheduleModal(context, cleanLvl),
                ),
              ),
              const SizedBox(width: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _ds.getOfficialScheduleStream(levelId: levelId),
                builder: (context, snapshot) {
                  int unpublishedCount = 0;
                  if (snapshot.hasData) {
                    unpublishedCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['isPublished'] != true;
                    }).length;
                  }
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(130, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(unpublishedCount > 0 ? 'نشر ($unpublishedCount)' : 'نشر الجدول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('نشر الجدول للطلاب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          content: Text('هل أنت متأكد من نشر جميع المحاضرات الحالية للفرقة $cleanLvl لكي تظهر للطلاب؟', style: GoogleFonts.cairo()),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('تأكيد النشر', style: GoogleFonts.cairo()),
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (confirm) {
                        try {
                          await _ds.publishScheduleEntriesForLevel(levelId, publish: true);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نشر جدول المحاضرات بنجاح للطلاب')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل النشر: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.getOfficialScheduleStream(levelId: levelId),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snap.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 70, color: Colors.grey.withAlpha(80)),
                      const SizedBox(height: 10),
                      Text('لا توجد محاضرات مضافة لهذه الفرقة بعد', style: GoogleFonts.cairo(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  var doc = docs[i];
                  var d = doc.data() as Map<String, dynamic>;
                  bool isPublished = d['isPublished'] == true;
                  String subject = d['subjectName'] ?? d['subject'] ?? '';
                  String doctor = d['doctorName'] ?? d['doctor'] ?? '--';
                  String day = d['day'] ?? d['dayName'] ?? 'السبت';
                  String time = d['startTime'] ?? d['time'] ?? '09:00';
                  String type = d['type'] ?? 'محاضرة';
                  String hall = d['location'] ?? d['hall'] ?? '--';
                  String section = d['targetSection'] ?? d['division'] ?? 'الكل';

                  return Card(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                                    child: Icon(Icons.menu_book_rounded, color: Theme.of(context).primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(subject, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPublished ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPublished ? 'منشور' : 'مسودة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPublished ? Colors.green.shade700 : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Text('اليوم: $day  |  الوقت: $time  |  النوع: $type', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('الدكتور: $doctor  |  القاعة: $hall', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text('الشعبة المستهدفة: ${section == 'all' ? 'جميع الشعب' : section}', style: GoogleFonts.cairo(fontSize: 12, color: Colors.purple.shade300)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: Text('تعديل', style: GoogleFonts.cairo()),
                                onPressed: () => _showAddScheduleModal(context, cleanLvl, existingEntry: d, existingId: doc.id),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                icon: const Icon(Icons.delete_outline, size: 16),
                                label: Text('حذف', style: GoogleFonts.cairo()),
                                onPressed: () async {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                      content: Text('هل أنت متأكد من حذف هذه المحاضرة؟', style: GoogleFonts.cairo()),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text('حذف', style: GoogleFonts.cairo()),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                  if (confirm) {
                                    await _ds.deleteOfficialScheduleEntry(doc.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المحاضرة بنجاح')));
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddScheduleModal(BuildContext context, String levelStr, {Map<String, dynamic>? existingEntry, String? existingId}) async {
    String levelId = 'level_$levelStr';
    bool isEditing = existingEntry != null && existingId != null;

    List<Map<String, dynamic>> coursesList = [];
    List<Map<String, dynamic>> instructorsList = [];
    List<Map<String, dynamic>> sectionsList = [{'id': 'all', 'name': 'جميع الشعب'}];

    String cleanInstructor(String rawName, String prefix) {
      String name = rawName.trim();
      while (true) {
        String oldName = name;
        name = name.replaceFirst(RegExp(r'^(دكتور|د\.|ميد|م\.|مهندس|أ\.|استاذ|أستاذ|أ\s+|\.\s*)\s*', caseSensitive: false), '').trim();
        if (name == oldName || name.isEmpty) break;
      }
      if (name.isEmpty) return '';
      return '$prefix $name';
    }

    try {
      var coursesSnap = await _ds.getCommerceCoursesColl(levelId).get();
      coursesList = coursesSnap.docs.map((c) => {'id': c.id, ...c.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      debugPrint("Error fetching courses: $e");
    }

    try {
      var docsSnap = await _ds.commerceDoctorsColl.get();
      for (var doc in docsSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String formatted = cleanInstructor(data['name'] ?? '', 'د.');
        if (formatted.isNotEmpty) {
          instructorsList.add({'id': doc.id, 'name': formatted});
        }
      }
    } catch (e) {
      debugPrint("Error fetching doctors: $e");
    }

    try {
      var taSnap = await _ds.commerceTasColl.get();
      for (var doc in taSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String formatted = cleanInstructor(data['name'] ?? '', 'م.');
        if (formatted.isNotEmpty) {
          instructorsList.add({'id': doc.id, 'name': formatted});
        }
      }
    } catch (e) {
      debugPrint("Error fetching TAs: $e");
    }

    instructorsList.add({'id': 'other', 'name': 'أخرى (إدخال يدوي)'});

    try {
      var secSnap = await _ds.getCommerceSectionsColl(levelId).get();
      for (var doc in secSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        sectionsList.add({'id': data['id'] ?? doc.id, 'name': data['name'] ?? 'شعبة'});
      }
    } catch (e) {
      debugPrint("Error fetching sections: $e");
    }

    if (coursesList.isEmpty) {
      coursesList = [{'id': 'none', 'name': 'يرجى إضافة مواد من تبويب المواد أولاً'}];
    }
    if (instructorsList.length <= 1) {
      instructorsList.insert(0, {'id': 'none', 'name': 'دكتور / معيد غير محدد'});
    }

    Map<String, dynamic> selectedCourse = coursesList.firstWhere(
      (c) => c['id'] == existingEntry?['subjectId'] || c['name'] == existingEntry?['subject'],
      orElse: () => coursesList.first,
    );

    bool isCustomInstructor = existingEntry?['doctorId']?.toString().startsWith('custom_') ?? false;
    Map<String, dynamic> selectedInstructor = isCustomInstructor 
        ? instructorsList.firstWhere((i) => i['id'] == 'other', orElse: () => instructorsList.first)
        : instructorsList.firstWhere(
            (d) => d['id'] == existingEntry?['doctorId'] || d['name'] == existingEntry?['doctor'],
            orElse: () => instructorsList.first,
          );

    final instructorCustomC = TextEditingController(text: isCustomInstructor ? (existingEntry?['doctorName'] ?? existingEntry?['doctor'] ?? '') : '');

    String dayName = existingEntry?['day'] ?? existingEntry?['dayName'] ?? 'السبت';
    String type = existingEntry?['type'] ?? 'محاضرة';
    String targetSection = existingEntry?['targetSection'] ?? existingEntry?['division'] ?? 'all';
    
    String timeStr = existingEntry?['startTime'] ?? existingEntry?['time'] ?? '09:00';
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}

    final hallC = TextEditingController(text: existingEntry?['location'] ?? existingEntry?['hall'] ?? 'قاعة المحاضرات');

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 25, right: 25, top: 25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(isEditing ? 'تعديل المحاضرة الرسمية' : 'إضافة محاضرة رسمية للفرقة $levelStr', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: dayName,
                  dropdownColor: _ds.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                  decoration: InputDecoration(labelText: 'اليوم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  items: ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setModalState(() => dayName = v ?? 'السبت'),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: _ds.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                  decoration: InputDecoration(labelText: 'النوع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  items: ['محاضرة', 'سكشن'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setModalState(() => type = v ?? 'محاضرة'),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: sectionsList.any((s) => s['name'] == targetSection || s['id'] == targetSection) ? targetSection : 'all',
                  dropdownColor: _ds.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                  decoration: InputDecoration(labelText: 'الشعبة المستهدفة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  items: sectionsList.map((sec) => DropdownMenuItem(
                    value: sec['id'] == 'all' ? 'all' : (sec['name']?.toString() ?? 'all'),
                    child: Text(sec['name'].toString())
                  )).toList(),
                  onChanged: (v) => setModalState(() => targetSection = v ?? 'all'),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedCourse,
                  dropdownColor: _ds.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                  decoration: InputDecoration(labelText: 'اختر المادة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  items: coursesList.map((c) => DropdownMenuItem(value: c, child: Text(c['name'] ?? ''))).toList(),
                  onChanged: (v) => setModalState(() => selectedCourse = v ?? coursesList.first),
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setModalState(() => selectedTime = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'الوقت',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      suffixIcon: const Icon(Icons.access_time_rounded),
                    ),
                    child: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(controller: hallC, decoration: InputDecoration(labelText: 'القاعة / المكان', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                const SizedBox(height: 15),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedInstructor,
                  dropdownColor: _ds.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                  decoration: InputDecoration(labelText: 'اختر الدكتور / المعيد', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  items: instructorsList.map((doc) => DropdownMenuItem(value: doc, child: Text(doc['name'] ?? ''))).toList(),
                  onChanged: (v) => setModalState(() => selectedInstructor = v ?? instructorsList.first),
                ),
                if (selectedInstructor['id'] == 'other') ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: instructorCustomC,
                    decoration: InputDecoration(
                      labelText: 'اسم المحاضر / المعيد (كتابة يدوي)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () async {
                      if (selectedCourse['id'] == 'none') {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إضافة أو اختيار مادة صحيحة أولاً')));
                        return;
                      }
                      String formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                      String hallText = hallC.text.trim().isEmpty ? 'قاعة المحاضرات' : hallC.text.trim();

                      String finalDocId = selectedInstructor['id'];
                      String finalDocName = selectedInstructor['name'];
                      if (finalDocId == 'other') {
                        finalDocId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                        finalDocName = instructorCustomC.text.trim().isEmpty ? 'مُحاضر غير محدد' : instructorCustomC.text.trim();
                      }

                      try {
                        if (isEditing) {
                          await _ds.updateOfficialScheduleEntry(
                            entryId: existingId,
                            levelId: levelId,
                            day: dayName,
                            type: type,
                            targetSection: targetSection,
                            subjectId: selectedCourse['id'],
                            subjectName: selectedCourse['name'],
                            doctorId: finalDocId,
                            doctorName: finalDocName,
                            startTime: formattedTime,
                            location: hallText,
                          );
                        } else {
                          await _ds.addOfficialScheduleEntry(
                            levelId: levelId,
                            day: dayName,
                            type: type,
                            targetSection: targetSection,
                            subjectId: selectedCourse['id'],
                            subjectName: selectedCourse['name'],
                            doctorId: finalDocId,
                            doctorName: finalDocName,
                            startTime: formattedTime,
                            location: hallText,
                          );
                        }

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEditing ? 'تم تعديل المحاضرة بنجاح' : 'تمت إضافة المحاضرة بنجاح')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Text(isEditing ? 'تعديل وحفظ التغييرات' : 'حفظ وإضافة للجدول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class ReportsManagementView extends StatefulWidget {
  final String? filterLevelId;
  const ReportsManagementView({super.key, this.filterLevelId});

  @override
  State<ReportsManagementView> createState() => _ReportsManagementViewState();
}

class _ReportsManagementViewState extends State<ReportsManagementView> {
  final DataService _ds = DataService();

  Future<void> _deleteMessageAndResolve(String collegeId, String levelId, String courseId, String msgDocId, String reportDocId, bool isAr) async {
    try {
      if (msgDocId.isNotEmpty && levelId.isNotEmpty && courseId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('colleges')
            .doc(collegeId)
            .collection('levels')
            .doc(levelId)
            .collection('courses')
            .doc(courseId)
            .collection('forum')
            .doc(msgDocId)
            .delete();
      }
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(collegeId)
          .collection('reports')
          .doc(reportDocId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? "تم حذف الرسالة المخالفة وحذف البلاغ بنجاح" : "Message deleted and report resolved"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _banUserAndResolve(String collegeId, String levelId, String courseId, String authorId, String reportDocId, bool isAr) async {
    try {
      if (authorId.isNotEmpty && levelId.isNotEmpty && courseId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('colleges')
            .doc(collegeId)
            .collection('levels')
            .doc(levelId)
            .collection('courses')
            .doc(courseId)
            .update({
          'bannedUids': FieldValue.arrayUnion([authorId])
        });
      }
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(collegeId)
          .collection('reports')
          .doc(reportDocId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? "تم حظر الطالب وإغلاق البلاغ بنجاح" : "User banned and report resolved"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _dismissReport(String collegeId, String reportDocId, bool isAr) async {
    try {
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(collegeId)
          .collection('reports')
          .doc(reportDocId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? "تم تجاهل البلاغ" : "Report dismissed")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    String collegeId = _ds.selectedInstituteId ?? 'commerce';

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('colleges')
        .doc(collegeId)
        .collection('reports')
        .orderBy('createdAt', descending: true);

    if (widget.filterLevelId != null && widget.filterLevelId!.isNotEmpty) {
      query = query.where('levelId', isEqualTo: widget.filterLevelId);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF673AB7)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 70, color: Colors.green.withAlpha(120)),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? "لا توجد بلاغات معلقة حالياً 🎉" : "No pending reports 🎉",
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data();
              String reportDocId = docs[index].id;
              String msgDocId = data['messageDocId'] ?? '';
              String msgContent = data['messageContent'] ?? '';
              String authorName = data['authorName'] ?? (isAr ? 'مرسل مجهول' : 'Unknown');
              String authorId = data['authorId'] ?? '';
              String reporterName = data['reporterName'] ?? (isAr ? 'مُبَلّغ' : 'Reporter');
              String courseName = data['courseName'] ?? '';
              String levelId = data['levelId'] ?? '';
              String courseId = data['courseId'] ?? '';
              String reason = data['reason'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withAlpha(60)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 15), blurRadius: 12, offset: const Offset(0, 5))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "$courseName (الفرقة $levelId)",
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isAr ? "بلاغ جديد" : "Report",
                              style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        isAr ? "الرسالة المخالفة:" : "Offensive Message:",
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.red.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withAlpha(30)),
                        ),
                        child: Text(
                          msgContent,
                          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? "صاحب الرسالة: " : "Author: ",
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            authorName,
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.report_problem_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? "المُبَلّغ: " : "Reporter: ",
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            reporterName,
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "${isAr ? "سبب الإبلاغ: " : "Reason: "}$reason",
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.delete_forever_rounded, size: 18),
                              label: Text(isAr ? "حذف الرسالة" : "Delete Msg", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _deleteMessageAndResolve(collegeId, levelId, courseId, msgDocId, reportDocId, isAr),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.block_rounded, size: 18),
                              label: Text(isAr ? "حظر الطالب" : "Ban User", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _banUserAndResolve(collegeId, levelId, courseId, authorId, reportDocId, isAr),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                            tooltip: isAr ? "تجاهل / إغلاق البلاغ" : "Dismiss",
                            onPressed: () => _dismissReport(collegeId, reportDocId, isAr),
                          ),
                        ],
                      ),
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
}
