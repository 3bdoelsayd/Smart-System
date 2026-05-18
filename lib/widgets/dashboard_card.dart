import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? count;
  final String? countLabel;
  final VoidCallback onTap;
  final Color color;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
    this.count,
    this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withOpacity(0.1),
            child: Stack(
              children: [
                // Glow Effect
                PositionedDirectional(
                  top: -20,
                  start: -20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [color.withOpacity(0.12), color.withOpacity(0)],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          icon,
                          color: isDark ? Colors.white.withOpacity(0.95) : color,
                          size: 28,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      
                      if (count != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          count!,
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: color,
                            height: 1,
                          ),
                        ),
                        if (countLabel != null)
                          Text(
                            countLabel!,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                
                // Small Decorative Icon
                PositionedDirectional(
                  bottom: 12,
                  end: 12,
                  child: Icon(
                    icon,
                    size: 14,
                    color: color.withOpacity(0.25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
