#!/bin/bash

# Script para regenerar los íconos de la app
# Asegúrate de tener el ícono en assets/images/icon.jpg antes de ejecutar

echo "🎨 Regenerando íconos de la app..."
echo ""

# Verificar que existe el archivo de ícono
if [ ! -f "assets/images/icon.jpg" ]; then
    echo "❌ Error: No se encontró assets/images/icon.jpg"
    echo "   Por favor, coloca tu ícono en esa ruta antes de continuar."
    exit 1
fi

echo "✅ Ícono encontrado: assets/images/icon.jpg"
echo ""

# Limpiar build anterior
echo "🧹 Limpiando build anterior..."
flutter clean
echo ""

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get
echo ""

# Generar íconos
echo "🚀 Generando íconos para Android e iOS..."
dart run flutter_launcher_icons
echo ""

# Verificar resultado
if [ $? -eq 0 ]; then
    echo "✅ ¡Íconos generados exitosamente!"
    echo ""
    echo "📱 Los íconos han sido actualizados para:"
    echo "   - Android (todas las densidades + ícono adaptativo)"
    echo "   - iOS (AppIcon)"
    echo ""
    echo "💡 Próximos pasos:"
    echo "   1. Ejecuta 'flutter run' para ver los cambios"
    echo "   2. En dispositivos físicos, es posible que necesites reinstalar la app"
else
    echo "❌ Error al generar íconos"
    exit 1
fi
