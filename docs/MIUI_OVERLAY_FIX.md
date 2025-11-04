# Solución de Problemas: Overlay en Tablets MIUI/Xiaomi

## Problema

El overlay flotante no responde a toques en tablets Xiaomi con MIUI. Los logs muestran:

- `ACTION_CANCEL` después de `ACTION_DOWN`
- Eventos interceptados pero cancelados por el sistema
- `windowName ''` indica pérdida de foco de la ventana

## Causa

MIUI tiene restricciones adicionales de seguridad para overlays flotantes. Los `WindowManager.LayoutParams` predeterminados no son suficientes para interceptar eventos táctiles correctamente.

## Solución Implementada

### 1. Flags de WindowManager actualizados

```kotlin
WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
```

**Cambios clave:**

- `FLAG_NOT_TOUCH_MODAL`: Permite que los toques fuera del bubble lleguen a otras apps
- `FLAG_WATCH_OUTSIDE_TOUCH`: Recibe notificaciones de toques externos (necesario para MIUI)

### 2. OnTouchListener mejorado

- Manejo explícito de `ACTION_CANCEL` (cuando MIUI cancela el evento)
- Tracking de tiempo de presión para distinguir clicks de drags
- Uso de `postDelayed()` para evitar conflictos con el sistema
- Variables de estado más robustas (`moved`, `downTime`)

### 3. Consumo correcto de eventos

- Siempre devolver `true` en `ACTION_DOWN`, `ACTION_MOVE`, `ACTION_UP`
- Devolver `true` en `ACTION_CANCEL` para reconocer la cancelación
- Usar `try-catch` en `updateViewLayout()` para evitar crashes

## Soluciones Adicionales si el Problema Persiste

### A. Configuración de MIUI necesaria

El usuario DEBE habilitar manualmente los permisos en MIUI:

1. **Permiso de Overlay** (SYSTEM_ALERT_WINDOW)
   - Ya se solicita programáticamente
2. **Permiso "Mostrar ventanas flotantes"**

   - `Configuración` → `Apps` → `Kanji no Ryoushi` → `Permisos` → `Mostrar ventanas emergentes` → **Permitir**

3. **Permiso "Iniciar en segundo plano"**

   - `Configuración` → `Apps` → `Kanji no Ryoushi` → `Permisos` → `Iniciar en segundo plano` → **Permitir**

4. **Desactivar optimización de batería**
   - `Configuración` → `Batería` → `Ahorro de batería` → `Kanji no Ryoushi` → **Sin restricciones**

### B. Alternativa: Usar ClickableSpan en el Bubble

Si los problemas continúan, cambiar de `OnTouchListener` a un `OnClickListener` simple:

```kotlin
bubbleView?.setOnClickListener {
    onBubbleClicked()
}
```

Esto elimina el drag pero garantiza que los clicks funcionen.

### C. Fallback: Cambiar TYPE_APPLICATION_OVERLAY

Para Android < 11 en MIUI, podría funcionar mejor:

```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
} else {
    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
}
```

⚠️ **Nota**: `TYPE_ACCESSIBILITY_OVERLAY` requiere servicio de accesibilidad activo.

## Testing

### Script de monitoreo específico

```bash
./scripts/monitor_bubble.sh
```

Esto muestra en tiempo real:

- Logs del `FloatingBubbleService`
- Eventos `onTouch` recibidos por el bubble
- Errores de WindowManager
- Estado de la ventana

### Verificación paso a paso

1. Abrir la app
2. Activar el bubble flotante
3. Ejecutar `./scripts/monitor_bubble.sh` en una terminal
4. Tocar el bubble en la tablet
5. Ver los logs en la terminal:
   - ✅ Debe mostrar: `FloatingBubble: onTouch: action=...`
   - ✅ Debe mostrar: `FloatingBubble: Click detectado!`
   - ❌ Si muestra: `Unknown window type: 2997` → Problema de permisos MIUI
   - ❌ Si no muestra nada → El bubble no se creó

### Debug adicional

Para ver si el bubble se añadió correctamente:

```bash
adb logcat -d | grep "FloatingBubble.*añadido"
```

Debe mostrar:

```
FloatingBubble: Bubble añadido correctamente a WindowManager
FloatingBubble: Layout params: width=..., height=..., type=..., flags=...
```

## Referencias

- [Android Overlay Best Practices](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#TYPE_APPLICATION_OVERLAY)
- [MIUI Developer Guidelines](https://dev.mi.com/docs/appsmarket/technical_docs/permission/)
- [StackOverflow: MIUI Overlay Issues](https://stackoverflow.com/questions/45074684/miui-overlay-permission-issue)
