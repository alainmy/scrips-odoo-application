#!/bin/bash

# ============================================================================
# Script Maestro de Despliegue Profesional de Odoo
# ============================================================================
# Automatiza el despliegue completo en secuencia interactiva
# Uso: sudo ./deploy_odoo_master.sh
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Validaciones iniciales
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Este script debe ejecutarse con sudo"
    exit 1
fi

# Función para mostrar banners
print_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}>>> [PASO $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

pause() {
    read -p "Presiona ENTER para continuar..." -r
}

# Banner inicial
print_banner "🚀 DESPLIEGUE PROFESIONAL DE ODOO 🚀"
echo "Esta herramienta automatizará el despliegue completo de Odoo en tu servidor."
echo ""
echo "Pasos que se ejecutarán:"
echo "  1. Instalación de PostgreSQL"
echo "  2. Instalación de Nginx"
echo "  3. Descarga de Odoo"
echo "  4. Instalación de dependencias"
echo "  5. Configuración de Odoo"
echo "  6. Configuración de servicios"
echo "  7. Configuración de SSL"
echo ""

read -p "¿Deseas proseguir con el despliegue? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Despliegue cancelado."
    exit 1
fi

# Recolectar información del usuario
print_banner "INFORMACIÓN REQUERIDA"

read -p "Ingresa tu dominio (ej: ejemplo.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    print_error "El dominio no puede estar vacío"
    exit 1
fi

read -p "Ingresa tu email para Let's Encrypt: " EMAIL
if [[ -z "$EMAIL" ]]; then
    print_error "El email no puede estar vacío"
    exit 1
fi

read -p "Ingresa número de workers (defecto 4): " WORKERS
WORKERS=${WORKERS:-4}

read -sp "Ingresa contraseña PostgreSQL: " DB_PASSWORD
echo
if [[ -z "$DB_PASSWORD" ]]; then
    print_error "La contraseña de BD no puede estar vacía"
    exit 1
fi

read -sp "Ingresa contraseña de administrador Odoo: " ADMIN_PASSWORD
echo
if [[ -z "$ADMIN_PASSWORD" ]]; then
    print_error "La contraseña admin no puede estar vacía"
    exit 1
fi

# Resumen
echo ""
print_banner "RESUMEN DE CONFIGURACIÓN"
echo "Dominio: $DOMAIN"
echo "Email: $EMAIL"
echo "Workers: $WORKERS"
echo "Contraseña BD: ***"
echo "Contraseña Admin: ***"
echo ""

read -p "¿Es correcto? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Configuración cancelada. Ejecuta de nuevo el script."
    exit 1
fi

# Crear directorio de logs
LOG_DIR="./deployment_logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"
GENERAL_LOG="$LOG_DIR/general.log"

print_success "Logs se guardarán en: $LOG_DIR"
echo ""

# ============================================================================
# PASO 1: PostgreSQL
# ============================================================================
print_step "1/7" "Instalando PostgreSQL..."

if [[ -f ./install_postgres.sh ]]; then
    sudo ./install_postgres.sh --user odoo --password "$DB_PASSWORD" | tee -a "$GENERAL_LOG"
    print_success "PostgreSQL instalado"
else
    print_error "Script install_postgres.sh no encontrado"
    exit 1
fi

pause

# ============================================================================
# PASO 2: Nginx
# ============================================================================
print_step "2/7" "Instalando Nginx..."

if [[ -f ./install_nginx.sh ]]; then
    sudo ./install_nginx.sh | tee -a "$GENERAL_LOG"
    print_success "Nginx instalado"
else
    print_error "Script install_nginx.sh no encontrado"
    exit 1
fi

pause

# ============================================================================
# PASO 3: Descargar Odoo
# ============================================================================
print_step "3/7" "Descargando Odoo..."

echo "¿Qué versión de Odoo deseas descargar?"
echo "1) 16.0 (Recomendado)"
echo "2) 15.0"
echo "3) 14.0"
read -p "Selecciona (1-3): " ODOO_VERSION_CHOICE

case $ODOO_VERSION_CHOICE in
    1) ODOO_VERSION="16.0" ;;
    2) ODOO_VERSION="15.0" ;;
    3) ODOO_VERSION="14.0" ;;
    *) ODOO_VERSION="16.0" ;;
esac

if [[ -f ./download_odoo.sh ]]; then
    ./download_odoo.sh --type community --version "$ODOO_VERSION" | tee -a "$GENERAL_LOG"
    print_success "Odoo $ODOO_VERSION descargado"
else
    print_error "Script download_odoo.sh no encontrado"
    exit 1
fi

pause

