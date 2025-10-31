# 漢字の漁師 🎣 🗾

Aplicación Flutter para reconocimiento de texto japonés (OCR) usando Google ML Kit.

## ¿Por qué hice este repo?

Todo lo que encontré en internet usa recursos gratuitos para cobrarte por copiar el texto de una imagen, ante esto, e invocando a a Bender, se me ocurrió hacer mi propia app de OCR con juego de azar y mujerzuelas. Todo puede cambiar y el código es basura.

## Características

### ✨ Funcionalidades Principales

- 📸 **Captura desde cámara**: Toma fotos directamente desde la app
- 🖼️ **Selección de galería**: Elige imágenes existentes de tu teléfono
- 🎌 **Reconocimiento de japonés**: OCR optimizado para texto japonés (Hiragana, Katakana, Kanji)
- 📋 **Texto seleccionable**: Copia fácilmente el texto reconocido
- 🔄 **Reprocesamiento**: Vuelve a procesar la misma imagen si es necesario
- 🎨 **Imagen de ejemplo**: Prueba la app con una imagen de ejemplo incluida
- 🌓 **Tema adaptativo**: Soporte completo para modo claro y oscuro
- 🎯 **Ícono personalizado**: Ícono único de la app
- 📚 **Historial persistente**: Guarda automáticamente todos los textos reconocidos
- 📦 **Bloques de texto**: Separa el texto en bloques para facilitar la copia
- 🌍 **Detección de idioma**: Identifica automáticamente el idioma reconocido y muestra su bandera

### 🏗️ Arquitectura

```
lib/
├── main.dart                   # Configuración de la app
├── models/
│   └── ocr_history_entry.dart # Modelo de entrada del historial
├── screens/
│   ├── ocr_page.dart          # Pantalla principal con UI
│   └── history_page.dart      # Pantalla de historial
└── services/
   ├── ocr_service.dart       # Lógica de OCR con ML Kit
   ├── history_service.dart   # Gestión del historial persistente
   └── image_service.dart     # Utilidades de recorte / manipulación de imagen
└── widgets/
   └── image_cropper_widget.dart # Editor de recorte modular (zoom, pan, seleccionar, mover)
```

**Modular y escalable**: Separación clara entre UI, lógica de negocio y modelos.

## 🚀 Instalación y Uso

### Prerrequisitos

- Flutter SDK >= 3.9.2
- Android Studio / Xcode (para compilar en dispositivos)

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/T4toh/Kanji-no-Ryoushi.git
cd kanji_no_ryoushi

# Instalar dependencias
flutter pub get

