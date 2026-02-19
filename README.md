# 🎵 Stems Auto — Separador de Stems para Edits

Automatización completa para separar stems con **Demucs** en Mac. Suelta una canción en tu carpeta y en minutos tienes vocals, drums, bass y other listos para Ableton.

---

## ⚡ Instalación en un comando

Abre **Terminal** y pega esto:

```bash
curl -fsSL https://raw.githubusercontent.com/sazosalgadojorge/Separador-Steams-Automatico/main/instalar.sh | bash
```

El instalador hace todo automáticamente:

- Instala Homebrew, Python 3.11, FFmpeg, pipx y Demucs
- Crea las carpetas `~/Music/Pre Editar` y `~/Music/Editar`
- Instala el script de separación
- Activa un servicio en segundo plano (`launchd`) que vigila la carpeta

Compatible con **Apple Silicon (M1/M2/M3)** e **Intel**.

---

## 🎬 Cómo funciona

```
Sueltas canción en ~/Music/Pre Editar/
        ↓
El servicio detecta el archivo (cada 5 s)
        ↓
Demucs separa los stems (1–5 min según Mac)
        ↓
🔔 Notificación en tu Mac
        ↓
Carpeta lista en ~/Music/Editar/<nombre>/ con:
  ├── Stems/   → vocals, drums, bass, other (.wav)
  ├── Audio/   → canción original
  └── Ableton/ → guarda tu .als aquí
```

---

## 📋 Requisitos

- macOS 12 Monterey o superior
- Conexión a internet (solo durante la instalación)
- ~4 GB de espacio en disco (modelos de Demucs + dependencias)

---

## 🔧 Comandos útiles

| Comando | Descripción |
|---------|-------------|
| `stems-limpiar` | Borra el registro de archivos procesados para que se reprocesen |

> Abre una terminal nueva después de instalar para que el alias quede disponible.

---

## ❓ Problemas comunes

| Error | Solución |
|-------|----------|
| `command not found: demucs` | Cierra y vuelve a abrir Terminal |
| El servicio no arranca | Cierra sesión y vuelve a entrar, o reinicia el Mac |
| Tarda mucho | Normal, Demucs es intensivo. M1/M2/M3 son más rápidos que Intel |
| La notificación no aparece | Sistema → Notificaciones → Script Editor → activar Alertas |
| Quiero reprocesar una canción | Ejecuta `stems-limpiar` en Terminal y vuelve a soltar el archivo |

---

## 📁 Archivos del repo

| Archivo | Descripción |
|---------|-------------|
| `instalar.sh` | Instalador automático — corre este primero |

---

Hecho para productores que hacen edits 🎧