# ============================================================================
# PASO 4: Instalación de dependencias
# ============================================================================
print_step "4/7" "Instalando dependencias de Python..."

if [[ -f ./install_odoo_dependencies.sh ]]; then
    sudo ./install_odoo_dependencies.sh | tee -a "$GENERAL_LOG"
    print_success "Dependencias instaladas"
else
    print_error "Script install_odoo_dependencies.sh no encontrado"
    exit 1
fi

pause

# ============================================================================
# PASO 5: Configuración de Odoo
# ============================================================================
print_step "5/7" "Configurando Odoo..."

if [[ -f ./configure_odoo.sh ]]; then
    sudo ./configure_odoo.sh \
        --user odoo \
        --db-name odoo \
        --db-user odoo \
        --db-password "$DB_PASSWORD" \
        --admin-passwd "$ADMIN_PASSWORD" \
        --workers "$WORKERS" | tee -a "$GENERAL_LOG"
    print_success "Odoo configurado"
else
    print_error "Script configure_odoo.sh no encontrado"
    exit 1
fi

pause

# ============================================================================
# PASO 6: Servicios systemd
# ============================================================================
print_step "6/7" "Configurando servicios systemd y Nginx..."

if [[ -f ./setup_services.sh ]]; then
    sudo ./setup_services.sh --domain "$DOMAIN" --user odoo | tee -a "$GENERAL_LOG"
    print_success "Servicios configurados"
    
    # Esperar a que Odoo inicie
    print_warning "Esperando a que Odoo inicie completamente (30 segundos)..."
    sleep 30
else
    print_error "Script setup_services.sh no encontrado"
    exit 1
fi

pause

# ============================================================================
# PASO 7: SSL
# ============================================================================
print_step "7/7" "Configurando certificado SSL..."

if [[ -f ./configure_nginx_ssl.sh ]]; then
    sudo ./configure_nginx_ssl.sh --domain "$DOMAIN" --email "$EMAIL" | tee -a "$GENERAL_LOG"
    print_success "SSL configurado"
else
    print_error "Script configure_nginx_ssl.sh no encontrado"
    exit 1
fi

# ============================================================================
# VERIFICACIÓN FINAL
# ============================================================================
print_banner "VERIFICACIÓN FINAL"

echo "Verificando servicios..."
echo ""

# Verificar PostgreSQL
if sudo systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL está corriendo"
else
    print_warning "PostgreSQL podría no estar corriendo"
fi

# Verificar Nginx
if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx está corriendo"
else
    print_warning "Nginx podría no estar corriendo"
fi

# Verificar Odoo
if sudo systemctl is-active --quiet odoo; then
    print_success "Odoo está corriendo"
else
    print_warning "Odoo podría no estar corriendo. Verifica los logs."
fi

echo ""
print_success "Verificando conectividad..."

# Esperar a que todos los servicios estén listos
sleep 5

# Verificar Odoo responde localmente
if curl -sf http://localhost:8069 > /dev/null 2>&1; then
    print_success "Odoo responde en puerto 8069"
else
    print_warning "Odoo might not be fully started yet. Check logs in 30 seconds."
fi

# Ver logs
echo ""
echo "Últimas líneas del log de Odoo:"
echo "================================"
sudo tail -n 20 /var/log/odoo/odoo.log

# ============================================================================
# RESUMEN FINAL
# ============================================================================
print_banner "🎉 DESPLIEGUE COMPLETADO EXITOSAMENTE 🎉"

echo "Tu instancia de Odoo está lista en:"
echo ""
echo -e "${GREEN}https://${DOMAIN}${NC}"
echo ""
echo "Credenciales:"
echo "  Usuario: admin"
echo "  Contraseña: (ingresada durante la configuración)"
echo ""
echo "Información importante:"
echo "  • Archivo de configuración: /etc/odoo.conf"
echo "  • Logs: /var/log/odoo/odoo.log"
echo "  • Virtual environment: /opt/odoo/venv"
echo "  • Directorio Odoo: /opt/odoo/odoo"
echo ""
echo "Próximos pasos recomendados:"
echo "  1. Acceder a https://$DOMAIN"
echo "  2. Cambiar contraseña del admin"
echo "  3. Instalar módulos necesarios"
echo "  4. Configurar backups automáticos"
echo "  5. Configurar alertas de monitoreo"
echo ""
echo "Comandos útiles:"
echo "  Ver estado: sudo systemctl status odoo"
echo "  Ver logs: sudo tail -f /var/log/odoo/odoo.log"
echo "  Reiniciar: sudo systemctl restart odoo"
echo ""
echo "Logs completos de despliegue:"
echo "  $GENERAL_LOG"
echo ""
print_success "¡Despliegue finalizado!"
echo ""