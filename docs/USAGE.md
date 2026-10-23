# GabbaSounds – Bedienung und Soundpakete

[Zurück zur README](../README.md) · [Entwicklung und Releases](RELEASING.md)

Diese Anleitung beschreibt **GabbaSounds 1.4.0** für Classic Era /
Hardcore 1.15.9, Interface 11509. Veröffentlichungen und Paketbau sind in der
[Release-Anleitung](RELEASING.md) dokumentiert.

## Noggenfogger-Stimme (neu für 1.2.0)

Mit dem Schrumpfeffekt des Noggenfogger-Elixiers klingen deine eigenen
GabbaSounds automatisch **vier Halbtöne höher**. Die Spieldauer bleibt gleich.
Das gilt für alle gesprochenen Pakete, Magier-Casts und synthetische Magie.
Fremde Angriffe behalten ihre normale Tonhöhe. Skelettform und langsamer Fall
allein aktivieren den Effekt nicht. Nach Ablauf oder Entfernen des Schrumpf-Buffs
werden wieder die normalen Dateien verwendet, auch nach Login oder Reload.

Die Option **„Noggenfogger: beim Schrumpfen höher“** ist pro Charakter
standardmäßig an. Abschalten mit `/gws noggenfogger off`, wieder einschalten
mit `/gws noggenfogger on`. `/gws status` zeigt den Zustand; die Hörproben im
Addon folgen deinem Schrumpfeffekt. Fehlt eine höhere Datei, versucht das
Addon den normalen Sound und meldet einmalig den nötigen vollständigen Neustart.

