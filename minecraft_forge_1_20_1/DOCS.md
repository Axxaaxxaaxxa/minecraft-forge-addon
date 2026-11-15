# Minecraft Paper 1.20.1 + Bedrock

PaperMC-1.20.1-Server mit Plugins für Multi-Version und Bedrock-Spieler.

## Enthaltene Plugins

| Plugin | Zweck |
|---|---|
| ViaVersion | Lässt andere Minecraft-Versionen auf den Server |
| ViaBackwards | Ältere Clients (Protokoll-Übersetzung) |
| ViaRewind | Noch ältere Clients (1.8 bis 1.12) |
| Geyser | Bedrock-Spieler (Handy, Konsole, Windows-Bedrock) |
| Floodgate | Bedrock-Spieler ohne Java-Account |

## Einrichtung

1. Add-on installieren und starten lassen. Der erste Start dauert einige Minuten (PaperMC wird vorbereitet, Plugins werden geladen).
2. In den Optionen **`eula` auf `true`** setzen (du akzeptierst damit die [Minecraft-EULA](https://aka.ms/MinecraftEULA)).
3. Optional `memory`, MOTD usw. anpassen.
4. Add-on **zweimal** neu starten: beim ersten Start wird die Geyser-Konfiguration erzeugt, beim zweiten Start wird Floodgate darin aktiviert.
5. Java-Spieler verbinden sich mit `IP:25565`.
6. Bedrock-Spieler verbinden sich mit `IP:19132` (Server hinzufügen, Port 19132).

## Dateien

Alles liegt unter `share/minecraft-forge/`:

- `plugins/` – Plugin-JARs und deren Konfiguration (z.B. `plugins/Geyser-Spigot/config.yml`)
- `world/` – Welt (bleibt beim Update erhalten)
- `server.properties` – wird bei jedem Start aus den Optionen überschrieben

## Update eines Plugins

Die Plugins werden nur einmal heruntergeladen. Für ein Update die JAR-Datei im Ordner `plugins/` löschen und das Add-on neu starten.

## Wichtige Optionen

| Option | Beschreibung |
|---|---|
| `eula` | Muss `true` sein, sonst startet der Server nicht. |
| `memory` | RAM für Java, z.B. `1G` (Standard für Pi 4 GB). |
| `motd` | Text in der Serverliste. |
| `max_players` | Maximale Spielerzahl. |
| `difficulty` | `peaceful`, `easy`, `normal`, `hard`. |
| `gamemode` | `survival`, `creative`, `adventure`, `spectator`. |
| `online_mode` | `true` = nur echte Minecraft-Accounts für Java-Spieler. |
| `view_distance` | Sichtweite in Chunks. |
| `level_name` | Name des Weltordners. Änderung erzeugt eine neue Welt. |
| `level_seed` | Seed für neue Welten (nur bei Erstellung wirksam). |
| `pvp` | Spieler-gegen-Spieler an/aus. |
| `java_args` | Zusätzliche JVM-Argumente. |

## Hinweise

- **Forge-Mods funktionieren nicht mehr.** Mit Version 2.0 läuft PaperMC, keine Forge-Mods. Bestehende Mod-JARs im Ordner `mods/` werden ignoriert.
- Port `25565/tcp` (Java) und `19132/udp` (Bedrock) müssen für Zugriff von außen im Router weitergeleitet werden.
- Beim Stoppen wird der Server mit `stop` sauber heruntergefahren, damit die Welt gespeichert wird.
- Auf einem Pi mit 4 GB RAM sind 1 GB für den Server knapp, aber mit Plugins und wenigen Spielern machbar. Bei Lags den Wert nicht erhöhen, sondern weniger Spieler/Sichtweite wählen oder weitere Add-ons abschalten.
