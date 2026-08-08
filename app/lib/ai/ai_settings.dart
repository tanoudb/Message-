/// Réglages de l'IA locale : activation + modèle installé.
/// Deux voies d'installation, toutes deux optionnelles — sans modèle,
/// le jeu utilise ses banques de répliques :
///  - téléchargement direct dans l'app (URL + jeton Hugging Face
///    éventuel), géré par flutter_gemma avec progression ;
///  - fichier `.task` déjà présent sur le téléphone (sélecteur de
///    fichiers), copié dans le stockage de l'app.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// URL par défaut du modèle recommandé (Gemma 3 1B IT int4, ~550 Mo).
/// Le dépôt Hugging Face est sous licence Gemma : un jeton d'accès
/// (hf_...) est nécessaire après acceptation de la licence.
const String defaultModelUrl =
    'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';

class AiSettings {
  static const _kEnabled = 'ai_enabled';
  static const _kModelPath = 'ai_model_path';
  static const _kInstalled = 'ai_model_installed';

  bool enabled;
  bool installed;

  /// Chemin local si le modèle vient d'un fichier ; null si le
  /// téléchargement est géré en interne par flutter_gemma.
  String? modelPath;

  AiSettings({this.enabled = false, this.installed = false, this.modelPath});

  bool get modelInstalled =>
      installed && (modelPath == null || File(modelPath!).existsSync());

  static Future<AiSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AiSettings(
      enabled: p.getBool(_kEnabled) ?? false,
      installed: p.getBool(_kInstalled) ?? false,
      modelPath: p.getString(_kModelPath),
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, enabled);
    await p.setBool(_kInstalled, installed);
    if (modelPath != null) {
      await p.setString(_kModelPath, modelPath!);
    } else {
      await p.remove(_kModelPath);
    }
  }

  /// Télécharge et installe le modèle depuis une URL (progression 0-100).
  Future<void> downloadAndInstallModel(
    String url, {
    String? token,
    void Function(int progress)? onProgress,
  }) async {
    var b = FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromNetwork(url, token: (token == null || token.isEmpty) ? null : token);
    if (onProgress != null) b = b.withProgress(onProgress);
    await b.install();
    modelPath = null; // fichier géré par flutter_gemma
    installed = true;
    enabled = true;
    await save();
  }

  /// Installe un modèle depuis un fichier déjà présent sur le téléphone.
  /// Renvoie null si l'utilisateur annule le sélecteur.
  Future<String?> pickAndInstallModel() async {
    final res = await FilePicker.pickFiles();
    final src = res?.files.single.path;
    if (src == null) return null;

    final dir = await getApplicationSupportDirectory();
    final dest = '${dir.path}/entity_model${_ext(src)}';
    if (src != dest) {
      await File(src).copy(dest);
    }
    await declareToGemma(dest);
    modelPath = dest;
    installed = true;
    enabled = true;
    await save();
    return dest;
  }

  /// Déclare un fichier modèle local à flutter_gemma comme modèle actif.
  static Future<void> declareToGemma(String path) async {
    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromFile(path)
        .install();
  }

  Future<void> removeModel() async {
    if (modelPath != null) {
      final f = File(modelPath!);
      if (f.existsSync()) await f.delete();
    }
    modelPath = null;
    installed = false;
    enabled = false;
    await save();
  }

  static String _ext(String path) {
    final i = path.lastIndexOf('.');
    return i < 0 ? '.task' : path.substring(i);
  }
}
