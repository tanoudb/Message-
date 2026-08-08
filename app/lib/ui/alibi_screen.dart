import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../engine/alibi.dart';
import 'palette.dart';

class AlibiScreen extends StatefulWidget {
  final Alibi alibi;
  final VoidCallback onDone;
  const AlibiScreen({super.key, required this.alibi, required this.onDone});

  @override
  State<AlibiScreen> createState() => _AlibiScreenState();
}

class _AlibiScreenState extends State<AlibiScreen> {
  static const int _seconds = 45;
  int _left = _seconds;
  Timer? _timer;
  bool _dissolving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) _leave();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_dissolving) return;
    _timer?.cancel();
    setState(() => _dissolving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) widget.onDone();
  }

  TextSpan _b(String s) =>
      TextSpan(text: s, style: const TextStyle(fontWeight: FontWeight.w700));

  @override
  Widget build(BuildContext context) {
    final a = widget.alibi;
    const body = TextStyle(fontSize: 15.5, height: 1.55, color: Palette.text);
    return AnimatedOpacity(
      opacity: _dissolving ? 0 : 1,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeIn,
      child: ImageFiltered(
        imageFilter: _dissolving
            ? ImageFilter.blur(sigmaX: 6, sigmaY: 6)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 34),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Palette.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NOTES',
                      style: TextStyle(
                          fontSize: 13,
                          color: Palette.accent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  const Text("Ce soir, tu es quelqu'un d'autre.",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Modifiée à ${fmtTime()} · Cette note s\'effacera.',
                      style: const TextStyle(fontSize: 12, color: Palette.textDim)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(style: body, children: [
                        const TextSpan(
                            text: "Cette nuit, si quelqu'un te parle, tu t'appelles "),
                        _b(a.prenom),
                        const TextSpan(text: '. Tu es '),
                        _b(a.metier),
                        const TextSpan(text: '.'),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(style: body, children: [
                        const TextSpan(text: 'Hier soir, tu étais '),
                        _b(a.lieu.canon),
                        const TextSpan(text: ' : '),
                        _b(a.detail.canon),
                        const TextSpan(text: '.'),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(style: body, children: [
                        const TextSpan(text: 'Arrivé vers '),
                        _b('${a.hArrivee}h'),
                        const TextSpan(text: '. Rentré vers '),
                        _b('${a.hRetour}h'),
                        const TextSpan(text: '. Déplacement '),
                        _b(a.transport.canon),
                        const TextSpan(text: '.'),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                        "⚠ Tout ce que cette note ne dit pas, tu devras l'inventer. Et t'en souvenir.",
                        style: TextStyle(fontSize: 14, color: Palette.accent)),
                    const SizedBox(height: 10),
                    const Text(
                        'Ne contrarie pas ce qui va te parler. Ne change jamais de version. Cette note ne réapparaîtra pas.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Palette.textDim,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Text('Effacement dans $_left s',
                      style: const TextStyle(fontSize: 12, color: Palette.textDim)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.btn,
                        foregroundColor: Palette.text,
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _leave,
                      child: const Text("J'ai mémorisé",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
