#!/bin/bash

# ============================================================
#  INSTALADOR AUTOMÁTICO — Separador de Stems
#  Compatible con cualquier Mac con macOS 12+
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31d'
BLUE='\033[0;34m'
NC='\033[0m'

MUSIC_DIR="$HOME/Music"
PROYECTOS_DIR="$HOME/Music/Editar"
PRE_EDITAR_DIR="$HOME/Music/Pre Editar"
SCRIPT_PATH="$MUSIC_DIR/separar_stems.sh"
WATCHER_PATH="$MUSIC_DIR/watcher_stems.sh"
PLIST_PATH="$HOME/Library/LaunchAgents/com.stemsauto.watcher.plist"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🎵  Instalador de Stems Auto       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# ── PASO 1: Homebrew ──
echo -e "${YELLOW}[1/7] Verificando Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    echo "  Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
echo -e "  ${GREEN}✓ Homebrew listo${NC}"

# ── PASO 2: Python 3.11 ──
echo -e "${YELLOW}[2/7] Verificando Python 3.11...${NC}"
PYTHON311=""
for p in "/opt/homebrew/bin/python3.11" "/usr/local/bin/python3.11"; do
    if [ -f "$p" ]; then PYTHON311="$p"; break; fi
done
if [ -z "$PYTHON311" ]; then
    echo "  Instalando Python 3.11..."
    brew install python@3.11
    for p in "/opt/homebrew/bin/python3.11" "/usr/local/bin/python3.11"; do
        if [ -f "$p" ]; then PYTHON311="$p"; break; fi
    done
fi
echo -e "  ${GREEN}✓ Python 3.11: $PYTHON311${NC}"

# ── PASO 3: pipx ──
echo -e "${YELLOW}[3/7] Verificando pipx...${NC}"
if ! command -v pipx &> /dev/null; then
    brew install pipx
fi
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
echo -e "  ${GREEN}✓ pipx listo${NC}"

# ── PASO 4: Demucs ──
echo -e "${YELLOW}[4/7] Instalando Demucs...${NC}"
DEMUCS_BIN=""
for d in "$HOME/.local/bin/demucs" "/opt/homebrew/bin/demucs" "/usr/local/bin/demucs" "$HOME/.local/pipx/venvs/demucs/bin/demucs"; do
    if [ -f "$d" ]; then DEMUCS_BIN="$d"; break; fi
done

if [ -z "$DEMUCS_BIN" ]; then
    pipx install demucs --python "$PYTHON311"
    pipx inject demucs soundfile
    for d in "$HOME/.local/bin/demucs" "/opt/homebrew/bin/demucs" "/usr/local/bin/demucs" "$HOME/.local/pipx/venvs/demucs/bin/demucs"; do
        if [ -f "$d" ]; then DEMUCS_BIN="$d"; break; fi
    done
fi
echo -e "  ${GREEN}✓ Demucs: $DEMUCS_BIN${NC}"

# ── PASO 5: Carpetas ──
echo -e "${YELLOW}[5/7] Creando carpetas...${NC}"
mkdir -p "$PROYECTOS_DIR"
mkdir -p "$PRE_EDITAR_DIR"
echo -e "  ${GREEN}✓ Carpetas creadas${NC}"

# ── PASO 6: Script principal ──
echo -e "${YELLOW}[6/7] Instalando script principal...${NC}"
cat > "$SCRIPT_PATH" << SCRIPTEOF
#!/bin/bash

DEMUCS_BIN=""
for d in "\$HOME/.local/bin/demucs" "/opt/homebrew/bin/demucs" "/usr/local/bin/demucs" "\$HOME/.local/pipx/venvs/demucs/bin/demucs"; do
    if [ -f "\$d" ]; then DEMUCS_BIN="\$d"; break; fi
done

if [ -z "\$DEMUCS_BIN" ]; then
    osascript -e "display notification \"❌ Demucs no encontrado. Reinstala.\" with title \"Separador de Stems\" sound name \"Basso\""
    exit 1
fi

PROYECTOS_DIR="\$HOME/Music/Editar"
ARCHIVO="\$1"

