import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../widgets/student_profile_modal.dart';
import 'private_chat_screen.dart';

class DoctorStudentsListScreen extends StatefulWidget {
  const DoctorStudentsListScreen({super.key});

  @override
  State<DoctorStudentsListScreen> createState() => _DoctorStudentsListScreenState();
}

class _DoctorStudentsListScreenState extends State<DoctorStudentsListScreen> {
  final DataService _ds = DataService();
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(isAr ? 'قائمة الطلاب والتواصل' : 'Students List & Chat', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: isAr ? 'ابحث باسم أو كود الطالب...' : 'Search student name or ID...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                  prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _ds.studentsColl.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;

                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      String name = (data['name'] ?? '').toLowerCase();
                      String id = (data['id'] ?? '').toString();
                      return name.contains(_searchQuery.toLowerCase()) || id.contains(_searchQuery);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(child: Text(isAr ? 'لا يوجد طلاب مسجلين' : 'No students found', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final studentData = docs[i].data() as Map<String, dynamic>;
                      final studentUid = studentData['uid'] ?? docs[i].id;
                      final studentName = studentData['name'] ?? 'الطالب';
                      final studentId = studentData['id'] ?? '';
                      final studentPhone = studentData['phone'] ?? '';
                      final division = studentData['division'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 8), blurRadius: 10)],
                        ),
                        child: ListTile(
                          onTap: () => showRichStudentProfileModal(context: context, studentIdOrUid: studentUid, studentName: studentName),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withAlpha(26),
                            backgroundImage: _ds.getAvatarImageProvider(studentData['photoUrl']),
                            child: (studentData['photoUrl'] ?? '').toString().isEmpty
                                ? Icon(Icons.school_rounded, color: primaryColor)
                                : null,
                          ),
                          title: Text(studentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text("ID: $studentId | $division\n${studentPhone.isNotEmpty ? '📞 $studentPhone' : (isAr ? 'رقم الهاتف غير مسجل' : 'No phone')}", style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // WhatsApp Shortcut Button
                              if (studentPhone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.chat_rounded, color: Colors.green, size: 24),
                                  tooltip: isAr ? 'مراسلة عبر واتساب' : 'WhatsApp',
                                  onPressed: () => _ds.launchWhatsApp(studentPhone),
                                ),
                              // Private Chat Button
                              IconButton(
                                icon: Icon(Icons.forum_rounded, color: primaryColor, size: 24),
                                tooltip: isAr ? 'شات خاص' : 'Private Chat',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => PrivateChatScreen(
                                        otherUserId: studentUid,
                                        otherUserName: studentName,
                                        otherUserRole: 'student',
                                      ),
                                    ),
                                  );
                                },
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
        ),
      ),
    );
  }
}
