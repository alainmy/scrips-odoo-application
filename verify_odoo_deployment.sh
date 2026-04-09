#!/bin/bash

# ============================================================================
# Script de Verificación de Despliegue de Odoo
# ============================================================================
# Verifica que todos los componentes estén correctamente instalados y corriendo
# Uso: ./verify_odoo_deployment.sh
# ============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Contadores
PASSED=0
FAILED=0
WARNINGS=0

# Funciones
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

# ============================================================================
# VERIFICACIONES
# ============================================================================

print_header "VERIFICACIÓN DE DESPLIEGUE DE ODOO"

# 1. Verificar PostgreSQL
echo "1️⃣  VERIFICAR POSTGRESQL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_test "¿PostgreSQL está instalado?"
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version)
    print_pass "PostgreSQL instalado: $PSQL_VERSION"
else
    print_fail "PostgreSQL no encontrado"
fi

print_test "¿PostgreSQL está corriendo?"
if sudo systemctl is-active --quiet postgresql; then
    print_pass "PostgreSQL está activo"
else
    print_fail "PostgreSQL no está corriendo"
fi

print_test "¿Usuario 'odoo' existe en PostgreSQL?"
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_user WHERE usename='odoo'" | grep -q 1; then
    print_pass "Usuario 'odoo' existe"
else
    print_warn "Usuario 'odoo' no encontrado en PostgreSQL"
fi

print_test "¿Base de datos 'odoo' existe?"
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw odoo; then
    print_pass "Base de datos 'odoo' existe"
else
    print_warn "Base de datos 'odoo' no encontrada"
fi

# 2. Verificar Nginx
echo ""
echo "2️⃣  VERIFICAR NGINX"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_test "¿Nginx está instalado?"
if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1)
    print_pass "Nginx instalado: $NGINX_VERSION"
else
    print_fail "Nginx no encontrado"
fi

print_test "¿Nginx está corriendo?"
if sudo systemctl is-active --quiet nginx; then
    print_pass "Nginx está activo"
else
    print_fail "Nginx no está corriendo"
fi

print_test "¿Configuración de Nginx es válida?"
if sudo nginx -t 2>&1 | grep -q "successful"; then
    print_pass "Configuración de Nginx válida"
else
    print_fail "Configuración de Nginx inválida"
fi

print_test "¿Sitio Odoo está habilitado en Nginx?"
if [[ -L /etc/nginx/sites-enabled/odoo ]]; then
    print_pass "Sitio Odoo habilitado"
else
    print_warn "Sitio Odoo no está habilitado"
fi

# 3. Verificar Odoo
echo ""
echo "3️⃣  VERIFICAR ODOO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_test "¿Archivo de configuración existe?"
if [[ -f /etc/odoo.conf ]]; then
    print_pass "Archivo /etc/odoo.conf existe"
else
    print_fail "Archivo /etc/odoo.conf no encontrado"
fi

print_test "¿Odoo está instalado?"
if [[ -f /opt/odoo/odoo/odoo-bin ]]; then
    print_pass "Odoo instalado en /opt/odoo/odoo"
else
    print_warn "Binario Odoo no encontrado en /opt/odoo/odoo/odoo-bin"
fi

print_test "¿Virtual environment existe?"
if [[ -d /opt/odoo/venv ]]; then
    PYTHON_VERSION=$(/opt/odoo/venv/bin/python --version 2>&1)
    print_pass "Venv existe: $PYTHON_VERSION"
else
    print_fail "Virtual environment no encontrado"
fi

print_test "¿Servicio Odoo está habilitado?"
if sudo systemctl is-enabled --quiet odoo; then
    print_pass "Servicio Odoo habilitado"
else
    print_warn "Servicio Odoo no habilitado en arranque"
fi

print_test "¿Servicio Odoo está activo?"
if sudo systemctl is-active --quiet odoo; then
    print_pass "Servicio Odoo está corriendo"
else
    print_fail "Servicio Odoo no está corriendo"
fi

print_test "¿Puerto Odoo (8069) está escuchando?"
if sudo netstat -tulpn 2>/dev/null | grep -q ":8069"; then
    print_pass "Odoo escuchando en puerto 8069"
else
    print_fail "Odoo no está escuchando en puerto 8069"
fi

# 4. Verificar Usuario Odoo
echo ""
echo "4️⃣  VERIFICAR USUARIO Y PERMISOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_test "¿Usuario 'odoo' existe?"
if id -u odoo &>/dev/null; then
    print_pass "Usuario 'odoo' existe"
else
    print_fail "Usuario 'odoo' no encontrado"
fi

print_test "¿Directorios tienen permisos correctos?"
if [[ -O /opt/odoo ]] || sudo test -O /opt/odoo; then
    print_pass "Permisos de /opt/odoo correctos"
