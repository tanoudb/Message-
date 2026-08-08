/// L'entité te réécrit quand tu ne joues pas.
///
/// Une notification locale, programmée à la fin de chaque nuit, arrive
/// quelques heures plus tard — de nuit de préférence. Elle imite une
/// vraie notification de messagerie : « Numéro inconnu · tu dors ? ».
/// Tout est local (aucun serveur) et entièrement facultatif : si la
/// permission est refusée, le jeu fonctionne exactement pareil.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Ce que l'entité envoie quand le joueur a disparu.
const List<String> reminderTexts = [
  'tu dors ?',
  "Tu n'as pas fini de répondre.",
  "J'ai relu tes réponses. On en reparle ?",
  'Il reste des pages au carnet.',
  "Ton dossier est resté ouvert.",
  'Encore une question. Une seule.',
  "Tu as arrêté de répondre. Les autres aussi, au début.",
];

abstract final class Reminders {
  static const _kPref = 'reminders_enabled';
  static const _id = 1001;

  static bool enabled = true;
  static bool _ready = false;

  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      enabled = p.getBool(_kPref) ?? true;
    } catch (_) {}
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kPref, v);
    } catch (_) {}
    if (!v) await cancel();
  }

  /// Demande la permission de notifier (Android 13+). Sans réponse
  /// positive, on n'insiste jamais.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Programme le prochain message de l'entité, [hours] heures plus tard
  /// (repoussé à la nuit suivante si l'heure tombe en pleine journée).
  static Future<void> schedule(String text, {int hours = 6}) async {
    if (!enabled || !_ready) return;
    try {
      await cancel();
      var when = tz.TZDateTime.now(tz.local).add(Duration(hours: hours));
      // les entités écrivent la nuit : on vise 22h-1h
      if (when.hour >= 2 && when.hour < 21) {
        when = tz.TZDateTime(tz.local, when.year, when.month, when.day, 22,
            15 + when.minute % 40);
      }
      await _plugin.zonedSchedule(
        id: _id,
        title: 'Numéro inconnu',
        body: text,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'entity_messages',
            'Messages',
            channelDescription: "Messages de l'entité",
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.message,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // permission refusée, exact alarms indisponibles… : on n'insiste pas
    }
  }

  static Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
