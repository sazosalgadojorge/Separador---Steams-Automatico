#!/bin/bash

# ============================================================
#  INSTALADOR AUTOMÁTICO — Separador de Stems
#  Corre este script y hace todo solo.
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

USUARIO=$(whoami)
MUSIC_DIR="$HOME/Music"
SCRIPT_PATH="$MUSIC_DIR/separar_stems.sh"
PROYECTOS_DIR="$HOME/Music/Editar"
PRE_EDITAR_DIR="$HOME/Music/Pre Editar"
AUTOMATOR_PATH="$HOME/Library/Application Support/Automator"
WORKFLOW_PATH="$HOME/Library/Workflows/Applications/Folder Actions/Stems Auto.workflow"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🎵  Instalador de Stems Auto       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# ── PASO 1: Homebrew ──
echo -e "${YELLOW}[1/6] Verificando Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    echo "  Instalando Homebrew (puede tardar unos minutos)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Agregar brew al PATH para Apple Silicon
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
else
    echo -e "  ${GREEN}✓ Homebrew ya está instalado${NC}"
fi

# ── PASO 2: Python 3.11 ──
echo -e "${YELLOW}[2/6] Verificando Python 3.11...${NC}"
if ! /opt/homebrew/bin/python3.11 --version &> /dev/null; then
    echo "  Instalando Python 3.11..."
    brew install python@3.11
else
    echo -e "  ${GREEN}✓ Python 3.11 ya está instalado${NC}"
fi

# ── PASO 3: pipx y Demucs ──
echo -e "${YELLOW}[3/6] Instalando Demucs...${NC}"
if ! command -v pipx &> /dev/null; then
    brew install pipx
    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v demucs &> /dev/null && ! [ -f "$HOME/.local/bin/demucs" ]; then
    pipx install demucs --python /opt/homebrew/bin/python3.11
    pipx inject demucs soundfile
    echo -e "  ${GREEN}✓ Demucs instalado${NC}"
else
    echo -e "  ${GREEN}✓ Demucs ya está instalado${NC}"
fi

# Asegurar PATH
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"

# ── PASO 4: Carpetas ──
echo -e "${YELLOW}[4/6] Creando carpetas...${NC}"
mkdir -p "$PROYECTOS_DIR"
mkdir -p "$PRE_EDITAR_DIR"
echo -e "  ${GREEN}✓ Carpetas creadas${NC}"
echo "     → Pre Editar: $PRE_EDITAR_DIR"
echo "     → Editar:     $PROYECTOS_DIR"

# ── PASO 5: Script principal ──
echo -e "${YELLOW}[5/6] Instalando script principal...${NC}"
cat > "$SCRIPT_PATH" << 'SCRIPTEOF'
#!/bin/bash
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

PROYECTOS_DIR="$HOME/Music/Editar"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}❌ No se indicó ningún archivo.${NC}"
    exit 1
fi

ARCHIVO="$1"
if [ ! -f "$ARCHIVO" ]; then
    echo -e "${RED}❌ El archivo no existe: $ARCHIVO${NC}"
    exit 1
fi

# Solo procesar archivos de audio
EXT="${ARCHIVO##*.}"
EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
if [[ "$EXT" != "mp3" && "$EXT" != "wav" && "$EXT" != "flac" && "$EXT" != "m4a" && "$EXT" != "aiff" ]]; then
    exit 0
fi

NOMBRE=$(basename "$ARCHIVO")
NOMBRE_LIMPIO="${NOMBRE%.*}"

echo ""
echo -e "${GREEN}🎵 Procesando: $NOMBRE_LIMPIO${NC}"
echo "────────────────────────────────────"

CARPETA_PROYECTO="$PROYECTOS_DIR/$NOMBRE_LIMPIO"
CARPETA_STEMS="$CARPETA_PROYECTO/Stems"
CARPETA_AUDIO="$CARPETA_PROYECTO/Audio"
CARPETA_ABLETON="$CARPETA_PROYECTO/Ableton"

mkdir -p "$CARPETA_STEMS" "$CARPETA_AUDIO" "$CARPETA_ABLETON"
cp "$ARCHIVO" "$CARPETA_AUDIO/"

echo -e "📁 Proyecto en: ${YELLOW}$CARPETA_PROYECTO${NC}"
echo ""
echo -e "🔪 Separando stems con Demucs..."

demucs -n htdemucs --out "$CARPETA_STEMS" "$ARCHIVO"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Demucs encontró un error.${NC}"
    osascript -e "display notification \"❌ Error al procesar: $NOMBRE_LIMPIO\" with title \"Separador de Stems\" sound name \"Basso\""
    exit 1
fi

