#!/bin/bash

# ============================================================
#  INSTALADOR AUTOMÁTICO — Separador de Stems
#  Compatible con cualquier Mac con macOS 12+ (Intel y Apple Silicon)
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

MUSIC_DIR="$HOME/Music"
PROYECTOS_DIR="$HOME/Music/Editar"
PRE_EDITAR_DIR="$HOME/Music/Pre Editar"
SCRIPT_PATH="$MUSIC_DIR/separar_stems.sh"
WATCHER_PATH="$MUSIC_DIR/watcher_stems.sh"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/com.stemsauto.watcher.plist"
SERVICE_LABEL="com.stemsauto.watcher"

abort() {
    echo -e "${RED}✖ Error: $1${NC}" >&2
    exit 1
}

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🎵  Instalador de Stems Auto       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# ── Detectar arquitectura ──
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

# ── PASO 1: Homebrew ──
echo -e "${YELLOW}[1/6] Verificando Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    echo "  Instalando Homebrew (puede tardar varios minutos)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || abort "No se pudo instalar Homebrew."
fi
# Cargar brew en PATH según arquitectura
if [ -f "$BREW_PREFIX/bin/brew" ]; then
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    grep -q "homebrew" "$HOME/.zprofile" 2>/dev/null \
        || echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> "$HOME/.zprofile"
fi
command -v brew &>/dev/null || abort "Homebrew instalado pero no encontrado en PATH."
echo -e "  ${GREEN}✓ Homebrew $(brew --version | head -1)${NC}"

# ── PASO 2: Python 3.11 ──
echo -e "${YELLOW}[2/6] Verificando Python 3.11...${NC}"
PYTHON311=""
for p in "$BREW_PREFIX/bin/python3.11" "/usr/local/bin/python3.11"; do
    [ -x "$p" ] && PYTHON311="$p" && break
done
if [ -z "$PYTHON311" ]; then
    echo "  Instalando Python 3.11..."
    brew install python@3.11 || abort "No se pudo instalar Python 3.11."
    for p in "$BREW_PREFIX/bin/python3.11" "/usr/local/bin/python3.11"; do
        [ -x "$p" ] && PYTHON311="$p" && break
    done
fi
[ -z "$PYTHON311" ] && abort "Python 3.11 no encontrado tras la instalación."
echo -e "  ${GREEN}✓ Python 3.11: $PYTHON311${NC}"

# ── PASO 3: FFmpeg ──
echo -e "${YELLOW}[3/6] Verificando FFmpeg...${NC}"
if ! command -v ffmpeg &> /dev/null; then
    echo "  Instalando FFmpeg..."
    brew install ffmpeg || abort "No se pudo instalar FFmpeg."
fi
echo -e "  ${GREEN}✓ FFmpeg $(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')${NC}"

# ── PASO 4: pipx ──
echo -e "${YELLOW}[4/6] Verificando pipx...${NC}"
export PATH="$HOME/.local/bin:$BREW_PREFIX/bin:/usr/local/bin:$PATH"
if ! command -v pipx &> /dev/null; then
    echo "  Instalando pipx..."
    brew install pipx || abort "No se pudo instalar pipx."
    pipx ensurepath --force 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"
fi
command -v pipx &>/dev/null || abort "pipx instalado pero no encontrado en PATH."
echo -e "  ${GREEN}✓ pipx $(pipx --version)${NC}"

# ── PASO 5: Demucs ──
echo -e "${YELLOW}[5/6] Verificando Demucs...${NC}"
DEMUCS_BIN=""
for d in "$HOME/.local/bin/demucs" "$BREW_PREFIX/bin/demucs" "/usr/local/bin/demucs"; do
    [ -x "$d" ] && DEMUCS_BIN="$d" && break
done

if [ -z "$DEMUCS_BIN" ]; then
    echo "  Instalando Demucs con Python 3.11 (puede tardar varios minutos)..."
    pipx install demucs --python "$PYTHON311" || abort "No se pudo instalar Demucs."
    for d in "$HOME/.local/bin/demucs" "$BREW_PREFIX/bin/demucs" "/usr/local/bin/demucs"; do
        [ -x "$d" ] && DEMUCS_BIN="$d" && break
    done
fi
[ -z "$DEMUCS_BIN" ] && abort "Demucs no encontrado tras la instalación."

# Inyectar soundfile (necesario para .flac y algunos .wav)
echo "  Verificando dependencias de Demucs..."
if ! pipx runpip demucs show soundfile &>/dev/null; then
    echo "  Instalando soundfile..."
    pipx inject demucs soundfile || abort "No se pudo inyectar soundfile en Demucs."
fi

echo -e "  ${GREEN}✓ Demucs: $DEMUCS_BIN${NC}"

# ── PASO 6: Carpetas, scripts y servicio ──
echo -e "${YELLOW}[6/6] Instalando scripts y servicio...${NC}"

mkdir -p "$PROYECTOS_DIR"
mkdir -p "$PRE_EDITAR_DIR"
mkdir -p "$LAUNCH_AGENTS_DIR"

# ── Script principal de separación ──
cat > "$SCRIPT_PATH" << 'SCRIPTEOF'
#!/bin/bash

DEMUCS_BIN=""
for d in "$HOME/.local/bin/demucs" "/opt/homebrew/bin/demucs" "/usr/local/bin/demucs"; do
    [ -x "$d" ] && DEMUCS_BIN="$d" && break
done

if [ -z "$DEMUCS_BIN" ]; then
    osascript -e 'display notification "❌ Demucs no encontrado. Reinstala." with title "Separador de Stems" sound name "Basso"'
    exit 1
fi

PROYECTOS_DIR="$HOME/Music/Editar"
ARCHIVO="$1"

