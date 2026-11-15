#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# Startet einen PaperMC-1.20.1-Server mit Plugins fuer Multi-Version (ViaVersion,
# ViaBackwards, ViaRewind) und Bedrock-Unterstuetzung (Geyser + Floodgate).

MC_VERSION="1.20.1"
SERVER_DIR="/share/minecraft-forge"
PLUGIN_DIR="${SERVER_DIR}/plugins"
FIFO="/tmp/mc-console"
UA="minecraft-forge-addon/2.0 (home-assistant)"

# ---- EULA pruefen ----
if ! bashio::config.true 'eula'; then
    bashio::log.fatal "Minecraft-EULA nicht akzeptiert. Setze die Option 'eula' auf true."
    bashio::log.fatal "EULA: https://aka.ms/MinecraftEULA"
    exit 1
fi

MEMORY="$(bashio::config 'memory')"

mkdir -p "${PLUGIN_DIR}" || exit 1
cd "${SERVER_DIR}" || exit 1

# ---- Paper-Server herunterladen (nur wenn noch nicht vorhanden) ----
if [ ! -f paper.jar ]; then
    bashio::log.info "Lade PaperMC ${MC_VERSION} herunter..."
    PAPER_URL="$(curl -fsSL --retry 3 --connect-timeout 20 -A "${UA}" "https://fill.papermc.io/v3/projects/paper/versions/${MC_VERSION}/builds/latest" \
        | sed 's/.*"server:default"//' | grep -o 'https://[^"]*' | head -1)"
    if [ -z "${PAPER_URL}" ] || ! curl -fsSL --retry 3 --connect-timeout 20 -A "${UA}" -o paper.jar.tmp "${PAPER_URL}"; then
        bashio::log.fatal "PaperMC-Download fehlgeschlagen. Internetverbindung pruefen."
        rm -f paper.jar.tmp
        exit 1
    fi
    mv paper.jar.tmp paper.jar
fi

# ---- Modrinth-Plugin laden (nur wenn noch nicht vorhanden) ----
# Argumente: Modrinth-Slug, Zieldatei
get_modrinth_plugin() {
    local slug="$1" target="$2" url
    if [ -f "${PLUGIN_DIR}/${target}" ]; then
        return 0
    fi
    url="$(curl -fsSG -A "${UA}" \
        --data-urlencode "game_versions=[\"${MC_VERSION}\"]" \
        --data-urlencode 'loaders=["paper"]' \
        "https://api.modrinth.com/v2/project/${slug}/version" \
        | jq -r '[.[0].files[] | select(.primary)][0].url // empty')"
    if [ -z "${url}" ]; then
        bashio::log.warning "Kein Paper-Build fuer ${slug} gefunden - uebersprungen."
        return 1
    fi
    if curl -fsSL --retry 3 --connect-timeout 20 -A "${UA}" -o "${PLUGIN_DIR}/${target}.tmp" "${url}"; then
        mv "${PLUGIN_DIR}/${target}.tmp" "${PLUGIN_DIR}/${target}"
        bashio::log.info "Plugin ${slug} installiert."
    else
        rm -f "${PLUGIN_DIR}/${target}.tmp"
        bashio::log.warning "Download von ${slug} fehlgeschlagen."
    fi
}

get_modrinth_plugin viaversion   ViaVersion.jar
get_modrinth_plugin viabackwards ViaBackwards.jar
get_modrinth_plugin viarewind    ViaRewind.jar

# ---- Geyser + Floodgate (GeyserMC-Download-API) ----
get_geyser_plugin() {
    local project="$1" target="$2" version="$3"
    if [ -f "${PLUGIN_DIR}/${target}" ]; then
        return 0
    fi
    if curl -fsSL --retry 3 --connect-timeout 20 -A "${UA}" -o "${PLUGIN_DIR}/${target}.tmp" \
        "https://download.geysermc.org/v2/projects/${project}/versions/${version}/builds/latest/downloads/spigot"; then
        mv "${PLUGIN_DIR}/${target}.tmp" "${PLUGIN_DIR}/${target}"
        bashio::log.info "Plugin ${project} installiert."
    else
        rm -f "${PLUGIN_DIR}/${target}.tmp"
        bashio::log.warning "Download von ${project} fehlgeschlagen."
    fi
}

get_geyser_plugin geyser    Geyser-Spigot.jar latest
get_geyser_plugin floodgate Floodgate-Spigot.jar latest

# ---- Geyser: Floodgate-Authentifizierung aktivieren (nur wenn Config schon existiert) ----
GEYSER_CFG="${PLUGIN_DIR}/Geyser-Spigot/config.yml"
if [ -f "${GEYSER_CFG}" ]; then
    sed -i 's/^  auth-type: .*/  auth-type: floodgate/' "${GEYSER_CFG}"
else
    bashio::log.info "Geyser-Config wird beim ersten Start erzeugt. Nach dem ersten Start das Add-on einmal neu starten."
fi

# ---- EULA akzeptieren ----
echo "eula=true" > eula.txt

# ---- server.properties aus den Add-on-Optionen setzen ----
PROPS="${SERVER_DIR}/server.properties"
touch "${PROPS}"

set_prop() {
    local key="$1"
    local value
    # Sonderzeichen fuer sed escapen
    value="$(printf '%s' "$2" | sed -e 's/[&|\\]/\\&/g')"
    if grep -q "^${key}=" "${PROPS}"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "${PROPS}"
    else
        echo "${key}=$2" >> "${PROPS}"
    fi
}

set_prop "server-port"   "25565"
set_prop "motd"          "$(bashio::config 'motd')"
set_prop "max-players"   "$(bashio::config 'max_players')"
set_prop "difficulty"    "$(bashio::config 'difficulty')"
set_prop "gamemode"      "$(bashio::config 'gamemode')"
set_prop "online-mode"   "$(bashio::config 'online_mode')"
set_prop "view-distance" "$(bashio::config 'view_distance')"
set_prop "level-name"    "$(bashio::config 'level_name')"
set_prop "level-seed"    "$(bashio::config 'level_seed' '')"
set_prop "pvp"           "$(bashio::config 'pvp')"

# ---- JVM-Argumente (Speicher + optionale Zusatzargumente) ----
JAVA_EXTRA="$(bashio::config 'java_args' '')"
JVM_ARGS="-Xms${MEMORY} -Xmx${MEMORY} -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 ${JAVA_EXTRA}"

# ---- Server starten ----
# Eine FIFO dient als Konsoleneingabe, damit wir beim Stoppen "stop" senden koennen.
rm -f "${FIFO}"
mkfifo "${FIFO}"
exec 3<>"${FIFO}"

bashio::log.info "Starte PaperMC-Server (Java: Port 25565, Bedrock: Port 19132/udp, ${MEMORY} RAM)..."
# shellcheck disable=SC2086
java ${JVM_ARGS} -jar paper.jar --nogui <&3 &
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
