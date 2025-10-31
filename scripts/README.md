# Scripts de Utilidad

Este directorio contiene documentación de los scripts de utilidad del proyecto. Los scripts están en la raíz del proyecto para facilitar su ejecución.

## Scripts Disponibles

### 1. generate_icons.sh

Script para regenerar automáticamente los íconos de la aplicación en Android e iOS.

#### Uso

```bash
./generate_icons.sh
```

#### Qué hace

1. ✅ Verifica que exista el archivo `assets/images/icon.jpg`
2. 🧹 Limpia builds anteriores con `flutter clean`
3. 📦 Obtiene dependencias con `flutter pub get`
4. 🎨 Genera íconos para todas las plataformas con `flutter_launcher_icons`
5. ✅ Muestra confirmación y próximos pasos

#### Requisitos

- El archivo de ícono debe estar en: `assets/images/icon.jpg`
- Tamaño recomendado: 1024x1024 píxeles
- Formato: JPG o PNG

#### Salida

El script genera:

- **Android**:
  - Íconos en múltiples densidades (mipmap-hdpi, mipmap-xhdpi, etc.)
  - Ícono adaptativo con foreground y background
  - Archivo `colors.xml` si es necesario
- **iOS**:
  - AppIcon completo en todos los tamaños requeridos

#### Notas

- En dispositivos físicos, puede ser necesario reinstalar la app para ver el nuevo ícono
- El script está configurado para usar bash (#!/bin/bash)

---

### 2. dev.sh

Menú interactivo con herramientas comunes de desarrollo.

#### Uso

```bash
./dev.sh
```

#### Opciones Disponibles

1. **🧪 Ejecutar tests**: Corre todos los tests del proyecto
2. **🔍 Analizar código**: Ejecuta `flutter analyze` para encontrar problemas
3. **🎨 Regenerar íconos**: Llama al script `generate_icons.sh`
4. **🧹 Limpiar proyecto**: Ejecuta `flutter clean`
5. **📦 Obtener dependencias**: Ejecuta `flutter pub get`
6. **🚀 Ejecutar app**: Inicia la app en modo debug
7. **📱 Compilar APK**: Genera APK release para Android
8. **🔄 Todo**: Limpieza completa + análisis + tests

#### Características

- Menú interactivo con colores
- Confirmación después de cada acción
- Manejo de errores
- Output con emojis para mejor UX

#### Flujo de Trabajo Recomendado

Para preparar la app antes de un commit:
```bash
./dev.sh
# Selecciona opción 8 (Todo)
```

Para desarrollo diario:
```bash
./dev.sh
# Selecciona opción 6 (Ejecutar app)
```
