import 'package:flutter/material.dart';
import '../services/data_service.dart';

/// A memory-optimized avatar widget that resizes network images to avatar size
/// to save RAM when rendering long lists.
class CachedAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final int cacheWidth;
  final int cacheHeight;

  const CachedAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.cacheWidth = 120,
    this.cacheHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    final primary = ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final bg = backgroundColor ?? primary.withAlpha(26);
    final fg = textColor ?? primary;

    final initial = name.trim().isNotEmpty ? name.trim()[0] : 'U';

    ImageProvider? imageProvider;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final bytes = ds.getBytesFromPhotoUrl(photoUrl);
      if (bytes != null) {
        imageProvider = MemoryImage(bytes);
      } else if (photoUrl!.startsWith('http')) {
        imageProvider = ResizeImage(
          NetworkImage(photoUrl!),
          width: cacheWidth,
          height: cacheHeight,
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: fg,
                fontSize: radius * 0.75,
              ),
            )
          : null,
    );
  }
}
