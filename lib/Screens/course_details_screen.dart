import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String levelId;
  final String courseId;
  final String courseName;

  const CourseDetailsScreen({
    super.key,
    required this.levelId,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final DataService _ds = DataService();

  void _showAddLectureBS() {
    final titleController = TextEditingController();
    final numberController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 25, right: 25, top: 15),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),
              CircleAvatar(radius: 35, backgroundColor: Colors.blue.withAlpha(30), child: const Icon(Icons.video_library_rounded, color: Colors.blue, size: 35)),
              const SizedBox(height: 15),
              Text('إضافة محاضرة جديدة', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              _buildInputField(numberController, 'رقم المحاضرة (مثلاً: 13)', Icons.format_list_numbered_rtl_rounded, isNumeric: true),
              _buildInputField(titleController, 'عنوان المحاضرة (اختياري)', Icons.title_rounded),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (numberController.text.isNotEmpty) {
                      _ds.addLectureToCourse(
                        widget.levelId,
                        widget.courseId,
                        titleController.text.trim(),
                        int.parse(numberController.text),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF673AB7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  child: Text('حفظ المحاضرة', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController c, String label, IconData icon, {bool isNumeric = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: _ds.isDarkMode ? Colors.black26 : Colors.grey.shade100, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.withAlpha(30))),
      child: TextField(
        controller: c,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFF673AB7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = _ds.isDarkMode;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text('محاضرات: ${widget.courseName}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _ds.getCommerceLecturesColl(widget.levelId, widget.courseId).orderBy('number').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            var lectures = snapshot.data!.docs;
            if (lectures.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library_outlined, size: 80, color: Colors.grey.withAlpha(50)), const SizedBox(height: 10), Text('لا توجد محاضرات مضافة بعد', style: GoogleFonts.cairo(color: Colors.grey))]));

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: lectures.length,
              itemBuilder: (context, index) {
                var data = lectures[index].data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF673AB7).withAlpha(20), borderRadius: BorderRadius.circular(15)),
                      child: Text(data['number'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF673AB7), fontSize: 18)),
                    ),
                    title: Text(data['title']?.isEmpty ?? true ? 'محاضرة رقم ${data['number']}' : data['title'], style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('تمت الإضافة: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : 'الآن'}', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                    trailing: Container(
                      decoration: BoxDecoration(color: Colors.red.withAlpha(15), shape: BoxShape.circle),
                      child: IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 22), onPressed: () => lectures[index].reference.delete()),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddLectureBS,
          backgroundColor: const Color(0xFF673AB7),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('إضافة محاضرة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
