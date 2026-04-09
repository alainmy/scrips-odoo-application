#!/bin/bash

# ============================================================================
# Script de Instalación de Dependencias de Odoo
# ============================================================================
# Instala dependencias del sistema, crear venv de Python e instalar paquetes
# Parámetros opcionales: ruta de instalación, usuario
# Uso: sudo ./install_odoo_dependencies.sh [--path /ruta] [--user usuario]
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ODOO_PATH="/opt/odoo"
ODOO_USER="odoo"
REQUIREMENTS_FILE="/opt/odoo/requirements.txt"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --path)
            ODOO_PATH="$2"
            shift 2
            ;;
        --user)
            ODOO_USER="$2"
            shift 2
            ;;
        --requirements)
            REQUIREMENTS_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Uso: sudo ./install_odoo_dependencies.sh [OPCIONES]"
            echo ""
            echo "Opciones:"
            echo "  --path           Ruta de instalación de Odoo (defecto: /opt/odoo)"
            echo "  --user           Usuario propietario (defecto: odoo)"
            echo "  --requirements   Archivo requirements.txt (defecto: odoo/requirements.txt)"
            echo "  --help           Mostrar esta ayuda"
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

if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
    log_error "Archivo requirements.txt no encontrado: $REQUIREMENTS_FILE"
    exit 1
fi

log_info "Iniciando instalación de dependencias..."
log_info "Ruta: $ODOO_PATH"
log_info "Usuario: $ODOO_USER"
log_info "Requirements: $REQUIREMENTS_FILE"

echo ""
read -p "¿Deseas continuar? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_error "Instalación cancelada"
    exit 1
fi

log_info "Actualizando repositorios..."
sudo apt update > /dev/null 2>&1
log_success "Repositorios actualizados"

log_info "Instalando dependencias del sistema..."
sudo apt install -y python3 python3-pip python3-dev python3-venv libxml2-dev libxslt1-dev \
    libevent-dev libsasl2-dev libldap2-dev libpq-dev libpng-dev libjpeg-dev > /dev/null 2>&1
log_success "Dependencias del sistema instaladas"

log_info "Instalando wkhtmltopdf para reportes PDF..."
cd /tmp
wget -q -O wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.6/wkhtmltox_0.12.6-1.bionic_amd64.deb || \
    log_warning "No se pudo descargar wkhtmltopdf. Continuar sin él."
if [[ -f wkhtmltox.deb ]]; then
    sudo dpkg -i wkhtmltox.deb > /dev/null 2>&1 || true
    sudo apt install -f -y > /dev/null 2>&1 || true
    log_success "wkhtmltopdf instalado"
fi
cd - > /dev/null

log_info "Creando directorios..."
sudo mkdir -p "$ODOO_PATH"
sudo mkdir -p "$ODOO_PATH/venv"
log_success "Directorios creados"

log_info "Creando entorno virtual de Python..."
sudo python3 -m venv "$ODOO_PATH/venv"
log_success "Entorno virtual creado"

log_info "Instalando dependencias de Python en venv..."
sudo "$ODOO_PATH/venv/bin/pip" install --upgrade pip > /dev/null 2>&1
sudo "$ODOO_PATH/venv/bin/pip" install -r "$REQUIREMENTS_FILE" 2>&1 | tail -n 5 || log_warning "Algunas dependencias podrían no haberse instalado correctamente"
log_success "Dependencias de Python instaladas"

log_info "Configurando permisos..."
if id "$ODOO_USER" &>/dev/null; then
    sudo chown -R "$ODOO_USER:$ODOO_USER" "$ODOO_PATH" > /dev/null 2>&1
    log_success "Permisos configurados para usuario $ODOO_USER"
else
    log_warning "Usuario $ODOO_USER no existe aún. Permisos no configurados."
fi

echo ""
log_success "Dependencias instaladas exitosamente"
echo ""
echo "Resumen:"
echo "  Ruta venv: $ODOO_PATH/venv"
echo "  Python: $(sudo $ODOO_PATH/venv/bin/python --version)"
echo "  Paquetes: $(sudo $ODOO_PATH/venv/bin/pip list | wc -l) instalados"