# Captura de Pantalla Flotante - Documentación

## Descripción

Sistema de overlay flotante para Android que permite capturar áreas específicas de la pantalla desde cualquier app y procesarlas con OCR. Utiliza MediaProjection API y es totalmente compatible con Android 10+ y las políticas de Google Play Store.

## Arquitectura

### Componentes Nativos (Kotlin)

#### 1. **ScreenCaptureService** (`ScreenCaptureService.kt`)
- Servicio foreground que ejecuta MediaProjection
- Muestra overlay flotante con área de selección
- Captura la pantalla y recorta el área seleccionada
- Envía imagen como ByteArray a Flutter

**Características del Overlay:**
- Vista translúcida con área de selección interactiva
- Botones de "Capturar" y "Cancelar"
- Selección por arrastre (drag)
- Ocultación temporal durante captura para evitar auto-referencia

#### 2. **MainActivity** (`MainActivity.kt`)
- Gestiona permisos de overlay (SYSTEM_ALERT_WINDOW)
- Solicita permisos de MediaProjection
- Configura MethodChannel para comunicación bidireccional con Flutter
- Gestiona lifecycle del servicio

### Componentes Flutter (Dart)

#### 3. **ScreenCaptureService** (`lib/services/screen_capture_service.dart`)
- Wrapper del MethodChannel nativo
- Métodos para verificar/solicitar permisos
- Callbacks para recibir imágenes capturadas
- Workflow completo: `captureWithPermissionCheck()`

#### 4. **OCRPage** (modificado)
- Integra botón de "Captura de pantalla" en el diálogo de selección de imagen
- Maneja callbacks de captura completa/cancelada
- Procesa automáticamente la imagen capturada con ML Kit

## Flujo de Uso

```
1. Usuario toca "Seleccionar Imagen" → "Captura de pantalla"
   ↓
2. App verifica permiso SYSTEM_ALERT_WINDOW
   ↓
3. Si no lo tiene, abre Settings para otorgarlo
   ↓
4. Solicita permiso MediaProjection (diálogo del sistema)
   ↓
5. Inicia ScreenCaptureService como foreground service
   ↓
6. Muestra overlay flotante sobre toda la UI del dispositivo
   ↓
7. Usuario arrastra para seleccionar área
   ↓
8. Usuario toca "Capturar"
   ↓
9. Overlay se oculta temporalmente
   ↓
10. MediaProjection captura pantalla completa
   ↓
11. Servicio recorta área seleccionada
   ↓
12. Envía PNG bytes a Flutter vía MethodChannel
   ↓
13. Flutter guarda en archivo temporal y procesa con OCR
```

## Configuración Requerida

### AndroidManifest.xml
```xml
<!-- Permisos -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Servicio -->
<service
    android:name=".ScreenCaptureService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="mediaProjection"/>
```

### build.gradle.kts
```kotlin
minSdk = 29 // Android 10+ requerido

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}
```

## API Pública (Flutter)

### Métodos

```dart
// Verificar si ya tiene permiso de overlay
Future<bool> checkOverlayPermission()

// Solicitar permiso de overlay (abre Settings)
Future<bool> requestOverlayPermission()

// Iniciar captura (solicita MediaProjection)
Future<bool> startScreenCapture()

// Workflow completo con verificación de permisos
Future<bool> captureWithPermissionCheck()
```

### Callbacks

```dart
// Se llama cuando la captura se completa exitosamente
ScreenCaptureService.onCaptureComplete = (Uint8List imageBytes) {
  // Procesar bytes...
};

// Se llama cuando el usuario cancela
ScreenCaptureService.onCaptureCancelled = () {
  // Manejar cancelación...
};
```

## Limitaciones y Consideraciones

### Técnicas
1. **Android 10+ únicamente**: MediaProjection en foreground service requiere API 29+
2. **Dos permisos requeridos**: 
   - SYSTEM_ALERT_WINDOW (requiere que usuario vaya a Settings)
   - MediaProjection (dialog en runtime)
3. **No funciona en modo background**: El servicio debe estar en foreground con notificación visible
4. **Formato PNG**: Las capturas se comprimen en PNG (sin pérdida)

### UX
1. Primera vez requiere 2 pasos de permisos
2. El overlay puede ser invasivo (cubre toda la pantalla)
3. Notificación persistente mientras el overlay está activo
4. No se puede capturar contenido DRM-protegido

### Políticas de Google Play
✅ **Cumple con todas las políticas:**
- No usa APIs privadas/ocultas
- No requiere root
- MediaProjection es una API pública documentada
- El usuario otorga permisos explícitamente
- Foreground service tipo `mediaProjection` es válido desde Android 14

## Testing

### Dispositivo Real
**Recomendado** - MediaProjection no funciona en emuladores sin configuración especial.

```bash
flutter run --release
```

### Emulador (opcional)
Requiere emulador con Google APIs y configurar permisos manualmente:
```bash
adb shell appops set com.example.kanji_no_ryoushi SYSTEM_ALERT_WINDOW allow
```

## Troubleshooting

### "Permission denied" en MediaProjection
- Verificar que minSdk >= 29
- Verificar que FOREGROUND_SERVICE_MEDIA_PROJECTION esté en manifest
- Verificar que el servicio tenga `foregroundServiceType="mediaProjection"`

### Overlay no se muestra
- Verificar permiso SYSTEM_ALERT_WINDOW en Settings → Apps → Kanji no Ryoushi → Permisos especiales
- En Android 11+ verificar que no esté en modo "Optimización de batería agresiva"

### Captura aparece negra
- Verificar que el overlay se oculte antes de capturar (delay de 100ms implementado)
- Algunas apps protegen contenido con FLAG_SECURE (no se puede capturar)

### Servicio se detiene solo
- Verificar que la notificación foreground esté configurada correctamente
- En Android 12+ verificar que se llame a `startForeground()` antes de los 5 segundos

## Próximas Mejoras Sugeridas

1. **Persistencia de permisos**: Cachear resultado de `checkOverlayPermission()` para evitar checks constantes
2. **UI mejorada del overlay**: Agregar guías de recorte, zoom, contraste
3. **Optimización de memoria**: Procesar bitmap en chunks para imágenes grandes
4. **Soporte multi-ventana**: Detectar y manejar split-screen mode
5. **Shortcuts**: Agregar Quick Settings Tile para captura rápida
6. **Compresión configurable**: Permitir JPEG con quality slider para menor tamaño

## Referencias

- [MediaProjection API Documentation](https://developer.android.com/reference/android/media/projection/MediaProjection)
- [Foreground Services](https://developer.android.com/guide/components/foreground-services)
- [Display over other apps permission](https://developer.android.com/reference/android/provider/Settings#ACTION_MANAGE_OVERLAY_PERMISSION)
