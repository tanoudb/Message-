/// Réglages de l'IA locale : activation + fichier modèle installé.
/// Le modèle (.task, ex. Gemma 3 1B IT int4) est fourni par le joueur via
/// le sélecteur de fichiers, copié dans le stockage de l'app, puis déclaré
/// à flutter_gemma. Tout est optionnel : sans modèle, le jeu utilise ses
/// banques de répliques.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiSettings {
  static const _kEnabled = 'ai_enabled';
  static const _kModelPath = 'ai_model_path';

  bool enabled;
  String? modelPath;

  AiSettings({this.enabled = false, this.modelPath});

  bool get modelInstalled =>
      modelPath != null && File(modelPath!).existsSync();

  static Future<AiSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AiSettings(
      enabled: p.getBool(_kEnabled) ?? false,
      modelPath: p.getString(_kModelPath),
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, enabled);
    if (modelPath != null) {
      await p.setString(_kModelPath, modelPath!);
    } else {
      await p.remove(_kModelPath);
    }
  }

  /// Ouvre le sélecteur de fichiers, copie le modèle dans le stockage de
  /// l'app et le déclare à flutter_gemma. Renvoie null si annulé, sinon
  /// le chemin installé.
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
    enabled = true;
    await save();
    return dest;
  }

  /// Déclare le fichier modèle à flutter_gemma comme modèle actif.
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
    enabled = false;
    await save();
  }

  static String _ext(String path) {
    final i = path.lastIndexOf('.');
    return i < 0 ? '.task' : path.substring(i);
  }
}
