#!/bin/bash

# ============================================================================
# Script de Instalación de Nginx
# ============================================================================
# Este script instala y configura Nginx para Odoo
# Uso: sudo ./install_nginx.sh [--verbose]
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERBOSE=false

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Uso: sudo ./install_nginx.sh [OPCIONES]"
            echo ""
            echo "Opciones:"
            echo "  --verbose    Mostrar logs detallados"
            echo "  --help       Mostrar esta ayuda"
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            exit 1
            ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    log_error "Este script debe ejecutarse con sudo"
    exit 1
fi

log_info "Iniciando instalación de Nginx..."

log_info "Actualizando repositorios..."
sudo apt update > /dev/null 2>&1
log_success "Repositorios actualizados"

log_info "Instalando Nginx..."
sudo apt install -y nginx > /dev/null 2>&1
log_success "Nginx instalado"

log_info "Iniciando y habilitando Nginx..."
sudo systemctl start nginx > /dev/null 2>&1
sudo systemctl enable nginx > /dev/null 2>&1
log_success "Nginx iniciado y habilitado"

echo ""
log_success "Nginx instalado y configurado exitosamente"
echo ""
echo "Verificación:"
sudo systemctl status nginx --no-pager | head -n 3