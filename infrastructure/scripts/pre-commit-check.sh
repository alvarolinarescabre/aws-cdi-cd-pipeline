#!/bin/bash
# Checklist de validación antes de pushear a GitHub (Monorepo)
# Uso: ./infrastructure/scripts/pre-commit-check.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🔍 Pre-Commit Validation Checklist (Monorepo)"
echo "=============================================="
echo ""

ERRORS=0

# 1. Verificar que buildspec.yml existe
echo -n "✓ services/pipeline/buildspec.yml existe... "
if [ -f "services/pipeline/buildspec.yml" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 2. Verificar que Dockerfile existe
echo -n "✓ apps/api/Dockerfile existe... "
if [ -f "apps/api/Dockerfile" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 3. Verificar que app.py existe
echo -n "✓ apps/api/app.py existe... "
if [ -f "apps/api/app.py" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 4. Verificar que requirements.txt existe
echo -n "✓ apps/api/requirements.txt existe... "
if [ -f "apps/api/requirements.txt" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 5. Verificar que .gitignore existe
echo -n "✓ .gitignore existe... "
if [ -f ".gitignore" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 6. Verificar que docs/README.md existe
echo -n "✓ docs/README.md existe... "
if [ -f "docs/README.md" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 7. Verificar que buildspec.yml tiene el nombre correcto del contenedor
echo -n "✓ buildspec.yml contiene 'mi-contenedor-app'... "
if grep -q "mi-contenedor-app" services/pipeline/buildspec.yml; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 8. Verificar que buildspec.yml genera imagedefinitions.json
echo -n "✓ buildspec.yml genera imagedefinitions.json... "
if grep -q "imagedefinitions.json" services/pipeline/buildspec.yml; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 9. Verificar que Dockerfile usa el puerto 80
echo -n "✓ Dockerfile expone puerto 80... "
if grep -q "EXPOSE 80" apps/api/Dockerfile; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# 10. Verificar que buildspec.yml construye desde apps/api
echo -n "✓ buildspec.yml construye desde ./apps/api... "
if grep -q "./apps/api" services/pipeline/buildspec.yml; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

echo ""
echo "=============================================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los checks pasaron!${NC}"
    echo ""
    echo "Estás listo para hacer push:"
    echo "  git add ."
    echo "  git commit -m 'Your message'"
    echo "  git push origin main"
    echo ""
    exit 0
else
    echo -e "${RED}❌ $ERRORS checks fallaron${NC}"
    echo ""
    echo "Por favor, revisa los archivos marcados como FAIL"
    echo ""
    exit 1
fi
