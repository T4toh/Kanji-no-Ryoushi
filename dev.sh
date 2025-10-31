#!/bin/bash

# Script de utilidad para tareas comunes de desarrollo

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛠️  Kanji no Ryoushi - Herramientas de Desarrollo${NC}"
echo ""

# Función para mostrar menú
show_menu() {
    echo "Selecciona una opción:"
    echo ""
    echo "  1) 🧪 Ejecutar tests"
    echo "  2) 🔍 Analizar código"
    echo "  3) 🎨 Regenerar íconos"
    echo "  4) 🧹 Limpiar proyecto"
    echo "  5) 📦 Obtener dependencias"
    echo "  6) 🚀 Ejecutar app (debug)"
    echo "  7) 📱 Compilar APK (release)"
    echo "  8) 🔄 Todo (limpiar + deps + análisis + tests)"
    echo "  0) ❌ Salir"
    echo ""
    read -p "Opción: " option
    echo ""
}

# Función para tests
run_tests() {
    echo -e "${GREEN}🧪 Ejecutando tests...${NC}"
    flutter test
}

# Función para análisis
run_analyze() {
    echo -e "${GREEN}🔍 Analizando código...${NC}"
    flutter analyze
}

# Función para regenerar íconos
regenerate_icons() {
    echo -e "${GREEN}🎨 Regenerando íconos...${NC}"
    ./generate_icons.sh
}

# Función para limpiar
clean_project() {
    echo -e "${GREEN}🧹 Limpiando proyecto...${NC}"
    flutter clean
    echo -e "${GREEN}✅ Proyecto limpio${NC}"
}

# Función para obtener dependencias
get_dependencies() {
    echo -e "${GREEN}📦 Obteniendo dependencias...${NC}"
    flutter pub get
}

# Función para ejecutar app
run_app() {
    echo -e "${GREEN}🚀 Ejecutando app en modo debug...${NC}"
    flutter run
}

# Función para compilar APK
build_apk() {
    echo -e "${GREEN}📱 Compilando APK release...${NC}"
    flutter build apk --release
    echo ""
    echo -e "${GREEN}✅ APK generado en: build/app/outputs/flutter-apk/app-release.apk${NC}"
}

# Función para ejecutar todo
run_all() {
    echo -e "${YELLOW}🔄 Ejecutando limpieza completa...${NC}"
    echo ""
    clean_project
    echo ""
    get_dependencies
    echo ""
    run_analyze
    echo ""
    run_tests
    echo ""
    echo -e "${GREEN}✅ Todas las tareas completadas${NC}"
}

# Loop principal
while true; do
    show_menu
    
    case $option in
        1)
            run_tests
            ;;
        2)
            run_analyze
            ;;
        3)
            regenerate_icons
            ;;
        4)
            clean_project
            ;;
        5)
            get_dependencies
            ;;
        6)
            run_app
            ;;
        7)
            build_apk
            ;;
        8)
            run_all
            ;;
        0)
            echo -e "${BLUE}👋 ¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}⚠️  Opción inválida${NC}"
            ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
    clear
done
