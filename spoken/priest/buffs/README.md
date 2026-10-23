# 💛 Priester-Buffwarnungen: persönlich und neutral

Automatische Warnungen gibt es für **alle Charaktere mit Klasse Priester**.
**Bobselinchen** bekommt ihre persönlichen Aufnahmen aus diesen Ordnern.
Andere Priester bekommen ausschließlich das [neutrale Paket ohne Namen](generic/README.md).
Die Auswahl richtet sich automatisch nach deinem eigenen Charakter, nicht nach
Namen in der Gruppe. Fehlt ein persönlicher Clip, darf Bobselinchen den neutralen
Clip verwenden. Andere Priester bekommen niemals Bobselinchens persönliche Clips.
Die Anzeige und die Aufnahme sind lokal. Es wird nichts in den Gruppen- oder
Raidchat geschickt. Einstellungen: `/gws buffs` oder „Buffwarnungen“ im Addon.

## Persönliches Paket für Bobselinchen: acht Aufnahmen

Alle Pfade beginnen bei `GabbaSounds/spoken/priest/buffs/`.

| Buff | Datei: höchstens 2 Minuten übrig | Spruch | Datei: fehlt / abgelaufen | Spruch |
| --- | --- | --- | --- | --- |
| 💪 Seelenstärke / Ausdauer | `fortitude/expiring.wav` | „Bobselinchen! Die Ausdauer hält nur noch zwei Minuten!“ | `fortitude/missing.wav` | „Die Ausdauer fehlt! Einmal Seelenstärke für die Truppe!“ |
| 🧘 Göttlicher Willen / Willenskraft | `spirit/expiring.wav` | „Die Willenskraft schwindet! Noch zwei Minuten!“ | `spirit/missing.wav` | „Ohne Willenskraft wird das nichts! Bitte nachbuffen!“ |
| 🔥 Inneres Feuer | `innerfire/expiring.wav` | „Bobselinchen! Dein inneres Feuer wird gleich zur Glut!“ | `innerfire/missing.wav` | „Inneres Feuer ist aus! Bitte einmal neu anzünden!“ |
| 🛡️ Furchtzauberschutz / Fear Ward | `fearward/expiring.wav` | „Der Furchtschutz läuft in zwei Minuten aus!“ | `fearward/missing.wav` | „Furchtschutz fehlt! Gleich wird wieder panisch gerannt!“ |

`missing.wav` gilt sowohl bei ausgelaufenem Buff als auch bei einem fehlenden
Buff auf einem neu erreichbaren Gruppenmitglied. Deshalb bitte **„fehlt“** statt
ausschließlich „ist gerade abgelaufen“ sagen. Kein Name eines Gruppenziels:
Eine Aufnahme fasst mehrere betroffene Mitglieder zusammen.

Je Datei einen vollständigen Spruch, gern 1–4 Sekunden, mit kurzer Ruhe davor
und danach. WAV mit 44,1 oder 48 kHz, Mono oder Stereo, ohne Übersteuerung.
Die Ordner sind angelegt; keine leeren WAV-Dateien als Platzhalter erstellen.
Aufnahmen bleiben lokal und kommen nicht in Git oder Release-ZIPs.

## Wer wird geprüft?

- **Ausdauer:** du selbst und alle Klassen in deiner Gruppe / deinem Raid.
- **Willenskraft:** nur bekannte Mana-Klassen; keine Krieger oder Schurken.
  Druiden zählen auch in Tiergestalt.
- **Inneres Feuer:** ausschließlich du selbst.
- **Furchtzauberschutz:** eigene Option, **standardmäßig aus**; nur wenn der
  Zwergenzauber gelernt wurde. Aktiviert gilt die Prüfung für dich und erreichbare
  Gruppenmitglieder aller Klassen. Situativ anschalten, wenn ihr ihn braucht.

Nur gelernte Buff-Kategorien zählen. Gruppenmitglieder müssen leben, verbunden
und sichtbar sein und sich in **bestätigter Buff-Reichweite** befinden. Unbekannte
Klasse oder unbekannte Reichweite lösen keinen Alarm aus. Gebete und andere
Priester zählen als gültige Buffs. Nachbuffen macht die jeweilige Warnung wieder
scharf; gleichbleibende Zustände werden nicht laufend wiederholt.

Alle acht persönlichen Aufnahmen sind importiert, einschließlich Noggenfogger-
Varianten. Fehlt eine passende Aufnahme, gibt es **nur Textwarnungen**. Die vorhandenen
Magier-Aufnahmen werden nicht als Ersatz benutzt. Läuft auch das alte Gabba-Addon,
überlässt dessen Priester-Modul diese persönlichen Warnungen GabbaSounds, damit
kein Priester doppelte Alarme bekommt. Dies gilt auch, wenn du die
GabbaSounds-Buffwarnungen ausschaltest: Das alte Modul springt dann nicht ein.

## Nach der Aufnahme

```sh
python3 tools/import_buff_alerts.py --priest
```

Importiert die acht Aufnahmen und ihre Noggenfogger-Varianten. Danach die fertigen
Addon-Dateien installieren und WoW vollständig neu starten.

[Zurück zu den Priester-Schadenszaubern](../README.md)
