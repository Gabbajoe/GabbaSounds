<p align="center">
  <img src="https://raw.githubusercontent.com/Gabbajoe/GabbaSounds/main/curseforge/logo.png" alt="GabbaSounds – grinsender Blitz mit Sprechblase" width="180">
</p>

<h1 align="center">GabbaSounds</h1>

<p align="center">
  <strong>Gib deinen Angriffen eine Stimme.</strong><br>
  Pew pew. Wusch. Bamm. Und beim Crit darf's ein bisschen episch werden. 🗣️
</p>

<p align="center">
  <a href="https://github.com/Gabbajoe/GabbaSounds/actions/workflows/ci.yml"><img src="https://github.com/Gabbajoe/GabbaSounds/actions/workflows/ci.yml/badge.svg?branch=main" alt="Tests und Paketbau"></a>
  <a href="https://github.com/Gabbajoe/GabbaSounds/releases"><img src="https://img.shields.io/github/v/release/Gabbajoe/GabbaSounds?style=flat-square&amp;color=a78bfa&amp;label=Release" alt="Neuester veröffentlichter Release"></a>
  <img src="https://img.shields.io/badge/WoW-Classic_Era_%26_Hardcore-a78bfa?style=flat-square" alt="WoW Classic Era und Hardcore">
  <img src="https://img.shields.io/badge/Interface-11509-22d3ee?style=flat-square" alt="Interface 11509">
  <img src="https://img.shields.io/badge/Sprachclips-219-f472b6?style=flat-square" alt="219 Sprachclips">
  <img src="https://img.shields.io/badge/Magie--Sounds-126-fbbf24?style=flat-square" alt="126 synthetische Magie-Sounds">
</p>

<p align="center">
  <a href="https://github.com/Gabbajoe/GabbaSounds/releases"><strong>📦 Downloads</strong></a> ·
  <a href="https://gabbajoe.github.io/GabbaSounds/"><strong>🎧 Hörproben</strong></a> ·
  <a href="https://github.com/Gabbajoe/GabbaSounds/issues"><strong>💬 Ideen &amp; Fehler</strong></a> ·
  <a href="docs/RELEASING.md"><strong>🛠️ Entwicklung</strong></a>
</p>

---

GabbaSounds bringt eigene **deutsche Sprachaufnahmen** in den Kampf:
Zauberstab-Laute, Pfeil- und Gewehr-Sounds, gesprochene Magier-Casts und
Waffenangriffe mit passenden Crit- und Fehlschlag-Sprüchen.

Angefangen hat alles mit einem Zauberstab-Priester und einem viel zu oft
gehörten **„wusch wusch“**. Daraus wurden **219 Sprachclips**, **126 synthetische
Magie-Sounds** und jede Menge Wünsche aus der Community. 💜

> **Stand dieser README: vorbereitete Version 1.1.0.** Der veröffentlichte
> GitHub-Release ist derzeit 1.0.0. Das Nahkampf-Update kommt erst auf CurseForge,
> nachdem das initiale Addon freigegeben wurde und der Autor den Start bestätigt.

## 🎯 Für jeden Angriff das passende Paket

| Bereich | Was du hörst |
| --- | --- |
| 🪄 **Zauberstab** | Gesprochene Laute oder synthetische Magie je Schadensart: Schatten, Feuer, Frost, Arkan, Natur und Heilig |
| 🏹 **Jäger** | Eigene Sprachpakete für Bogen/Armbrust und Gewehr bei Auto-Schüssen |
| ⚔️ **Nahkampf** | Schwerter/Äxte, Streitkolben/Stäbe, Dolche und Faustwaffen/unbewaffnet – je **6 normale Laute + 4 Crit-Sprüche** |
| ❄️ **Frostmagier** | Frostblitz, Frostnova, Blizzard, Kältekegel, Eisbarriere, Eisblock, Kälteeinbruch und Frostzauberschutz |
| 🔥 **Feuermagier** | Feuerball, Feuerschlag, Versengen, Pyroschlag, Flammenstoß, Druckwelle und Verbrennung |
| 💨 **Miss & Teiltreffer** | Acht gemeinsame Fehlschlag-Sprüche und acht Teiltreffer-Sprüche, auch für Streifschläge im Nahkampf |

## ✨ Was GabbaSounds kann

