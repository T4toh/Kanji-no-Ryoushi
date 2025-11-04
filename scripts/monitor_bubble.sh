#!/bin/bash
# Monitor específico para el FloatingBubbleService y ScreenCaptureService

echo "=== Monitor Completo de Bubble + Captura + Flutter ==="
echo "Esperando eventos del bubble, servicio de captura y callbacks a Flutter..."
echo ""

adb logcat -c
adb logcat | grep -E "(FloatingBubble|ScreenCapture|MainActivity.*(capture|Callback)|anji_no_ryoushi.*(Click|Bubble|Capture|overlay))"
