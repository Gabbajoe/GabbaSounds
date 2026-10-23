# ✨ Priester-Aufnahmen

**Die sieben Schadensaufnahmen sind importiert und eingebunden:** 28 einzelne
Clips, zusätzlich als höhere Noggenfogger-Varianten. Die WAV-Originale bleiben
unverändert. Diese Seite enthält auch Vorlagen für spätere Neuaufnahmen.
Die [Buff-Erinnerungen für Priester](buffs/README.md) mit persönlichen Aufnahmen
für Bobselinchen und neutralen für andere Priester haben
eigene Ordner und Aufnahmen für die Zwei-Minuten- und Fehlend-Warnung.

## Ablage

```text
GabbaSounds/spoken/priest/
├── mindblast/          # Gedankenschlag
│   ├── hit.wav         # alle vier normalen Laute in einer Aufnahme
│   └── crit.wav        # alle vier Crit-Sprüche in einer Aufnahme
├── shadowwordpain/     # Schattenwort: Schmerz
│   └── hit.wav         # vier Varianten; kann in Classic Era nicht critten
├── smite/              # Göttliche Pein (hier als „Holy Strike“ gemeint)
│   ├── hit.wav
│   └── crit.wav
├── holynova/           # Heilige Nova, Schadensanteil
│   ├── hit.wav
│   └── crit.wav
└── buffs/              # siehe eigene Aufnahmevorlage
    ├── fortitude/      # expiring.wav und missing.wav
    ├── spirit/         # expiring.wav und missing.wav
    ├── innerfire/      # expiring.wav und missing.wav
    └── fearward/       # expiring.wav und missing.wav, optional
```

Pro Schadens-Datei die **vier Varianten nacheinander** einsprechen, mit jeweils
**1–2 Sekunden Ruhe** dazwischen. Ich kann sie danach einzeln schneiden.
Normale Laute gern kurz, Crit-Sprüche etwas größer und übertriebener.
WAV, 44,1 oder 48 kHz, Mono oder Stereo, ohne Übersteuerung.

## Vier normale Treffer-Laute je Zauber

| Zauber / Ordner | Hit 1 | Hit 2 | Hit 3 | Hit 4 |
| --- | --- | --- | --- | --- |
| 🧠 Gedankenschlag — `mindblast/hit.wav` | „Hirn-Bumm!“ | „Denk-Zack!“ | „Kopf-Poff!“ | „Synapsen-Peng!“ |
| 🌑 Schattenwort: Schmerz — `shadowwordpain/hit.wav` | „Das zwickt!“ | „Schatten-Pieks!“ | „Aua auf Raten!“ | „Schmerz-Abo!“ |
| ✨ Göttliche Pein — `smite/hit.wav` | „Licht-Pew!“ | „Heilig-Zack!“ | „Lichtschelle!“ | „Segen-Bamm!“ |
| 💥 Heilige Nova — `holynova/hit.wav` | „Heilig-Wumm!“ | „Lichtwelle!“ | „Rundum-Poff!“ | „Nova-Puff!“ |

## Vier Crit-Sprüche je kritfähigem Schadenszauber

| Zauber / Ordner | Crit 1 | Crit 2 | Crit 3 | Crit 4 |
| --- | --- | --- | --- | --- |
| 🧠 Gedankenschlag — `mindblast/crit.wav` | „Gedanken? Jetzt nicht mehr!“ | „Hirn an die Wand!“ | „Synapsen-Supernova!“ | „Das war ein Denkanstoß!“ |
| ✨ Göttliche Pein — `smite/crit.wav` | „Die volle Lichtschelle!“ | „Göttlich eins übergezogen!“ | „Erleuchtung mit Nachdruck!“ | „Heiliger Volltreffer!“ |
| 💥 Heilige Nova — `holynova/crit.wav` | „Heilige Diskokugel!“ | „Alle einmal erleuchten!“ | „Licht aus? Licht an!“ | „Die volle Ladung Heilig!“ |

**Schattenwort: Schmerz kann in Classic Era nicht kritisch treffen.** Dafür keine
`crit.wav` aufnehmen. Eine Reaktion spielt beim erfolgreichen Auftragen oder Auffrischen, ohne
weitere Kommentare bei DoT-Ticks. Heilige Nova fasst gleichzeitige Schadensziele
zusammen, bevorzugt Crits und ignoriert ihren Heilanteil.

Die Schadens-Aufnahmen ergeben **7 Dateien mit insgesamt 28 Varianten**.
Dazu kommen **8 persönliche Buff-Erinnerungen** und optional **8 neutrale
Erinnerungen für andere Priester**. Fehlversuche können später die
vorhandenen gemeinsamen Miss-/Resist-Aufnahmen verwenden.

## Benutzen und erneut importieren

`/gws pack priest` oder `/gws pack priester`: nur Priester-Schadenszauber.
`/gws pack spoken`: alle gesprochenen Waffen und Zauber. Einzelpakete heißen
`mindblast`, `shadowwordpain`, `smite`, `holynova`.
Hörproben: `/gws test hit mindblast`, `/gws test crit holynova` oder die
[lokale Priester-Hörprobe](../../previews/priest/index.html).

Die Schadenszauber funktionieren für alle Priester, unabhängig vom Namen.
Es gibt bisher keine eigenen Priester-Cast-Aufnahmen. „Nur gesprochene Sounds“
schaltet bei vollständigen Ersatzpools die verifizierten nativen Dateien stumm,
auch geteilte Cast-/Wirkungssounds. Die Wirkung bleibt global pro Sounddatei.

```sh
python3 tools/import_spoken_library.py --priest-only
```

Liest nur die sieben Schadens-WAVs und aktualisiert Clips, Registry, Hörproben
und Noggenfogger-Varianten. Nicht-Priesterclips bleiben erhalten. Die vier
Schnittbereiche pro Datei stehen mit Quell-Hash in `cuts.json`. Veränderte
Aufnahmen brauchen neu geprüfte Schnittmarken; veraltete Schnitte werden abgelehnt.
