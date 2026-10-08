# Hörproben

Öffne `index.html` im Browser. `spoken/` enthält alle Sprachaufnahmen,
`melee/` die vier Nahkampf-Pakete und `magic/` die synthetischen Zauberstab-Sounds.
Die kleinen HTML-Seiten sind im Git-Repository enthalten und laden ihre OGGs
über relative Pfade aus `Sounds/`. Deshalb das komplette Repository herunterladen,
nicht nur eine einzelne HTML-Datei. Im WoW-Installations-ZIP sind keine Hörproben.

Ohne Mikrofon-Quelldateien lassen sich die Seiten neu bauen:

```sh
python3 tools/build_previews.py
```

Aufnahmen und bearbeitbare WAV-Schnitte bleiben unter `spoken/`; die WAVs sind
lokal. Die Importer erzeugen dieselben Seiten nach einem neuen Audio-Import.
Optionale Referenzvergleiche landen unter `reference/`, historische Einzelimporte
unter `legacy/`. Diese enthalten ggf. eingebettete Audiodaten und bleiben lokal.

Bereits vorhandene ältere Hörproben liegen gesammelt unter `archive/`, darunter
`Anhoeren-v0.4.html` und `Anhoeren-v0.5.html`. Sie wurden unverändert aus dem
Addon-Hauptordner verschoben. Das Archiv bleibt lokal und ist von Git sowie
dem Installations-ZIP ausgeschlossen; die aktuellen Hörproben sind oben verlinkt.
