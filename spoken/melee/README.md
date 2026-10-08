# Nahkampf-Aufnahmen

Diese Ordner sind für normale Waffenangriffe mit Haupt- und Nebenhand vorgesehen.
Klassenfähigkeiten und Cast-Sounds kommen später. Die Nahkampf-Pakete sind ab
Version 1.1.0 integriert, auf Wunsch von **Tsukimo**.

## Ordner und Dateinamen

```text
GabbaSounds/spoken/melee/
├── blade/                 Schwerter und Äxte
│   ├── hit.wav            6 normale Laute in einer Aufnahme
│   └── crit.wav           4 Crit-Sprüche in einer Aufnahme
├── blunt/                 Streitkolben und Stäbe
│   ├── hit.wav
│   └── crit.wav
├── dagger/                Dolche
│   ├── hit.wav
│   └── crit.wav
└── fist/                  Faustwaffen und unbewaffnete Angriffe
    ├── hit.wav
    └── crit.wav
```

Die Ordner sind angelegt. `hit.wav` und `crit.wav` erstellst du durch deine
Aufnahmen; leere WAV-Dateien sind nicht nötig. Die Zuordnung ist unser geplanter
Klangstil. Weitere Waffentypen und Gestaltangriffe legen wir später gesondert fest.

## Normale Treffer: 6 Varianten pro Paket

Sprich die sechs Laute einer Zeile nacheinander in die angegebene `hit.wav`.

| Paket / Datei | 1 | 2 | 3 | 4 | 5 | 6 |
| --- | --- | --- | --- | --- | --- | --- |
| Schwerter / Äxte – `blade/hit.wav` | Schwing! | Schack! | Zack! | Schnetz! | Schwapp! | Tschak! |
| Streitkolben / Stäbe – `blunt/hit.wav` | Bamm! | Wumm! | Donk! | Klonk! | Boff! | Ponk! |
| Dolche – `dagger/hit.wav` | Zick! | Stich! | Piks! | Tschick! | Zipp! | Schnipp! |
| Faustwaffen / unbewaffnet – `fist/hit.wav` | Paff! | Pow! | Watsch! | Batsch! | Pomm! | Zonk! |

## Crits: 4 Sprüche pro Paket

Sprich die vier vollständigen Sprüche einer Zeile nacheinander in die
angegebene `crit.wav`.

| Paket / Datei | 1 | 2 | 3 | 4 |
| --- | --- | --- | --- | --- |
| Schwerter / Äxte – `blade/crit.wav` | Sauber geteilt! | Ein Schnitt genügt! | Kopf einziehen! | Das war scharf! |
| Streitkolben / Stäbe – `blunt/crit.wav` | Der Hammer spricht! | Licht aus! | Ordentlich eingedellt! | Das hat gesessen! |
| Dolche – `dagger/crit.wav` | Überraschung! | Mitten ins Schwarze! | Grüße aus dem Schatten! | Präzisionsarbeit! |
| Faustwaffen / unbewaffnet – `fist/crit.wav` | Schlaf gut! | Direkt auf die Zwölf! | Faustrecht! | Knockout! |

Die Texte sind Vorschläge: Du kannst sie durch eigene Laute und Sprüche ersetzen.

## So aufnehmen

- Normale Treffer möglichst kurz sprechen: etwa **0,2–0,5 Sekunden** pro Laut.
- Crits kräftiger und theatralischer sprechen, möglichst **unter 1,5 Sekunden**.
- Zwischen allen Varianten ungefähr **1 Sekunde deutlich still bleiben**.
- Innerhalb eines Spruchs natürlich sprechen; keine künstlichen Schnittpausen.
- Vor dem ersten Laut und nach dem letzten Spruch ebenfalls kurz still bleiben.
- Als **WAV** exportieren; Mono oder Stereo und 44,1 oder 48 kHz sind geeignet.
- Kein Hall, keine Musik, keine extremen Lautstärkesprünge oder Übersteuerung.
- Pro Paket **eine `hit.wav` und eine `crit.wav`**, insgesamt **8 Dateien / 40 Varianten**.

Die vollständigen Aufnahmen werden anschließend in einzelne Spiel-Clips
geschnitten und ins Addon integriert. Deine Quelldateien bleiben dabei erhalten.
Die Ordner werden durch `python3 tools/import_spoken_library.py --melee-only`
importiert. Die geprüften Schnitte stehen in `cuts.json`; neue Aufnahmen benötigen
neue überprüfte Grenzen und einen passenden Quellhash. Hörproben liegen zentral
unter `previews/melee/index.html` im Addon-Hauptordner.
Im Spiel: `/gws pack melee` oder `/gws spokenonly on`.

## Gemeinsame Fehler- und Teiltreffer-Sprüche

Die vorhandenen Dateien bleiben an ihrem bisherigen Ort:

```text
GabbaSounds/spoken/shared/miss.wav
GabbaSounds/spoken/shared/graze.wav
```

Sie müssen nicht in die vier Waffenordner kopiert oder erneut aufgenommen werden.
`miss.wav` wird auch für ausgewichene, parierte und vollständig geblockte
Angriffe verwendet. `graze.wav` deckt Streifschläge und passende Teiltreffer ab. Getrennte Dodge-, Parry- und Block-Aufnahmen sind für den ersten Ausbau
nicht erforderlich.
