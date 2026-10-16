# 🌿 Kräuter-Alarm aufnehmen

Dieser Ausbau kommt vor den Kriegerfähigkeiten. Lege die **zwei einzelnen
Aufnahmen** direkt in diesen Ordner:

| Datei | Kraut | Vorschläge — einen Spruch auswählen |
| --- | --- | --- |
| `gromsblood.wav` | Gromsblut / Gromsblood | „Gromsbluuut!“ · „Da wächst die Wut!“ · „Blut im Grünen!“ |
| `blacklotus.wav` | Schwarzer Lotus / Black Lotus | „LOOOTUS!“ · „Alles stehen lassen!“ · „Der Lotus gehört mir!“ |

**Ein Spruch pro Datei**, gerne etwa 0,5–3 Sekunden. Vor und nach dem Spruch
kurz Ruhe lassen. WAV mit 44,1 oder 48 kHz, Mono oder Stereo; ohne Hall und
ohne Übersteuerung. Du musst die Dateien weder schneiden noch umwandeln.
Die WAV-Originale bleiben lokal und werden nicht ins Git-Repo oder Release-ZIP gepackt.

## Tooltip-Alarm (Testfassung 1.4.0)

Die beiden Aufnahmen sind jetzt im Addon eingebunden, einschließlich höherer
Noggenfogger-Varianten. Beim **Darüberfahren mit der Maus** über einen echten
Gromsblut-/Lotus-Trackingpunkt auf der Minimap oder das Kraut in der Spielwelt
wird der passende Sound abgespielt. Deutsche und englische Namen werden erkannt.

- Nur beim eigenen Kräuterkundler; erkennbar über die gelernte Kräutersuche.
- Standardmäßig aktiv, unabhängig vom gewählten Angriffs-Soundpaket.
- Mindestens 30 Sekunden Pause pro Kraut. Solange derselbe Tooltip stehen bleibt,
  gibt es auch nach 30 Sekunden keine erneute Meldung.
- Gespeicherte Addon-Pins, Taschengegenstände, Chatlinks, Einheiten und Zauber
  lösen keinen Alarm aus. Schwarzer Lotus hat bei überlappenden Kräuterpunkten Vorrang.
- Eigene Wiedergabe: Angriffsgeräusche schneiden die Kräuteraufnahme nicht ab.
- Kein automatischer Minimap-Suchlauf und kein Nachweis der Pflückreichweite.

Die zwei nötigen Funktionen für einen automatischen Scan fehlen dem verwendeten
Classic-Era-Client (`AutoScan: nil nil`, 16.10.2026). Deshalb wurde die
Tooltip-Variante ausdrücklich ausgewählt. Der Alarm muss noch an echten Kräutern
im Spiel geprüft werden; dies ist zunächst eine lokale Testfassung.

## Einstellungen und Hörproben

`/gws herbs` oder der Button „Kräuter-Alarm“ im `/gws`-Fenster öffnet die Optionen.
Die Einstellung ist pro Charakter gespeichert. Ausschalten des ganzen Addons
stoppt auch die Kräuter-Alarme. Hörproben funktionieren auf Charakteren ohne
Kräuterkunde und bei abgeschaltetem Addon.

```text
/gws herbs on
/gws herbs off
/gws herbs gromsblood
/gws herbs blacklotus
```

[Lokale Hörproben](../../previews/herbalism/index.html) im Browser öffnen.

## Neue Aufnahmen importieren

```sh
python3 tools/import_herbalism.py
```

Trimmt die äußere Stille, gleicht die Lautstärke an und erzeugt die zwei OGGs
plus zwei höhere Noggenfogger-Varianten. Die WAV-Quellen und alle bisherigen
Angriffs- und Buffaufnahmen bleiben unverändert. Registry, Manifest und Player
werden aktualisiert. Die Release-ZIP enthält nur fertige Sounds und Laufzeitdateien.

`python3 tools/build_previews.py` regeneriert die Player aus den OGG-Metadaten
auch ohne private WAV-Dateien. `tools/preview_herbalism.py` bleibt als alter
Aufruf für den Kräuter-Player nutzbar.

Nach Installation **WoW vollständig schließen und neu starten**, damit die
neuen Audiodateien geladen werden.
