import 'package:flutter/material.dart';
import '../services/data_service.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        bool isAr = _ds.isArabic;
        bool isDark = _ds.isDarkMode;
        Color primaryColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF2196F3);
        final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
        final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: scaffoldBg,
            body: Stack(
              children: [
                // Header Gradient
                Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: isDark 
                        ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                        : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
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
                        // Icon Container
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
                            tag: 'doctor_icon',
                            child: Icon(Icons.psychology_rounded, size: 60, color: isDark ? const Color(0xFF121212) : primaryColor),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          isAr ? 'بوابة المحاضرين' : 'Staff Portal',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                        ),
                        const SizedBox(height: 40),

                        // Login Card
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
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800),
                              ),
                              const SizedBox(height: 30),
                              _buildTextField(_idController, isAr ? 'الكود الأكاديمي' : 'Staff ID', Icons.account_circle_outlined, primaryColor, isDark),
                              const SizedBox(height: 20),
                              _buildTextField(_passwordController, isAr ? 'كلمة المرور' : 'Password', Icons.lock_person_outlined, primaryColor, isDark, isPass: true),
                              const SizedBox(height: 40),
                              _buildLoginButton(primaryColor, isAr, isDark),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                        Text(
                          isAr ? 'هل تواجه مشكلة؟ تواصل مع الدعم التقني' : 'Having trouble? Contact IT Support',
                          style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500),
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
          if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'يرجى ملء كافة الحقول' : 'Please fill all fields')));
            return;
          }
          setState(() => _isLoading = true);
          bool success = await _ds.loginDoctor(_idController.text, _passwordController.text);
          if (mounted) {
            setState(() => _isLoading = false);
            if (success) {
              Navigator.pushReplacementNamed(context, '/doctor/home');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'بيانات الدخول غير صحيحة' : 'Invalid Credentials')));
            }
          }
        },
        child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(isAr ? 'دخول للبوابة' : 'Enter Portal', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
