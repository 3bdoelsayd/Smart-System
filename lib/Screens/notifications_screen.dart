import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;
    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

    // نوع المستخدم الحالي (طالب أو دكتور)
    final String userType = (ModalRoute.of(context)?.settings.arguments as String?) ?? 'all';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          title: Text(isAr ? 'الإشعارات' : 'Notifications', style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // زر لمسح كل الإشعارات
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => ds.clearAllNotifications(userType),
              tooltip: isAr ? 'مسح الكل' : 'Clear All',
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('notifications')
              .where('targetType', isEqualTo: userType)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey.withAlpha(50)),
                    const SizedBox(height: 15),
                    Text(
                      isAr ? 'لا توجد إشعارات حالياً' : 'No notifications yet',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.notifications_active_rounded, color: primaryColor, size: 20),
                    ),
                    title: Text(
                      data['title'] ?? (isAr ? 'تنبيه' : 'Alert'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    subtitle: Text(
                      data['body'] ?? '',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close, size: 18, color: isDark ? Colors.white24 : Colors.grey),
                      onPressed: () => doc.reference.delete(), // حذف إشعار واحد
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