# Ejecutar en dispositivo/emulador
flutter run
```

### Uso de la App

1. **Al abrir la app**: Se carga automáticamente una imagen de ejemplo
2. **Seleccionar imagen**: Toca el botón "Seleccionar Imagen" o "Cambiar Imagen"
3. **Elegir fuente**:
   - 📷 **Cámara**: Toma una foto nueva
   - 🖼️ **Galería**: Selecciona de tus fotos
   - 🎴 **Imagen de ejemplo**: Vuelve al ejemplo predeterminado
4. **Ver resultado**: El texto reconocido aparece automáticamente y se guarda en el historial
5. **Copiar texto**: Selecciona y copia el texto reconocido
6. **Ver historial**: Toca el ícono de historial en la esquina superior derecha
   - 🌍 **Idiomas detectados**: Cada entrada muestra la bandera del idioma reconocido
   - 📖 **Ver bloques**: Los textos se separan automáticamente en bloques
   - 📋 **Copiar bloques**: Copia bloques individuales o el texto completo
   - 🗑️ **Eliminar**: Elimina entradas individuales o todo el historial

## ✂️ Editor de recorte (nuevo)

Uso rápido:

- Toca la imagen (ejemplo o seleccionada) en la pantalla principal para abrir el editor de recorte.
- Arrastra sobre la imagen para crear un rectángulo de selección.
- Si arrastras dentro del rectángulo, mueves la selección (útil para ajustar sin cambiar el tamaño).
- Pellizca para hacer zoom y arrastra para mover la vista (el editor usa `InteractiveViewer` para precisión).
- Pulsa "Recortar" para confirmar: el recorte se guarda como imagen temporal, reemplaza la imagen actualmente seleccionada y se vuelve a ejecutar el OCR automáticamente (y se guarda en el historial).

Archivos y arquitectura:

- `lib/services/image_service.dart`: función `cropImage(File, CropRect)` que decodifica la imagen, aplica el recorte y escribe un JPEG temporal.
- `lib/widgets/image_cropper_widget.dart`: widget modular que muestra la imagen, permite seleccionar y mover la selección, y devuelve el `File` recortado mediante el callback `onCropped`.

Dependencia nueva:

- `image` — usada por `ImageService` para decodificar/recortar/encodear en Dart. Añadida en `pubspec.yaml`.

Notas de usabilidad:

- Para recortes muy grandes o imágenes pesadas, el proceso de recorte se realiza en Dart y puede tardar; para rendimiento extremo se puede integrar un recortador nativo más adelante.
- Podemos añadir handles de redimensionado en el editor (esquinas) y guardar miniaturas en el historial como mejoras futuras.

## 📱 Permisos

### Android

- Cámara
- Lectura de almacenamiento externo
- Lectura de imágenes (Android 13+)

### iOS

- Acceso a cámara
- Acceso a biblioteca de fotos

## 🛠️ Dependencias Principales

- `google_mlkit_text_recognition`: OCR con ML Kit
- `image_picker`: Selección de imágenes
- `path_provider`: Gestión de archivos temporales
- `shared_preferences`: Almacenamiento persistente del historial
- `flutter_launcher_icons`: Generación de íconos para la app

## 🎨 Personalización

### Historial

El historial guarda automáticamente hasta 50 entradas. Los textos se separan en bloques de las siguientes formas:

- **Párrafos**: Bloques separados por líneas en blanco
- **Líneas**: Cuando no hay párrafos, cada línea se convierte en un bloque

Puedes copiar bloques individuales o el texto completo desde la vista de detalle.

### Detección de Idioma

La app detecta automáticamente el idioma del texto reconocido usando ML Kit.

**Idiomas soportados con banderas:**

- 🇯🇵 Japonés
- 🇨🇳 Chino
- 🇰🇷 Coreano
- 🇺🇸 Inglés
- 🇪🇸 Español
- 🇫🇷 Francés
- 🇩🇪 Alemán
- 🇮🇹 Italiano
- 🇵🇹 Portugués
- 🇷🇺 Ruso
- 🇸🇦 Árabe
- 🇮🇳 Hindi
- 🇹🇭 Tailandés
- 🇻🇳 Vietnamita
- 🌐 Y más...

Las banderas aparecen automáticamente en el historial para identificar rápidamente el idioma del texto.

### Tema

La app soporta automáticamente modo claro y oscuro siguiendo la configuración del sistema. Los colores se basan en Material 3 con un color principal púrpura.

### Ícono

Para cambiar el ícono de la app:

1. Reemplaza `assets/images/icon.jpg` con tu imagen (preferiblemente 1024x1024px)
2. Ejecuta el script automático:

   ```bash
   ./generate_icons.sh
   ```

   O manualmente:

   ```bash
   flutter clean
   flutter pub get
   dart run flutter_launcher_icons
   ```

El script `generate_icons.sh` automatiza todo el proceso:

- Verifica que exista el archivo de ícono
- Limpia builds anteriores
- Obtiene dependencias
- Genera íconos para Android e iOS
- Muestra confirmación y próximos pasos

## 📝 Desarrollo

### Scripts de Utilidad

El proyecto incluye scripts para facilitar tareas comunes:

#### `./generate_icons.sh` - Regenerar Íconos

Regenera automáticamente los íconos de la app para Android e iOS.

```bash
./generate_icons.sh
```

#### `./dev.sh` - Herramientas de Desarrollo

Menú interactivo con opciones para:

- Ejecutar tests
- Analizar código
- Regenerar íconos
- Limpiar proyecto
- Obtener dependencias
- Ejecutar app
- Compilar APK
- Ejecutar todo (limpieza completa + análisis + tests)

```bash
./dev.sh
```

### Comandos Manuales

#### Ejecutar tests

```bash
flutter test
```

#### Analizar código

```bash
flutter analyze
```

#### Compilar release

```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## 🔧 Configuración ML Kit

### Android

Dependencia nativa en `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.google.mlkit:text-recognition-japanese:16.0.0")
}
```

### iOS

Configuración automática vía CocoaPods.

## 📄 Licencia

Este proyecto es de código abierto.

---

Desarrollado con ❤️ usando Flutter por un gordo barbudo.
