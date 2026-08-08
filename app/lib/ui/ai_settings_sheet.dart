import 'package:flutter/material.dart';

import '../ai/ai_settings.dart';
import 'palette.dart';

/// Feuille de réglages de l'IA locale, accessible depuis l'écran verrouillé.
class AiSettingsSheet extends StatefulWidget {
  final AiSettings settings;
  const AiSettingsSheet({super.key, required this.settings});

  @override
  State<AiSettingsSheet> createState() => _AiSettingsSheetState();
}

class _AiSettingsSheetState extends State<AiSettingsSheet> {
  bool _busy = false;
  String? _error;

  AiSettings get s => widget.settings;

  Future<void> _install() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await s.pickAndInstallModel();
    } catch (e) {
      _error = "Installation impossible : $e";
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final installed = s.modelInstalled;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IA locale',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              "Avec un modèle installé, l'entité reformule ses messages et répond "
              "à ce que tu écris — entièrement sur ton téléphone, sans réseau. "
              "Sans modèle, le jeu utilise ses répliques écrites : il fonctionne "
              "dans les deux cas.",
              style: TextStyle(fontSize: 14, color: Palette.textDim, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Icon(installed ? Icons.check_circle : Icons.circle_outlined,
                  size: 18, color: installed ? Palette.ok : Palette.textDim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  installed
                      ? 'Modèle installé'
                      : 'Aucun modèle installé (format .task, ex. Gemma 3 1B IT int4)',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Utiliser l'IA locale", style: TextStyle(fontSize: 15)),
              value: s.enabled && installed,
              onChanged: installed
                  ? (v) async {
                      s.enabled = v;
                      await s.save();
                      if (mounted) setState(() {});
                    }
                  : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(fontSize: 13, color: Palette.danger)),
              ),
            Row(children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.btn,
                    foregroundColor: Palette.text,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _busy ? null : _install,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(installed
                          ? 'Remplacer le modèle'
                          : 'Choisir le fichier modèle'),
                ),
              ),
              if (installed) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          await s.removeModel();
                          if (mounted) setState(() {});
                        },
                  icon: const Icon(Icons.delete_outline, color: Palette.danger),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            const Text(
              'Le modèle est copié dans le stockage de l\'app : la copie peut '
              'prendre un moment. Prévois ~1 Go d\'espace libre.',
              style: TextStyle(fontSize: 12, color: Palette.textDim, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
