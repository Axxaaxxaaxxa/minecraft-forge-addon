# Minecraft Forge 1.20.1

Betreibt einen Minecraft-Java-Server mit **Forge 1.20.1** in Home Assistant.

## Einrichtung

1. Add-on installieren und starten lassen (der erste Start dauert wegen Forge-Installation und Download einige Minuten).
2. In den Optionen **`eula` auf `true`** setzen (du akzeptierst damit die [Minecraft-EULA](https://aka.ms/MinecraftEULA)).
3. Optional Speicher (`memory`), MOTD, Schwierigkeit usw. anpassen.

### Hinweis für Raspberry Pi (4 GB RAM)

Auf einem Pi mit 4 GB RAM braucht Home Assistant OS selbst schon ~1–1,5 GB. Für den Minecraft-Server bleiben also maximal ca. **2 GB** sinnvoll. Die Standardwerte sind auf sehr geringen Verbrauch ausgelegt: `memory: 1G`, `max_players: 3`, `view_distance: 4`. Mit `1G` laufen nur kleine Setups mit wenigen Mods flüssig. Wenn der Server ruckelt oder abstürzt, zuerst die Mods reduzieren, dann `memory` auf `1536M` oder `2G` erhöhen (falls der Pi genug frei hat). Bei vielen Mods auf einem Pi ist der Server generell sehr langsam.
4. Add-on neu starten.
5. Im Minecraft-Client (Forge 1.20.1 aktiviert) die IP von Home Assistant mit Port **25565** eintragen.

## Mods hinzufügen

Der Server-Ordner liegt unter `share/minecraft-forge/` (über Samba oder den File-Editor erreichbar).

- Mod-Dateien (`.jar`) nach `share/minecraft-forge/mods/` kopieren.
- Achte darauf, dass die Mods für **Minecraft 1.20.1** und **Forge 47.x** gebaut sind.
- Clients brauchen dieselben Mods.
- Danach das Add-on neu starten.

## Wichtige Optionen

| Option | Beschreibung |
|---|---|
| `eula` | Muss `true` sein, sonst startet der Server nicht. |
| `forge_version` | Forge-Version ohne MC-Version, z.B. `47.3.0`. Änderung löst eine Neuinstallation aus. Aktuelle Versionen: https://files.minecraftforge.net |
| `memory` | RAM für Java (`-Xms` und `-Xmx`), z.B. `1G` (Standard für Pi 4 GB). |
| `motd` | Text in der Serverliste. |
| `max_players` | Maximale Spielerzahl. |
| `difficulty` | `peaceful`, `easy`, `normal`, `hard`. |
| `gamemode` | `survival`, `creative`, `adventure`, `spectator`. |
| `online_mode` | `true` = nur echte Minecraft-Accounts. |
| `view_distance` | Sichtweite in Chunks. |
| `level_name` | Name des Weltordners. Änderung erzeugt eine neue Welt. |
| `level_seed` | Seed für neue Welten (nur bei Erstellung wirksam). |
| `pvp` | Spieler-gegen-Spieler an/aus. |
| `java_args` | Zusätzliche JVM-Argumente. |

## Hinweise

- Port `25565/tcp` wird standardmäßig vom Host bereitgestellt. Für Zugriff von außen Port-Weiterleitung im Router einrichten.
- Beim Stoppen des Add-ons wird der Server mit `stop` sauber heruntergefahren, damit die Welt gespeichert wird.
- Forge 1.20.1 benötigt Java 17 (ist im Add-on enthalten).
- Server-Einstellungen (`server.properties`) werden bei jedem Start aus den Add-on-Optionen überschrieben. Andere Einstellungen darin bleiben erhalten.
