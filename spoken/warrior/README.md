# Krieger-Aufnahmen

Hier legst du die neuen WAV-Aufnahmen ab. Die Ordner sind vorbereitet;
Import, Schnitt und Einbindung der Kriegerfähigkeiten folgen nach den Aufnahmen.
Die bestehenden Nahkampf-Pakete bleiben für normale Waffenangriffe zuständig.

## Dateien und Mengen

Alle Pfade beziehen sich auf `GabbaSounds/spoken/warrior/`.

| Fähigkeit / Ereignis | Datei | Inhalt |
| --- | --- | --- |
| Sturmangriff / Charge | `charge/cast.wav` | 4 Aktivierungsrufe |
| Berserkerwut | `berserkerrage/cast.wav` | 4 Aktivierungsrufe |
| Blutrausch / Bloodrage | `bloodrage/cast.wav` | 4 Aktivierungsrufe |
| Todeswunsch | `deathwish/cast.wav` | 4 Aktivierungsrufe |
| Tollkühnheit | `recklessness/cast.wav` | 4 Aktivierungsrufe |
| Schlachtruf | `battleshout/cast.wav` | 4 Aktivierungsrufe |
| Schildwall | `shieldwall/cast.wav` | 4 Aktivierungsrufe |
| Spott / Taunt | `taunt/cast.wav` | 4 Aktivierungsrufe |
| Spöttischer Schlag / Mocking Blow | `mockingblow/hit.wav` | 6 normale Treffer |
| Spöttischer Schlag / Mocking Blow | `mockingblow/crit.wav` | 4 Crit-Sprüche |
| Wirbelwind | `whirlwind/hit.wav` | 6 normale Treffer |
| Wirbelwind | `whirlwind/crit.wav` | 4 Crit-Sprüche |
| **Du blockst** einen gegnerischen Angriff | `defense/block.wav` | 4 Abwehrreaktionen |
| **Du parierst** einen gegnerischen Angriff | `defense/parry.wav` | 4 Abwehrreaktionen |

Das sind **14 WAV-Dateien mit insgesamt 60 Varianten** für den vollständigen Plan.
Du kannst zunächst einzelne Fähigkeiten aufnehmen. Sturmangriff, Berserkerwut,
Blutrausch und Schlachtruf ergeben einen guten ersten Satz.

„Cast“ meint hier das Aktivieren, auch bei sofortigen Fähigkeiten.
Spott und Spöttischer Schlag haben eigene Ordner. Für Blutrausch verwenden wir
den englischen Namen **Bloodrage**, damit die Zuordnung eindeutig bleibt.

## Aktivierungsrufe: 4 Varianten pro Datei

| Datei | 1 | 2 | 3 | 4 |
| --- | --- | --- | --- | --- |
| `charge/cast.wav` | WUUUSCH! | Aus dem Weg! | Ich kooomme! | ATTACKE! |
| `berserkerrage/cast.wav` | GRRRRAAAH! | Keine Angst! | Jetzt erst recht! | WUUUUT! |
| `bloodrage/cast.wav` | Mein Blut kocht! | Mehr Wut! | Hrrrnnngh! | Ich dreh durch! |
| `deathwish/cast.wav` | Keine Gnade! | Jetzt wird's hässlich! | Alles oder nichts! | RAAAARGH! |
| `recklessness/cast.wav` | Alle Sicherungen raus! | VOLLGAS! | Ohne Bremse! | Jetzt eskaliert's! |
| `battleshout/cast.wav` | Auf in den Kampf! | Für die Truppe! | RAAAAH! | Los, ihr Helden! |
| `shieldwall/cast.wav` | Hier kommt keiner durch! | Nicht mit mir! | MAUER! | Ich halte stand! |
| `taunt/cast.wav` | DU! HIERHER! | Schau mich an! | Ich bin dein Problem! | Na, komm! |

## Normale Treffer: 6 Varianten pro Datei

| Datei | 1 | 2 | 3 | 4 | 5 | 6 |
| --- | --- | --- | --- | --- | --- | --- |
| `mockingblow/hit.wav` | Pah! | Na, du! | Hier spielt die Musik! | Klatsch! | Frechheit! | Schau her! |
| `whirlwind/hit.wav` | Wusch-wusch! | Schwirrr! | Huiiii! | Surr-surr! | Wuuusch! | Rundherum! |

## Crits: 4 Varianten pro Datei

| Datei | 1 | 2 | 3 | 4 |
| --- | --- | --- | --- | --- |
| `mockingblow/crit.wav` | Frech und kräftig! | Die hat gesessen! | Jetzt kennste mich! | Respekt, bitte! |
| `whirlwind/crit.wav` | FLEISCHWOLF! | Alle einmal drehen! | RUNDUMSCHLAG! | Hier wird gemäht! |

## Eigene Abwehr: 4 Varianten pro Datei

| Datei | 1 | 2 | 3 | 4 |
| --- | --- | --- | --- | --- |
| `defense/block.wav` | Klonk! | Abgeblockt! | Nicht durch meinen Schild! | Nö! |
| `defense/parry.wav` | Kling! | Abgewehrt! | Zu langsam! | Netter Versuch! |

Diese Aufnahmen sind für erfolgreiche Abwehr **durch deinen Charakter** geplant.
Wenn ein Gegner deinen Angriff abwehrt oder dein Angriff verfehlt, bleiben
die vorhandenen gemeinsamen Aufnahmen unter `../shared/miss.wav` und
`../shared/graze.wav` vorgesehen. Die müssen nicht kopiert oder neu aufgenommen werden.
Für Wirbelwind planen wir eine Ergebnis-Reaktion pro Anwendung; für Block und
Parieren eine gemeinsame Mindestpause gegen zu viele gleichzeitige Rufe.

## So aufnehmen

- Alle Varianten einer Zeile **nacheinander in die angegebene WAV-Datei** sprechen.
- Zwischen Varianten etwa **eine Sekunde echte Stille** lassen, ebenso am Anfang und Ende.
- Innerhalb eines Spruchs natürlich sprechen; zusammengesetzte Laute wie
  „Wusch-wusch!“ gehören als eine Variante zusammen.
- Häufige Treffer und Abwehrreaktionen kurz halten; große Aktivierungsrufe dürfen länger sein.
- WAV mit **44,1 oder 48 kHz**, Mono oder Stereo. Kein Hall, keine Musik und keine Übersteuerung.
- Die Texte sind Vorschläge. Eigene Laute und Sprüche sind willkommen.

Die vollständigen Aufnahmen bleiben erhalten und werden später in einzelne
Spiel-Clips geschnitten. Die höheren Noggenfogger-Varianten entstehen beim
späteren Audiobau automatisch; dafür brauchst du nichts zusätzlich einzusprechen.
WAVs bleiben durch `.gitignore` lokal. Platzhalter-WAVs sind nicht nötig.
