import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';

class ResearchListScreen extends StatelessWidget {
  const ResearchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    bool isAr = ds.isArabic;
    bool isDark = ds.isDarkMode;
    
    // الألوان الجديدة للوضع الداكن (رمادي غامق وفيروزي)
    final Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final dynamic studentId = ds.currentStudent?['id'];

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(isAr ? 'أبحاثي المرفوعة' : 'My Submissions'),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: studentId == null
          ? Center(child: Text(isAr ? 'يرجى تسجيل الدخول' : 'Please login'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('submissions').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                final allDocs = snapshot.data?.docs ?? [];
                // تصفية الأبحاث للطالب الحالي
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['studentId'].toString() == studentId.toString();
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 15),
                        Text(isAr ? 'لا توجد أبحاث مرفوعة لهذا الحساب' : 'No submissions found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final String docId = docs[i].id;
                    final r = docs[i].data() as Map<String, dynamic>;
                    String status = r['status'] ?? 'Submitted';
                    
                    // تحسين ألوان الحالة للوضع الداكن
                    Color statusColor = status == 'Accepted'
                        ? (isDark ? Colors.greenAccent : Colors.green) 
                        : (status == 'Rejected' ? (isDark ? Colors.redAccent : Colors.red) : primaryColor);

                    return Card(
                      color: surfaceColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isDark ? 0 : 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: Icon(Icons.cloud_done_rounded, color: primaryColor),
                        ),
                        title: Text(r['subject'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['fileName'] ?? '', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                            const SizedBox(height: 4),
                            Text(
                              status == 'Accepted' ? (isAr ? 'مقبول' : 'Accepted') : (status == 'Rejected' ? (isAr ? 'مرفوض' : 'Rejected') : (isAr ? 'تم الرفع' : 'Sent')),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: surfaceColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                title: Text(isAr ? 'حذف البحث' : 'Delete Research', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                                content: Text(isAr ? 'هل أنت متأكد من حذف هذا البحث؟' : 'Are you sure?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: primaryColor))),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      bool success = await ds.deleteResearch(docId);
                                      if (!success && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(isAr ? 'فشل الحذف، تحقق من الاتصال' : 'Delete failed')),
                                        );
                                      }
                                    },
                                    child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
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
