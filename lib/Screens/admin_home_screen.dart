import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/app_drawer.dart';
import '../services/data_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    
    return ListenableBuilder(
      listenable: ds,
      builder: (context, _) {
        bool isAr = ds.isArabic;
        bool isDark = ds.isDarkMode;
        
        final primaryColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE91E63);
        final adminName = ds.currentAdmin?['name'] ?? ds.translate('welcome');

        final List<Map<String, dynamic>> cards = [
          {'icon': Icons.manage_accounts_rounded, 'title': ds.translate('manage_passwords'), 'route': '/admin/password-management', 'color': Colors.blue},
          {'icon': Icons.cloud_upload_rounded, 'title': ds.translate('upload_results_bulk'), 'route': '/admin/bulk-upload', 'color': Colors.green},
          {'icon': Icons.settings_rounded, 'title': ds.translate('settings'), 'route': '/settings', 'color': Colors.purple},
        ];

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
            drawer: AppDrawer(
              name: adminName,
              role: isAr ? 'مسؤول شؤون الطلاب' : 'Student Affairs Admin',
            ),
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [primaryColor, primaryColor.withAlpha(204)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),
                            // No notifications for admin for now
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(ds.translate('welcome'), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        Text(adminName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      mainAxisExtent: 160,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => DashboardCard(
                        icon: cards[i]['icon'] as IconData,
                        title: cards[i]['title'] as String,
                        color: cards[i]['color'] as Color,
                        onTap: () => Navigator.pushNamed(context, cards[i]['route'] as String),
                      ),
                      childCount: cards.length,
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
}
