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

log_info "Configurando autenticación de PostgreSQL..."
# Modificar pg_hba.conf para permitir autenticación con contraseña
PG_VERSION=$(sudo -u postgres psql --version | awk '{print $3}' | cut -d. -f1)
PG_CONFIG_PATH="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

if [[ -f "$PG_CONFIG_PATH" ]]; then
    # Reemplazar peer con md5 para conexiones locales
    sudo sed -i 's/^local[ \t]*all[ \t]*all[ \t]*peer/local   all             all                     md5/' "$PG_CONFIG_PATH"
    log_success "Autenticación configurada"
else
    log_warning "No se encontró pg_hba.conf en $PG_CONFIG_PATH"
fi

log_info "Recargando configuración de PostgreSQL..."
sudo systemctl reload postgresql > /dev/null 2>&1
log_success "Configuración recargada"

log_info "Creando usuario '$DB_USER' en PostgreSQL..."
# Escapar la contraseña para PostgreSQL
ESCAPED_PASSWORD="${DB_PASSWORD//\'/\'\'}"

# Crear usuario con contraseña segura
sudo -u postgres psql <<EOF > /dev/null 2>&1
CREATE USER $DB_USER WITH PASSWORD '$ESCAPED_PASSWORD';
ALTER USER $DB_USER CREATEDB;
EOF

# Verificar que el usuario fue creado
if sudo -u postgres psql -t -c "SELECT 1 FROM pg_user WHERE usename='$DB_USER'" | grep -q 1; then
    log_success "Usuario $DB_USER creado"
else
    log_error "No se pudo crear el usuario $DB_USER"
    exit 1
fi

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