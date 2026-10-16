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

## Stand: automatischer Alarm technisch blockiert

Gewünscht ist ein Alarm **ohne Darüberfahren mit der Maus**, wenn das Kraut als
echter Trackingpunkt auf der Minimap erscheint. Eine Tooltip-Variante ist nicht
gewünscht und wurde nicht ins Addon übernommen.

Der Test im Classic-Era-Client am 16.10.2026 ergab:

```lua
/run print("AutoScan:", type(Minimap.UpdateMouseoverAtPoint), type(C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover))
-- AutoScan: nil nil
```

Das hängt nicht von Kräuterkunde oder der gerade aktiven Schatzsuche ab: Die
beiden Funktionen fehlen dem Client grundsätzlich. Der automatische Suchlauf
anderer Clients lässt sich deshalb hier nicht verwenden. Vergleiche die
[Classic-Era-Minimap-API](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapFrameAPIDocumentation.lua)
mit der [Forever-Minimap-API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapFrameAPIDocumentation.lua).

Ein Alarm bei Nähe zu **gespeicherten Fundstellen** wäre eine andere Möglichkeit,
würde aber auch bei leeren Spawnpunkten auslösen. Diese Alternative ist noch
nicht ausgewählt oder eingebaut. Es wurde kein automatischer Kräuter-Alarm
installiert oder veröffentlicht.

## Lokale Hörproben

```sh
python3 tools/preview_herbalism.py
```

Das Werkzeug trimmt die äußere Stille, gleicht die Lautstärke an und erstellt
zwei OGG-Hörproben unter `previews/herbalism/`. Den erzeugten
[Player](../../previews/herbalism/index.html) lokal im Browser öffnen.
Die WAV-Quellen bleiben unverändert. Die Hörproben sind lokal, werden nicht
in Git aufgenommen und landen nicht im Addon-Release oder auf GitHub Pages.
