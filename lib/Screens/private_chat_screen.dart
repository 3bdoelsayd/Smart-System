import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';

class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DataService _ds = DataService();
  bool _isSending = false;

  String get _currentUserId {
    if (_ds.userRole == 'student') {
      return _ds.currentStudent?['uid'] ?? _ds.currentStudent?['id'] ?? '';
    } else {
      return _ds.currentDoctor?['uid'] ?? _ds.currentDoctor?['id'] ?? '';
    }
  }

  String get _currentUserName {
    if (_ds.userRole == 'student') {
      return _ds.currentStudent?['name'] ?? 'طالب';
    } else {
      return _ds.currentDoctor?['name'] ?? 'دكتور';
    }
  }

  String get _chatId {
    List<String> ids = [_currentUserId, widget.otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  DocumentReference get _chatRef => FirebaseFirestore.instance
      .collection('colleges')
      .doc(_ds.selectedInstituteId ?? 'commerce')
      .collection('private_chats')
      .doc(_chatId);

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    setState(() => _isSending = true);

    try {
      await _chatRef.collection('messages').add({
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'receiverId': widget.otherUserId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat meta
      await _chatRef.set({
        'lastMessage': content,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participants': [_currentUserId, widget.otherUserId],
        'participantNames': {_currentUserId: _currentUserName, widget.otherUserId: widget.otherUserName},
      }, SetOptions(merge: true));

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint("Send message error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : 'U', style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.otherUserRole == 'student' ? (isAr ? 'طالب' : 'Student') : (isAr ? 'عضو هيئة تدريس' : 'Doctor'), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatRef.collection('messages').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        isAr ? 'لا توجد رسائل سابقة. ابدأ المحادثة الآن!' : 'No messages yet. Start conversation!',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == _currentUserId;
                      final content = data['content'] ?? '';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe 
                              ? primaryColor 
                              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(18),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 10), blurRadius: 5, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            content,
                            style: TextStyle(
                              color: isMe 
                                ? (isDark ? Colors.black : Colors.white) 
                                : (isDark ? Colors.white : Colors.black87),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 10), blurRadius: 10, offset: const Offset(0, -3))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: isAr ? 'اكتب رسالتك هنا...' : 'Type your message...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