if [ -z "\$ARCHIVO" ] || [ ! -f "\$ARCHIVO" ]; then exit 1; fi

EXT="\${ARCHIVO##*.}"
EXT=\$(echo "\$EXT" | tr '[:upper:]' '[:lower:]')
if [[ "\$EXT" != "mp3" && "\$EXT" != "wav" && "\$EXT" != "flac" && "\$EXT" != "m4a" && "\$EXT" != "aiff" ]]; then
    exit 0
fi

NOMBRE=\$(basename "\$ARCHIVO")
NOMBRE_LIMPIO="\${NOMBRE%.*}"
CARPETA_PROYECTO="\$PROYECTOS_DIR/\$NOMBRE_LIMPIO"
CARPETA_STEMS="\$CARPETA_PROYECTO/Stems"
CARPETA_AUDIO="\$CARPETA_PROYECTO/Audio"
CARPETA_ABLETON="\$CARPETA_PROYECTO/Ableton"

mkdir -p "\$CARPETA_STEMS" "\$CARPETA_AUDIO" "\$CARPETA_ABLETON"
cp "\$ARCHIVO" "\$CARPETA_AUDIO/"

osascript -e "display notification \"⏳ Separando stems: \$NOMBRE_LIMPIO\" with title \"Separador de Stems\""

"\$DEMUCS_BIN" -n htdemucs --out "\$CARPETA_STEMS" "\$ARCHIVO"

if [ \$? -ne 0 ]; then
    osascript -e "display notification \"❌ Error: \$NOMBRE_LIMPIO\" with title \"Separador de Stems\" sound name \"Basso\""
    exit 1
fi

STEMS_GENERADOS="\$CARPETA_STEMS/htdemucs/\$NOMBRE_LIMPIO"
if [ -d "\$STEMS_GENERADOS" ]; then
    mv "\$STEMS_GENERADOS"/*.wav "\$CARPETA_STEMS/"
    rm -rf "\$CARPETA_STEMS/htdemucs"
fi

for STEM in "\$CARPETA_STEMS"/*.wav; do
    STEM_NOMBRE=\$(basename "\$STEM")
    mv "\$STEM" "\$CARPETA_STEMS/\${NOMBRE_LIMPIO}_\${STEM_NOMBRE}"
done

osascript -e "display notification \"✅ Stems listos: \$NOMBRE_LIMPIO\" with title \"Separador de Stems\" sound name \"Glass\""
SCRIPTEOF

chmod +x "$SCRIPT_PATH"
echo -e "  ${GREEN}✓ Script principal listo${NC}"

# ── PASO 7: Watcher con launchd ──
echo -e "${YELLOW}[7/7] Configurando vigilante de carpeta...${NC}"

cat > "$WATCHER_PATH" << WATCHEOF
#!/bin/bash
export PATH="\$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"
WATCH_DIR="\$HOME/Music/Pre Editar"
PROCESSED="\$HOME/Music/.stems_procesados"
touch "\$PROCESSED"

while true; do
    find "\$WATCH_DIR" -maxdepth 1 \( -name "*.mp3" -o -name "*.wav" -o -name "*.flac" -o -name "*.m4a" -o -name "*.aiff" \) | while read -r FILE; do
        if ! grep -qF "\$FILE" "\$PROCESSED"; then
            echo "\$FILE" >> "\$PROCESSED"
            bash "\$HOME/Music/separar_stems.sh" "\$FILE" &
        fi
    done
    sleep 5
done
WATCHEOF

chmod +x "$WATCHER_PATH"

# Detener watcher anterior si existe
launchctl unload "$PLIST_PATH" 2>/dev/null

cat > "$PLIST_PATH" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.stemsauto.watcher</string>
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
    <string>$HOME/Music/.stems_log.txt</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Music/.stems_error.txt</string>
</dict>
</plist>
PLISTEOF

launchctl load "$PLIST_PATH"
echo -e "  ${GREEN}✓ Vigilante activo — revisa Pre Editar cada 5 segundos${NC}"

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

open "$PRE_EDITAR_DIR"
