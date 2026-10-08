# GabbaSounds

[GitHub](https://github.com/Gabbajoe/GabbaSounds) ·
[Releases und Downloads](https://github.com/Gabbajoe/GabbaSounds/releases) ·
[Fehler melden](https://github.com/Gabbajoe/GabbaSounds/issues) ·
[Build- und Release-Anleitung](https://github.com/Gabbajoe/GabbaSounds/blob/main/docs/RELEASING.md)

GitHub Actions prüft Änderungen und baut ZIPs. Versions-Tags veröffentlichen
geprüfte Releases; der CurseForge-Upload verwendet Projekt **1733615** und
ein separat hinterlegtes API-Secret. Das öffentliche Repository enthält die
fertigen OGGs; ungeschnittene WAV-Aufnahmen bleiben lokal. Details zu den
öffentlichen und lokalen Prüfungen stehen in der Release-Anleitung.

Version 1.0.0 für WoW Classic Era/Hardcore 1.15.9, Interface 11509.
Gesprochene Sounds für Zauberstab, Bogen/Armbrust, Gewehr und 15 Frost-/Feuerzauber
mit eigenen Aufnahmen je Zauber und Ergebnis. Das bisherige synthetische
Zauberstab-Magiepaket bleibt verfügbar.

## Installation und Auswahl

`GabbaSounds-1.0.0.zip` in `World of Warcraft/_classic_era_/Interface/AddOns/`
entpacken. Darin muss anschließend `GabbaSounds/GabbaSounds.toc` liegen.
Den WoW-Client vollständig schließen und neu starten, damit alle neuen
Sounddateien geladen werden. Das ZIP enthält 305 fertige OGGs (179 Aufnahmen
und 126 synthetische Sounds), ohne WAV-Quellen, Charakterdaten oder
Entwicklerwerkzeuge. Die Einstellungen bleiben pro Charakter gespeichert;
neue Charaktere starten wie bisher mit dem Magiepaket.

`/gws` oder `/gabbasounds` öffnet die Optionen. Für alle gesprochenen Sounds:

```text
/gws on
/gws spokenonly on
```

„Nur gesprochene Sounds“ wählt das automatische Sprachpaket und aktiviert
eigene und fremde Angriffe, alle Ergebnisarten sowie Magier-Casts. Die vom
Paket vollständig abgedeckten Originaldateien werden stummgeschaltet.
`/gws spokenonly off` lässt das Sprachpaket ausgewählt und gibt die eigenen
Stummschaltungen frei, sodass Originale und Aufnahmen zusammen hörbar werden.
„Originalgeräusche stummschalten“ und `/gws mute on|off` steuern die
Stummschaltung auch unabhängig davon für das ausgewählte Paket.

Das grinsende Blitz-Symbol erscheint auf der Minimap und in der Addonliste.
Linksklick schaltet das Addon an/aus, Rechtsklick öffnet die Optionen auch bei
deaktiviertem Addon. Ziehen verschiebt das Symbol am Kartenrand. Ein graues
Symbol zeigt den ausgeschalteten Zustand. Position und Sichtbarkeit werden
pro Charakter gespeichert; `/gws minimap on|off` zeigt bzw. versteckt es.

## Pakete und Hörproben

| Befehl | Auswahl |
| --- | --- |
| `/gws pack spoken` | Alle gesprochenen Waffen und Magierzauber automatisch |
| `/gws pack mage` / `magier` | Nur die 15 Magierzauber; Waffen bleiben unverändert |
| `/gws pack magic` | Synthetische Zauberstab-Sounds je Schadensart |
| `/gws pack wand` / `bow` / `gun` | Gesprochenes Einzelpaket für die jeweilige Waffe |
| `/gws pack frostbolt` / `frostblitz` | Nur Frostblitz |
| `/gws pack fireball` / `blizzard` / `iceblock` | Nur den genannten Magierzauber |

Alle Magier-Ordnernamen aus `spoken/mage/README.md` sind auch Paketnamen.
Die vollständigen IDs wie `spoken_fireball` werden ebenfalls akzeptiert.
`custom` und `eigene` wählen das automatische Sprachpaket. Der obere Button
im Optionsfenster wechselt die allgemeinen Pakete. Der Hörproben-Button
wechselt im automatischen Paket zwischen der eigenen Waffe, den drei
Waffengruppen und allen 15 Zaubern; im Magierpaket zwischen den 15 Zaubern.
Im Magiepaket wechselt er die Schadensart. Die Auswahl betrifft nur die
Vorschau. Im Kampf wird jede Quelle unabhängig ausgewertet.

```text
/gws test cast fireball
/gws test hit frostnova
/gws test crit pyroblast
/gws test graze
```

Diese Vorschauen funktionieren im automatischen Sprach- oder Magierpaket.
Einzelpakete behalten ihre eigene Zuordnung. `/gws test hit shadow` bleibt
als Schadensart-Vorschau im Magiepaket verfügbar. Hörproben gehen auch bei
deaktiviertem Addon und verändern keine Kampfzähler.

## Deine Aufnahmen

43 WAV-Quelldateien wurden in 179 unterschiedliche OGG-Clips geschnitten.

| Waffe / Zauber | Cast / Aktivieren | Normale Treffer | Crits |
| --- | ---: | ---: | ---: |
| Zauberstab | 0 | 16 | 3 |
| Bogen / Armbrust | 0 | 7 | 4 |
| Gewehr | 0 | 7 | 4 |
| Frostblitz | 2 | 7 | 7 |
| Frostnova | 3 | 5 | 4 |
| Blizzard | 2 | 5 | 0 |
| Kältekegel | 2 | 5 | 4 |
| Eisbarriere | 2 | 0 | 0 |
| Eisblock | 2 | 0 | 0 |
| Kälteeinbruch | 2 | 0 | 0 |
| Frostzauberschutz | 2 | 0 | 0 |
| Feuerball | 2 | 5 | 4 |
| Feuerschlag | 2 | 5 | 4 |
| Versengen | 2 | 5 | 4 |
| Pyroschlag | 2 | 5 | 4 |
| Flammenstoß | 2 | 5 | 4 |
| Druckwelle | 2 | 5 | 4 |
| Verbrennung | 2 | 0 | 0 |

Alle Waffen und Schadenszauber verwenden dieselben acht Miss- und acht
Teiltreffer-Sprüche aus `spoken/shared/`. `RESIST` und vollständiges `ABSORB`
verwenden ebenfalls den Miss-Pool. Blizzard hat in Classic Era keine Crits;
Schutz-/Aktivierungszauber verwenden ausschließlich ihre Cast-Aufnahmen.
Frostnova enthält drei Cast-Varianten. Frostblitz behält seine sieben
bisherigen normalen Treffer und sieben Crits zusätzlich zu den zwei neuen
Cast-Laute. Es wurden keine Varianten erfunden oder kopiert.

Die Quellen bleiben unverändert. `spoken/manifest.json` dokumentiert
SHA256-Werte, Schnittpositionen, Pausenschwellen, Lautstärken und Zuordnungen.
Neue Magier-Treffer werden bei Pausen ab 0,40 Sekunden getrennt; Cast-/Crit-
und gemeinsame Sprüche ab 0,60 Sekunden. So bleiben mehrteilige Phrasen
zusammen. Das bisherige kurze Zauberstab-„pew pew“ behält seine 0,08-Sekunden-
Trennung; andere Waffen-Laute ihre 0,20 Sekunden. Hauptlaute werden bei
−35 dB erkannt, leise Ränder bis −42 dB erhalten. Schnitte liegen in leisen
Pausen, überlappen nicht und erhalten kurze Blenden gegen Klicks. Lautstärken
sind vorsichtig angeglichen, Crits etwas kräftiger. Tonhöhe und Tempo bleiben
unverändert. WAV-Clips liegen unter `spoken/clips/`, WoW-Dateien unter `Sounds/`.

`spoken/Anhoeren.html` und `spoken/Anhoeren-v0.9.html` enthalten alle 179 Clips
als eigenständige Browser-Hörprobe. Zauber/Waffe und Kategorie können gewählt
und zufällig angehört werden; Internet oder Webserver sind nicht nötig.

## Casts, Treffer und Flächenzauber

Alle 83 Classic-Ränge der 15 aufgenommenen Zauber werden über IDs erkannt.
Normale Frostblitze, Feuerbälle, Versengen, Pyroschläge und Flammenstöße
spielen beim Cast-Beginn einen Sound. Sofortige Anwendungen derselben Zauber
spielen ihn beim Erfolg, wenn kein Start gemeldet wurde. Frostnova,
Kältekegel, Feuerschlag, Druckwelle und die fünf Schutz-/Aktivierungszauber
spielen beim erfolgreichen Wirken. Blizzard spielt beim Kanalbeginn.
Eigene Ereignisse kommen aus `UNIT_SPELLCAST_*`, fremde aus dem Kampflog;
doppelte eigene Unit-/Kampflog-Meldungen werden vermieden. Abgebrochene oder
fehlgeschlagene eigene Casts stoppen ihren noch laufenden Cast-Sound.
„Magier-Casts“ bzw. `/gws cast on|off` ist unabhängig von Treffer-/Crit-Sounds.

Cast und Einschlag nutzen getrennte Handles, sodass ein früherer Einschlag
den nächsten Cast nicht abschneidet. Pro Quelle ersetzt ein neuer Cast den
vorherigen Cast-Ausklang; ein neues Ergebnis den vorherigen Ergebnis-Ausklang.
Andere Quellen und Hörproben können gleichzeitig hörbar sein. Zufallswahl
vermeidet direkte Wiederholungen und nach Möglichkeit dieselbe Klangfamilie.
Gemeinsame Fehlerpools behalten ihren Verlauf auch bei Waffenwechseln.

Frostnova, Kältekegel, Flammenstoß und Druckwelle sammeln einen Trefferburst
für 0,08 Sekunden und spielen einen Ergebnis-Spruch pro Anwendung. Ein Crit
hat Vorrang vor normalen Treffern; Treffer vor Verfehlen. Blizzard spielt
nach seinem ersten Schadensburst einmal einen Treffer-/Fehler-Spruch und
wiederholt ihn nicht bei jedem Gegner oder Tick. Ein neuer Kanal startet
seine Zuordnung neu. Nachbrennen von Feuerball, Pyroschlag und Flammenstoß
spielt keine weiteren Treffer-Sprüche. Aura-Anwendungen spielen keine
zusätzlichen Sounds; NPCs und Begleiter lösen keine Magieraufnahmen aus.

Positive Treffer mit widerstandenem/geblocktem Schadensanteil können die
Teiltreffer-Sprüche verwenden; Crits haben Vorrang. Das ist eine gewählte
Addon-Zuordnung, kein Fernkampf-„Glancing Blow“. Mit `/gws graze off` springen
normale Treffer-Sounds ein. Null Schaden und negative Widerstandswerte werden
nicht als Teiltreffer umgedeutet. Vollständige Fehler wie MISS, BLOCK, IMMUNE,
EVADE oder DEFLECT verwenden gemeinsame Miss-Sprüche.

Fernkampf bleibt für `5019` (Zauberstab), `75` (Auto Shot), `2480` (Bogen),
`7919` (Armbrust) und `7918` (Gewehr) unterstützt. Waffe und Schadenstyp
werden aus Ausrüstung, Tooltip, Schaden und bekannten Schüssen erkannt;
Inspektionsanfragen sind nicht nötig. Bei unbekannten fremden Auto Shots
und stummen Bogen-/Gewehrdateien dienen Zauberstab-Laute als gesprochene
Reserve; die Waffe bleibt unbekannt. Sobald sie erkannt wird, gilt ihr
passendes Paket. Nahkampf und Jäger-Spezialschüsse haben keinen Ersatzsound.

## Originalgeräusche und Grenzen

Das automatische Sprachpaket deckt 27 Originaldateien der Magierzauber,
14 Bogen-/Armbrustdateien, sieben Gewehrdateien und acht Zauberstabdateien ab.
Vollständige Pools, eingeschaltetes Addon, Stummschaltung, alle Quellen und
alle fünf Haupt-Ergebnisarten sind erforderlich. Neue Magierzauber verlangen
auch eine aktive Cast-Option und gefüllte Cast-Pools. Blizzard benötigt
keinen Crit-Pool; reine Schutzzauber keine Treffer-/Crit-Pools. Frostblitz
behält seine bisherige Abdeckungsregel für Einschlag- und Fehlerpools.

**Die Stummschaltung wirkt global pro Sounddatei.** Magierzauber teilen
Vorbereitungs-, Abschuss- und Einschlagsdateien miteinander und mit anderen
Fähigkeiten. Auch nicht unterstützte Zauber, NPCs oder Jäger-Spezialschüsse
können deshalb gemeinsam genutzte Originalgeräusche verlieren. Einzelpakete
wählen ihre eigenen Dateien aus, können deren weitere Verwendungen aber
nicht trennen. Anzeige und `/gws status` nennen die vollständig abgedeckten
Gruppen, nicht jede weitere Verwendung einer gemeinsam genutzten Datei.

Originale werden einmal unter temporärer Stummschaltung vorgeladen;
anschließend bleibt genau eine eigene dauerhafte Stummschaltung pro Datei.
Paketwechsel, Ausschalten, Ausloggen und Wiedergabefehler geben ausschließlich
die eigenen Stummschaltungen frei. Fremde Addon-Stummschaltungen bleiben
bestehen. Nach einem Wiedergabefehler kann eine erfolgreiche Vorschau oder
explizites erneutes Aktivieren die gewählte Stummschaltung wieder aufnehmen.

Ersatzsounds für Treffer beginnen beim Kampflog-Ergebnis. Fremde Audiodateien
haben über PlaySoundFile keine räumliche Position oder entfernungsabhängige
Lautstärke. Der gewählte Kanal ist Soundeffekte (`SFX`) oder Gesamtlautstärke
(`Master`). `/gws channel sfx|master` wechselt ihn.

## Weitere Befehle und Entwicklung

`/gws on|off`, `/gws all on|off`, `/gws hit on|off`, `/gws crit on|off`,
`/gws miss on|off`, `/gws resist on|off`, `/gws absorb on|off`,
`/gws graze on|off`, `/gws cast on|off` und `/gws status` steuern Umfang und
Trefferarten oder zeigen den aktuellen Zustand.

Weitere Aufnahmen unter `spoken/mage/<zauber>/cast*.wav`, `hit*.wav` oder
`crit*.wav` ablegen. Die Zuordnungen stehen in `MageSpells.lua`; Quellen und
geprüfte IDs in `analysis/mage_spells.json`. Die Sounddaten wurden gegen
[Resonance v1.13.1](https://www.curseforge.com/wow/addons/resonance/files/8899894)
und die Rangtabellen gegen [WoWSims Classic](https://github.com/wowsims/classic/tree/master/sim/mage)
geprüft. Weitere Rang-/Soundquellen nennt `THIRD_PARTY_NOTICES.md`.

Python 3, NumPy und ffmpeg/ffprobe mit libvorbis werden benötigt:

```sh
python3 tools/import_spoken_library.py
python3 tools/validate_sounds.py --pack spoken
bash tests/run_tests.sh
python3 tools/build_package.py
```

Ohne die privaten WAV-Quellen im öffentlichen Checkout:

```sh
GABBA_RUNTIME_ONLY=1 bash tests/run_tests.sh
python3 tools/validate_sounds.py --pack all --runtime-only
python3 tools/build_package.py --output-dir dist
```

`--registry-only` aktualisiert die Bibliothekszuordnung und Browser-Vorschau
ohne neue Kodierung. `tools/generate_sounds.py` bleibt für das synthetische
Magiepaket zuständig. Der alte Einzelaufnahme-Importer überschreibt keine
Mehrdatei-Bibliothek. Die Prüfungen decken Original-Hashes, unabhängige Pools,
Phrasenschnitte, Kodierung, alle Ränge, Casts, Quelle/Paket/Kategorien,
AoE-Zusammenfassung, echte Frostblitz- und Magier-AoE-Kampflog-Ereignisse,
Stummschaltungsbesitz sowie UI-/Minimap-Interaktionen ab. WoW-APIs werden in
Tests simuliert; die tatsächliche Audioausgabe ist im Client zu beurteilen.

Beim Wechsel vom alten GabbaWandSounds den alten Addon-Ordner sichern und
entfernen, um doppelte Sounds zu vermeiden. Bei geschlossenem Client kann
eine alte per-Charakter-SavedVariables-Datei als GabbaSounds.lua übernommen
werden, falls noch keine neue existiert; unterstützte Einstellungen werden
validiert migriert. Eine vorhandene GabbaSounds.lua wird beibehalten.
