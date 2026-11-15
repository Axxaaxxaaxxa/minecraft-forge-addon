#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# Startet einen Minecraft-Forge-1.20.1-Server. Forge wird beim ersten Start
# (bzw. bei Änderung von forge_version) automatisch installiert.

MC_VERSION="1.20.1"
SERVER_DIR="/share/minecraft-forge"
FIFO="/tmp/mc-console"

# ---- EULA prüfen ----
if ! bashio::config.true 'eula'; then
    bashio::log.fatal "Minecraft-EULA nicht akzeptiert. Setze die Option 'eula' auf true."
    bashio::log.fatal "EULA: https://aka.ms/MinecraftEULA"
    exit 1
fi

FORGE_VERSION="$(bashio::config 'forge_version')"
FORGE_FULL="${MC_VERSION}-${FORGE_VERSION}"
MEMORY="$(bashio::config 'memory')"

mkdir -p "${SERVER_DIR}/mods" || exit 1
cd "${SERVER_DIR}" || exit 1

# ---- Forge installieren (nur wenn diese Version noch nicht vorhanden ist) ----
MARKER=".forge-installed-${FORGE_FULL}"
if [ ! -f "${MARKER}" ] || [ ! -f "libraries/net/minecraftforge/forge/${FORGE_FULL}/unix_args.txt" ]; then
    bashio::log.info "Installiere Forge ${FORGE_FULL} (einmalig, kann einige Minuten dauern)..."
    rm -f .forge-installed-*

    URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_FULL}/forge-${FORGE_FULL}-installer.jar"
    if ! curl -fsSL -o forge-installer.jar "${URL}"; then
        bashio::log.fatal "Download fehlgeschlagen: ${URL}"
        bashio::log.fatal "Bitte forge_version prüfen (z.B. 47.3.0 für Minecraft 1.20.1)."
        exit 1
    fi

    if ! java -jar forge-installer.jar --installServer "${SERVER_DIR}"; then
        bashio::log.fatal "Forge-Installation fehlgeschlagen. Siehe Log oben."
        exit 1
    fi

    rm -f forge-installer.jar forge-installer.jar.log
    touch "${MARKER}"
    bashio::log.info "Forge-Installation abgeschlossen."
fi

# ---- EULA akzeptieren ----
echo "eula=true" > eula.txt

# ---- server.properties aus den Add-on-Optionen setzen ----
PROPS="${SERVER_DIR}/server.properties"
touch "${PROPS}"

set_prop() {
    local key="$1"
    local value
    # Sonderzeichen für sed escapen
    value="$(printf '%s' "$2" | sed -e 's/[&|\\]/\\&/g')"
    if grep -q "^${key}=" "${PROPS}"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "${PROPS}"
    else
        echo "${key}=$2" >> "${PROPS}"
    fi
}

set_prop "server-port"  "25565"
set_prop "motd"         "$(bashio::config 'motd')"
set_prop "max-players"  "$(bashio::config 'max_players')"
set_prop "difficulty"   "$(bashio::config 'difficulty')"
set_prop "gamemode"     "$(bashio::config 'gamemode')"
set_prop "online-mode"  "$(bashio::config 'online_mode')"
set_prop "view-distance" "$(bashio::config 'view_distance')"
set_prop "level-name"   "$(bashio::config 'level_name')"
set_prop "level-seed"   "$(bashio::config 'level_seed' '')"
set_prop "pvp"          "$(bashio::config 'pvp')"

# ---- JVM-Argumente (Speicher + optionale Zusatzargumente) ----
JAVA_EXTRA="$(bashio::config 'java_args' '')"
printf '%s\n' "-Xms${MEMORY} -Xmx${MEMORY} -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 ${JAVA_EXTRA}" \
    > user_jvm_args.txt

# ---- Server starten ----
# Eine FIFO dient als Konsoleneingabe, damit wir beim Stoppen "stop" senden können.
rm -f "${FIFO}"
mkfifo "${FIFO}"
exec 3<>"${FIFO}"

bashio::log.info "Starte Minecraft-Server (Port 25565, ${MEMORY} RAM)..."
java @user_jvm_args.txt "@libraries/net/minecraftforge/forge/${FORGE_FULL}/unix_args.txt" nogui <&3 &
JAVA_PID=$!

shutdown() {
    bashio::log.info "Stopp-Signal empfangen - Server wird sauber beendet (Welt wird gespeichert)..."
    echo "stop" >&3
    wait "${JAVA_PID}"
    exit $?
}
trap shutdown TERM INT

wait "${JAVA_PID}"
RC=$?
bashio::log.info "Server beendet (Exit-Code ${RC})."
exit "${RC}"
