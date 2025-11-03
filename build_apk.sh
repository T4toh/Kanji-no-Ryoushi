#!/bin/bash

# Script para buildear APK de Kanji no Ryoushi
# Uso: ./build_apk.sh [release|debug]

set -e  # Salir si hay algún error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BUILD_TYPE="${1:-release}"  # Por defecto: release

echo -e "${GREEN}🏗️  Construyendo APK en modo: $BUILD_TYPE${NC}"
echo ""

# Limpiar build anterior
echo -e "${YELLOW}🧹 Limpiando builds anteriores...${NC}"
flutter clean

# Obtener dependencias
echo -e "${YELLOW}📦 Obteniendo dependencias...${NC}"
flutter pub get

# Construir APK
if [ "$BUILD_TYPE" = "release" ]; then
    echo -e "${YELLOW}🔨 Construyendo APK de release...${NC}"
    flutter build apk --release
    
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    
elif [ "$BUILD_TYPE" = "debug" ]; then
    echo -e "${YELLOW}🔨 Construyendo APK de debug...${NC}"
    flutter build apk --debug
    
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    
else
    echo -e "${RED}❌ Tipo de build inválido: $BUILD_TYPE${NC}"
    echo "Uso: ./build_apk.sh [release|debug]"
    exit 1
fi

# Verificar que se creó el APK
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo -e "${GREEN}✅ APK construido exitosamente!${NC}"
    echo -e "${GREEN}📍 Ubicación: $APK_PATH${NC}"
    echo -e "${GREEN}📊 Tamaño: $APK_SIZE${NC}"
    echo ""
    
    # Mostrar hash SHA256
    echo -e "${YELLOW}🔐 SHA256:${NC}"
    sha256sum "$APK_PATH"
    echo ""
    
else
    echo -e "${RED}❌ Error: No se encontró el APK en $APK_PATH${NC}"
    exit 1
fi
