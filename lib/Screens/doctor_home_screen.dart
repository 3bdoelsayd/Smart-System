import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/app_drawer.dart';
import '../services/data_service.dart';
import 'discussion_forum_screen.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  void _showSubjectPicker(BuildContext context, String doctorId, List<String> teachingLevels, DataService ds) {
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text(ds.translate('select_subject_forum'), style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            StreamBuilder<List<QuerySnapshot>>(
              stream: Stream.fromFuture(Future.wait(
                teachingLevels.map((lvlId) => ds.getCommerceCoursesColl(lvlId).where('doctor_id', isEqualTo: doctorId).get())
              )),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final allDocs = snapshot.data?.expand((qs) => qs.docs).toList() ?? [];
                if (allDocs.isEmpty) return Padding(padding: const EdgeInsets.all(20), child: Text(ds.translate('no_subjects_assigned')));

                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allDocs.length,
                    itemBuilder: (context, index) {
                      final doc = allDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      final levelId = data['level_id'] ?? 'level_1';
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.forum_rounded)),
                        title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                        subtitle: Text("${ds.translate('level')}: ${levelId.toString().replaceAll('level_', '')}"),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (ctx) => DiscussionForumScreen(
                            levelId: levelId, 
                            courseId: doc.id, 
                            courseName: name
                          )));
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    
    return ListenableBuilder(
      listenable: ds,
      builder: (context, _) {
        bool isAr = ds.isArabic;
        bool isDark = ds.isDarkMode;
        
        final primaryColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFF673AB7);
        final doctorName = ds.currentDoctor?['name'] ?? ds.translate('welcome');
        final doctorId = ds.currentDoctor?['uid'] ?? '';
        final List<String> teachingLevels = List<String>.from(ds.currentDoctor?['teachingLevels'] ?? []);

        final List<Map<String, dynamic>> cards = [
          {'icon': Icons.qr_code_rounded, 'title': ds.translate('attendance_mng'), 'route': '/doctor/attendance', 'color': Colors.blue},
          {'icon': Icons.assignment_turned_in_rounded, 'title': ds.translate('research_review'), 'route': '/doctor/researches', 'color': Colors.orange},
          {'icon': Icons.forum_rounded, 'title': ds.translate('forum'), 'color': Colors.cyan, 'action': 'open_picker'},
          {'icon': Icons.settings_rounded, 'title': ds.translate('settings'), 'route': '/settings', 'color': Colors.purple},
        ];

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
            drawer: AppDrawer(name: doctorName, role: ds.translate('faculty_member')),
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [primaryColor, primaryColor.withAlpha(204)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => Scaffold.of(context).openDrawer())),
                            IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/notifications', arguments: 'doctor')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(ds.translate('welcome'), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        Text(doctorName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, mainAxisExtent: 160),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => DashboardCard(
                        icon: cards[i]['icon'] as IconData,
                        title: cards[i]['title'] as String,
                        color: cards[i]['color'] as Color,
                        onTap: () {
                          if (cards[i].containsKey('route')) {
                            Navigator.pushNamed(context, cards[i]['route'] as String);
                          } else if (cards[i]['action'] == 'open_picker') {
                            _showSubjectPicker(context, doctorId, teachingLevels, ds);
                          }
                        },
                      ),
                      childCount: cards.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    child: Text(ds.translate('my_courses'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  ),
                ),
                teachingLevels.isEmpty 
                ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(isAr ? "لم يتم إسناد فرق دراسية لك بعد" : "No levels assigned"))))
                : StreamBuilder<List<QuerySnapshot>>(
                  stream: Stream.fromFuture(Future.wait(
                    teachingLevels.map((lvlId) => ds.getCommerceCoursesColl(lvlId).where('doctor_id', isEqualTo: doctorId).get())
                  )),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                    final allDocs = snapshot.data?.expand((qs) => qs.docs).toList() ?? [];
                    if (allDocs.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(ds.translate('no_subjects_assigned')))));

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = allDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name']?.toString() ?? 'Unknown';
                          final levelId = data['level_id']?.toString() ?? 'level_1';
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)]),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: const Color(0xFF673AB7).withAlpha(26), child: const Icon(Icons.book_rounded, color: Color(0xFF673AB7))),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${ds.translate('level')}: ${levelId.replaceAll('level_', '')}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.forum_rounded, color: Colors.cyan),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => DiscussionForumScreen(levelId: levelId, courseId: doc.id, courseName: name)));
                                },
                              ),
                            ),
                          );
                        },
                        childCount: allDocs.length,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),
        );
      },
    );
  }
}