else
    print_warn "Verificar permisos de /opt/odoo"
fi

print_test "¿Logs está accesible?"
if [[ -d /var/log/odoo ]] && [[ -w /var/log/odoo ]] || sudo test -w /var/log/odoo; then
    print_pass "/var/log/odoo accesible"
else
    print_warn "Verificar permisos de /var/log/odoo"
fi

# 5. Verificar SSL
echo ""
echo "5️⃣  VERIFICAR SSL/CERTIFICADOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v certbot &> /dev/null; then
    print_test "¿Certbot está instalado?"
    print_pass "Certbot encontrado"
    
    print_test "¿Certificados están configurados?"
    if sudo certbot certificates 2>&1 | grep -q "Certificate Name"; then
        CERT_INFO=$(sudo certbot certificates 2>&1 | grep -A 2 "Certificate Name" | head -n 3)
        print_pass "Certificados encontrados:"
        echo "$CERT_INFO" | sed 's/^/  /'
    else
        print_warn "No hay certificados configurados"
    fi
else
    print_warn "Certbot no está instalado"
fi

# 6. Verificar Dependencias
echo ""
echo "6️⃣  VERIFICAR DEPENDENCIAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_test "¿Dependencias de Python instaladas?"
PIP_COUNT=$(/opt/odoo/venv/bin/pip list 2>/dev/null | wc -l)
if [[ $PIP_COUNT -gt 5 ]]; then
    print_pass "~$PIP_COUNT paquetes Python instalados"
else
    print_warn "Posibles problemas con dependencias Python"
fi

print_test "¿wkhtmltopdf está instalado?"
if command -v wkhtmltopdf &>/dev/null; then
    WKHTMLTOPDF_VERSION=$(wkhtmltopdf --version 2>&1 | head -n 1)
    print_pass "wkhtmltopdf encontrado"
else
    print_warn "wkhtmltopdf no encontrado (necesario para reportes PDF)"
fi

# 7. Verificar Conectividad
echo ""
echo "7️⃣  VERIFICAR CONECTIVIDAD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_test "¿Odoo responde en localhost:8069?"
if curl -sf http://localhost:8069 > /dev/null 2>&1 || timeout 2 curl -sf http://127.0.0.1:8069 > /dev/null 2>&1; then
    print_pass "Odoo responde en puerto 8069"
else
    print_fail "Odoo no responde en puerto 8069 (podría estar iniciando)"
fi

# 8. Verificar Logs
echo ""
echo "8️⃣  VERIFICAR LOGS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_test "¿Archivo de log existe?"
if [[ -f /var/log/odoo/odoo.log ]]; then
    LOG_SIZE=$(wc -c < /var/log/odoo/odoo.log)
    print_pass "Log existe ($(numfmt --to=iec-i --suffix=B $LOG_SIZE 2>/dev/null || echo "$LOG_SIZE bytes"))"
    
    print_test "¿Log tiene errores críticos?"
    if grep -qi "error\|critical" /var/log/odoo/odoo.log; then
        ERROR_COUNT=$(grep -ci "error\|critical" /var/log/odoo/odoo.log)
        print_warn "Log contiene $ERROR_COUNT líneas con ERROR/CRITICAL"
    else
        print_pass "No hay errores críticos recientes en log"
    fi
else
    print_fail "Log de Odoo no encontrado"
fi

# ============================================================================
# RESUMEN
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ VERIFICACIÓN EXITOSA${NC}"
    echo ""
    echo "Resultados:"
    echo "  ${GREEN}✓ PASS: $PASSED${NC}"
    echo "  ${YELLOW}⚠ WARN: $WARNINGS${NC}"
    echo "  ${RED}✗ FAIL: $FAILED${NC}"
    echo ""
    echo "Tu despliegue de Odoo está listo para producción."
else
    echo -e "${RED}✗ PROBLEMAS ENCONTRADOS${NC}"
    echo ""
    echo "Resultados:"
    echo "  ${GREEN}✓ PASS: $PASSED${NC}"
    echo "  ${YELLOW}⚠ WARN: $WARNINGS${NC}"
    echo "  ${RED}✗ FAIL: $FAILED${NC}"
    echo ""
    echo "Por favor, revisa los errores marcados con [FAIL]"
fi

echo ""
echo "Próximos pasos:"
echo "  1. Acceder a Odoo: https://tu-dominio.com"
echo "  2. Verificar logs: tail -f /var/log/odoo/odoo.log"
echo "  3. Configurar módulos necesarios"
echo "  4. Hacer backup de la BD: sudo -u postgres pg_dump -U odoo odoo > backup.sql"
echo ""

# Retornar código de salida apropiado
if [[ $FAILED -gt 0 ]]; then
    exit 1
else
    exit 0
fi