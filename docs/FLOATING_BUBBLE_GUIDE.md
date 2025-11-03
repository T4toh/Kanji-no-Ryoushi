# Bubble Flotante Persistente - Guía de Uso

## ¿Qué es el Bubble Flotante?

Es un **ícono pequeño que flota sobre todas las apps** de tu teléfono, similar a los "chat heads" de Facebook Messenger. Te permite capturar texto japonés **sin tener que cambiar de app**.

## 🎯 Ventajas

### Antes (sin bubble):
```
Estás en un manga → Cambias a Kanji no Ryoushi → Captura de pantalla → Vuelves al manga
```

### Ahora (con bubble):
```
Estás en un manga → Tocas el bubble flotante → ¡Captura! → Sigues en el manga
```

**¡No interrumpe tu lectura/juego!**

## 🚀 Cómo Activar

### Primera Vez

1. **Abrir Kanji no Ryoushi**
2. En la pantalla de OCR, **mirar el AppBar** (barra superior)
3. Verás **dos iconos a la derecha**:
   - 🔵 **Bubble flotante** (círculo)
   - 📜 **Historial**
4. **Tocar el ícono del bubble** (círculo)
5. Si es la primera vez, dar permiso de "Mostrar sobre otras apps"
6. **¡Listo!** Verás un ícono de cámara flotante

### Estado del Bubble

- **Gris** = Inactivo
- **Verde** = Activo y flotando

## 📱 Uso del Bubble

### Posicionamiento
- **Arrastra** el bubble a cualquier parte de la pantalla
- Al soltarlo, se **pegará automáticamente** al borde más cercano
- Permanece **semi-transparente** cuando no lo usas

### Capturar desde Cualquier App

1. **Abrir la app** donde quieres capturar (Chrome, manga reader, juego, etc.)
2. **Tocar el bubble** flotante
3. Se abrirá Kanji no Ryoushi y **automáticamente** iniciará la captura
4. Aparece el **overlay de selección** sobre la pantalla
5. **Seleccionar área** con el dedo
6. **Capturar**
7. OCR se procesa automáticamente

## 🎮 Casos de Uso Ideales

### ✅ Perfecto Para:

**📖 Leer Manga Digital**
```
Lees Shōnen Jump app → Bubble visible a un lado
Kanji difícil → Tocas bubble → Seleccionas → Traducción
Vuelves a leer → Bubble sigue ahí
```

**🎮 Juegos RPG Japoneses**
```
Diálogo importante → Toca bubble → Captura → Entiendes
Juego pausado solo 3 segundos
```

**🌐 Navegación Web**
```
Artículo en japonés → Bubble siempre visible
Palabra desconocida → Toca → Busca en diccionario
```

**💬 Mensajería**
```
WhatsApp/LINE en japonés → Bubble presente
Mensaje confuso → Captura → OCR
```

## ⚙️ Configuración

### Activar/Desactivar

**Método 1: Desde la App**
- Tocar el ícono del bubble en el AppBar
- Verde = Activo
- Gris = Inactivo

**Método 2: Desde Notificación**
- Mientras esté activo, verás notificación "Captura Rápida Activa"
- Expandir notificación
- Tocar "Cerrar"

### Permisos Requeridos

El bubble necesita el mismo permiso que el overlay normal:
- **"Mostrar sobre otras apps"** (SYSTEM_ALERT_WINDOW)
- Se solicita automáticamente al activar

### Notificación Persistente

Mientras el bubble esté activo:
- ✅ Notificación visible (requerido por Android)
- ✅ Indica "Captura Rápida Activa"
- ✅ Botón para cerrar el bubble
- ✅ Prioridad baja (no molesta)

## 🔋 Impacto en Batería

- **Muy bajo**: Solo usa recursos cuando lo tocas
- **Foreground service**: Android no lo mata
- **Recomendación**: Desactivar cuando no lo uses para ahorrar batería mínima

## 🐛 Troubleshooting

### El bubble no aparece
**Causa**: Falta permiso  
**Solución**:
1. Settings → Apps → Kanji no Ryoushi
2. Permisos especiales → Mostrar sobre otras apps → Activar

### El bubble desaparece solo
**Causa**: Android mató el servicio por optimización de batería  
**Solución**:
1. Settings → Apps → Kanji no Ryoushi → Batería
2. Seleccionar "Sin restricciones"

### No puedo arrastrar el bubble
**Causa**: Está en modo "solo lectura" por restricción del sistema  
**Solución**: Reiniciar la app

### El bubble cubre contenido importante
**Solución**: Arrástralo a otra parte de la pantalla

### Al tocar el bubble, la captura falla
**Causa**: Falta permiso de MediaProjection  
**Solución**: La primera vez, aceptar "Grabar pantalla"

## 🎨 Personalización (Futuro)

Funcionalidades planeadas:
- [ ] Elegir ícono del bubble
- [ ] Ajustar tamaño del bubble
- [ ] Ocultar automáticamente después de X segundos
- [ ] Vibración al tocar
- [ ] Diferentes acciones (captura, diccionario directo, etc.)

## 📊 Comparación: Bubble vs Captura Normal

| Característica | Bubble Flotante | Captura Normal |
|----------------|-----------------|----------------|
| **Velocidad** | ⚡ Instantáneo | 🐌 Cambiar de app |
| **Fluidez** | ✅ No interrumpe | ❌ Rompe el flujo |
| **Conveniencia** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Siempre disponible** | ✅ Sí | ❌ No |
| **Batería** | ⚠️ Mínima | ✅ Nada |
| **Espacio en pantalla** | ⚠️ Ocupa espacio | ✅ Limpio |

## 🎯 Recomendación de Uso

**Activa el bubble cuando:**
- Vas a leer manga/novela por tiempo prolongado
- Estás jugando un JRPG con mucho texto
- Navegas web en japonés
- Estudias con material en japonés

**Desactiva el bubble cuando:**
- Ya terminaste de usar apps en japonés
- Necesitas pantalla completa limpia (videos, fotos)
- Vas a usar apps que no requieren OCR

## 🔒 Privacidad

- ✅ El bubble **NO captura nada** automáticamente
- ✅ Solo captura cuando **tú lo tocas**
- ✅ No envía datos a ningún servidor
- ✅ Todo el procesamiento es local

## 💡 Tips Pro

1. **Posiciona el bubble en el borde** donde menos moleste según la app
2. **Combina con modo lectura** de apps de manga
3. **Usa con apps de mensajería** para traducir rápido
4. **Perfecto para stream/videos** con subtítulos japoneses

---

**¡Disfruta de la captura instantánea de texto japonés!** 🎣🗾
