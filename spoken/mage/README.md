# Magier-Aufnahmen

Pro Zauber gibt es einen eigenen Ordner. Mehrere Varianten dürfen in einer
WAV-Datei liegen: etwa eine Sekunde Stille zwischen den Lauten/Sprüchen lassen.
Die Quelldateien bleiben beim späteren Schnitt unverändert.

- `cast.wav`: Laute/Sprüche beim Wirken bzw. Aktivieren.
- `hit.wav`: normale Treffer bei Schadenszaubern.
- `crit.wav`: kritische Treffer bei Schadenszaubern.
- `../shared/miss.wav` und `../shared/graze.wav`: gemeinsame Fehler-/Teiltreffer-Aufnahmen.

Alle 15 Zauber sind ab Version 1.0.0 im automatischen Sprachpaket oder
Magierpaket zugeordnet. Die aufgenommenen Varianten sind importiert.
Für weitere Takes werden `cast*.wav`, `hit*.wav` und `crit*.wav` erkannt.
Nach Änderungen müssen Import, Audioprüfung, Paketbau und Installation
wiederholt werden. Die Browser-Vorschau liegt unter `previews/spoken/index.html` im Addon-Hauptordner.
Flächenzauber sprechen einmal pro Anwendung bzw. beim ersten Blizzard-Tick,
nicht pro Ziel oder jedem weiteren Tick. Frostnova enthält drei Casts;
Frostblitz behält die sieben bisherigen Treffer- und Crit-Varianten.

Pro Schadenszauber sind fünf normale Treffer-Laute und vier Crit-Laute
vorgesehen; bei Blizzard bleibt der Crit-Pool leer. Jede Spalte kommt in
ihre eigene WAV-Datei.

| Zauber | Ordner | Cast / Aktivieren | Hit: 5 Varianten | Crit: 4 Varianten |
| --- | --- | --- | --- | --- |
| Frostblitz | `frostbolt/` | Frrr… / Kälte kommt! | Pschiu! / Eis geliefert! / Tschikk! / Frripp! / Pschack! | Tiefgefroren! / Eiskalt erwischt! / Direkt aus dem Eisfach! / Frostbeule deluxe! |
| Frostnova | `frostnova/` | Stehen bleiben! / Füße still! | Festgefroren! / Bleib da! / Krisch! / Pling! / Frost – stopp! | Schockgefrostet! / Eis bis zum Hals! / Bewegung gestrichen! / Fest wie ein Eiswürfel! |
| Blizzard | `blizzard/` | Schneesturm! / Winterdienst! | Schneetreffer! / Brrr! / Psch-psch! / Frrsch! / Schnee ins Gesicht! | — (keine Crits in Classic Era) |
| Kältekegel | `coneofcold/` | Einmal pusten! / Kalte Dusche! | Fuuusch! / Brrr – ins Gesicht! / Pfff! / Frruuu! / Eisiger Wind! | Eisatem deluxe! / Volle Frostladung! / Kalt erwischt! / Gefrierbrand! |
| Eisbarriere | `icebarrier/` | Gut eingepackt! / Schutzschicht drauf! | — | — |
| Eisblock | `iceblock/` | Bin im Kühlschrank! / Bitte auftauen! | — | — |
| Kälteeinbruch | `coldsnap/` | Zweite Eiszeit! / Nochmal von vorn! | — | — |
| Frostzauberschutz | `frostward/` | Frostschutz drauf! / Kälte bleibt draußen! | — | — |
| Feuerball | `fireball/` | Fuuusch… / Wird gleich heiß! | Paff! / Schön angebraten! / Fwoop! / Pschumm! / Flamme geliefert! | Voll durchgegrillt! / Extra knusprig! / Außen kross, innen heiß! / Das hat gesessen! |
| Feuerschlag | `fireblast/` | Zack – Feuer! / Heiß kommt’s! | Puff! / Finger verbrannt! / Zapp! / Patsch! / Heiß erwischt! | Bumm! / Röstaroma! / Voll angeflammt! / Jetzt raucht’s! |
| Versengen | `scorch/` | Kurz anbraten! / Zisch… | Sss! / Angekokelt! / Ziss! / Fssst! / Kurz geröstet! | Kross geworden! / Gut durch! / Schön verkohlt! / Röststufe maximal! |
| Pyroschlag | `pyroblast/` | Große Flamme kommt! / Jetzt wird’s heiß! | Kabumm! / Feuerpost! / Fwooom! / Badumm! / Flamme im Anflug! | Ofen auf Anschlag! / Grillmeister! / Feuerwerk im Gesicht! / Das war die große Flamme! |
| Flammenstoß | `flamestrike/` | Bodenheizung! / Grillparty! | Fwooom! / Heiße Füße! / Pschaa! / Wusch-baff! / Boden brennt! | Alles knusprig! / Voll auf die Flamme! / Fußboden auf Lava! / Grillparty eröffnet! |
| Druckwelle | `blastwave/` | Hitzewelle! / Abstand bitte! | Wumm! / Heiße Luft! / Bwoah! / Waff! / Einmal durchgepustet! | Backofenexplosion! / Voll weggebrutzelt! / Druck ordentlich drauf! / Hitzeschock! |
| Verbrennung | `combustion/` | Alles auf Flamme! / Grillmodus an! | — | — |

Bei sofortigen Zaubern meint „Cast“ das Aktivieren. Schutzzauber und
Verbrennung verursachen selbst keinen direkten Treffer: dafür genügt cast.wav.
Blizzard hat in Classic Era keine kritischen Treffer. Bei Flammenstoß sind
Crit-Sprüche für den unmittelbaren Treffer gedacht, nicht für die späteren
Schadensticks. Flächenzauber-Sprüche sollten künftig pro Anwendung begrenzt
werden, damit nicht jedes Ziel oder jeder Tick gleichzeitig spricht.

Quelle für Blizzard: https://www.wowhead.com/classic/de/spell=10/blizzard

Bei Eisblock, Eisbarriere und anderen reinen Schutz-/Aktivierungszaubern
reicht `cast.wav`; sie brauchen keine Treffer- oder Crit-Dateien.
