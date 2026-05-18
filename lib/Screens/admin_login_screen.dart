import 'package:flutter/material.dart';
import '../services/data_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
        
        // الألوان الخاصة بالأدمن: الوردي للوضع العادي والفيروزي للوضع الليلي ليتوافق مع التصميم
        Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFFE91E63);
        final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
        final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

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
                        : [const Color(0xFFE91E63), const Color(0xFFC2185B)],
                    ),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
                  ),
                ),
                
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Icon(Icons.admin_panel_settings_rounded, size: 60, color: primaryColor),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          isAr ? 'شؤون الطلاب' : 'Student Affairs',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                        ),
                        const SizedBox(height: 40),
                        
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 25),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 100 : 20), blurRadius: 30, offset: const Offset(0, 15))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isAr ? 'تسجيل دخول الإدارة' : 'Admin Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800)),
                              const SizedBox(height: 30),
                              _buildTextField(_idController, isAr ? 'كود الموظف' : 'Admin ID', Icons.badge_outlined, primaryColor, isDark),
                              const SizedBox(height: 20),
                              _buildTextField(_passwordController, isAr ? 'كلمة المرور' : 'Password', Icons.lock_person_outlined, primaryColor, isDark, isPass: true),
                              const SizedBox(height: 40),
                              _buildLoginButton(primaryColor, isAr, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context))),
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
        prefixIcon: Icon(icon, color: color),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400),
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
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isDark ? Colors.black : Colors.white, // النص أسود في الوضع الليلي على زرار فيروزي
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
        ),
        onPressed: _isLoading ? null : () async {
          _ds.playClickSound();
          if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'يرجى ملء كافة الحقول' : 'Please fill all fields')));
            return;
          }
          setState(() => _isLoading = true);
          bool success = await _ds.loginAdmin(_idController.text, _passwordController.text);
          if (mounted) {
            setState(() => _isLoading = false);
            if (success) {
              Navigator.pushNamedAndRemoveUntil(context, '/admin/home', (r) => false);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'بيانات الدخول غير صحيحة' : 'Invalid Admin Credentials')));
            }
          }
        },
        child: _isLoading 
          ? CircularProgressIndicator(color: isDark ? Colors.black : Colors.white)
          : Text(isAr ? 'دخول النظام' : 'Login System', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
