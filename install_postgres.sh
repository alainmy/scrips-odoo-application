#!/bin/bash

# ============================================================================
# Script de Instalación de PostgreSQL para Odoo
# ============================================================================
# Este script instala y configura PostgreSQL para un despliegue de Odoo
# Parámetros opcionales: usuario, contraseña
# Uso: sudo ./install_postgres.sh [--user <usuario>] [--password <contraseña>]
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración por defecto
DB_USER="odoo"
DB_PASSWORD="odoo"
VERBOSE=false

# Función para mostrar logs
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
        --user)
            DB_USER="$2"
            shift 2
            ;;
        --password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Uso: sudo ./install_postgres.sh [OPCIONES]"
            echo ""
            echo "Opciones:"
            echo "  --user       Nombre del usuario PostgreSQL (defecto: odoo)"
            echo "  --password   Contraseña del usuario (defecto: generada aleatoria)"
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

# Validar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
    log_error "Este script debe ejecutarse con sudo"
    exit 1
fi

log_info "Iniciando instalación de PostgreSQL..."
log_info "Usuario: $DB_USER"
log_info "Contraseña: $DB_PASSWORD (cambiar en producción)"

echo ""
read -p "¿Deseas continuar? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_error "Instalación cancelada"
    exit 1
fi

log_info "Actualizando el sistema..."
sudo apt update > /dev/null 2>&1 && sudo apt upgrade -y > /dev/null 2>&1
log_success "Sistema actualizado"

log_info "Instalando PostgreSQL y contrib..."
sudo apt install -y postgresql postgresql-contrib > /dev/null 2>&1
log_success "PostgreSQL instalado"

log_info "Iniciando y habilitando PostgreSQL..."
sudo systemctl start postgresql > /dev/null 2>&1
sudo systemctl enable postgresql > /dev/null 2>&1
log_success "PostgreSQL iniciado y habilitado"

log_info "Creando usuario '$DB_USER' en PostgreSQL..."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" > /dev/null 2>&1
sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;" > /dev/null 2>&1
log_success "Usuario $DB_USER creado"

echo ""
log_success "PostgreSQL instalado y configurado exitosamente"
echo ""
echo "Credenciales:"
echo "  Usuario: $DB_USER"
echo "  Contraseña: $DB_PASSWORD"
echo "  Host: localhost"
echo "  Puerto: 5432"
echo ""
log_warning "Guarda estas credenciales en un lugar seguro"
log_warning "Recuerda cambiar la contraseña en producción"