import 'package:flutter/material.dart';

/// Identité visuelle Al-Fakhir (déclaré dans [pubspec.yaml]).
abstract final class AppBranding {
  static const String logoAsset = 'assets/images/restaurant_logo.jpg';
}

/// Logo officiel (image asset), avec repli si le fichier manque.
class AppLogoAsset extends StatelessWidget {
  const AppLogoAsset({
    super.key,
    required this.size,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.clipOval = false,
  });

  final double size;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool clipOval;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget img = Image.asset(
      AppBranding.logoAsset,
      width: size,
      height: size,
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.restaurant_menu_rounded,
        size: size * 0.45,
        color: cs.primary,
      ),
    );
    if (clipOval) {
      img = ClipOval(child: img);
    } else if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}
