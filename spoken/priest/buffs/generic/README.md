# 🗣️ Neutrale Priester-Buffwarnungen

Diese Aufnahmen verwenden **alle Priester außer Bobselinchen**. Bitte keine
Charakternamen nennen. Bobselinchen verwendet ihre persönlichen Aufnahmen aus
dem übergeordneten Ordner; fehlt dort ein Clip, kann auch sie den neutralen Clip
verwenden. Die Auswahl erfolgt automatisch anhand deines eigenen Charakters.

## Acht Dateien, je ein vollständiger Spruch

Alle Pfade beginnen bei `GabbaSounds/spoken/priest/buffs/generic/`.

| Buff / Ordner | `expiring.wav` — höchstens 2 Minuten übrig | `missing.wav` — fehlt / abgelaufen |
| --- | --- | --- |
| 💪 `fortitude/` | „Die Seelenstärke läuft gleich aus! Noch zwei Minuten!“ | „Der Truppe fehlt Ausdauer! Einmal nachbuffen!“ |
| 🧘 `spirit/` | „Die Willenskraft hält nur noch zwei Minuten!“ | „Willenskraft fehlt! Zeit für einen göttlichen Motivationsschub!“ |
| 🔥 `innerfire/` | „Das innere Feuer geht gleich aus!“ | „Dein inneres Feuer fehlt! Zünd es wieder an!“ |
| 🛡️ `fearward/` | „Der Furchtschutz läuft gleich ab! Noch zwei Minuten!“ | „Furchtschutz fehlt! Bitte die Panikversicherung erneuern!“ |

```text
generic/
├── fortitude/
│   ├── expiring.wav
│   └── missing.wav
├── spirit/
│   ├── expiring.wav
│   └── missing.wav
├── innerfire/
│   ├── expiring.wav
│   └── missing.wav
└── fearward/
    ├── expiring.wav
    └── missing.wav
```

Je Datei einen vollständigen Spruch, gern 1–4 Sekunden, mit kurzer Ruhe davor und
danach. WAV mit 44,1 oder 48 kHz, Mono oder Stereo. Keine leeren WAV-Platzhalter
anlegen. Die Ordner sind vorbereitet; die Aufnahmen bleiben lokal und werden
weder in Git noch in Release-ZIPs gepackt.

`missing.wav` gilt auch für fehlende Buffs auf neu erreichbaren Gruppenmitgliedern,
nicht nur für gerade abgelaufene Buffs. Inneres Feuer betrifft ausschließlich
den eigenen Priester. Furchtzauberschutz bleibt eine eigene, standardmäßig
ausgeschaltete Option und setzt den gelernten Zauber voraus. Die gemeinsamen
[Klassen- und Reichweitenregeln](../README.md) gelten auch hier.

## Import nach der Aufnahme

```sh
python3 tools/import_buff_alerts.py --priest-generic
```

Erzeugt acht eigene OGGs und acht Noggenfogger-Varianten, ohne persönliche Priester-
oder Magierdateien zu überschreiben. Hörproben und Paketmanifest werden ergänzt.
Die persönlichen Aufnahmen importiert weiterhin `--priest`, die Magieraufnahmen
der Aufruf ohne zusätzliche Option. Ohne passende importierte Aufnahme erscheint
nur die Textwarnung.

## Importierter Stand

Alle acht neutralen Erinnerungen sind enthalten, jeweils mit Noggenfogger-Variante.
Für **Inneres Feuer fehlt** wird auf deinen Wunsch `innerfire/missing1.wav`
verwendet; `missing.wav` bleibt unverändert als Alternative erhalten.
Bei erneutem Import dieselbe Auswahl verwenden:

```sh
python3 tools/import_buff_alerts.py --priest-generic --source-override innerfire:missing=spoken/priest/buffs/generic/innerfire/missing1.wav
```