[ -z "$ARCHIVO" ] || [ ! -f "$ARCHIVO" ] && exit 1

EXT="${ARCHIVO##*.}"
EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
case "$EXT" in
    mp3|wav|flac|m4a|aiff) ;;
    *) exit 0 ;;
esac

NOMBRE=$(basename "$ARCHIVO")
NOMBRE_LIMPIO="${NOMBRE%.*}"
CARPETA_PROYECTO="$PROYECTOS_DIR/$NOMBRE_LIMPIO"
CARPETA_STEMS="$CARPETA_PROYECTO/Stems"
CARPETA_AUDIO="$CARPETA_PROYECTO/Audio"
CARPETA_ABLETON="$CARPETA_PROYECTO/Ableton"

mkdir -p "$CARPETA_STEMS" "$CARPETA_AUDIO" "$CARPETA_ABLETON"
cp "$ARCHIVO" "$CARPETA_AUDIO/"

osascript -e "display notification \"⏳ Separando stems: $NOMBRE_LIMPIO\" with title \"Separador de Stems\""

"$DEMUCS_BIN" -n htdemucs --out "$CARPETA_STEMS" "$ARCHIVO"

if [ $? -ne 0 ]; then
    osascript -e "display notification \"❌ Error al separar: $NOMBRE_LIMPIO\" with title \"Separador de Stems\" sound name \"Basso\""
    exit 1
fi

STEMS_GENERADOS="$CARPETA_STEMS/htdemucs/$NOMBRE_LIMPIO"
if [ -d "$STEMS_GENERADOS" ]; then
    # Mover y renombrar solo si hay archivos wav
    shopt -s nullglob
    WAV_FILES=("$STEMS_GENERADOS"/*.wav)
    shopt -u nullglob
    if [ ${#WAV_FILES[@]} -gt 0 ]; then
        for STEM in "${WAV_FILES[@]}"; do
            STEM_NOMBRE=$(basename "$STEM")
            mv "$STEM" "$CARPETA_STEMS/${NOMBRE_LIMPIO}_${STEM_NOMBRE}"
        done
    fi
    rm -rf "$CARPETA_STEMS/htdemucs"
fi

osascript -e "display notification \"✅ Stems listos: $NOMBRE_LIMPIO\" with title \"Separador de Stems\" sound name \"Glass\""
SCRIPTEOF
chmod +x "$SCRIPT_PATH"

# ── Script watcher ──
cat > "$WATCHER_PATH" << 'WATCHEOF'
#!/bin/bash
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

WATCH_DIR="$HOME/Music/Pre Editar"
PROYECTOS_DIR="$HOME/Music/Editar"
PROCESSED="$HOME/Music/.stems_procesados"
touch "$PROCESSED"

while true; do
    while IFS= read -r FILE; do
        NOMBRE=$(basename "$FILE")
        NOMBRE_LIMPIO="${NOMBRE%.*}"
        STEMS_DIR="$PROYECTOS_DIR/$NOMBRE_LIMPIO/Stems"

        shopt -s nullglob
        STEM_ARRAY=("$STEMS_DIR"/*.wav)
        shopt -u nullglob
        STEM_COUNT=${#STEM_ARRAY[@]}

        if ! grep -qF "$FILE" "$PROCESSED" && [ "$STEM_COUNT" -lt 4 ]; then
            echo "$FILE" >> "$PROCESSED"
            bash "$HOME/Music/separar_stems.sh" "$FILE" &
        fi
    done < <(find "$WATCH_DIR" -maxdepth 1 \( -name "*.mp3" -o -name "*.wav" -o -name "*.flac" -o -name "*.m4a" -o -name "*.aiff" \) 2>/dev/null)

    sleep 5
done
WATCHEOF
chmod +x "$WATCHER_PATH"

# ── Instalar servicio launchd ──
# Detener servicio existente usando la API correcta (compatible con macOS 12+)
if launchctl list "$SERVICE_LABEL" &>/dev/null 2>&1; then
    launchctl bootout "gui/$(id -u)/$SERVICE_LABEL" 2>/dev/null || true
fi

cat > "$PLIST_PATH" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$WATCHER_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$MUSIC_DIR/.stems_log.txt</string>
    <key>StandardErrorPath</key>
    <string>$MUSIC_DIR/.stems_error.txt</string>
</dict>
</plist>
PLISTEOF

# Cargar con la API moderna (macOS 12+)
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true

sleep 2
if launchctl list "$SERVICE_LABEL" &>/dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Scripts instalados${NC}"
    echo -e "  ${GREEN}✓ Vigilante activo (arranca automáticamente al iniciar sesión)${NC}"
else
    echo -e "  ${YELLOW}⚠  Vigilante instalado. Si no arranca, reinicia sesión una vez.${NC}"
fi

# ── Alias en .zshrc (método seguro) ──
ALIAS_LINE='alias stems-limpiar='"'"'> "$HOME/Music/.stems_procesados" && echo "Registro limpiado. Las canciones en Pre Editar se reprocesarán."'"'"
grep -qF "stems-limpiar" "$HOME/.zshrc" 2>/dev/null \
    || echo "$ALIAS_LINE" >> "$HOME/.zshrc"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅  Instalación completa        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  🎵 Suelta canciones en:"
echo -e "  ${BLUE}$PRE_EDITAR_DIR${NC}"
echo ""
echo -e "  📂 Los stems aparecerán en:"
echo -e "  ${BLUE}$PROYECTOS_DIR${NC}"
echo ""
echo -e "  🔔 Recibirás notificación cuando terminen."
echo ""
echo -e "  💡 Tip: usa ${YELLOW}stems-limpiar${NC} (nueva terminal) para reprocesar canciones."
echo ""

open "$PRE_EDITAR_DIR"
