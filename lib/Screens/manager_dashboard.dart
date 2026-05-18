import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../utils/excel_helper.dart';
import '../widgets/app_drawer.dart';

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
  
  // Attendance Selection State
  Map<String, dynamic>? _selectedAttCourseData;
  int? _selectedAttLecture;

  @override
  void initState() {
    super.initState();
    _managedLevels = List<String>.from(_ds.currentAdmin?['managedLevels'] ?? []);
    _selectedLevel = _managedLevels.isNotEmpty ? _managedLevels.first : null;
    _tabController = TabController(length: 5, vsync: this);
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
                        const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
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
                    Tab(text: 'الحضور'),
                    Tab(text: 'الفصول'),
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
              _buildAttendanceTab(),
              _buildSemestersTab(),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(),
      ),
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
    var semSnap = await _ds.commerceSemestersColl.where('isActive', isEqualTo: true).get(); 
    var docSnap = await _ds.commerceDoctorsColl.get();

    _showStyledBS(title: 'إضافة مادة ودكتور', icon: Icons.book, color: Colors.deepPurple, children: [
      _buildInputField(nameC, 'اسم المادة', Icons.book_outlined),
      _buildInputField(lecturesC, 'عدد المحاضرات', Icons.format_list_numbered, isNumber: true),
      _buildDropdown('الشعبة', Icons.groups, [const DropdownMenuItem(value: 'all', child: Text('الكل')), const DropdownMenuItem(value: 'محاسبه', child: Text('محاسبه')), const DropdownMenuItem(value: 'نظم معلومات الاعمال', child: Text('نظم معلومات الاعمال'))], (v) => selDiv = v),
      _buildDropdown('الفصل الدراسي (النشط حالياً)', Icons.calendar_today, semSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text((d.data() as Map)['name'] ?? ''))).toList(), (v) => selSem = v),
      _buildDropdown('الدكتور المسؤول', Icons.person_search, docSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text((d.data() as Map)['name'] ?? ''))).toList(), (v) => selDoc = v),
    ], onSave: () async {
      if (selSem != null && selDoc != null && nameC.text.isNotEmpty) {
        int count = int.tryParse(lecturesC.text) ?? 12;
        await _ds.addCourseToLevel(_selectedLevel!, nameC.text, selDiv ?? 'all', selSem!, selDoc!, lecturesCount: count);
        Navigator.pop(context);
      }
    });
  }

  void _showEditCourseBS(DocumentSnapshot courseDoc) async {
    final data = courseDoc.data() as Map<String, dynamic>;
    final nameC = TextEditingController(text: data['name']); 
    final lecturesC = TextEditingController(text: (data['lecturesCount'] ?? 12).toString());
    String? selDiv = data['division'];
    String? selDoc = data['doctor_id'];
    
    var docSnap = await _ds.commerceDoctorsColl.get();

    _showStyledBS(
      title: 'تعديل بيانات المادة', 
      icon: Icons.edit_note_rounded, 
      color: Colors.blue, 
      children: [
        _buildInputField(nameC, 'اسم المادة', Icons.book_outlined),
        _buildInputField(lecturesC, 'عدد المحاضرات', Icons.format_list_numbered, isNumber: true),
        _buildDropdown('الشعبة', Icons.groups, [
          const DropdownMenuItem(value: 'all', child: Text('الكل')), 
          const DropdownMenuItem(value: 'محاسبه', child: Text('محاسبه')), 
          const DropdownMenuItem(value: 'نظم معلومات الاعمال', child: Text('نظم معلومات الاعمال'))
        ], (v) => selDiv = v, value: selDiv),
        _buildDropdown('الدكتور المسؤول', Icons.person_search, docSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text((d.data() as Map)['name'] ?? ''))).toList(), (v) => selDoc = v, value: selDoc),
      ], 
      onSave: () async {
        if (nameC.text.isNotEmpty && selDoc != null) {
          int count = int.tryParse(lecturesC.text) ?? 12;
          await courseDoc.reference.update({
            'name': nameC.text,
            'lecturesCount': count,
            'division': selDiv ?? 'all',
            'doctor_id': selDoc,
          });
          Navigator.pop(context);
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
        Navigator.pop(context);
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
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ds.studentsColl.where('level', isEqualTo: _selectedLevel!.replaceAll('level_', '')).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snap.data!.docs.where((d) => (d.data() as Map)['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              if (docs.isEmpty) return _buildEmptyState(Icons.group_off, 'لا يوجد طلاب');
              return ListView.builder(padding: const EdgeInsets.all(15), itemCount: docs.length, itemBuilder: (ctx, i) {
                var d = docs[i].data() as Map<String, dynamic>;
                return _buildListItem(title: d['name'] ?? '', subtitle: 'ID: ${d['id']} | ${d['division']}', icon: Icons.school, color: Colors.green, onDelete: () => _ds.deleteStudent(docs[i].id, _selectedLevel!.replaceAll('level_', '')));
              });
            },
          ),
        ),
      ],
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
      stream: _ds.commerceDoctorsColl.where('teachingLevels', arrayContains: _selectedLevel).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs;
        if (docs.isEmpty) return _buildEmptyState(Icons.person_off_outlined, 'لا يوجد دكاترة');
        return ListView.builder(padding: const EdgeInsets.all(15), itemCount: docs.length, itemBuilder: (ctx, i) {
          var d = docs[i].data() as Map<String, dynamic>;
          return _buildListItem(title: d['name'] ?? '', subtitle: d['email'] ?? '', icon: Icons.person, color: Colors.pink, onDelete: () => _ds.deleteDoctor(docs[i].id));
        });
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
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: _ds.isArabic ? 'ابحث بالاسم...' : 'Search by name...',
          prefixIcon: const Icon(Icons.search_rounded),
          fillColor: _ds.isDarkMode ? const Color(0xFF1C1C23) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildListItem({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onDelete, VoidCallback? onEdit}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 22)),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null) IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: onDelete),
          ],
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
    var snap = await _ds.attendanceColl
        .where('subject', isEqualTo: _selectedAttCourseData!['name'])
        .where('level', isEqualTo: _selectedLevel!.replaceAll('level_', ''))
        .where('lectureNumber', isEqualTo: _selectedAttLecture.toString())
        .get();
    
    List<Map<String, dynamic>> data = snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    await ExcelHelper.exportAttendance(data, "${_selectedAttCourseData!['name']}_Lec$_selectedAttLecture");
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تصدير ملف الاكسيل بنجاح')));
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
