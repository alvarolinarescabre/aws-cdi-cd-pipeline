#!/bin/bash
# Script para testear localmente la construcción de Docker
# Uso: ./infrastructure/scripts/test-build.sh

set -e

echo "================================"
echo "🔧 Test Local - Docker Build"
echo "================================"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi

echo -e "${YELLOW}1. Verificando Dockerfile en apps/api...${NC}"
if [ ! -f "apps/api/Dockerfile" ]; then
    echo "❌ apps/api/Dockerfile no encontrado"
    exit 1
fi
echo -e "${GREEN}✓ Dockerfile encontrado${NC}"

echo -e "${YELLOW}2. Verificando requirements.txt en apps/api...${NC}"
if [ ! -f "apps/api/requirements.txt" ]; then
    echo "❌ apps/api/requirements.txt no encontrado"
    exit 1
fi
echo -e "${GREEN}✓ requirements.txt encontrado${NC}"

echo -e "${YELLOW}3. Construyendo imagen Docker desde apps/api...${NC}"
docker build -t mi-app-test:latest ./apps/api
echo -e "${GREEN}✓ Imagen construida exitosamente${NC}"

echo -e "${YELLOW}4. Listando imagen...${NC}"
docker images | grep mi-app-test

echo ""
echo -e "${GREEN}================================"
echo "✅ Build completado correctamente"
echo "================================${NC}"
echo ""
echo "Para ejecutar la imagen localmente:"
echo "  docker run -p 80:80 mi-app-test:latest"
echo ""
echo "Luego accede a: http://localhost"
