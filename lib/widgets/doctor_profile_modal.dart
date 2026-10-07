import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../Screens/private_chat_screen.dart';

void showRichDoctorProfileModal({
  required BuildContext context,
  required String doctorUidOrEmail,
  String? doctorName,
}) async {
  final ds = DataService();
  bool isAr = ds.isArabic;
  bool isDark = ds.isDarkMode;
  Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
  bool isStudentViewer = ds.userRole == 'student';

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  Map<String, dynamic>? doctorData;
  try {
    var docSnap = await ds.commerceDoctorsColl.doc(doctorUidOrEmail.trim()).get();
    if (docSnap.exists && docSnap.data() != null) {
      doctorData = docSnap.data() as Map<String, dynamic>;
    }

    if (doctorData == null) {
      var snap = await ds.commerceDoctorsColl.where('email', isEqualTo: doctorUidOrEmail.trim()).get();
      if (snap.docs.isEmpty) {
        snap = await ds.commerceDoctorsColl.where('uid', isEqualTo: doctorUidOrEmail.trim()).get();
      }
      if (snap.docs.isNotEmpty) {
        doctorData = snap.docs.first.data() as Map<String, dynamic>;
      }
    }

    if (doctorData == null) {
      var allSnap = await ds.commerceDoctorsColl.get();
      for (var d in allSnap.docs) {
        var data = d.data() as Map<String, dynamic>;
        String dName = (data['name'] ?? '').toString().trim();
        if (doctorName != null && dName == doctorName.trim()) {
          doctorData = data;
          break;
        }
      }
    }
  } catch (e) {
    debugPrint("Fetch doctor error: $e");
  }

  if (context.mounted) {
    Navigator.pop(context); // Close loading dialog
  }

  if (doctorData == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'لم يتم العثور على بيانات المحاضر' : 'Doctor data not found')));
    }
    return;
  }

  final name = doctorData['name'] ?? doctorName ?? 'دكتور المادة';
  final phone = doctorData['phone'] ?? '';
  final personalEmail = doctorData['personalEmail'] ?? '';
  final photoUrl = doctorData['photoUrl'];
  final uid = doctorData['uid'] ?? doctorUidOrEmail;

  final Map privacy = doctorData['privacy'] as Map? ?? {};
  final bool hidePhoto = isStudentViewer && (privacy['hidePhoto'] == true);
  final bool hidePhone = isStudentViewer && (privacy['hidePhone'] == true);
  final bool hideEmail = isStudentViewer && (privacy['hideEmail'] == true);

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
                backgroundImage: (!hidePhoto && (photoUrl ?? '').toString().isNotEmpty) ? ds.getAvatarImageProvider(photoUrl) : null,
                child: (hidePhoto || (photoUrl ?? '').toString().isEmpty) ? Icon(Icons.person, size: 50, color: primaryColor) : null,
              ),
              const SizedBox(height: 15),
              Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center),
              Text(isAr ? "عضو هيئة التدريس / محاضر المادة" : "Faculty Member / Lecturer", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 25),

              // التفاصيل والاتصال (مراعاة الخصوصية)
              if (!hidePhone && phone.toString().isNotEmpty)
                _docDetailRow(Icons.phone_rounded, isAr ? "رقم الهاتف والواتساب:" : "Phone:", phone.toString(), isDark),
              if (!hideEmail && personalEmail.toString().isNotEmpty)
                _docDetailRow(Icons.email_rounded, isAr ? "البريد الإلكتروني الشخصي:" : "Personal Email:", personalEmail.toString(), isDark),

              if (hidePhone && hideEmail && isStudentViewer)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    isAr ? "قام المحاضر بفرض قيود الخصوصية على وسائل الاتصال المباشر" : "Direct contact info is hidden by doctor privacy settings",
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 25),

              // أزرار التواصل
              Row(
                children: [
                  if (!hidePhone && phone.toString().isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        icon: const Icon(Icons.chat_rounded, color: Colors.white),
                        label: Text(isAr ? "واتساب" : "WhatsApp", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => ds.launchWhatsApp(phone.toString()),
                      ),
                    ),
                  if (!hidePhone && phone.toString().isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      icon: const Icon(Icons.forum_rounded, color: Colors.white),
                      label: Text(isAr ? "مراسلة خاصة" : "Private Message", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => PrivateChatScreen(
                              otherUserId: uid,
                              otherUserName: name,
                              otherUserRole: 'doctor',
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

Widget _docDetailRow(IconData icon, String label, String value, bool isDark) {
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