- 🎲 **Abwechslung:** zufällige Auswahl, ohne direkte Wiederholung bei mehreren Varianten.
- 💥 **Treffer & Crits:** eigene Pools für normale Treffer und kritische Treffer.
- 🗣️ **Magier-Casts:** Laute beim Cast-Beginn, Kanalbeginn oder Aktivieren – passend zum Zauber.
- ⚔️ **Beide Hände:** Nahkampf-Pakete werden getrennt nach Haupt- und Nebenhand erkannt.
- 🛡️ **Sprüche dürfen ausreden:** schnelle normale Nahkampf-Treffer schneiden Crit- und Fehlschlag-Sprüche nicht ab; die Mindestpause ist einstellbar.
- ❄️ **Flächenzauber mit Augenmaß:** eine Ergebnis-Reaktion pro Anwendung; Blizzard reagiert beim ersten Schadensburst.
- 🔇 **Originale optional stumm:** „Nur gesprochene Sounds“ aktiviert das automatische Sprachpaket und schaltet abgedeckte Originaldateien stumm.
- 🎧 **Direkt anhören:** Hörproben im Spiel und im Browser.
- 🧭 **Minimap-Symbol:** Linksklick an/aus, Rechtsklick Optionen, Ziehen verschiebt das Symbol.
- 💾 **Dein Charakter, deine Auswahl:** Einstellungen pro Charakter, ohne erforderliche Zusatzaddons.

## 🚀 Installation & erster Start

1. Lade das ZIP der gewünschten Version herunter und entpacke es.
2. Kopiere den Ordner **`GabbaSounds`** nach:

   ```text
   World of Warcraft/_classic_era_/Interface/AddOns/
   ```

3. Prüfe, dass dort `GabbaSounds/GabbaSounds.toc` liegt.
4. **WoW vollständig schließen und neu starten**, damit neue Audiodateien geladen werden.

Alle gesprochenen Pakete aktivieren:

```text
/gws on
/gws spokenonly on
```

**`/gws` öffnet die Optionen.** Neue Charaktere starten mit dem synthetischen
Zauberstab-Paket. Sounds und Optionsoberfläche sind Deutsch. Die Aufnahmen
werden lokal abgespielt; andere Spieler erhalten deine Audiodateien nicht.

## 🎧 Hör dir die Pakete an

Die [Browser-Hörproben](https://gabbajoe.github.io/GabbaSounds/) zeigen dir alle Sprachclips,
die vier Nahkampf-Pakete und die synthetischen Zauberstab-Sounds.
**Direkt öffnen und abspielen — kein Download nötig.**
Für die [Offline-Nutzung und den Bau der Player](previews/README.md) gibt es eine eigene Anleitung.
Im Spiel findest du die Hörproben direkt unter **`/gws`**.

## 💜 Auf Wunsch der Community

| Wunschgeber | Soundpaket |
| --- | --- |
| **Tsukimo** | ⚔️ Nahkampf |
| **Palaberd** | 🏹 Jäger: Pfeile und Gewehre |
| **Bobselinchen aka Minibobsel** | ❄️ Frostblitz |
| **Zeldazar** | 🔥 Feuerzauber |
| **Gabbajoe** | 🪄 Addon und eigene Sprachaufnahmen – entstanden aus dem Zauberstab-„wusch wusch“ |

## 🎮 Kompatibilität & Umfang

Für **WoW Classic Era / Hardcore 1.15.9**, Interface **11509**.
Nahkampf umfasst zunächst normale Auto-Angriffe; Klassenfähigkeiten,
Stangenwaffen und Gestaltangriffe haben keine eigenen Pakete.

**Original-Stummschaltung wirkt pro Sounddatei global.** Gemeinsam verwendete
Dateien können dadurch auch bei anderen Fähigkeiten oder NPCs verstummen.
Einzelne Nahkampf-Pakete lassen die Originale hörbar; die vollständige
Nahkampf-Stummschaltung benötigt ein automatisches Paket mit allen vier Gruppen.

## 📚 Mehr wissen? Ab in die Docs

| Dokument | Hier findest du … |
| --- | --- |
| [Bedienung & Soundpakete](docs/USAGE.md) | Alle Befehle, Varianten, Einstellungen und die Grenzen der Original-Stummschaltung |
| [Hörproben](previews/README.md) | Browser-Player öffnen und aus den fertigen OGGs neu bauen |
| [Magier-Aufnahmen](spoken/mage/README.md) | Ordner, Dateinamen und Aufnahmevorlagen für Frost- und Feuerzauber |
| [Nahkampf-Aufnahmen](spoken/melee/README.md) | Vorlagen und Ablage für Schwerter, Äxte, Kolben, Stäbe, Dolche und Fäuste |
| [Entwicklung & Releases](docs/RELEASING.md) | Arbeitsbranches, Pull Requests, CI, Paketbau und Veröffentlichungen |
| [Sound-ID-Quellen](THIRD_PARTY_NOTICES.md) | Herkunft der verwendeten Originalsound-Zuordnungen |

## 💬 Deine Idee fürs nächste Paket

Ein neuer Spruch, ein Wunsch für deine Klasse oder ein Sound, der sich komisch
verhält? [Schreib uns ein GitHub Issue](https://github.com/Gabbajoe/GabbaSounds/issues).

<p align="center"><strong>Mit eigener Stimme aufgenommen. Für mehr Abwechslung in Azeroth. 💜</strong></p>
