import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';

class CollegeSelectionScreen extends StatefulWidget {
  const CollegeSelectionScreen({super.key});

  @override
  State<CollegeSelectionScreen> createState() => _CollegeSelectionScreenState();
}

class _CollegeSelectionScreenState extends State<CollegeSelectionScreen> {
  final DataService _ds = DataService();

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF0F2F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'اختر الكلية / المعهد' : 'Select College / Institute',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1A1A1E) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
        ),
        body: Container(
          decoration: !isDark ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade100],
            ),
          ) : null,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF673AB7)));
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 80, color: Colors.grey.withAlpha(100)),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'لا توجد كليات متاحة حالياً' : 'No colleges available',
                        style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr ? 'يرجى إضافة الكليات من لوحة التحكم' : 'Please add colleges from Firebase Console',
                        style: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              var colleges = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                itemCount: colleges.length,
                itemBuilder: (context, index) {
                  var college = colleges[index].data() as Map<String, dynamic>;
                  String id = colleges[index].id;
                  String name = isAr ? (college['nameAr'] ?? id) : (college['nameEn'] ?? id);
                  String? logo = college['logoUrl'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1E) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 40 : 10),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await _ds.setInstitute(id);
                          if (mounted) Navigator.pushNamed(context, '/login');
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF673AB7).withAlpha(15),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: logo != null && logo.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.network(logo, fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.account_balance_rounded, color: Color(0xFF673AB7), size: 28),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.cairo(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF2D3142),
                                      ),
                                    ),
                                    Text(
                                      isAr ? 'اضغط للدخول للخدمات' : 'Tap to enter services',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isAr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
