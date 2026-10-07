import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../widgets/doctor_profile_modal.dart';
import 'private_chat_screen.dart';

class StudentDoctorsListScreen extends StatefulWidget {
  const StudentDoctorsListScreen({super.key});

  @override
  State<StudentDoctorsListScreen> createState() => _StudentDoctorsListScreenState();
}

class _StudentDoctorsListScreenState extends State<StudentDoctorsListScreen> {
  final DataService _ds = DataService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
          title: Text(isAr ? 'مراسلة المحاضرين (شات خاص)' : 'Doctors & Private Chat', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            // --- حقل البحث عن دكتور ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: isAr ? 'ابحث باسم المحاضر...' : 'Search doctor name...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),

            // --- قائمة دكاترة الكلية ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _ds.commerceDoctorsColl.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snap.data!.docs;

                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((d) {
                      var data = d.data() as Map<String, dynamic>;
                      String name = (data['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(child: Text(isAr ? 'لا يوجد محاضرين مسجلين' : 'No doctors found', style: const TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final docData = docs[i].data() as Map<String, dynamic>;
                      final doctorUid = docData['uid'] ?? docs[i].id;
                      final doctorName = docData['name'] ?? 'دكتور';
                      final phone = docData['phone'] ?? '';
                      final photoUrl = docData['photoUrl'];

                      final Map privacy = docData['privacy'] as Map? ?? {};
                      final bool hidePhone = privacy['hidePhone'] == true;
                      final bool hidePhoto = privacy['hidePhoto'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 8), blurRadius: 10)],
                        ),
                        child: ListTile(
                          onTap: () => showRichDoctorProfileModal(context: context, doctorUidOrEmail: doctorUid, doctorName: doctorName),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: primaryColor.withAlpha(26),
                            backgroundImage: (!hidePhoto && (photoUrl ?? '').toString().isNotEmpty) ? _ds.getAvatarImageProvider(photoUrl) : null,
                            child: (hidePhoto || (photoUrl ?? '').toString().isEmpty) ? Icon(Icons.person_rounded, color: primaryColor) : null,
                          ),
                          title: Text(doctorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text(isAr ? 'عضو هيئة التدريس / محاضر المادة' : 'Faculty Member', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!hidePhone && phone.toString().isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.chat_rounded, color: Colors.green, size: 24),
                                  tooltip: isAr ? 'واتساب' : 'WhatsApp',
                                  onPressed: () => _ds.launchWhatsApp(phone.toString()),
                                ),
                              IconButton(
                                icon: Icon(Icons.forum_rounded, color: primaryColor, size: 24),
                                tooltip: isAr ? 'شات خاص' : 'Private Chat',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => PrivateChatScreen(
                                        otherUserId: doctorUid,
                                        otherUserName: doctorName,
                                        otherUserRole: 'doctor',
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
