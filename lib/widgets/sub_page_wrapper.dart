import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const SubPageWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        iconTheme: const IconThemeData(color: Color(0xFF673AB7)), // Changed back button color to purple
        centerTitle: true,
      ),
      body: child
    );
  }
}
