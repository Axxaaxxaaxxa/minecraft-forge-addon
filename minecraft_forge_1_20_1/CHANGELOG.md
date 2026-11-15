# Changelog

## 2.0.1
- Fix: PaperMC-Download-URL wurde nicht gefunden.
- Downloads mit Wiederholungen und Timeouts.

## 2.0.0
- **Breaking:** Forge wurde durch PaperMC 1.20.1 ersetzt. Forge-Mods funktionieren nicht mehr, Bukkit/Paper-Plugins stattdessen.
- Neue Plugins: ViaVersion, ViaBackwards, ViaRewind (ältere Clients), Geyser + Floodgate (Bedrock-Spieler, Port 19132/udp).
- Option `forge_version` entfernt.

## 1.0.2
- Standardwerte weiter reduziert: `memory` 1G, `max_players` 3, `view_distance` 4.

## 1.0.1
- Standardwerte für Raspberry Pi mit 4 GB RAM angepasst: `memory` 2G, `max_players` 5, `view_distance` 6.

## 1.0.0
- Erste Version: Minecraft Forge 1.20.1 Server als Home-Assistant-Add-on (amd64, aarch64).
- Automatische Forge-Installation, EULA-Prüfung, Optionen für server.properties, sauberes Herunterfahren.
