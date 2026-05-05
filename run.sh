#!/usr/bin/env bash
#
# run.sh — Build & run del progetto PuzzleGame su simulatore iOS senza aprire Xcode
#
# Uso:
#   ./run.sh                          # usa il simulatore di default (vedi DEFAULT_DEVICE)
#   ./run.sh "iPhone 15 Pro"          # specifica un simulatore
#   ./run.sh --list                   # elenca i simulatori disponibili
#   ./run.sh --clean                  # pulisce la build prima di compilare
#   ./run.sh --clean "iPhone 15"      # combina i due
#
# Requisiti:
#   - Xcode installato + Command Line Tools  (`xcode-select --install`)
#   - xcrun, xcodebuild, simctl  (vengono con Xcode)
#
# Da posizionare nella cartella ROOT del progetto (quella che contiene PuzzleGame.xcodeproj).

set -euo pipefail

# ---------------------------------------------------------------------------
# Configurazione — modifica qui se cambia nome progetto/scheme/bundle id
# ---------------------------------------------------------------------------
PROJECT_NAME="PuzzleGame"
SCHEME="PuzzleGame"
CONFIGURATION="Debug"
# Bundle id: deve combaciare con quello impostato in Xcode → Target → General → Bundle Identifier.
# Se non sei sicuro, lancia: defaults read "$APP_PATH/Info" CFBundleIdentifier dopo la build.
BUNDLE_ID="it.funambol.puzzlegame"
# Simulatore di default se non passato come argomento.
DEFAULT_DEVICE="iPhone 15"
# Cartella build locale (evitiamo DerivedData di sistema, più semplice da pulire).
BUILD_DIR="./build"

# ---------------------------------------------------------------------------
# Colori per output leggibile
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
    BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
else
    BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

log()  { echo -e "${BOLD}${GREEN}▶${RESET} $*"; }
warn() { echo -e "${BOLD}${YELLOW}!${RESET} $*"; }
err()  { echo -e "${BOLD}${RED}✗${RESET} $*" >&2; }

# ---------------------------------------------------------------------------
# Parsing argomenti
# ---------------------------------------------------------------------------
CLEAN=false
DEVICE_NAME=""

while [ $# -gt 0 ]; do
    case "$1" in
        --list)
            log "Simulatori iOS disponibili:"
            xcrun simctl list devices available | grep -E "iPhone|iPad" || true
            exit 0
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            sed -n '2,20p' "$0"
            exit 0
            ;;
        *)
            DEVICE_NAME="$1"
            shift
            ;;
    esac
done

DEVICE_NAME="${DEVICE_NAME:-$DEFAULT_DEVICE}"

# ---------------------------------------------------------------------------
# Sanity check: siamo nella cartella giusta?
# ---------------------------------------------------------------------------
if [ ! -d "${PROJECT_NAME}.xcodeproj" ] && [ ! -d "${PROJECT_NAME}.xcworkspace" ]; then
    err "Non trovo ${PROJECT_NAME}.xcodeproj o .xcworkspace nella cartella corrente."
    err "Posiziona lo script nella root del progetto (quella che contiene .xcodeproj)."
    exit 1
fi

# Preferisce workspace se esiste (utile se in futuro aggiungerai SPM/CocoaPods).
if [ -d "${PROJECT_NAME}.xcworkspace" ]; then
    XCODE_TARGET_FLAG="-workspace ${PROJECT_NAME}.xcworkspace"
else
    XCODE_TARGET_FLAG="-project ${PROJECT_NAME}.xcodeproj"
fi

# ---------------------------------------------------------------------------
# Trova / avvia il simulatore richiesto
# ---------------------------------------------------------------------------
log "Cerco simulatore: ${BOLD}${DEVICE_NAME}${RESET}"

# Estraiamo l'UDID del PRIMO simulatore "available" il cui nome combacia esattamente.
# Output di simctl list devices available ha la forma:
#     iPhone 15 (UDID) (Shutdown)
DEVICE_UDID=$(xcrun simctl list devices available \
    | grep -E "^\s+${DEVICE_NAME} \(" \
    | head -n 1 \
    | grep -oE "\([0-9A-F-]{36}\)" \
    | head -n 1 \
    | tr -d '()')