STEMS_GENERADOS="$CARPETA_STEMS/htdemucs/$NOMBRE_LIMPIO"
if [ -d "$STEMS_GENERADOS" ]; then
    mv "$STEMS_GENERADOS"/*.wav "$CARPETA_STEMS/"
    rm -rf "$CARPETA_STEMS/htdemucs"
fi

for STEM in "$CARPETA_STEMS"/*.wav; do
    STEM_NOMBRE=$(basename "$STEM")
    mv "$STEM" "$CARPETA_STEMS/${NOMBRE_LIMPIO}_${STEM_NOMBRE}"
done

echo ""
echo -e "${GREEN}✅ ¡Listo! Stems generados:${NC}"
ls "$CARPETA_STEMS"
echo ""
echo -e "${YELLOW}💡 Arrastra la carpeta Stems directo a Ableton Live${NC}"

osascript -e "display notification \"✅ Stems listos: $NOMBRE_LIMPIO\" with title \"Separador de Stems\" sound name \"Glass\""
SCRIPTEOF

chmod +x "$SCRIPT_PATH"
echo -e "  ${GREEN}✓ Script instalado en $SCRIPT_PATH${NC}"

# ── PASO 6: Workflow de Automator ──
echo -e "${YELLOW}[6/6] Creando workflow de Automator...${NC}"
mkdir -p "$WORKFLOW_PATH/Contents"

cat > "$WORKFLOW_PATH/Contents/document.wflow" << WFLOWEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>521.1</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMAccepts</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Optional</key>
                    <true/>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.path</string>
                    </array>
                </dict>
                <key>AMActionVersion</key>
                <string>2.0.3</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>AMParameterProperties</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <dict/>
                    <key>CheckedForUserDefaultShell</key>
                    <dict/>
                    <key>inputMethod</key>
                    <dict/>
                    <key>shell</key>
                    <dict/>
                    <key>source</key>
                    <dict/>
                </dict>
                <key>AMProvides</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.path</string>
                    </array>
                </dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>for f in "$@"
do
    bash "$HOME/Music/separar_stems.sh" "$f"
done</string>
                    <key>CheckedForUserDefaultShell</key>
                    <true/>
                    <key>inputMethod</key>
                    <integer>1</integer>
                    <key>shell</key>
                    <string>/bin/zsh</string>
                    <key>source</key>
                    <string></string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.RunShellScript</string>
                <key>CFBundleVersion</key>
                <string>2.0.3</string>
                <key>CanShowSelectedItemsWhenRun</key>
                <false/>
                <key>CanShowWhenRun</key>
                <true/>
                <key>Category</key>
                <array>
                    <string>AMCategoryUtilities</string>
                </array>
                <key>Class Name</key>
                <string>RunShellScriptAction</string>
                <key>InputUUID</key>
                <string>6A3B2C1D-4E5F-6A7B-8C9D-0E1F2A3B4C5D</string>
                <key>Keywords</key>
                <array>
                    <string>Shell</string>
                    <string>Script</string>
                    <string>Command</string>
                    <string>Run</string>
                    <string>Unix</string>
                </array>
                <key>OutputUUID</key>
                <string>1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D</string>
                <key>UUID</key>
                <string>9F8E7D6C-5B4A-3928-1706-F5E4D3C2B1A0</string>
                <key>UnlocalizedApplications</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>arguments</key>
                <dict/>
                <key>isViewVisible</key>
                <true/>
                <key>location</key>
                <string>309.000000:388.000000</string>
                <key>nibPath</key>
                <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/English.lproj/main.nib</string>
            </dict>
            <key>isViewVisible</key>
            <true/>
        </dict>
    </array>
    <key>connectors</key>
    <dict/>
    <key>workflowMetaData</key>
    <dict>
        <key>folderActionFolderPath</key>
        <string>$PRE_EDITAR_DIR</string>
        <key>workflowTypeIdentifier</key>
        <string>com.apple.Automator.folderaction</string>
    </dict>
</dict>
</plist>
WFLOWEOF

echo -e "  ${GREEN}✓ Workflow creado${NC}"

# Activar Folder Actions via osascript
osascript << APPLESCRIPT
tell application "System Events"
    set folder actions enabled to true
end tell
APPLESCRIPT

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅  Instalación completa        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "  Solo falta conectar Automator a tu carpeta:"
echo ""
echo -e "  ${YELLOW}1.${NC} Abre Finder y ve a tu carpeta 'Pre Editar'"
echo -e "  ${YELLOW}2.${NC} Clic derecho → 'Folder Actions Setup...'"
echo -e "  ${YELLOW}3.${NC} Haz clic en '+' del lado derecho"
echo -e "  ${YELLOW}4.${NC} Selecciona 'Stems Auto' y haz clic en 'Attach'"
echo ""
echo -e "  Tu carpeta Pre Editar está en:"
echo -e "  ${BLUE}$PRE_EDITAR_DIR${NC}"
echo ""

# Abrir la carpeta en Finder para facilitar el último paso
open "$PRE_EDITAR_DIR"
