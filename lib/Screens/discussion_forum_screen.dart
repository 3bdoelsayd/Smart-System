import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/data_service.dart';
import 'private_chat_screen.dart';
import 'doctor_students_list_screen.dart';
import 'student_doctors_list_screen.dart';

class DiscussionForumScreen extends StatefulWidget {
  final String levelId;
  final String courseId;
  final String courseName;

  const DiscussionForumScreen({
    super.key,
    required this.levelId,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<DiscussionForumScreen> createState() => _DiscussionForumScreenState();
}

class _DiscussionForumScreenState extends State<DiscussionForumScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DataService _ds = DataService();
  bool _isSending = false;

  // تم تعديل المسار ليكون ديناميكياً حسب المعهد المختار
  DocumentReference get _courseRef => FirebaseFirestore.instance
      .collection('colleges')
      .doc(_ds.selectedInstituteId ?? 'commerce') 
      .collection('levels')
      .doc(widget.levelId)
      .collection('courses')
      .doc(widget.courseId);

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final user = _ds.userRole == 'student' ? _ds.currentStudent : _ds.currentDoctor;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      if (_ds.userRole == 'student') {
        final courseDoc = await _courseRef.get();
        final data = courseDoc.data() as Map<String, dynamic>?;
        if (data?['forumLocked'] == true) {
          _showError("عذراً، النقاش مغلق حالياً بواسطة المحاضر");
          return;
        }
        List banned = data?['bannedUids'] ?? [];
        if (banned.contains(user['uid'])) {
          _showError("تم حظرك من المشاركة في هذا النقاش");
          return;
        }
      }

      final content = _messageController.text.trim();
      _messageController.clear();

      await _courseRef.collection('forum').add({
        'authorId': user['uid'] ?? user['id'],
        'authorName': user['name'],
        'authorRole': _ds.userRole,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      _showError("فشل إرسال الرسالة");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo())));
  }

  void _toggleChatLock(bool currentStatus) async {
    try {
      await _courseRef.update({'forumLocked': !currentStatus});
      _showError(!currentStatus ? "تم إغلاق الشات" : "تم فتح الشات");
    } catch (e) {
      _showError("فشل تغيير حالة الشات");
    }
  }

  void _clearChat() async {
    bool isAr = _ds.isArabic;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? "مسح الشات" : "Clear Chat"),
        content: Text(isAr ? "هل أنت متأكد من مسح جميع الرسائل في هذا القسم؟" : "Are you sure you want to delete all messages?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? "إلغاء" : "Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAr ? "مسح الكل" : "Delete All", style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final batch = FirebaseFirestore.instance.batch();
      final snapshots = await _courseRef.collection('forum').get();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _showError(isAr ? "تم مسح الشات بنجاح" : "Chat cleared");
    }
  }

  void _showBannedList() async {
    bool isAr = _ds.isArabic;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Text(isAr ? "قائمة المحظورين" : "Banned Students", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _courseRef.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final data = snap.data!.data() as Map<String, dynamic>?;
                  final List bannedUids = data?['bannedUids'] ?? [];

                  if (bannedUids.isEmpty) return Center(child: Text(isAr ? "لا يوجد طلاب محظورين" : "No banned students"));

                  return ListView.builder(
                    itemCount: bannedUids.length,
                    itemBuilder: (ctx, i) => FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collectionGroup('students').where('uid', isEqualTo: bannedUids[i]).get(),
                      builder: (ctx, sSnap) {
                        if (!sSnap.hasData || sSnap.data!.docs.isEmpty) return const SizedBox();
                        final sData = sSnap.data!.docs.first.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(sData['name'] ?? ''),
                          subtitle: Text("ID: ${sData['id']}"),
                          trailing: TextButton(
                            child: Text(isAr ? "إلغاء الحظر" : "Unblock", style: const TextStyle(color: Colors.green)),
                            onPressed: () async {
                              await _courseRef.update({
                                'bannedUids': FieldValue.arrayRemove([bannedUids[i]])
                              });
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentOptions(Map<String, dynamic> msgData) async {
    if (_ds.userRole != 'doctor') return;
    if (msgData['authorRole'] != 'student') return;

    final studentUid = msgData['authorId'];
    final studentSnap = await FirebaseFirestore.instance.collectionGroup('students').where('uid', isEqualTo: studentUid).get();
    if (studentSnap.docs.isEmpty) return;
    final studentData = studentSnap.docs.first.data() as Map<String, dynamic>;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 35, backgroundColor: Colors.blue.withAlpha(30), child: const Icon(Icons.person, size: 40, color: Colors.blue)),
            const SizedBox(height: 15),
            Text(studentData['name'] ?? '', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("كود الطالب: ${studentData['id']}", style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            if ((studentData['phone'] ?? '').toString().isNotEmpty)
              _optionTile(Icons.chat_rounded, "مراسلة عبر واتساب", Colors.green, () {
                Navigator.pop(ctx);
                _ds.launchWhatsApp(studentData['phone']);
              }),
            _optionTile(Icons.forum_rounded, "فتح شات خاص", Colors.blue, () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => PrivateChatScreen(
                    otherUserId: studentUid,
                    otherUserName: studentData['name'] ?? 'الطالب',
                    otherUserRole: 'student',
                  ),
                ),
              );
            }),
            _optionTile(Icons.block, "حظر من هذا النقاش", Colors.red, () async {
              Navigator.pop(ctx);
              await _courseRef.update({
                'bannedUids': FieldValue.arrayUnion([studentUid])
              });
              _showError("تم حظر الطالب بنجاح");
            }),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: StreamBuilder<DocumentSnapshot>(
        stream: _courseRef.snapshots(),
        builder: (context, courseSnap) {
          final courseData = courseSnap.data?.data() as Map<String, dynamic>?;
          final bool isLocked = courseData?['forumLocked'] ?? false;

          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.courseName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(isLocked ? (isAr ? "النقاش مغلق" : "Locked") : (isAr ? "ساحة النقاش" : "Forum"), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
              foregroundColor: Colors.white,
              actions: [
                if (_ds.userRole == 'doctor') ...[
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const DoctorStudentsListScreen()),
                    ),
                    tooltip: isAr ? "قائمة الطلاب والواتساب" : "Students Chat",
                  ),
                  IconButton(
                    icon: const Icon(Icons.people_outline_rounded),
                    onPressed: _showBannedList,
                    tooltip: isAr ? "المحظورين" : "Banned List",
                  ),
                  IconButton(
                    icon: Icon(isLocked ? Icons.lock_outline : Icons.lock_open_rounded),
                    onPressed: () => _toggleChatLock(isLocked),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: _clearChat,
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.forum_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const StudentDoctorsListScreen()),
                    ),
                    tooltip: isAr ? "مراسلة المحاضرين (شات خاص)" : "Doctors Private Chat",
                  ),
                ]
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _courseRef.collection('forum').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return _buildEmptyState(isAr);

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(15),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final authorId = data['authorId']?.toString();
                          
                          String? myId;
                          if (_ds.userRole == 'student') {
                            myId = _ds.currentStudent?['uid']?.toString();
                          } else {
                            myId = _ds.currentDoctor?['uid']?.toString();
                          }
                          
                          bool isMe = (authorId != null && myId != null && authorId == myId);
                          bool isDoc = data['authorRole'] == 'doctor';

                          return GestureDetector(
                            onLongPress: () => _showStudentOptions(data),
                            child: _buildChat_Bubble(data, isMe, isDoc, isDark, primaryColor),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (isLocked && _ds.userRole == 'student')
                  _buildLockedNotice(isAr, isDark)
                else
                  _buildInputArea(isDark, primaryColor, isAr),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildLockedNotice(bool isAr, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.orange.withAlpha(20),
      child: Text(
        isAr ? "🔒 تم إغلاق النقاش حالياً بواسطة المحاضر" : "🔒 Discussion is locked by instructor",
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(color: Colors.orange, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.withAlpha(50)),
          const SizedBox(height: 15),
          Text(isAr ? 'كن أول من يبدأ النقاش!' : 'Start the discussion!', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChat_Bubble(Map<String, dynamic> data, bool isMe, bool isDoc, bool isDark, Color primaryColor) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? primaryColor : (isDoc ? Colors.orange.withAlpha(40) : (isDark ? const Color(0xFF1E1E1E) : Colors.white)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
          border: isDoc ? Border.all(color: Colors.orange.withAlpha(100), width: 1) : null,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              InkWell(
                onTap: () => _showStudentOptions(data),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['authorName'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 11, 
                        color: isDoc ? Colors.orange : (isDark ? Colors.white70 : Colors.black54),
                        decoration: !isDoc ? TextDecoration.underline : null
                      ),
                    ),
                    if (isDoc) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Colors.orange, size: 12),
                    ]
                  ],
                ),
              ),
            const SizedBox(height: 4),
            _buildMessageBody(data['content'] ?? '', isMe, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBody(String text, bool isMe, bool isDark) {
    final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
    if (!text.contains('http')) {
      return Text(text, style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87), fontSize: 14));
    }
    return SelectableText(text, style: TextStyle(color: isMe ? Colors.white : Colors.blue, decoration: isMe ? null : TextDecoration.underline), onTap: () async {
      final firstUrl = urlRegExp.firstMatch(text)?.group(0);
      if (firstUrl != null) {
        final uri = Uri.parse(firstUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    });
  }

  Widget _buildInputArea(bool isDark, Color color, bool isAr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(hintText: isAr ? "اكتب سؤالك..." : "Ask...", hintStyle: const TextStyle(fontSize: 13, color: Colors.grey), border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(backgroundColor: color, child: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage)),
        ],
      ),
    );
  }
}
