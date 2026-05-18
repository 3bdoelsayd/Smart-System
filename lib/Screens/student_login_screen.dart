import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DataService _ds = DataService();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAffairsContact() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _ds.isDarkMode ? const Color(0xFF1A1A1E) : Colors.white,
        title: Text(
          _ds.isArabic ? "شؤون الطلاب - معهد بلقاس" : "Student Affairs - Belqas Institute",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(_ds.affairsPhone, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_ds.isArabic ? "رقم الهاتف" : "Phone Number"),
              onTap: () => _ds.launchURL("tel:${_ds.affairsPhone}"),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.redAccent),
              title: Text(_ds.affairsEmail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(_ds.isArabic ? "البريد الإلكتروني" : "Email Address"),
              onTap: () => _ds.launchURL("mailto:${_ds.affairsEmail}"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_ds.isArabic ? "إغلاق" : "Close", style: GoogleFonts.cairo()),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        bool isAr = _ds.isArabic;
        bool isDark = _ds.isDarkMode;
        
        Color primaryColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF673AB7);
        final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
        final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white70 : Colors.grey.shade800;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: scaffoldBg,
            body: Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: isDark 
                        ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                        : [const Color(0xFF673AB7), const Color(0xFF512DA8)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                ),
                
                Positioned(top: -30, left: -30, child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withAlpha(isDark ? 5 : 26))),
                Positioned(top: 100, right: -40, child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withAlpha(isDark ? 5 : 13))),

                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Hero(
                            tag: 'student_icon',
                            child: Icon(Icons.school_rounded, size: 60, color: isDark ? const Color(0xFF121212) : primaryColor),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          isAr ? 'بوابة الطلاب' : 'Student Portal',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                        ),
                        const SizedBox(height: 40),
                        
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 25),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(isDark ? 100 : 20), blurRadius: 30, offset: const Offset(0, 15))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'تسجيل الدخول' : 'Sign In',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 30),
                              _buildTextField(_idController, isAr ? 'كود الطالب' : 'Student ID', Icons.badge_outlined, primaryColor, isDark),
                              const SizedBox(height: 20),
                              _buildTextField(_passwordController, isAr ? 'كلمة المرور' : 'Password', Icons.lock_person_outlined, primaryColor, isDark, isPass: true),
                              const SizedBox(height: 40),
                              _buildLoginButton(primaryColor, isAr, isDark),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: _showAffairsContact,
                          child: Text(
                            isAr ? 'نسيت كلمة المرور؟ تواصل مع شؤون الطلاب' : 'Forgot Password? Contact Student Affairs',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, Color color, bool isDark, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass && !_showPassword,
      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: color.withAlpha(179)),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: isDark ? Colors.white24 : Colors.grey.shade400),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ) : null,
        filled: true,
        fillColor: isDark ? Colors.black.withAlpha(50) : Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: color, width: 1.5)),
      ),
    );
  }

  Widget _buildLoginButton(Color color, bool isAr, bool isDark) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [color, color.withAlpha(217)]),
        boxShadow: [
          BoxShadow(color: color.withAlpha(isDark ? 40 : 77), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: _isLoading ? null : () async {
          _ds.playClickSound();
          String studentId = _idController.text.trim();
          String password = _passwordController.text.trim();

          if (studentId.isEmpty || password.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'يرجى ملء كافة الحقول' : 'Please fill all fields')));
            return;
          }

          setState(() => _isLoading = true);

          String email = "$studentId@smart.edu";

          bool success = await _ds.loginStudent(email, password);
          if (mounted) {
            setState(() => _isLoading = false);
            if (success) {
              Navigator.pushNamedAndRemoveUntil(context, '/student/home', (r) => false);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'بيانات الدخول غير صحيحة' : 'Invalid Credentials')));
            }
          }
        },
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : Text(isAr ? 'دخول للمنصة' : 'Enter Platform', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
