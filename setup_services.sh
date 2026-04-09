#!/bin/bash

# ============================================================================
# Script de Configuración de Servicios Systemd y Nginx
# ============================================================================
# Crea archivo de servicio systemd para Odoo y configura Nginx como proxy reverso
# Parámetros opcionales: dominio, usuario, puerto, ruta venv, ruta odoo
# Uso: sudo ./setup_services.sh --domain ejemplo.com [--user odoo]
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración por defecto
DOMAIN="tu-dominio.com"
ODOO_USER="odoo"
ODOO_PATH="/opt/odoo"
ODOO_BIN_PATH=""  # Se detectará automáticamente
VENV_PATH="/opt/odoo/venv"
ODOO_PORT="8069"
GEVENT_PORT="8072"
SSL_CERT_PATH="/etc/letsencrypt/live"

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
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --user)
            ODOO_USER="$2"
            shift 2
            ;;
        --odoo-path)
            ODOO_PATH="$2"
            shift 2
            ;;
        --venv-path)
            VENV_PATH="$2"
            shift 2
            ;;
        --odoo-bin)
            ODOO_BIN_PATH="$2"
            shift 2
            ;;
        --odoo-port)
            ODOO_PORT="$2"
            shift 2
            ;;
        --gevent-port)
            GEVENT_PORT="$2"
            shift 2
            ;;
        --help)
            echo "Uso: sudo ./setup_services.sh --domain DOMINIO [OPCIONES]"
            echo ""
            echo "Argumentos requeridos:"
            echo "  --domain         Dominio para Odoo (ej: ejemplo.com)"
            echo ""
            echo "Opciones:"
            echo "  --user           Usuario Odoo (defecto: odoo)"
            echo "  --odoo-path      Ruta de instalación de Odoo (defecto: /opt/odoo)"
            echo "  --venv-path      Ruta del venv (defecto: /opt/odoo/venv)"
            echo "  --odoo-bin       Ruta de odoo-bin (se detecta automáticamente si omite)"
            echo "  --odoo-port      Puerto Odoo (defecto: 8069)"
            echo "  --gevent-port    Puerto Gevent (defecto: 8072)"
            echo "  --help           Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  sudo ./setup_services.sh --domain ejemplo.com"
            echo "  sudo ./setup_services.sh --domain ejemplo.com --user odoo --odoo-port 8080"
            echo "  sudo ./setup_services.sh --domain ejemplo.com --odoo-bin /opt/odoo/odoo-bin"
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

if [[ "$DOMAIN" == "tu-dominio.com" ]]; then
    log_error "Debes especificar un dominio válido con --domain"
    exit 1
fi

# Validaciones de rutas y archivos
log_info "Validando rutas y archivos..."

if [[ ! -d "$ODOO_PATH" ]]; then
    log_error "Ruta de Odoo no encontrada: $ODOO_PATH"
    exit 1
fi

# Auto-detectar la ruta de odoo-bin si no se especificó
if [[ -z "$ODOO_BIN_PATH" ]] || [[ ! -f "$ODOO_BIN_PATH" ]]; then
    log_info "Detectando ubicación de odoo-bin..."
    
    # Buscar odoo-bin en ubicaciones comunes
    if [[ -f "$ODOO_PATH/odoo-bin" ]]; then
        ODOO_BIN_PATH="$ODOO_PATH/odoo-bin"
        log_success "odoo-bin encontrado en: $ODOO_BIN_PATH"
    elif [[ -f "$ODOO_PATH/odoo/odoo-bin" ]]; then
        ODOO_BIN_PATH="$ODOO_PATH/odoo/odoo-bin"
        log_success "odoo-bin encontrado en: $ODOO_BIN_PATH"
    else
        # Buscar en cualquier subdirectorio
        FOUND_BIN=$(find "$ODOO_PATH" -maxdepth 3 -name "odoo-bin" -type f 2>/dev/null | head -n 1)
        if [[ -n "$FOUND_BIN" ]]; then
            ODOO_BIN_PATH="$FOUND_BIN"
            log_success "odoo-bin encontrado en: $ODOO_BIN_PATH"
        else
            log_error "No se encontró odoo-bin en $ODOO_PATH"
            log_error "Verifica la estructura del directorio:"
            ls -la "$ODOO_PATH" | head -n 20
            exit 1
        fi
    fi
