# 🧙 Minibobsels gesprochene Buffwarnungen

Nur ein Charakter namens **Minibobsel** mit der Klasse **Magier** bekommt
automatische Warnungen. Die große Bildschirmwarnung und deine Aufnahme sind
lokal; es wird nichts in den Gruppen- oder Raidchat geschickt.

## Vier Aufnahmen

Je Datei **einen vollständigen Spruch** aufnehmen. Die beiden Warnstufen bekommen
unterschiedliche Aufnahmen:

| Pfad ab `GabbaSounds/` | Zeitpunkt | Beispiel zum Einsprechen |
| --- | --- | --- |
| `spoken/mage/buffs/intellect/expiring.wav` | Int-Buff hat höchstens 2 Minuten Restzeit | „Minibobsel! Die Intelligenz läuft gleich ab!“ |
| `spoken/mage/buffs/intellect/missing.wav` | Int-Buff fehlt oder ist abgelaufen | „Alarm! Ohne Intelligenz müssen wir selber denken! Nachbuffen!“ |
| `spoken/mage/buffs/armor/expiring.wav` | Eigener Rüstungsbuff hat höchstens 2 Minuten Restzeit | „Dein magischer Mantel löst sich gleich auf!“ |
| `spoken/mage/buffs/armor/missing.wav` | Eigener Rüstungsbuff fehlt oder ist abgelaufen | „Minibobsel! Du stehst ohne Rüstung da!“ |

Gerne 1–4 Sekunden pro Spruch. WAV, 44,1 oder 48 kHz, Mono oder Stereo,
kurz Ruhe davor und danach, ohne Hall und ohne Übersteuerung. Die Ordner sind
angelegt. WAVs bleiben lokal und werden weder in Git noch in Release-ZIPs gepackt.

Arkane Intelligenz und Arkane Brillanz erfüllen gemeinsam die Int-Prüfung,
einschließlich verschiedener Ränge und Buffs anderer Magier. Sie prüft dich
sowie sichtbare, lebende, verbundene Mana-Klassen in Gruppe oder Raid; Krieger
und Schurken werden ausgelassen. Für dich selbst reicht **eine** Frost-, Eis-
oder Magierrüstung. Nur bereits gelernte Buff-Kategorien werden verlangt.
Situative Zauber wie Magie verstärken/dämpfen und kurzlebige Schutzzauber werden
nicht dauerhaft verlangt.

Jede Stufe meldet sich einmal, bis sich der Zustand ändert. Nachbuffen macht
die Warnung wieder scharf. Mehrere Gruppenmitglieder teilen dieselbe Aufnahme;
verschiedene Warnungen werden nacheinander abgespielt. Gleiche Sprachwarnungen
haben 30 Sekunden Mindestabstand. Nach dem Einloggen/Zonenwechsel werden fünf
Sekunden auf die Buffdaten gewartet; tot oder im Flugtaxi bleibt der Alarm ruhig.

## Optionen und Hörproben

`/gws buffs` oder „Buffwarnungen“ im `/gws`-Fenster. Eigene Schalter für das
Modul, Int-Buffs, Rüstungsbuff und Sprachausgabe. Alle standardmäßig an und pro
Charakter gespeichert. Ausschalten des ganzen Addons stoppt auch die Warnungen.
Ohne importierte Aufnahmen funktionieren Textwarnungen; es wird kein
beliebiger Angriffssound als Ersatz abgespielt. Hörproben sind auch auf anderen
Charakteren möglich.

```text
/gws buffs on
/gws buffs off
/gws buffs intellect expiring
/gws buffs intellect missing
/gws buffs armor expiring
/gws buffs armor missing
```

## Nach der Aufnahme importieren

```sh
python3 tools/import_buff_alerts.py
```

Trimmt äußere Stille, gleicht Lautstärke an, erzeugt vier OGGs und vier
Noggenfogger-Varianten, aktualisiert Registry und Paketmanifest. Die vorhandenen
Angriffsaufnahmen bleiben unverändert. Lokale Hörproben entstehen unter
`previews/buffs/index.html`; nach Installation der fertigen Dateien WoW komplett
neu starten. Die automatische Warnung muss noch im echten Client geprüft werden.
