#!/bin/bash
# Script para depurar eventos del overlay flotante en tiempo real

echo "=== Monitor de eventos del Overlay Flotante ==="
echo "Filtrando logs relevantes..."
echo ""

adb logcat -c  # Limpiar logs anteriores
adb logcat | grep -E "(FloatingBubble|MotionEvent|MIUIInput|ACTION_)"
