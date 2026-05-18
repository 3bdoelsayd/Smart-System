import 'package:flutter/material.dart';
import 'dart:async';
import '../services/data_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final DataService _ds = DataService();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    String? type = await _ds.loadSession();
    
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        if (type == 'student') {
          Navigator.pushReplacementNamed(context, '/student/home');
        } else if (type == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor/home');
        } else if (type == 'super_admin') {
          Navigator.pushReplacementNamed(context, '/super-admin/dashboard');
        } else if (type == 'manager') {
          Navigator.pushReplacementNamed(context, '/manager/dashboard');
        } else if (type == 'admin') {
          // للتوافق مع الإصدارات القديمة إذا وجد
          Navigator.pushReplacementNamed(context, '/admin/home');
        } else {
          Navigator.pushReplacementNamed(context, '/start');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        bool isAr = _ds.isArabic;
        bool isDark = _ds.isDarkMode;
        Color primaryColor = const Color(0xFF673AB7);
        Color accentColor = isDark ? const Color(0xFF03DAC6) : primaryColor;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
          body: Stack(
            children: [
              // دوائر زينة خلفية هادئة
              Positioned(
                top: -50, left: -50,
                child: _buildBackgroundOrb(accentColor.withAlpha(isDark ? 20 : 30), 250),
              ),
              Positioned(
                bottom: -80, right: -50,
                child: _buildBackgroundOrb(accentColor.withAlpha(isDark ? 15 : 20), 300),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // دائرة الأيقونة بتصميم ناعم وهادئ
                            Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    // توهج ناعم جداً ومنتشر
                                    color: accentColor.withAlpha(isDark ? 45 : 30),
                                    blurRadius: isDark ? 60 : 30,
                                    spreadRadius: isDark ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.school_rounded, 
                                size: 80, 
                                color: isDark ? Colors.white : primaryColor
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              _ds.translate('app_title'),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(isDark ? 30 : 26),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAr ? 'مستقبلك يبدأ من هنا' : 'Your future starts here',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? accentColor.withAlpha(200) : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                    // شريط تحميل أنيق
                    SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: accentColor.withAlpha(26),
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      isAr ? 'المطور عبده الشربيني' : 'Developed by Abdo Elsherbiny',
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.grey.shade400, 
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        letterSpacing: 1.2
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundOrb(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
      ),
    );
  }
}
