import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';

class PasswordManagementScreen extends StatefulWidget {
  const PasswordManagementScreen({super.key});

  @override
  State<PasswordManagementScreen> createState() => _PasswordManagementScreenState();
}

class _PasswordManagementScreenState extends State<PasswordManagementScreen> {
  final DataService _ds = DataService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _searchQuery = "";
  bool _isStudents = true;

  @override
  void dispose() {
    _searchController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    Color color = isDark ? const Color(0xFF03DAC6) : const Color(0xFFE91E63);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(isAr ? 'إدارة كلمات المرور' : 'Password Management'),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Expanded(
                    child: _tabButton(isAr ? 'الطلاب' : 'Students', _isStudents, () => setState(() => _isStudents = true), color, isDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tabButton(isAr ? 'الدكاترة' : 'Doctors', !_isStudents, () => setState(() => _isStudents = false), color, isDark),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: isAr ? 'ابحث بالاسم أو الكود...' : 'Search by name or ID...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: (_isStudents ? _ds.studentsColl : _ds.doctorsColl).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var users = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    String name = (data['name'] ?? '').toString().toLowerCase();
                    String id = (data['id'] ?? '').toString().toLowerCase();
                    String q = _searchQuery.toLowerCase();
                    return q.isEmpty || name.contains(q) || id.contains(q);
                  }).toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (ctx, i) {
                      final user = users[i].data() as Map<String, dynamic>;
                      final docId = users[i].id;
                      final userId = user['id'] ?? 'N/A';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withAlpha(20),
                            child: Icon(_isStudents ? Icons.school : Icons.psychology, color: color),
                          ),
                          title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("ID: $userId"),
                          trailing: IconButton(
                            icon: const Icon(Icons.lock_reset, color: Colors.orange),
                            onPressed: () => _showChangePasswordDialog(docId, user['name'], userId),
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

  Widget _tabButton(String text, bool active, VoidCallback onTap, Color color, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : Colors.transparent),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(String docId, String name, String userId) {
    _passwordController.clear();
    bool isAr = _ds.isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تغيير كلمة المرور' : 'Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${isAr ? 'المستخدم:' : 'User:'} $name", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: isAr ? 'كلمة المرور الجديدة' : 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_ds.translate('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (_passwordController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'كلمة المرور قصيرة جداً' : 'Password too short')));
                return;
              }
              await _ds.changeUserPassword(docId, _passwordController.text, _isStudents);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully')));
            },
            child: Text(isAr ? 'تغيير' : 'Change'),
          ),
        ],
      ),
    );
  }
}
