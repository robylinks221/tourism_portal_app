import 'package:flutter/material.dart';
import '../services/platform_branding_service.dart';

/// Circular server-managed brand logo with a graceful default icon.
/// Uses BoxFit.contain so transparent logos are never cropped or distorted.
class PlatformBrandLogo extends StatelessWidget {
  const PlatformBrandLogo({super.key, this.size = 44, this.refresh = false});
  final double size;
  final bool refresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: PlatformBrandingService.instance.logoUrl(refresh: refresh),
      builder: (context, snapshot) {
        final url = snapshot.data ?? '';
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * .085),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: ClipOval(
            child: url.isEmpty
                ? Icon(Icons.landscape_rounded, color: const Color(0xFF165B5D), size: size * .48)
                : Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.landscape_rounded, color: const Color(0xFF165B5D), size: size * .48),
                  ),
          ),
        );
      },
    );
  }
}
