# Hörproben

[**🎧 Direkt im Browser anhören**](https://gabbajoe.github.io/GabbaSounds/)

GitHub zeigt HTML-Dateien im Repository als Quellcode. Die spielbaren Player
werden deshalb auf GitHub Pages veröffentlicht und nach Änderungen auf `main`
automatisch aktualisiert.

Für die Offline-Nutzung öffne `index.html` im Browser. `spoken/` enthält alle Sprachaufnahmen,
`melee/` die vier Nahkampf-Pakete und `magic/` die synthetischen Zauberstab-Sounds.
Die kleinen HTML-Seiten sind im Git-Repository enthalten und laden ihre OGGs
über relative Pfade aus `Sounds/`. Deshalb das komplette Repository herunterladen,
nicht nur eine einzelne HTML-Datei. Im WoW-Installations-ZIP sind keine Hörproben.

Ohne Mikrofon-Quelldateien lassen sich die Seiten neu bauen:

```sh
python3 tools/build_previews.py
```

Die veröffentlichbare Webseite lässt sich separat bauen und lokal prüfen:

```sh
python3 tools/build_preview_site.py --output-dir dist/site
python3 -m http.server --directory dist/site 8000
```

Öffne anschließend `http://localhost:8000/`. Der Zielordner muss beim Bauen
noch nicht existieren. Die Webseite enthält nur aktuelle Player, das Logo und
die 345 fertigen OGGs. WAVs, Archive und Tooling werden nicht veröffentlicht.
Der Website-Bau ist unabhängig vom Addon-ZIP und löst keinen Addon-Release aus.

Aufnahmen und bearbeitbare WAV-Schnitte bleiben unter `spoken/`; die WAVs sind
lokal. Die Importer erzeugen dieselben Seiten nach einem neuen Audio-Import.
Optionale Referenzvergleiche landen unter `reference/`, historische Einzelimporte
unter `legacy/`. Diese enthalten ggf. eingebettete Audiodaten und bleiben lokal.

Bereits vorhandene ältere Hörproben liegen gesammelt unter `archive/`, darunter
`Anhoeren-v0.4.html` und `Anhoeren-v0.5.html`. Sie wurden unverändert aus dem
Addon-Hauptordner verschoben. Das Archiv bleibt lokal und ist von Git sowie
dem Installations-ZIP ausgeschlossen; die aktuellen Hörproben sind oben verlinkt.
