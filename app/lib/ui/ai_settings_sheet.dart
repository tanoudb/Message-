import 'package:flutter/material.dart';

import '../ai/ai_settings.dart';
import '../meta/reminders.dart';
import 'palette.dart';
import 'sfx.dart';

/// Feuille de réglages de l'IA locale, accessible depuis l'écran verrouillé
/// et l'écran de fin.
class AiSettingsSheet extends StatefulWidget {
  final AiSettings settings;
  const AiSettingsSheet({super.key, required this.settings});

  @override
  State<AiSettingsSheet> createState() => _AiSettingsSheetState();
}

class _AiSettingsSheetState extends State<AiSettingsSheet> {
  bool _busy = false;
  int? _progress; // 0-100 pendant un téléchargement
  String? _error;
  late final TextEditingController _urlCtrl;
  final _tokenCtrl = TextEditingController();

  AiSettings get s => widget.settings;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: defaultModelUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _progress = 0;
      _error = null;
    });
    try {
      await s.downloadAndInstallModel(
        _urlCtrl.text.trim(),
        token: _tokenCtrl.text.trim(),
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
    } catch (e) {
      _error = 'Téléchargement impossible. Vérifie la connexion, l\'URL et le '
          'jeton (modèle sous licence : accepte-la sur Hugging Face et colle un '
          'jeton hf_...).';
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _progress = null;
      });
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await s.pickAndInstallModel();
    } catch (e) {
      _error = 'Installation impossible depuis ce fichier.';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final installed = s.modelInstalled;
    const dim = TextStyle(fontSize: 13, color: Palette.textDim, height: 1.45);
    return SafeArea(
      child: Padding(
        // laisse la place au clavier quand on édite l'URL ou le jeton
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Réglages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sons', style: TextStyle(fontSize: 15)),
                value: Sfx.enabled,
                onChanged: (v) async {
                  await Sfx.setEnabled(v);
                  if (mounted) setState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Laisser l'entité me réécrire",
                    style: TextStyle(fontSize: 15)),
                subtitle: const Text(
                    'Elle enverra un message quand tu auras arrêté de jouer.',
                    style: TextStyle(fontSize: 12, color: Palette.textDim)),
                value: Reminders.enabled,
                onChanged: (v) async {
                  if (v) await Reminders.requestPermission();
                  await Reminders.setEnabled(v);
                  if (mounted) setState(() {});
                },
              ),
              const Divider(height: 16, color: Palette.border),
              const Text('IA locale',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                "Avec un modèle installé, l'entité écrit ses propres messages et "
                "répond à ce que tu dis — entièrement sur ton téléphone, sans "
                "réseau pendant le jeu. Sans modèle, le jeu utilise ses répliques "
                "écrites et fonctionne quand même.",
                style: dim,
              ),
              const SizedBox(height: 14),
              Row(children: [
                Icon(installed ? Icons.check_circle : Icons.circle_outlined,
                    size: 18, color: installed ? Palette.ok : Palette.textDim),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    installed ? 'Modèle installé' : 'Aucun modèle installé',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (installed)
                  IconButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            await s.removeModel();
                            if (mounted) setState(() {});
                          },
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Palette.danger),
                  ),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Utiliser l'IA locale",
                    style: TextStyle(fontSize: 15)),
                value: s.enabled && installed,
                onChanged: installed && !_busy
                    ? (v) async {
                        s.enabled = v;
                        await s.save();
                        if (mounted) setState(() {});
                      }
                    : null,
              ),
              if (!installed) ...[
                const Divider(height: 24, color: Palette.border),
                const Text('Installer le modèle (~550 Mo, Wi-Fi conseillé)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: _urlCtrl,
                  enabled: !_busy,
                  style: const TextStyle(fontSize: 13),
                  decoration: _fieldDeco('URL du modèle (.task)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tokenCtrl,
                  enabled: !_busy,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: _fieldDeco(
                      'Jeton Hugging Face (hf_...) — requis pour Gemma'),
                ),
                const SizedBox(height: 6),
                const Text(
                  '1. Crée un compte Hugging Face et accepte la licence Gemma '
                  'sur la page du modèle. 2. Génère un jeton d\'accès (Settings '
                  '→ Access Tokens) et colle-le ci-dessus.',
                  style: dim,
                ),
                const SizedBox(height: 12),
                if (_progress != null) ...[
                  LinearProgressIndicator(
                      value: _progress! / 100,
                      backgroundColor: Palette.border,
                      color: Palette.ok),
                  const SizedBox(height: 6),
                  Text('Téléchargement... $_progress %', style: dim),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      style: _btnStyle(),
                      onPressed: _busy ? null : _download,
                      child: _busy && _progress != null
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Télécharger et installer'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _pickFile,
                    child: const Text(
                        'ou choisir un fichier .task déjà téléchargé',
                        style:
                            TextStyle(fontSize: 13, color: Palette.textDim)),
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style:
                          const TextStyle(fontSize: 13, color: Palette.danger)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Palette.textDim, fontSize: 13),
        filled: true,
        fillColor: Palette.bg,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.border),
        ),
      );

  ButtonStyle _btnStyle() => FilledButton.styleFrom(
        backgroundColor: Palette.btn,
        foregroundColor: Palette.text,
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
