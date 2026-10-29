import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';
import '../utils/debouncer.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/student_profile_modal.dart';
import 'private_chat_screen.dart';

class DoctorStudentsListScreen extends StatefulWidget {
  const DoctorStudentsListScreen({super.key});

  @override
  State<DoctorStudentsListScreen> createState() => _DoctorStudentsListScreenState();
}

class _DoctorStudentsListScreenState extends State<DoctorStudentsListScreen> {
  final DataService _ds = DataService();
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = _ds.isArabic;
    final bool isDark = _ds.isDarkMode;
    final Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            isAr ? 'قائمة الطلاب والتواصل' : 'Students List & Chat',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _ds.studentsColl.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final teachingLevels = List<String>.from(_ds.currentDoctor?['teachingLevels'] ?? []);
                  final normalizedDoctorLevels = teachingLevels.map((l) => _ds.normalizeLevel(l)).toList();

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final studentLevel = _ds.normalizeLevel(data['level']?.toString() ?? '1');

                    final bool levelMatch = teachingLevels.isEmpty || normalizedDoctorLevels.contains(studentLevel);
                    if (!levelMatch) return false;

                    if (_searchQuery.isNotEmpty) {
                      final String name = (data['name'] ?? '').toString().toLowerCase();
                      final String id = (data['id'] ?? '').toString();
                      return name.contains(_searchQuery) || id.contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        isAr ? 'لا يوجد طلاب مسجلين' : 'No students found',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final studentData = docs[i].data() as Map<String, dynamic>;
                      final studentUid = studentData['uid'] ?? docs[i].id;

                      return RepaintBoundary(
                        key: ValueKey<String>(studentUid),
                        child: StudentListItemTile(
                          studentUid: studentUid,
                          studentData: studentData,
                          isAr: isAr,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          ds: _ds,
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

class StudentListItemTile extends StatelessWidget {
  final String studentUid;
  final Map<String, dynamic> studentData;
  final bool isAr;
  final bool isDark;
  final Color primaryColor;
  final DataService ds;

  const StudentListItemTile({
    super.key,
    required this.studentUid,
    required this.studentData,
    required this.isAr,
    required this.isDark,
    required this.primaryColor,
    required this.ds,
  });

  @override
  Widget build(BuildContext context) {
    final String studentName = studentData['name'] ?? 'الطالب';
    final String studentId = studentData['id'] ?? '';
    final String studentPhone = studentData['phone'] ?? '';
    final String division = studentData['division'] ?? '';
    final String? photoUrl = studentData['photoUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 8),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        onTap: () => showRichStudentProfileModal(
          context: context,
          studentIdOrUid: studentUid,
          studentName: studentName,
          initialStudentData: studentData,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () {
            if ((photoUrl ?? '').isNotEmpty) {
              showFullScreenImageViewer(context, photoUrl!, studentName);
            } else {
              showRichStudentProfileModal(
                context: context,
                studentIdOrUid: studentUid,
                studentName: studentName,
                initialStudentData: studentData,
              );
            }
          },
          child: CachedAvatar(
            photoUrl: photoUrl,
            name: studentName,
            radius: 24,
            cacheWidth: 120,
            cacheHeight: 120,
          ),
        ),
        title: Text(
          studentName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          "ID: $studentId | $division\n${studentPhone.isNotEmpty ? '📞 $studentPhone' : (isAr ? 'رقم الهاتف غير مسجل' : 'No phone')}",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (studentPhone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.chat_rounded, color: Colors.green, size: 24),
                tooltip: isAr ? 'مراسلة عبر واتساب' : 'WhatsApp',
                onPressed: () => ds.launchWhatsApp(studentPhone),
              ),
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
                      otherUserPhotoUrl: photoUrl,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
