# Testing del Sistema de Captura de Pantalla

## Setup Inicial

### 1. Compilar y ejecutar en dispositivo real

```bash
# Conectar dispositivo Android 10+ por USB
adb devices

# Compilar y ejecutar
flutter run --release
```

**Nota:** MediaProjection no funciona correctamente en emuladores. Se recomienda usar dispositivo real.

### 2. Otorgar permisos (primera vez)

La app solicitará automáticamente:
1. **Overlay permission**: Se abrirá Settings
2. **MediaProjection**: Diálogo del sistema "Iniciar grabación de pantalla"

## Test Cases

### ✅ Test 1: Flujo Completo Básico

**Objetivo:** Verificar que el overlay aparece y captura correctamente

**Pasos:**
1. Abrir Kanji no Ryoushi
2. Tocar "Seleccionar Imagen"
3. Tocar "Captura de pantalla"
4. Si es primera vez, otorgar permisos
5. Verificar que aparece overlay translúcido
6. Arrastrar dedo para seleccionar área pequeña
7. Tocar "Capturar"
8. Verificar que la imagen aparece en OCRPage
9. Verificar que OCR se ejecuta automáticamente

**Resultado esperado:**
- Overlay se muestra correctamente
- Área seleccionada se visualiza con borde verde
- Captura se procesa y muestra texto reconocido

---

### ✅ Test 2: Captura desde Otra App

**Objetivo:** Verificar captura sobre otras aplicaciones

**Pasos:**
1. Abrir Chrome y navegar a: `https://ja.wikipedia.org`
2. Volver a Kanji no Ryoushi (sin cerrar Chrome)
3. Iniciar "Captura de pantalla"
4. Overlay debe aparecer sobre toda la UI
5. Volver mentalmente a Chrome (el overlay cubre todo)
6. Seleccionar área con texto japonés
7. Capturar

**Resultado esperado:**
- Se captura contenido de Chrome
- OCR reconoce texto japonés de Wikipedia

---

### ✅ Test 3: Cancelación

**Objetivo:** Verificar que la cancelación funciona correctamente

**Pasos:**
1. Iniciar captura
2. Seleccionar área
3. Tocar "Cancelar"

**Resultado esperado:**
- Overlay se cierra
- Servicio se detiene
- Snackbar muestra "Captura cancelada"
- No se procesa nada

---

### ✅ Test 4: Selección Inválida

**Objetivo:** Verificar manejo de áreas muy pequeñas

**Pasos:**
1. Iniciar captura
2. Hacer un tap sin arrastrar (área < 10px)
3. Tocar "Capturar"

**Resultado esperado:**
- Se captura pantalla completa (fallback)
- OCR procesa toda la imagen

---

### ✅ Test 5: Permisos Revocados

**Objetivo:** Verificar manejo cuando se revoca permiso overlay

**Pasos:**
1. Settings → Apps → Kanji no Ryoushi
2. Permisos especiales → Mostrar sobre otras apps → Desactivar
3. Volver a la app
4. Intentar captura

**Resultado esperado:**
- Snackbar muestra mensaje de error sobre permiso requerido
- Se abre Settings automáticamente (si se usa `requestOverlayPermission()`)

---

### ✅ Test 6: Notificación Foreground

**Objetivo:** Verificar que el servicio crea notificación correctamente

**Pasos:**
1. Iniciar captura
2. Deslizar barra de notificaciones mientras overlay está activo

**Resultado esperado:**
- Notificación visible: "Captura de Pantalla Activa"
- Icono de cámara
- Al capturar, notificación desaparece automáticamente

---

### ✅ Test 7: Múltiples Capturas Consecutivas

**Objetivo:** Verificar que no hay memory leaks

**Pasos:**
1. Realizar 10 capturas consecutivas
2. Verificar memoria en Android Studio Profiler

**Resultado esperado:**
- Memoria se mantiene estable
- No hay crashes
- Cada captura se procesa correctamente

---

### ✅ Test 8: Rotación de Pantalla

**Objetivo:** Verificar comportamiento en landscape/portrait

**Pasos:**
1. Iniciar captura en portrait
2. Rotar a landscape mientras overlay está activo
3. Capturar

**Resultado esperado:**
- Overlay se adapta a nueva orientación
- Captura refleja orientación correcta
- Coordenadas de selección son correctas

---

## Tests de Edge Cases

### ⚠️ Test 9: App con FLAG_SECURE

**Setup:**
1. Instalar app bancaria o Netflix
2. Abrir contenido protegido
3. Intentar capturar

**Resultado esperado:**
- Captura aparece negra (comportamiento normal de Android)
- OCR no encuentra texto

---

### ⚠️ Test 10: Batería Baja

**Setup:**
1. Configurar batería < 15%
2. Activar modo ahorro de energía
3. Intentar captura

**Resultado esperado:**
- Funciona normalmente (foreground service tiene prioridad)
- O muestra mensaje si Android mata el servicio

---

## Verificación de Compliance

### ✅ Checklist Google Play

- [ ] No usa APIs ocultas/privadas
- [ ] Declara permiso SYSTEM_ALERT_WINDOW en manifest
- [ ] Declara FOREGROUND_SERVICE_MEDIA_PROJECTION
- [ ] Notificación visible durante servicio foreground
- [ ] Solicita permisos en runtime
- [ ] minSdk >= 29 (Android 10)
- [ ] targetSdk >= 34 (recomendado para 2024+)

### Comando de verificación

```bash
# Verificar permisos declarados
adb shell dumpsys package com.example.kanji_no_ryoushi | grep permission

# Verificar servicio foreground activo durante captura
adb shell dumpsys activity services com.example.kanji_no_ryoushi

# Ver logs en tiempo real
adb logcat | grep -i "kanji\|mediaprojection\|overlay"
```

---

## Debugging

### Ver logs del servicio

```bash
adb logcat -s ScreenCaptureService:V MainActivity:V
```

### Forzar crash para testing

En `ScreenCaptureService.kt`, agregar temporalmente:
```kotlin
private fun processCapture() {
    throw RuntimeException("Test crash")
}
```

### Inspeccionar layout del overlay

```bash
adb shell uiautomator dump
adb pull /sdcard/window_dump.xml
```

---

## Performance Benchmarks

### Tiempos Esperados

| Operación | Tiempo | Notas |
|-----------|--------|-------|
| Mostrar overlay | < 500ms | Desde tap hasta visible |
| Captura + recorte | < 1000ms | Depende de resolución |
| OCR (imagen pequeña) | 500-2000ms | 100x100px a 500x500px |
| OCR (imagen grande) | 2000-5000ms | > 1000x1000px |

### Medir performance

```dart
// En _processSelectedImage()
final stopwatch = Stopwatch()..start();
final result = await _ocrService.processImageFromFile(_selectedImage!);
print('OCR took ${stopwatch.elapsedMilliseconds}ms');
```

---

## Checklist Final Pre-Release

- [ ] Todos los tests pasan
- [ ] No hay memory leaks (verificado con Profiler)
- [ ] Funciona en Android 10, 11, 12, 13, 14
- [ ] Funciona en diferentes resoluciones
- [ ] Documentación actualizada
- [ ] Mensajes de error son user-friendly
- [ ] Permisos se solicitan con contexto claro
- [ ] ProGuard rules no rompen MediaProjection
- [ ] APK firmado con release key