fi

if [[ ! -f "$ODOO_BIN_PATH" ]]; then
    log_error "odoo-bin no encontrado en: $ODOO_BIN_PATH"
    exit 1
fi

if [[ ! -d "$VENV_PATH" ]]; then
    log_error "Virtual environment no encontrado en: $VENV_PATH"
    exit 1
fi

if [[ ! -f "$VENV_PATH/bin/python" ]]; then
    log_error "Python ejecutable no encontrado en: $VENV_PATH/bin/python"
    exit 1
fi

if [[ ! -f "/etc/odoo.conf" ]]; then
    log_error "Archivo de configuración no encontrado: /etc/odoo.conf"
    log_error "Crea el archivo de configuración antes de continuar"
    exit 1
fi

log_success "Todas las rutas y archivos validados"

log_info "Configurando servicios de Odoo..."
log_info "Dominio: $DOMAIN"
log_info "Usuario: $ODOO_USER"
log_info "Puerto Odoo: $ODOO_PORT"

echo ""
read -p "¿Deseas continuar? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_error "Configuración cancelada"
    exit 1
fi

# Crear archivo de servicio systemd para Odoo
log_info "Creando archivo de servicio systemd para Odoo..."
sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOF
# ============================================================================
# Servicio de Odoo
# ============================================================================
# Generado automáticamente por setup_services.sh

[Unit]
Description=Odoo
Requires=postgresql.service
After=network.target postgresql.service
StartLimitInterval=0
StartLimitBurst=0

[Service]
Type=simple
SyslogIdentifier=odoo
User=$ODOO_USER
Group=$ODOO_USER
WorkingDirectory=$ODOO_PATH
ExecStart=$VENV_PATH/bin/python $ODOO_BIN_PATH -c /etc/odoo.conf
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Límites de recursos
LimitNOFILE=65536
LimitNPROC=65536

[Install]
WantedBy=multi-user.target
EOF

log_success "Archivo de servicio systemd creado"

log_info "Recargando systemd..."
sudo systemctl daemon-reload > /dev/null 2>&1
log_success "Systemd recargado"

log_info "Habilitando Odoo en arranque..."
sudo systemctl enable odoo > /dev/null 2>&1
log_success "Odoo habilitado en arranque"

log_info "Iniciando Odoo..."
if ! sudo systemctl start odoo 2>&1; then
    log_error "No se pudo iniciar el servicio Odoo"
    log_error "Verifica los logs: sudo journalctl -u odoo -n 30"
    exit 1
fi
log_success "Odoo iniciado"

# Esperar un poco para que Odoo inicie y verificar su estado
sleep 3

# Verificar si el servicio está activo
if ! sudo systemctl is-active --quiet odoo; then
    log_error "El servicio Odoo no se mantuvo activo"
    log_error "Estado del servicio:"
    sudo systemctl status odoo --no-pager || true
    log_error "Últimos logs:"
    sudo journalctl -u odoo -n 30 || true
    exit 1
fi

log_success "Servicio Odoo confirmado como activo"

# Crear configuración de Nginx
log_info "Configurando Nginx como proxy reverso..."

# Verificar si existe el certificado SSL
if [[ -f "$SSL_CERT_PATH/$DOMAIN/fullchain.pem" ]]; then
    log_success "Certificado SSL encontrado para $DOMAIN"
    USE_SSL=true
else
    log_warning "Certificado SSL no encontrado. Configurando solo HTTP."
    log_warning "Ejecuta: sudo ./configure_nginx_ssl.sh --domain $DOMAIN --email tu-email@ejemplo.com"
    USE_SSL=false
fi

# Generar configuración de Nginx según disponibilidad de SSL
if [[ "$USE_SSL" == true ]]; then
    sudo tee /etc/nginx/sites-available/odoo > /dev/null <<'EOF'
# ============================================================================
# Configuración de Nginx para Odoo (CON SSL)
# ============================================================================
# Generado automáticamente por setup_services.sh

upstream odoo {
    server 127.0.0.1:ODOO_PORT;
}