if [ -z "${DEVICE_UDID:-}" ]; then
    err "Nessun simulatore disponibile con nome '${DEVICE_NAME}'."
    warn "Lancia './run.sh --list' per vedere quelli installati."
    exit 1
fi

log "UDID simulatore: ${DEVICE_UDID}"

# Boot del simulatore se non già acceso. simctl boot fallisce se è già in stato Booted,
# quindi lo gestiamo con un check preventivo.
DEVICE_STATE=$(xcrun simctl list devices \
    | grep "${DEVICE_UDID}" \
    | grep -oE "\(Booted\)|\(Shutdown\)" \
    | head -n 1)

if [ "${DEVICE_STATE}" != "(Booted)" ]; then
    log "Avvio simulatore..."
    xcrun simctl boot "${DEVICE_UDID}"
else
    log "Simulatore già avviato."
fi

# Apre l'app Simulator.app per renderlo visibile (altrimenti gira in background).
open -a Simulator

# ---------------------------------------------------------------------------
# Clean (opzionale)
# ---------------------------------------------------------------------------
if [ "${CLEAN}" = true ]; then
    log "Clean build..."
    rm -rf "${BUILD_DIR}"
    # shellcheck disable=SC2086
    xcodebuild ${XCODE_TARGET_FLAG} \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        clean | xcpretty_or_cat
fi

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
# Se installato, usa xcpretty per output leggibile; altrimenti fallback su cat.
xcpretty_or_cat() {
    if command -v xcpretty >/dev/null 2>&1; then
        xcpretty
    else
        cat
    fi
}

log "Build in corso (${CONFIGURATION})..."
# -derivedDataPath isola gli artefatti in ./build, così sappiamo dove pescare il .app.
# -destination usa generic/platform=iOS Simulator + id specifico → build per quell'arch.
# shellcheck disable=SC2086
xcodebuild ${XCODE_TARGET_FLAG} \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -destination "platform=iOS Simulator,id=${DEVICE_UDID}" \
    -derivedDataPath "${BUILD_DIR}" \
    build | xcpretty_or_cat
# PIPESTATUS controlla lo status di xcodebuild, non di xcpretty (che ritorna sempre 0).
BUILD_STATUS=${PIPESTATUS[0]}
if [ "${BUILD_STATUS}" -ne 0 ]; then
    err "Build fallita (exit ${BUILD_STATUS})."
    exit "${BUILD_STATUS}"
fi

# ---------------------------------------------------------------------------
# Trova il bundle .app appena prodotto
# ---------------------------------------------------------------------------
APP_PATH=$(find "${BUILD_DIR}/Build/Products/${CONFIGURATION}-iphonesimulator" \
    -maxdepth 1 -name "*.app" -type d 2>/dev/null | head -n 1)

if [ -z "${APP_PATH}" ] || [ ! -d "${APP_PATH}" ]; then
    err "Build OK ma non trovo il file .app in ${BUILD_DIR}/Build/Products/${CONFIGURATION}-iphonesimulator/"
    exit 1
fi

log "App buildata: ${APP_PATH}"

# Estrae il bundle id direttamente dall'Info.plist nel .app, così se cambi
# il bundle id in Xcode lo script funziona comunque senza modifiche.
ACTUAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${APP_PATH}/Info.plist" 2>/dev/null || echo "")
if [ -n "${ACTUAL_BUNDLE_ID}" ]; then
    BUNDLE_ID="${ACTUAL_BUNDLE_ID}"
fi
log "Bundle id: ${BUNDLE_ID}"

# ---------------------------------------------------------------------------
# Install + Launch
# ---------------------------------------------------------------------------
log "Installazione su simulatore..."
xcrun simctl install "${DEVICE_UDID}" "${APP_PATH}"

log "Avvio app..."
# --console-pty fa lo stream dei log direttamente nel terminale: comodo per debug.
# Rimuovi --console-pty se vuoi che il terminale torni libero subito dopo il launch.
xcrun simctl launch --console-pty "${DEVICE_UDID}" "${BUNDLE_ID}"
