import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../Screens/private_chat_screen.dart';

void showRichStudentProfileModal({
  required BuildContext context,
  required String studentIdOrUid,
  String? studentName,
  String? subject,
  Map<String, dynamic>? initialStudentData,
}) async {
  final ds = DataService();
  bool isAr = ds.isArabic;
  bool isDark = ds.isDarkMode;
  Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

  Map<String, dynamic>? studentData = initialStudentData;

  if (studentData == null) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var docSnap = await ds.studentsColl.doc(studentIdOrUid.trim()).get();
      if (docSnap.exists && docSnap.data() != null) {
        studentData = docSnap.data() as Map<String, dynamic>;
      }

      if (studentData == null) {
        var snap = await ds.studentsColl.where('id', isEqualTo: studentIdOrUid.trim()).get();
        if (snap.docs.isEmpty && int.tryParse(studentIdOrUid.trim()) != null) {
          snap = await ds.studentsColl.where('id', isEqualTo: int.tryParse(studentIdOrUid.trim())).get();
        }
        if (snap.docs.isEmpty) {
          snap = await ds.studentsColl.where('uid', isEqualTo: studentIdOrUid.trim()).get();
        }
        if (snap.docs.isNotEmpty) {
          studentData = snap.docs.first.data() as Map<String, dynamic>;
        }
      }

      if (studentData == null) {
        var allSnap = await ds.studentsColl.get();
        for (var d in allSnap.docs) {
          var data = d.data() as Map<String, dynamic>;
          String sId = (data['id'] ?? '').toString().trim();
          String sUid = (data['uid'] ?? '').toString().trim();
          String sName = (data['name'] ?? '').toString().trim();

          if (sId == studentIdOrUid.trim() || sUid == studentIdOrUid.trim() || (studentName != null && sName == studentName.trim())) {
            studentData = data;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("Fetch student error: $e");
    }

    if (context.mounted) {
      Navigator.pop(context); // إغلاق مؤشر التحميل فقط عندما يفتح
    }
  }

  int attCount = 0;
  int resCount = 0;
  String sId = studentData?['id'] ?? studentIdOrUid;

  if (subject != null && subject.isNotEmpty) {
    try {
      final results = await Future.wait([
        ds.attendanceColl.where('studentId', isEqualTo: sId.trim()).where('subject', isEqualTo: subject.trim()).get(),
        ds.submissionsColl.where('studentId', isEqualTo: sId.trim()).where('subject', isEqualTo: subject.trim()).get(),
      ]);
      attCount = results[0].docs.length;
      resCount = results[1].docs.length;
    } catch (_) {}
  }

  if (studentData == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'لم يتم العثور على بيانات الطالب' : 'Student data not found')));
    }
    return;
  }

  final name = studentData['name'] ?? studentName ?? 'طالب';
  final id = studentData['id'] ?? '---';
  final level = studentData['level'] ?? '---';
  final division = studentData['division'] ?? '---';
  final phone = studentData['phone'] ?? '';
  final personalEmail = studentData['personalEmail'] ?? '';
  final photoUrl = studentData['photoUrl'];
  final uid = studentData['uid'] ?? id;

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),

              // الصورة والاسم
              CircleAvatar(
                radius: 45,
                backgroundColor: primaryColor.withAlpha(30),
                backgroundImage: ds.getAvatarImageProvider(photoUrl),
                child: (photoUrl ?? '').toString().isEmpty ? Icon(Icons.person, size: 50, color: primaryColor) : null,
              ),
              const SizedBox(height: 15),
              Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center),
              Text("ID: $id", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),

              // التفاصيل
              _detailRow(Icons.layers_rounded, isAr ? "الفرقة / المستوى:" : "Level:", "الفرقة $level", isDark),
              _detailRow(Icons.grid_view_rounded, isAr ? "الشعبة:" : "Division:", division, isDark),
              if (phone.toString().isNotEmpty) _detailRow(Icons.phone_rounded, isAr ? "رقم الهاتف:" : "Phone:", phone.toString(), isDark),
              if (personalEmail.toString().isNotEmpty) _detailRow(Icons.email_rounded, isAr ? "البريد الشخصي:" : "Personal Email:", personalEmail.toString(), isDark),
              
              if (subject != null && subject.isNotEmpty) ...[
                const Divider(height: 25),
                Row(
                  children: [
                    Expanded(child: _statBox(isAr ? "حضور المادة" : "Attendance", "$attCount", Colors.green, isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _statBox(isAr ? "أبحاث مرفوعة" : "Researches", "$resCount", Colors.blue, isDark)),
                  ],
                ),
              ],

              const SizedBox(height: 25),

              // أزرار التواصل المباشر (واتساب وشات خاص)
              Row(
                children: [
                  if (phone.toString().isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        icon: const Icon(Icons.chat_rounded, color: Colors.white),
                        label: Text(isAr ? "واتساب" : "WhatsApp", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => ds.launchWhatsApp(phone.toString()),
                      ),
                    ),
                  if (phone.toString().isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      icon: const Icon(Icons.forum_rounded, color: Colors.white),
                      label: Text(isAr ? "شات خاص" : "Private Chat", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => PrivateChatScreen(
                              otherUserId: uid,
                              otherUserName: name,
                              otherUserRole: 'student',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _detailRow(IconData icon, String label, String value, bool isDark) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(color: isDark ? Colors.black26 : const Color(0xFFF8F9FE), borderRadius: BorderRadius.circular(15)),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF673AB7)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      ],
    ),
  );
}

Widget _statBox(String label, String value, Color color, bool isDark) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withAlpha(26),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: color.withAlpha(30)),
    ),
    child: Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
