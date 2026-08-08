import 'dart:async';

import 'package:flutter/material.dart';

import 'palette.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final VoidCallback? onSettings;

  /// Corps de la notification — varie selon la progression du joueur.
  final String notifBody;

  /// Accès aux Archives (null tant qu'aucun fragment n'a été obtenu).
  final VoidCallback? onArchives;
  final int archivesCount;
  const LockScreen({
    super.key,
    required this.onUnlock,
    this.onSettings,
    this.onArchives,
    this.archivesCount = 0,
    this.notifBody = '1 nouveau message',
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _notifVisible = false;
  Timer? _notifTimer;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _notifTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _notifVisible = true);
    });
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onUnlock,
      child: Container(
        color: Colors.black,
        // SafeArea : en plein écran immersif, l'encoche et les coins
        // arrondis recouvraient le contenu (et le bouton de réglages)
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(fmtTime(),
                    style: const TextStyle(
                        fontSize: 76, fontWeight: FontWeight.w200, letterSpacing: -2)),
                const SizedBox(height: 4),
                Text(fmtDate(),
                    style: const TextStyle(fontSize: 16, color: Palette.textDim)),
                const SizedBox(height: 48),
                AnimatedOpacity(
                  opacity: _notifVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: AnimatedSlide(
                    offset: _notifVisible ? Offset.zero : const Offset(0, 0.08),
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('MESSAGES',
                                  style: TextStyle(fontSize: 12, color: Palette.textDim)),
                              Text('maintenant',
                                  style: TextStyle(fontSize: 12, color: Palette.textDim)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Numéro inconnu',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(widget.notifBody,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFFCFD2DA))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
              const Positioned(bottom: 56, child: _PulsingHint()),
              if (widget.onArchives != null)
                Positioned(
                  bottom: 14,
                  child: TextButton.icon(
                    onPressed: widget.onArchives,
                    icon: const Icon(Icons.folder_outlined,
                        size: 15, color: Palette.textDim),
                    label: Text('Archives · ${widget.archivesCount}',
                        style: const TextStyle(
                            fontSize: 12.5, color: Palette.textDim)),
                  ),
                ),
              if (widget.onSettings != null)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onSettings,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings_outlined,
                                size: 16, color: Palette.textDim),
                            SizedBox(width: 6),
                            Text('IA',
                                style: TextStyle(
                                    fontSize: 13, color: Palette.textDim)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingHint extends StatefulWidget {
  const _PulsingHint();

  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

class _PulsingHintState extends State<_PulsingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: const Text('Appuie pour déverrouiller',
          style: TextStyle(fontSize: 14, color: Palette.textDim)),
    );
  }
}