upstream odoochat {
    server 127.0.0.1:GEVENT_PORT;
}

# Redirigir HTTP a HTTPS
server {
    listen 80;
    server_name DOMAIN;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name DOMAIN;

    # SSL
    ssl_certificate SSL_CERT;
    ssl_certificate_key SSL_KEY;
    ssl_session_duration 1d;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logging
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log warn;

    # Tamaño máximo de carga
    client_max_body_size 100M;

    # Proxy a Odoo
    location / {
        proxy_pass http://odoo;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
    }

    # WebSocket para chat en vivo
    location /websocket {
        proxy_pass http://odoochat;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Longpolling
    location /longpolling {
        proxy_pass http://odoochat;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Caché estática
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        expires 1w;
        proxy_pass http://odoo;
        proxy_cache_valid 200 1w;
    }
}
EOF
else
    # Configuración HTTP simple sin SSL
    sudo tee /etc/nginx/sites-available/odoo > /dev/null <<'EOF'
# ============================================================================
# Configuración de Nginx para Odoo (SIN SSL - HTTP)
# ============================================================================
# Generado automáticamente por setup_services.sh

upstream odoo {
    server 127.0.0.1:ODOO_PORT;
}

upstream odoochat {
    server 127.0.0.1:GEVENT_PORT;
}

# HTTP
server {
    listen 80;
    server_name DOMAIN;

    # Logging
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log warn;

    # Tamaño máximo de carga
    client_max_body_size 100M;

    # Proxy a Odoo
    location / {
        proxy_pass http://odoo;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
    }

    # WebSocket para chat en vivo
    location /websocket {
        proxy_pass http://odoochat;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Longpolling
    location /longpolling {
        proxy_pass http://odoochat;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Caché estática
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        expires 1w;
        proxy_pass http://odoo;
        proxy_cache_valid 200 1w;
    }
}
EOF
fi

# Reemplazar placeholders comunes
sed -i "s|DOMAIN|$DOMAIN|g" /etc/nginx/sites-available/odoo
sed -i "s|ODOO_PORT|$ODOO_PORT|g" /etc/nginx/sites-available/odoo
sed -i "s|GEVENT_PORT|$GEVENT_PORT|g" /etc/nginx/sites-available/odoo

# Reemplazar placeholders SSL solo si está habilitado
if [[ "$USE_SSL" == true ]]; then
    sed -i "s|SSL_CERT|$SSL_CERT_PATH/$DOMAIN/fullchain.pem|g" /etc/nginx/sites-available/odoo
    sed -i "s|SSL_KEY|$SSL_CERT_PATH/$DOMAIN/privkey.pem|g" /etc/nginx/sites-available/odoo
fi

log_success "Configuración de Nginx creada"

# Crear enlace simbólico si no existe
if [[ ! -L /etc/nginx/sites-enabled/odoo ]]; then
    log_info "Habilitando sitio Odoo en Nginx..."
    sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/
    log_success "Sitio habilitado"
fi

# Verificar sintaxis de Nginx
log_info "Verificando configuración de Nginx..."
if sudo nginx -t > /dev/null 2>&1; then
    log_success "Configuración de Nginx válida"
    sudo systemctl reload nginx > /dev/null 2>&1
    log_success "Nginx recargado"
else
    log_error "Error en la configuración de Nginx"
    exit 1
fi

echo ""
log_success "Servicios configurados exitosamente"
echo ""
echo "Resumen:"
echo "  Dominio: $DOMAIN"
echo "  Usuario Odoo: $ODOO_USER"
echo "  Puerto Odoo: $ODOO_PORT"
echo "  SSL habilitado: $USE_SSL"
echo ""
echo "Verificación del estado:"
echo ""
sudo systemctl status odoo --no-pager
echo ""

if [[ "$USE_SSL" == true ]]; then
    echo "Puedes acceder a Odoo en: https://$DOMAIN"
else
    echo "Puedes acceder a Odoo en: http://$DOMAIN"
fi
echo ""
log_warning "Si falta el certificado SSL, ejecuta:"
log_warning "  sudo ./configure_nginx_ssl.sh --domain $DOMAIN --email tu-email@ejemplo.com"