Die Erkennung verwendet die sprachunabhängige
[Schrumpf-Zauber-ID 16595](https://www.wowhead.com/spell=16595/noggenfogger-elixir).
Die höheren Dateien liegen unter `Sounds/noggenfogger/`; `noggenfogger/manifest.json`
verknüpft sie mit den Originalen. Neu bauen mit `python3 tools/build_noggenfogger.py`
(FFmpeg mit Rubber Band, libvorbis und NumPy). Die Originaldateien bleiben erhalten.

## Minibobsels Magier-Buffwarnungen (neu für 1.3.0)

`/gws buffs` oder der Button „Buffwarnungen“ öffnet die Einstellungen. Nur für
**Minibobsel mit Klasse Magier**: Arkane Intelligenz/Brillanz bei dir und den
Mana-Klassen in deiner Gruppe oder deinem Raid sowie eine eigene Frost-, Eis-
oder Magierrüstung. Verschiedene Ränge und Buffs anderer Magier zählen.

Eine lokale Bildschirmwarnung kommt bei **höchstens zwei Minuten Restzeit** und
erneut beim fehlenden/abgelaufenen Buff, jeweils einmal pro Zustand. Nachbuffen
aktiviert sie wieder. Sprachausgabe hat getrennte Aufnahmen für die beiden
Stufen und die beiden Kategorien; Gruppenmeldungen werden zusammengefasst.
Es wird kein Chat an andere Spieler gesendet.

Keine Prüfung ungelernter Buff-Kategorien, toter/offline/unsichtbarer Mitglieder
oder während du tot/im Flugtaxi bist. Gruppenmitglieder brauchen eine bekannte
passende Klasse und bestätigte Buff-Reichweite; unbekannte Werte werden übersprungen. Nach Ladebildschirmen fünf Sekunden Pause.
Schalter für das Modul, Intelligenz, Rüstung und Ton sind standardmäßig an und
pro Charakter gespeichert. Das ganze Addon ausschalten stoppt auch diese Warnungen.
Vier Warnaufnahmen und vier höhere Noggenfogger-Varianten sind enthalten. Mehr zu Aufnahme,
Hörproben und Import: [Aufnahmevorlagen](../spoken/mage/buffs/README.md).

## Priester-Buffwarnungen

`/gws buffs` öffnet auf einem Priester die Priester-Optionen. Automatische
Warnungen erhalten **alle Charaktere mit Klasse Priester**: Seelenstärke/Ausdauer
für alle Klassen, Göttlicher Willen nur für Mana-Klassen (keine Krieger/Schurken),
Inneres Feuer nur für dich selbst. **Furchtzauberschutz** ist ein eigener Schalter,
standardmäßig aus, und setzt den gelernten Zwergenzauber voraus. Eingeschaltet
wird er für dich und erreichbare Gruppenmitglieder aller Klassen geprüft.
Gebete, verschiedene Ränge und Buffs anderer Priester zählen.

Dieselben Reichweiten-, Lebensstatus- und Ladepausen-Regeln wie beim Magier
verhindern Meldungen für entfernte oder noch unbekannte Gruppenmitglieder.
Jede Kategorie hat getrennte Warnungen bei höchstens zwei Minuten Restzeit
und bei fehlendem/abgelaufenem Buff. Die acht gesprochenen Warnungen sind enthalten,
auch höher für Noggenfogger. Fehlt eine passende Aufnahme, bleibt die Warnung
rein visuell. Das alte Gabba-Priestermodul überlässt seine Warnungen diesem
Modul für alle Priester, wenn es geladen ist; auch bei ausgeschalteten Warnungen
springt dann nicht plötzlich das alte Modul ein.

Die Hörproben verwenden automatisch dieselben Aufnahmen wie die Warnungen auf
deinem Charakter. Es gibt keine Auswahl zwischen verschiedenen Stimmen.
Einstellungen bleiben pro Charakter gespeichert.

[Aufnahmevorlagen](../spoken/priest/buffs/generic/README.md) ·
[Aufnahmeplan für Priester-Schadenszauber](../spoken/priest/README.md)

## Priester-Schadenszauber

`/gws pack priest` oder `priester` spielt 28 Aufnahmen für Gedankenschlag,
Schattenwort: Schmerz, Göttliche Pein und Heilige Nova. Sie gehören auch zu
`/gws pack spoken`. Gedankenschlag/Pein/Nova haben je vier normale und vier
Crit-Aufnahmen. Schmerz hat vier Aufnahmen beim Auftragen/Auffrischen, keine
Crits und keine zusätzlichen DoT-Tick-Reaktionen. Heilige Nova fasst Schadensziele
zusammen, bevorzugt Crits und ignoriert Heilung. Miss-/Resist-/Absorb- und
Teiltreffer-Sprüche sind gemeinsam. Quellenfilter, Ergebnisschalter und
Noggenfogger gelten wie bei den anderen Zaubern. Keine eigenen Cast-Aufnahmen.
Bei vollständigen Ersatzpools kann „Nur gesprochene Sounds“ die verifizierten
nativen Dateien stummschalten; diese umfassen auch teils geteilte Cast-Sounds.
[Aufnahmen, Hörproben und Import](../spoken/priest/README.md).

## Kräuter-Alarm über Tooltips

`/gws herbs` oder „Kräuter-Alarm“ in den Optionen. Auf dem eigenen Kräuterkundler
spielt Gromsblut oder Schwarzer Lotus deine jeweilige Aufnahme, sobald du mit der
Maus über den echten Kräuterpunkt auf der Minimap oder das Kraut in der Spielwelt
fährst. Deutsche und englische Namen zählen. Gespeicherte Kartenpins,
Taschengegenstände und Chatlinks lösen keine Meldung aus.

Standardmäßig an, pro Charakter gespeichert, mindestens 30 Sekunden Abstand
pro Kraut und keine Wiederholung beim Stehenlassen der Maus. Kein automatischer
Suchlauf. Höhere Noggenfogger-Varianten sind enthalten; Vorschauen gehen auch ohne
Kräuterkunde. `/gws herbs on|off` schaltet den Alarm; `/gws herbs gromsblood` und
`/gws herbs blacklotus` spielen die Hörproben. Tooltip-Erkennung und Audio wurden
im Classic-Client geprüft; der temporäre Einsteigerkräuter-Test ist entfernt. [Aufnahmen und Details](../spoken/herbalism/README.md).

## Installation und Auswahl

`GabbaSounds-1.4.0.zip` in `World of Warcraft/_classic_era_/Interface/AddOns/`
entpacken. Darin muss anschließend `GabbaSounds/GabbaSounds.toc` liegen.
Den WoW-Client vollständig schließen und neu starten, damit alle neuen
Sounddateien geladen werden. Das ZIP enthält 790 fertige OGGs: 269 Sprachaufnahmen,
126 synthetische Sounds und 395 höhere Noggenfogger-Varianten, ohne WAV-Quellen, Charakterdaten oder
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
| `/gws pack melee` / `nahkampf` | Nur normale Nahkampf-Waffenangriffe, automatisch |
| `/gws pack blade` / `blunt` / `dagger` / `fist` | Nur die gewählte Nahkampf-Waffengruppe |
| `/gws pack magic` | Synthetische Zauberstab-Sounds je Schadensart |
| `/gws pack wand` / `bow` / `gun` | Gesprochenes Einzelpaket für die jeweilige Waffe |
| `/gws pack frostbolt` / `frostblitz` | Nur Frostblitz |
| `/gws pack fireball` / `blizzard` / `iceblock` | Nur den genannten Magierzauber |

Alle Magier-Ordnernamen aus `spoken/mage/README.md` sind auch Paketnamen.
Die vollständigen IDs wie `spoken_fireball` werden ebenfalls akzeptiert.
`custom` und `eigene` wählen das automatische Sprachpaket.

Das Konfigurationsfenster hat eine feste Navigation links und zeigt immer nur
einen Bereich. Es passt sich bei Bedarf der verfügbaren Bildschirmgröße an und
lässt sich verschieben. Schließen oder Escape schließt das ganze Fenster.

| Bereich | Inhalt |
| --- | --- |
| Allgemein | Paket direkt aus der Liste auswählen, Originalsounds, Trefferarten, Magier-Zauberbeginn, Kanal, Noggenfogger und Minimap-Symbol |
| Waffen | Zauberstab, Bogen/Armbrust, Gewehr und vier Nahkampfgruppen |
| Magier | Alle 15 Zauber mit Treffer-, Crit- und Cast-Hörproben, soweit vorhanden |
| Priester | Vier Schadenszauber mit ihren Treffer- und Crit-Hörproben; keine geliehenen Magier-Casts |
| Zauberstab-Sounds | Synthetische Zauberstab-Laute je Schadensart |
| Buffwarnungen | Magier/Priester auswählen, Optionen einstellen und Warnungen für zwei Minuten oder fehlende Buffs anhören |
| Kräuter-Alarm | Tooltip-Alarm für Gromsblut und Schwarzen Lotus mit Hörproben |

In den Soundbereichen wählst du links die Waffe oder den Zauber und hörst rechts
die gewünschten Varianten. Längere Listen haben Zurück/Weiter und unterstützen
das Mausrad. Fehlende oder ungeeignete Varianten sind ausgegraut, etwa Crits bei
Schattenwort: Schmerz. Die Clip-Anzahlen stehen direkt bei den Hörproben.

**Anhören ändert das aktive Paket nicht.** Erst „Nur dieses Paket aktivieren“
oder die Paketauswahl unter Allgemein wechselt die Kampf-Sounds. Die normalen
Waffen-/Zauber-Zuordnungen werden weiterhin pro Quelle ausgewertet.
`/gws herbs` und `/gws buffs` öffnen direkt den zugehörigen Bereich im selben
Fenster. Die zuletzt geöffnete Seite bleibt beim erneuten Öffnen ausgewählt.
Es verwendet wie das GabbaAddon die normale Fensterebene: andere Fenster können
durch Anklicken davor liegen.

Unter Buffwarnungen kannst du auf jedem Charakter zwischen Magier und Priester
wechseln. Die Hörproben verwenden die Aufnahmen für deinen Charakter.
Automatische Priester-Warnungen gibt es nur auf Priestern; Magier-Warnungen
bleiben auf Minibobsel beschränkt. Priesterwarnungen enthalten Seelenstärke,
Willenskraft, Inneres Feuer und Furchtzauberschutz, jeweils für zwei Minuten
Restzeit und fehlenden Buff. Furchtzauberschutz bleibt optional und setzt den
gelernten Zauber voraus.

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

58 WAV-Quelldateien wurden in 247 unterschiedliche Angriffsclips geschnitten.
Mit Buffwarnungen und den beiden Kräuter-Aufnahmen enthält das Paket insgesamt
269 Sprachclips, jeweils mit einer höheren Noggenfogger-Variante.

| Waffe / Zauber | Cast / Aktivieren | Normale Treffer | Crits |
| --- | ---: | ---: | ---: |
| Zauberstab | 0 | 16 | 3 |
| Bogen / Armbrust | 0 | 7 | 4 |
| Gewehr | 0 | 7 | 4 |
| Schwerter / Äxte | 0 | 6 | 4 |
| Streitkolben / Stäbe | 0 | 6 | 4 |
| Dolche | 0 | 6 | 4 |
| Faustwaffen / unbewaffnet | 0 | 6 | 4 |
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
| Gedankenschlag | 0 | 4 | 4 |
| Schattenwort: Schmerz | 0 | 4 | 0 |
| Göttliche Pein | 0 | 4 | 4 |
| Heilige Nova | 0 | 4 | 4 |

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

Die [Browser-Hörproben](https://gabbajoe.github.io/GabbaSounds/) sind direkt online
abspielbar. Für die Offline-Nutzung verlinkt `previews/index.html` dieselben Player. `previews/spoken/index.html`
enthält die 247 Angriffsclips; `previews/buffs/` vier Magier- und acht Priester-Buffwarnungen,
`previews/herbalism/` die beiden Kräuter-Alarme, `previews/melee/` die Nahkampf-Pakete und
`previews/magic/` die synthetischen Sounds. `previews/priest/` bietet die Priester-Angriffsclips und gemeinsamen Fehlschläge. Die kleinen HTML-Seiten sind im Repo
enthalten und laden OGGs aus `Sounds/`, ohne Internet oder Webserver. Lade dafür
das vollständige Repository herunter. `python3 tools/build_previews.py` baut
die Seiten ohne private WAV-Quellen neu.

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
„Magier: Sound beim Zauberbeginn“ bzw. `/gws cast on|off` ist unabhängig von Treffer-/Crit-Sounds.

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
passendes Paket. Jäger-Spezialschüsse haben keinen Ersatzsound.

## Normale Nahkampf-Angriffe

Auf Wunsch von **Tsukimo** gibt es vier Waffenpakete für `SWING_DAMAGE` und
`SWING_MISSED`: Schwerter/Äxte, Streitkolben/Stäbe, Dolche und Faustwaffen/unbewaffnet.
Haupt- und Nebenhand werden über die sichtbare Ausrüstung getrennt erkannt.
Klassenfähigkeiten, Begleiter, NPCs, Stangenwaffen, Angelruten und Gestaltangriffe
sind nicht enthalten. Eigene Druiden in Gestalt und fremde sichtbare Druiden
werden ausgelassen, weil deren Gestaltangriff nicht der ausgerüsteten Waffe entspricht.
Bei unsichtbaren fremden Spielern ist keine Gestalterkennung möglich. Unbekannte
fremde Waffen verwenden bei vollständiger Stummschaltung Klingen-Laute als neutrale
Reserve; diese Auswahl wird nicht als erkannte Waffenart gespeichert.

Streifschläge und positive teilweise geblockte/widerstandene Treffer nutzen den
Teiltreffer-Pool. Crits haben Vorrang. Miss, Ausweichen, Parieren und vollständig
geblockte Angriffe nutzen die gemeinsamen Miss-Sprüche. Normale Treffer schneiden
laufende Crit-/Fehlschlag-/Teiltreffer-Sprüche nicht ab. Ein Crit darf einen normalen
oder Fehler-Sound ersetzen; weitere Crits warten nicht in einer Warteschlange,
sondern werden während eines laufenden Crit-Spruchs ausgelassen.

Die Mindestpause für normale Nahkampf-Reaktionen beträgt standardmäßig **0,25 s**
pro Spieler, gemeinsam für beide Hände. Der Optionsbutton wechselt zwischen
0 / 0,25 / 0,5 / 0,75 / 1 s; `/gws meleeinterval 0.5` erlaubt Werte von 0 bis 2 s.
Die 40 neuen Clips werden aus acht WAVs importiert. `spoken/melee/cuts.json`
speichert die überprüften Schnittgrenzen samt Quellhash; eine geänderte Aufnahme
muss vor erneutem Import geprüft werden. `--melee-only` erhält alle bisherigen Clips.

## Originalgeräusche und Grenzen

Das automatische Sprachpaket deckt 27 Originaldateien der Magierzauber,
14 Bogen-/Armbrustdateien, sieben Gewehrdateien, acht Zauberstabdateien und
301 Nahkampfdateien ab. Die Nahkampf-Stummschaltung verlangt das automatische
Gesamt- oder Nahkampf-Paket mit allen vier gefüllten Waffenbanken und aktiven
Teiltreffer-Sprüchen. Einzelne Nahkampf-Pakete lassen Originale hörbar, da
Schwingen/Parieren von mehreren Waffengruppen verwendet werden.
Vollständige Pools, eingeschaltetes Addon, Stummschaltung, alle Quellen und
alle fünf Haupt-Ergebnisarten sind erforderlich. Neue Magierzauber verlangen
auch eine aktive Cast-Option und gefüllte Cast-Pools. Blizzard benötigt
keinen Crit-Pool; reine Schutzzauber keine Treffer-/Crit-Pools. Frostblitz
behält seine bisherige Abdeckungsregel für Einschlag- und Fehlerpools.

**Die Stummschaltung wirkt global pro Sounddatei.** Magierzauber teilen
Vorbereitungs-, Abschuss- und Einschlagsdateien miteinander und mit anderen
Fähigkeiten. Auch nicht unterstützte Zauber, NPCs, Nahkampf-Klassenfähigkeiten oder Jäger-Spezialschüsse
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

`--melee-only` importiert ausschließlich die Nahkampf-Aufnahmen und bewahrt die
bisherigen Fernkampf-/Magierclips. `--registry-only` aktualisiert die Bibliothekszuordnung und Browser-Vorschau
ohne neue Kodierung. `tools/generate_sounds.py` bleibt für das synthetische
Magiepaket zuständig. Der alte Einzelaufnahme-Importer überschreibt keine
Mehrdatei-Bibliothek. Die Prüfungen decken Original-Hashes, unabhängige Pools,
Phrasenschnitte, Kodierung, alle Ränge, Casts, Quelle/Paket/Kategorien,
Haupt-/Nebenhand, Streifschläge, Dual-Wield-Wiedergabe, echte Nahkampf-Ergebnisse,
AoE-Zusammenfassung, echte Frostblitz- und Magier-AoE-Kampflog-Ereignisse,
Stummschaltungsbesitz sowie UI-/Minimap-Interaktionen ab. WoW-APIs werden in
Tests simuliert; die tatsächliche Audioausgabe ist im Client zu beurteilen.

Beim Wechsel vom alten GabbaWandSounds den alten Addon-Ordner sichern und
entfernen, um doppelte Sounds zu vermeiden. Bei geschlossenem Client kann
eine alte per-Charakter-SavedVariables-Datei als GabbaSounds.lua übernommen
werden, falls noch keine neue existiert; unterstützte Einstellungen werden
validiert migriert. Eine vorhandene GabbaSounds.lua wird beibehalten.
