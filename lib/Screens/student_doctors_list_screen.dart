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
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
          appBar: AppBar(
            title: Text(
              isAr ? 'المحادثات والاتصال المباشر' : 'Private Messaging & Support',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            bottom: TabBar(
              indicatorColor: isDark ? const Color(0xFF03DAC6) : Colors.amber,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
              tabs: [
                Tab(
                  icon: const Icon(Icons.school_rounded, size: 20),
                  text: isAr ? 'أعضاء هيئة التدريس' : 'Doctors',
                ),
                Tab(
                  icon: const Icon(Icons.badge_rounded, size: 20),
                  text: isAr ? 'المعيدين' : 'TAs',
                ),
                Tab(
                  icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                  text: isAr ? 'إدارة الفرقة' : 'Managers',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // --- حقل البحث ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: isAr ? 'بحث بالاسم...' : 'Search by name...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildDoctorsTab(isAr, isDark, primaryColor),
                    _buildTAsTab(isAr, isDark, primaryColor),
                    _buildManagersTab(isAr, isDark, primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorsTab(bool isAr, bool isDark, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
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
                onTap: () => showRichDoctorProfileModal(
                  context: context, 
                  doctorUidOrEmail: doctorUid, 
                  doctorName: doctorName,
                  initialDoctorData: docData,
                ),
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
                              otherUserPhotoUrl: hidePhoto ? null : photoUrl,
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
    );
  }

  Widget _buildTAsTab(bool isAr, bool isDark, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.commerceTasColl.snapshots(),
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
          return Center(child: Text(isAr ? 'لا يوجد معيدين مسجلين حالياً' : 'No TAs found', style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final docData = docs[i].data() as Map<String, dynamic>;
            final taUid = docData['uid'] ?? docs[i].id;
            final taName = docData['name'] ?? 'معيد';
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
                onTap: () => showRichDoctorProfileModal(
                  context: context, 
                  doctorUidOrEmail: taUid, 
                  doctorName: taName,
                  initialDoctorData: docData,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal.withAlpha(30),
                  backgroundImage: (!hidePhoto && (photoUrl ?? '').toString().isNotEmpty) ? _ds.getAvatarImageProvider(photoUrl) : null,
                  child: (hidePhoto || (photoUrl ?? '').toString().isEmpty) ? const Icon(Icons.person_outline_rounded, color: Colors.teal) : null,
                ),
                title: Text(taName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text(isAr ? 'معيد السكشن' : 'Teaching Assistant', style: TextStyle(fontSize: 12, color: isDark ? Colors.tealAccent : Colors.teal)),
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
                      icon: const Icon(Icons.forum_rounded, color: Colors.teal, size: 24),
                      tooltip: isAr ? 'شات خاص' : 'Private Chat',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => PrivateChatScreen(
                              otherUserId: taUid,
                              otherUserName: taName,
                              otherUserRole: 'ta',
                              otherUserPhotoUrl: hidePhoto ? null : photoUrl,
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
    );
  }

  Widget _buildManagersTab(bool isAr, bool isDark, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ds.commerceManagersColl.snapshots(),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 15),
                Text(
                  isAr ? 'لا يوجد مديري فرقة متاحين حالياً' : 'No managers registered',
                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final docData = docs[i].data() as Map<String, dynamic>;
            final managerUid = docData['uid'] ?? docs[i].id;
            final managerName = docData['name'] ?? 'مدير الفرقة';
            final phone = docData['phone'] ?? '';
            final photoUrl = docData['photoUrl'];

            List managedLvls = docData['managedLevels'] as List? ?? [];
            String levelText = managedLvls.isEmpty
                ? (isAr ? 'إدارة الكلية' : 'College Management')
                : (isAr ? "مدير الفرقة ${managedLvls.join(', ')}" : "Manager Lvl ${managedLvls.join(', ')}");

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 8), blurRadius: 10)],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.amber.withAlpha(30),
                  backgroundImage: (photoUrl ?? '').toString().isNotEmpty ? _ds.getAvatarImageProvider(photoUrl) : null,
                  child: (photoUrl ?? '').toString().isEmpty ? const Icon(Icons.security_rounded, color: Colors.amber) : null,
                ),
                title: Text(managerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text(levelText, style: TextStyle(fontSize: 12, color: isDark ? Colors.amber.shade200 : Colors.deepOrange)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phone.toString().isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.chat_rounded, color: Colors.green, size: 24),
                        tooltip: isAr ? 'واتساب' : 'WhatsApp',
                        onPressed: () => _ds.launchWhatsApp(phone.toString()),
                      ),
                    IconButton(
                      icon: const Icon(Icons.forum_rounded, color: Colors.amber, size: 24),
                      tooltip: isAr ? 'شات خاص' : 'Private Chat',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => PrivateChatScreen(
                              otherUserId: managerUid,
                              otherUserName: managerName,
                              otherUserRole: 'manager',
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
          },
        );
      },
    );
  }
}
