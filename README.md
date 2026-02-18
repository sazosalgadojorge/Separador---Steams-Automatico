# 🎵 Stems Auto — Separador de Stems para Edits

Automatización completa para separar stems con **Demucs** en Mac. Suelta una canción en tu carpeta y en minutos tienes vocals, drums, bass y other listos para Ableton.

---

## ⚡ Instalación en un comando

Abre **Terminal** y pega esto:

```bash
curl -fsSL https://raw.githubusercontent.com/TUUSUARIO/stems-auto/main/instalar.sh | bash
```

> Reemplaza `TUUSUARIO` con tu usuario de GitHub antes de compartirlo.

El instalador hace todo automáticamente:
- Instala Homebrew, Python 3.11, pipx y Demucs
- Crea las carpetas `Pre Editar` y `Editar` en tu Music
- Instala el script principal
- Crea el workflow de Automator

Al final solo necesitas **4 clics** para conectar la carpeta (el instalador te guía).

---

## 🎬 Cómo funciona

```
Sueltas canción en Pre Editar/
        ↓
Automator detecta el archivo
        ↓
Demucs separa los stems (1-5 min)
        ↓
🔔 Notificación en tu Mac
        ↓
Carpeta lista en Editar/ con:
  ├── Stems/   → vocals, drums, bass, other
  ├── Audio/   → canción original
  └── Ableton/ → guarda tu .als aquí
```

---

## 📋 Requisitos

- macOS 12 Monterey o superior
- Conexión a internet (solo para la instalación)
- Ableton Live (o cualquier DAW)

---

## 🔧 Instalación manual (paso a paso)

Si prefieres hacerlo tú mismo, descarga los archivos y sigue la `Guia_Stems_Automatizacion.docx` incluida en el repo.

---

## ❓ Problemas comunes

| Error | Solución |
|-------|----------|
| `command not found: demucs` | Cierra y vuelve a abrir Terminal |
| Automator no hace nada | Verifica que "Pass input" sea "as arguments" |
| Tarda mucho | Normal, Demucs es intensivo. M1/M2 son más rápidos |
| La notificación no aparece | Ve a Configuración → Notificaciones → Automator → Alertas |

---

## 📁 Archivos del repo

| Archivo | Descripción |
|---------|-------------|
| `instalar.sh` | Instalador automático — corre esto primero |
| `separar_stems.sh` | Script principal (se instala automáticamente) |
| `Guia_Stems_Automatizacion.docx` | Guía detallada con capturas |

---

Hecho para productores que hacen edits 🎧
