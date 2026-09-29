import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_service.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _ds = DataService();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _rememberMe = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedUser = prefs.getString('saved_login_user');
      String? savedPass = prefs.getString('saved_login_pass');
      bool remember = prefs.getBool('saved_remember_me') ?? true;
      if (remember && savedUser != null && savedPass != null) {
        if (mounted) {
          setState(() {
            _emailController.text = savedUser;
            _passController.text = savedPass;
            _rememberMe = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showSnackBar(_ds.isArabic ? 'يرجى إدخال جميع البيانات' : 'Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      TextInput.finishAutofillContext(); // إشعار المتصفح لحفظ الكود والباسورد
      String? role = await _ds.unifiedLogin(_emailController.text.trim(), _passController.text.trim());
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_login_user', _emailController.text.trim());
        await prefs.setString('saved_login_pass', _passController.text.trim());
        await prefs.setBool('saved_remember_me', true);
      } else {
        await prefs.remove('saved_login_user');
        await prefs.remove('saved_login_pass');
        await prefs.setBool('saved_remember_me', false);
      }

      switch (role) {
        case 'super_admin': Navigator.pushReplacementNamed(context, '/super-admin/dashboard'); break;
        case 'manager': Navigator.pushReplacementNamed(context, '/manager/dashboard'); break;
        case 'doctor': Navigator.pushReplacementNamed(context, '/doctor/home'); break;
        case 'student': Navigator.pushReplacementNamed(context, '/student/home'); break;
        default: _showSnackBar(_ds.isArabic ? 'لم يتم العثور على المستخدم' : 'User not found', isError: true);
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(height: 1.2)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF673AB7),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAffairsContact() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _ds.isDarkMode ? const Color(0xFF1A1A1E) : Colors.white,
        title: Text(
          _ds.isArabic ? "شؤون الطلاب - معهد بلقاس" : "Student Affairs - Belqas",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.phone, color: Colors.green),
              label: Text(_ds.affairsPhone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => _ds.launchURL("tel:${_ds.affairsPhone}"),
            ),
            const Divider(),
            TextButton.icon(
              icon: const Icon(Icons.email, color: Colors.redAccent),
              label: Text(_ds.affairsEmail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              onPressed: () => _ds.launchURL("mailto:${_ds.affairsEmail}"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_ds.isArabic ? "إغلاق" : "Close", style: GoogleFonts.cairo()))
        ],
      ),
    );
  }

  void _showDevContact() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _ds.isDarkMode ? const Color(0xFF1A1A1E) : Colors.white,
        title: Text(
          _ds.isArabic ? "تواصل مع المطور" : "Developer Contact",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.phone_android, color: Colors.green),
              label: Text(_ds.devPhone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => _ds.launchURL("tel:${_ds.devPhone}"),
            ),
            const Divider(),
            TextButton.icon(
              icon: const Icon(Icons.facebook, color: Colors.blue),
              label: Text(_ds.isArabic ? "فيسبوك" : "Facebook", style: const TextStyle(fontSize: 16)),
              onPressed: () => _ds.launchURL(_ds.devAccountUrl),
            ),
          ],
        ),
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
        Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8F9FE),
            body: Stack(
              children: [
                _buildBackground(primaryColor, isDark),

                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            children: [
                              _buildHeader(primaryColor, isDark),
                              const SizedBox(height: 40),
                              _buildLoginCard(isDark, isAr, primaryColor),
                              const SizedBox(height: 30),
                              GestureDetector(
                                onTap: _showAffairsContact,
                                child: Text(
                                  isAr ? "مشكلة في الدخول؟ تواصل مع شؤون الطلاب" : "Login issue? Contact Student Affairs",
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: isDark ? Colors.white38 : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              _buildDevSignature(isDark, isAr),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(Color color, bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -100, right: -50,
          child: CircleAvatar(radius: 150, backgroundColor: color.withAlpha(isDark ? 10 : 15)),
        ),
        Positioned(
          bottom: -50, left: -50,
          child: CircleAvatar(radius: 100, backgroundColor: color.withAlpha(isDark ? 8 : 12)),
        ),
      ],
    );
  }

  Widget _buildHeader(Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(5) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 5), blurRadius: 20)
            ],
          ),
          child: Icon(Icons.school_rounded, size: 65, color: color),
        ),
        const SizedBox(height: 20),
        Text(
          _ds.translate('app_title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 26, fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF2D3142),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isDark, bool isAr, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 100 : 10),
              blurRadius: 40, offset: const Offset(0, 15)
          )
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? "تسجيل الدخول" : "Login",
              style: GoogleFonts.cairo(
                fontSize: 22, fontWeight: FontWeight.bold,
                height: 1.6,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 25),
            _buildTextField(
                controller: _emailController,
                hint: isAr ? "البريد الإلكتروني" : "Email",
                icon: Icons.alternate_email_rounded,
                isDark: isDark, color: color,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 18),
            _buildTextField(
                controller: _passController,
                hint: isAr ? "كلمة المرور" : "Password",
                icon: Icons.lock_outline_rounded,
                isDark: isDark, color: color,
                isPass: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Text(
                    isAr ? "تذكرني (حفظ بيانات الدخول)" : "Remember Me",
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildLoginButton(color, isDark, isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color color,
    bool isPass = false,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withAlpha(40) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass && _obscureText,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: GoogleFonts.cairo(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color.withAlpha(180), size: 20),
          suffixIcon: isPass ? IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.grey),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ) : null,
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14, height: 1.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton(Color color, bool isDark, bool isAr) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isAr ? "دخول" : "Sign In", style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold, height: 1.2)),
      ),
    );
  }

  Widget _buildDevSignature(bool isDark, bool isAr) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showDevContact,
          child: Text(
            "FROM BY A.SHERBINY",
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(width: 20, height: 1, color: Colors.grey.withAlpha(50)),
      ],
    );
  }
}
