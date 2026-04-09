#!/bin/bash

# ============================================================================
# Script de Configuración de Odoo
# ============================================================================
# Crea usuario odoo, directorios y archivo de configuración con parámetros
# Parámetros opcionales: usuario, base de datos, contraseña, workers, puerto
# Uso: sudo ./configure_odoo.sh [--user odoo] [--db-name odoo] [--db-user odoo]
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración por defecto
ODOO_USER="odoo"
ODOO_PATH="/opt/odoo/odoo"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="odoo"
DB_USER="odoo"
DB_PASSWORD="odoo_password"
ADMIN_PASSWD="admin_password"
WORKERS="2"
XMLRPC_PORT="8069"
LOG_LEVEL="info"
MAX_CRON_THREADS="1"

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
            ODOO_USER="$2"
            shift 2
            ;;
        --odoo-path)
            ODOO_PATH="$2"
            shift 2
            ;;
        --db-host)
            DB_HOST="$2"
            shift 2
            ;;
        --db-port)
            DB_PORT="$2"
            shift 2
            ;;
        --db-name)
            DB_NAME="$2"
            shift 2
            ;;
        --db-user)
            DB_USER="$2"
            shift 2
            ;;
        --db-password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        --admin-passwd)
            ADMIN_PASSWD="$2"
            shift 2
            ;;
        --workers)
            WORKERS="$2"
            shift 2
            ;;
        --xmlrpc-port)
            XMLRPC_PORT="$2"
            shift 2
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        --help)
            echo "Uso: sudo ./configure_odoo.sh [OPCIONES]"
            echo ""
            echo "Opciones:"
            echo "  --user              Usuario Odoo (defecto: odoo)"
            echo "  --odoo-path         Ruta de Odoo (defecto: /opt/odoo/odoo)"
            echo "  --db-host           Host de BD (defecto: localhost)"
            echo "  --db-port           Puerto de BD (defecto: 5432)"
            echo "  --db-name           Nombre de BD (defecto: odoo)"
            echo "  --db-user           Usuario de BD (defecto: odoo)"
            echo "  --db-password       Contraseña de BD (defecto: odoo_password)"
            echo "  --admin-passwd      Contraseña admin (defecto: admin_password)"
            echo "  --workers           Número de workers (defecto: 2)"
            echo "  --xmlrpc-port       Puerto XMLRPC (defecto: 8069)"
            echo "  --log-level         Nivel de log (defecto: info)"
            echo "  --help              Mostrar esta ayuda"
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

log_info "Configurando Odoo..."
log_info "Usuario: $ODOO_USER"
log_info "Ruta: $ODOO_PATH"
log_info "Base de datos: $DB_NAME en $DB_HOST:$DB_PORT"
log_info "Workers: $WORKERS"

echo ""
read -p "¿Deseas continuar? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_error "Configuración cancelada"
    exit 1
fi

# Verificar si el usuario ya existe
if id "$ODOO_USER" &>/dev/null; then
    log_warning "Usuario '$ODOO_USER' ya existe"
else
    log_info "Creando usuario '$ODOO_USER'..."
    sudo useradd -m -d /opt/odoo -U -r -s /bin/bash $ODOO_USER
    log_success "Usuario '$ODOO_USER' creado"
fi

log_info "Creando directorios..."
sudo mkdir -p "$ODOO_PATH"
sudo mkdir -p /var/log/odoo
sudo mkdir -p /var/lib/odoo
sudo chown -R $ODOO_USER:$ODOO_USER /opt/odoo
sudo chown -R $ODOO_USER:$ODOO_USER /var/log/odoo
sudo chown -R $ODOO_USER:$ODOO_USER /var/lib/odoo
log_success "Directorios creados"

# Verificar que existe el archivo odoo si está en directorio actual
if [[ "./$ODOO_USER" != "$ODOO_PATH" ]] && [[ -d "./odoo" ]]; then
    log_info "Moviendo Odoo a $ODOO_PATH..."
    sudo mv ./odoo/* "$ODOO_PATH"/ 2>/dev/null || log_warning "Error moviendo algunos archivos"
    log_success "Odoo movido"
fi

log_info "Creando archivo de configuración /etc/odoo.conf..."
sudo tee /etc/odoo.conf > /dev/null <<EOF
# ============================================================================
# Configuración de Odoo
# ============================================================================
# Generado automáticamente por configure_odoo.sh
# ============================================================================

[options]
; Contraseña del administrador
admin_passwd = $ADMIN_PASSWD

; Configuración de la base de datos
db_host = $DB_HOST
db_port = $DB_PORT
db_user = $DB_USER
db_password = $DB_PASSWORD
db_name = $DB_NAME

; Rutas y logging
addons_path = $ODOO_PATH/addons
logfile = /var/log/odoo/odoo.log
log_level = $LOG_LEVEL

; Configuración de red
xmlrpc_port = $XMLRPC_PORT
xmlrpc_interface = 127.0.0.1
longpolling_port = 8072

; Configuración de workers y procesos
workers = $WORKERS
max_cron_threads = $MAX_CRON_THREADS

; Límites de recursos
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120

; Configuración de seguridad
secure_cookie = False
EOF

sudo chown $ODOO_USER:$ODOO_USER /etc/odoo.conf
sudo chmod 640 /etc/odoo.conf

log_success "Archivo de configuración creado"

echo ""
log_success "Odoo configurado exitosamente"
echo ""
echo "Resumen de configuración:"
echo "  Usuario: $ODOO_USER"
echo "  Ruta Odoo: $ODOO_PATH"
echo "  BD: $DB_NAME en $DB_HOST:$DB_PORT"
echo "  Workers: $WORKERS"
echo "  Puerto: $XMLRPC_PORT"
echo "  Archivo config: /etc/odoo.conf"
echo ""
echo "Próximo paso: Ejecutar setup_services.sh para crear los servicios systemd"