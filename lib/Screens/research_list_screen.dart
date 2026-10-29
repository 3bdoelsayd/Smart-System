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
    
    final Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final dynamic studentId = ds.currentStudent?['id'];

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(isAr ? 'أبحاثي والشيتات المرفوعة' : 'My Submissions'),
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
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['studentId'].toString() == studentId.toString();
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey.withAlpha(80)),
                        const SizedBox(height: 15),
                        Text(isAr ? 'لا توجد أبحاث أو شيتات مرفوعة' : 'No submissions found'),
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
                    
                    final String recipientStr = r['recipientName'] ?? (r['recipientType'] == 'ta' ? (isAr ? 'المعيد' : 'TA') : (isAr ? 'الدكتور' : 'Doctor'));

                    Color statusColor = status == 'Accepted' || status == 'Graded'
                        ? (isDark ? Colors.greenAccent : Colors.green) 
                        : (status == 'Rejected' ? (isDark ? Colors.redAccent : Colors.red) : primaryColor);

                    return Card(
                      color: surfaceColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isDark ? 0 : 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withAlpha(25),
                          child: Icon(Icons.cloud_done_rounded, color: primaryColor),
                        ),
                        title: Text(r['subject'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(r['fileName'] ?? '', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person_outline_rounded, size: 12, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${isAr ? 'إلى:' : 'To:'} $recipientStr",
                                        style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status == 'Accepted' || status == 'Graded' 
                                        ? (isAr ? 'تم التقييم' : 'Graded') 
                                        : (status == 'Rejected' ? (isAr ? 'مرفوض' : 'Rejected') : (isAr ? 'في انتظار المراجعة' : 'Pending')),
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          tooltip: isAr ? 'حذف الملف' : 'Delete file',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                backgroundColor: surfaceColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                title: Text(isAr ? 'حذف البحث / الشيت' : 'Delete File', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                                content: Text(isAr ? 'هل أنت متأكد من حذف هذا الملف؟' : 'Are you sure you want to delete this file?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx), 
                                    child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: primaryColor))
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogCtx);
                                      bool success = await ds.deleteResearch(docId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(success 
                                              ? (isAr ? 'تم حذف الملف بنجاح' : 'File deleted successfully')
                                              : (isAr ? 'فشل الحذف، تحقق من الاتصال' : 'Delete failed')),
                                            backgroundColor: success ? Colors.green : Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
