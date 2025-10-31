# Kanji no Ryoushi

Aplicación Flutter para reconocimiento de texto japonés (OCR) usando Google ML Kit.

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

### 🏗️ Arquitectura

```
lib/
├── main.dart              # Configuración de la app
├── screens/
│   └── ocr_page.dart     # Pantalla principal con UI
└── services/
    └── ocr_service.dart  # Lógica de OCR con ML Kit
```

**Modular y escalable**: Separación clara entre UI y lógica de negocio.

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
4. **Ver resultado**: El texto reconocido aparece automáticamente
5. **Copiar texto**: Selecciona y copia el texto reconocido

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
- `flutter_launcher_icons`: Generación de íconos para la app

## 🎨 Personalización

### Tema

La app soporta automáticamente modo claro y oscuro siguiendo la configuración del sistema. Los colores se basan en Material 3 con un color principal púrpura.

### Ícono

Para cambiar el ícono de la app:

1. Reemplaza `assets/images/icon.jpg` con tu imagen
2. Ejecuta: `dart run flutter_launcher_icons`

## 📝 Desarrollo

### Ejecutar tests

```bash
flutter test
```

### Analizar código

```bash
flutter analyze
```

### Compilar release

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
