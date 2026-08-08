import 'package:flutter/material.dart';

import 'palette.dart';

/// Barre de statut du faux téléphone : heure réelle + batterie réelle.
class StatusBar extends StatelessWidget {
  final int? batteryPct;
  const StatusBar({super.key, required this.batteryPct});

  @override
  Widget build(BuildContext context) {
    final pct = batteryPct;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(fmtTime(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Row(children: [
            Text(pct == null ? '--%' : '$pct%',
                style: const TextStyle(fontSize: 13, color: Palette.text)),
            const SizedBox(width: 4),
            _BatteryIcon(pct: pct),
          ]),
        ],
      ),
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  final int? pct;
  const _BatteryIcon({required this.pct});

  @override
  Widget build(BuildContext context) {
    final level = (pct ?? 60).clamp(0, 100);
    final fill = level <= 20 ? Palette.danger : Palette.text;
    return Row(children: [
      Container(
        width: 22,
        height: 11,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(color: Palette.textDim),
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: level / 100,
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
      Container(
        width: 2,
        height: 5,
        margin: const EdgeInsets.only(left: 1),
        decoration: const BoxDecoration(
          color: Palette.textDim,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(1)),
        ),
      ),
    ]);
  }
}
