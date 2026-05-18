import 'package:flutter/material.dart';
import '../services/data_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final DataService _ds = DataService();

  void _showDevContact() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _ds.isDarkMode ? const Color(0xFF1A1A1E) : Colors.white,
        title: Text(
          _ds.isArabic ? "تواصل مع المطور" : "Developer Contact",
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
        
        List<Color> bgGradient = isDark
            ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
            : [const Color(0xFF673AB7), const Color(0xFF512DA8)];

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            body: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: bgGradient,
                    ),
                  ),
                ),

                Positioned(top: -50, left: -50, child: _buildOrb(Colors.white.withAlpha(isDark ? 10 : 26), 200)),
                Positioned(bottom: -100, right: -50, child: _buildOrb(Colors.white.withAlpha(isDark ? 10 : 26), 300)),

                Positioned(
                  top: 50,
                  right: 20,
                  left: 20,
                  child: Row(
                    mainAxisAlignment: isAr ? MainAxisAlignment.start : MainAxisAlignment.end,
                    children: [
                      _buildHeaderButton(
                        onTap: () => _ds.toggleLanguage(!isAr),
                        icon: Icons.language_rounded,
                        label: isAr ? "English" : "عربي",
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: isDark ? Colors.black54 : Colors.black.withAlpha(26), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            size: 80,
                            color: isDark ? const Color(0xFF121212) : const Color(0xFF673AB7)
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _ds.translate('app_name'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isAr ? 'منصة متكاملة للحضور والأبحاث العلمية' : 'Integrated Platform for Attendance & Research',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.white.withAlpha(200)),
                        ),
                        const SizedBox(height: 50),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              _ds.playClickSound();
                              Navigator.pushNamed(context, '/college-selection');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 5,
                            ),
                            child: Text(
                              isAr ? 'ابدأ الآن' : 'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF121212) : const Color(0xFF673AB7),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),
                        
                        InkWell(
                          onTap: _showDevContact,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _ds.translate('developed_by'),
                                  style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAr ? _ds.companyNameAr : _ds.companyNameEn,
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
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
      },
    );
  }

  Widget _buildHeaderButton({required VoidCallback onTap, required IconData icon, required String label, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(isDark ? 20 : 40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb(Color color, double size) {
    return Container(height: size, width: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}
