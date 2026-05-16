import 'package:flutter/material.dart';

/// Helper pour afficher une notification éphémère **en haut** de la page.
///
/// Remplacement de [ScaffoldMessenger.showSnackBar] qui, par défaut, place
/// la SnackBar en bas de l'écran. On utilise ici un [OverlayEntry] avec une
/// animation de glissement depuis le haut + auto-fermeture après 3 secondes.
///
/// Usage :
/// ```dart
/// TopNotifier.success(context, 'Commande créée');
/// TopNotifier.error(context, 'Quantité invalide');
/// TopNotifier.info(context, 'Synchronisation en cours…');
/// ```
class TopNotifier {
  TopNotifier._();

  /// Notification de succès (vert, icône check).
  static void success(BuildContext context, String message) =>
      _show(context, message, _NotifKind.success);

  /// Notification d'erreur (rouge, icône !).
  static void error(BuildContext context, String message) =>
      _show(context, message, _NotifKind.error);

  /// Notification neutre / info (bleu, icône info).
  static void info(BuildContext context, String message) =>
      _show(context, message, _NotifKind.info);

  /// Notification d'avertissement (orange, icône warning).
  static void warning(BuildContext context, String message) =>
      _show(context, message, _NotifKind.warning);

  static void _show(BuildContext context, String message, _NotifKind kind) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopBanner(
        message: message,
        kind: kind,
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

enum _NotifKind { success, error, info, warning }

class _TopBanner extends StatefulWidget {
  const _TopBanner({
    required this.message,
    required this.kind,
    required this.onDismissed,
  });

  final String message;
  final _NotifKind kind;
  final VoidCallback onDismissed;

  @override
  State<_TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<_TopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;
      await _ctrl.reverse();
      if (!mounted) return;
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({Color bg, Color fg, IconData icon}) _style(BuildContext context) {
    switch (widget.kind) {
      case _NotifKind.success:
        return (
          bg: Colors.green.shade600,
          fg: Colors.white,
          icon: Icons.check_circle_outline,
        );
      case _NotifKind.error:
        return (
          bg: Colors.red.shade700,
          fg: Colors.white,
          icon: Icons.error_outline,
        );
      case _NotifKind.warning:
        return (
          bg: Colors.orange.shade700,
          fg: Colors.white,
          icon: Icons.warning_amber_outlined,
        );
      case _NotifKind.info:
        return (
          bg: Theme.of(context).colorScheme.inverseSurface,
          fg: Theme.of(context).colorScheme.onInverseSurface,
          icon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style(context);
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topInset + 16,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _opacity,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, color: s.fg),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: s.fg,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minHeight: 28,
                          minWidth: 28,
                        ),
                        icon: Icon(Icons.close, color: s.fg, size: 18),
                        onPressed: () async {
                          await _ctrl.reverse();
                          if (!mounted) return;
                          widget.onDismissed();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
