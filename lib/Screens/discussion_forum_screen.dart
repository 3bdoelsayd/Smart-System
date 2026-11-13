import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/data_service.dart';
import '../widgets/doctor_profile_modal.dart';
import '../widgets/student_profile_modal.dart';
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
  DocumentReference get _courseRef => _ds.instituteRef
      .collection('levels')
      .doc(widget.levelId)
      .collection('courses')
      .doc(widget.courseId);

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    Map<String, dynamic>? user;
    if (_ds.userRole == 'student') {
      user = _ds.currentStudent;
    } else if (_ds.userRole == 'doctor' || _ds.userRole == 'ta') {
      user = _ds.currentDoctor;
    } else if (_ds.userRole == 'manager' || _ds.userRole == 'super_admin') {
      user = _ds.currentAdmin;
    }

    if (user == null) {
      _showError("تعذر العثور على بيانات الحساب المودعة للإرسال");
      return;
    }

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
        if (banned.contains(user['uid'] ?? user['id'])) {
          _showError("تم حظرك من المشاركة في هذا النقاش");
          return;
        }
      }

      final content = _messageController.text.trim();
      _messageController.clear();

      await _courseRef.collection('forum').add({
        'authorId': user['uid'] ?? user['id'] ?? 'user',
        'authorName': user['name'] ?? 'مستخدم',
        'authorRole': _ds.userRole,
        'photoUrl': user['photoUrl'] ?? '',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      _showError("فشل إرسال الرسالة: $e");
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
                          onTap: () {
                            showRichStudentProfileModal(
                              context: context,
                              studentIdOrUid: bannedUids[i],
                              studentName: sData['name'],
                              initialStudentData: sData,
                            );
                          },
                          leading: CircleAvatar(
                            backgroundImage: _ds.getAvatarImageProvider(sData['photoUrl']),
                            child: (sData['photoUrl'] ?? '').toString().isEmpty ? const Icon(Icons.person) : null,
                          ),
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

  void _showReportDialog(Map<String, dynamic> msgData, String msgDocId) {
    final reasonController = TextEditingController();
    bool isAr = _ds.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.flag_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAr ? "الإبلاغ عن رسالة مخالفة" : "Report Offensive Message",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msgData['authorName'] ?? (isAr ? 'مستخدم' : 'User'),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msgData['content'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: isAr ? "سبب الإبلاغ (اختياري)" : "Reason (Optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? "إلغاء" : "Cancel", style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                String myName = "مستخدم";
                String myUid = "user";
                if (_ds.userRole == 'student') {
                  myName = _ds.currentStudent?['name']?.toString() ?? 'طالب';
                  myUid = _ds.currentStudent?['uid']?.toString() ?? _ds.currentStudent?['id']?.toString() ?? 'student';
                } else if (_ds.userRole == 'doctor' || _ds.userRole == 'ta') {
                  myName = _ds.currentDoctor?['name']?.toString() ?? 'دكتور';
                  myUid = _ds.currentDoctor?['uid']?.toString() ?? _ds.currentDoctor?['id']?.toString() ?? 'doctor';
                } else {
                  myName = _ds.currentAdmin?['name']?.toString() ?? 'مدير';
                  myUid = _ds.currentAdmin?['uid']?.toString() ?? 'admin';
                }

                await _ds.reportForumMessage(
                  collegeId: _ds.selectedInstituteId ?? 'commerce',
                  levelId: widget.levelId,
                  courseId: widget.courseId,
                  courseName: widget.courseName,
                  messageDocId: msgDocId,
                  messageContent: msgData['content'] ?? '',
                  authorId: msgData['authorId'] ?? '',
                  authorName: msgData['authorName'] ?? '',
                  authorRole: msgData['authorRole'] ?? 'student',
                  reporterId: myUid,
                  reporterName: myName,
                  reporterRole: _ds.userRole ?? 'student',
                  reason: reasonController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? "تم إرسال الإبلاغ لمدير الفرقة بنجاح 🚩" : "Report sent to manager 🚩"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(isAr ? "إرسال الإبلاغ" : "Send Report", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> msgData, String msgDocId, bool isMe) {
    bool isAr = _ds.isArabic;

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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            Text(
              msgData['authorName'] ?? '',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              msgData['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 25),
            if (!isMe)
              _optionTile(Icons.flag_rounded, isAr ? "الإبلاغ عن هذه الرسالة لمدير الفرقة" : "Report to Level Manager", Colors.redAccent, () {
                Navigator.pop(ctx);
                _showReportDialog(msgData, msgDocId);
              }),
            if (_ds.userRole == 'doctor' && msgData['authorRole'] == 'student') ...[
              _optionTile(Icons.block, isAr ? "حظر الطالب من النقاش" : "Block Student", Colors.orange, () async {
                Navigator.pop(ctx);
                await _courseRef.update({
                  'bannedUids': FieldValue.arrayUnion([msgData['authorId']])
                });
                _showError("تم حظر الطالب بنجاح");
              }),
            ],
            if (isMe || _ds.userRole == 'doctor' || _ds.userRole == 'manager' || _ds.userRole == 'super_admin')
              _optionTile(Icons.delete_outline_rounded, isAr ? "حذف الرسالة" : "Delete Message", Colors.red, () async {
                Navigator.pop(ctx);
                try {
                  await _courseRef.collection('forum').doc(msgDocId).delete();
                  _showError(isAr ? "تم حذف الرسالة" : "Message deleted");
                } catch (e) {
                  _showError("Error: $e");
                }
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
                if (_ds.userRole != 'student') ...[
                  if (_ds.userRole == 'doctor' || _ds.userRole == 'ta')
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
                            myId = _ds.currentStudent?['uid']?.toString() ?? _ds.currentStudent?['id']?.toString();
                          } else if (_ds.userRole == 'doctor' || _ds.userRole == 'ta') {
                            myId = _ds.currentDoctor?['uid']?.toString() ?? _ds.currentDoctor?['id']?.toString();
                          } else {
                            myId = _ds.currentAdmin?['uid']?.toString() ?? _ds.currentAdmin?['id']?.toString();
                          }
                          
                          bool isMe = (authorId != null && myId != null && authorId == myId);
                          String role = data['authorRole']?.toString() ?? 'student';

                          return GestureDetector(
                            onLongPress: () => _showMessageOptions(data, docs[index].id, isMe),
                            child: _buildChat_Bubble(data, isMe, role, isDark, primaryColor),
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

  Widget _buildChat_Bubble(Map<String, dynamic> data, bool isMe, String role, bool isDark, Color primaryColor) {
    bool isDoc = role == 'doctor';
    bool isTa = role == 'ta';
    bool isManager = role == 'manager' || role == 'super_admin';
    bool isStaff = isDoc || isTa || isManager;

    Color bubbleColor = isMe 
        ? primaryColor 
        : (isDoc ? Colors.orange.withAlpha(40) : (isTa ? Colors.teal.withAlpha(40) : (isManager ? Colors.indigo.withAlpha(40) : (isDark ? const Color(0xFF1E1E1E) : Colors.white))));

    String roleTitle = isDoc ? 'دكتور' : (isTa ? 'معيد' : (isManager ? 'مدير الفرقة' : ''));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
          border: isStaff ? Border.all(color: isDoc ? Colors.orange.withAlpha(100) : (isTa ? Colors.teal.withAlpha(100) : Colors.indigo.withAlpha(100)), width: 1) : null,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              InkWell(
                onTap: () {
                  if (isStaff) {
                    showRichDoctorProfileModal(
                      context: context,
                      doctorUidOrEmail: data['authorId'] ?? '',
                      doctorName: data['authorName'],
                    );
                  } else {
                    if (_ds.userRole != 'student') {
                      _showMessageOptions(data, '', isMe);
                    } else {
                      showRichStudentProfileModal(
                        context: context,
                        studentIdOrUid: data['authorId'] ?? '',
                        studentName: data['authorName'],
                      );
                    }
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: _ds.getAvatarImageProvider(data['photoUrl']),
                      child: (data['photoUrl'] ?? '').toString().isEmpty ? const Icon(Icons.person, size: 12) : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data['authorName'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 11, 
                        color: isDoc ? Colors.orange : (isTa ? Colors.teal : (isManager ? Colors.indigo : (isDark ? Colors.white70 : Colors.black54))),
                      ),
                    ),
                    if (isStaff) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDoc ? Colors.orange.withAlpha(30) : (isTa ? Colors.teal.withAlpha(30) : Colors.indigo.withAlpha(30)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roleTitle,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDoc ? Colors.orange : (isTa ? Colors.teal : Colors.indigo)),
                        ),
                      ),
                    ],
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
