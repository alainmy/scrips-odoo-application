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
ODOO_BIN_PATH="/opt/odoo/odoo/odoo-bin"
VENV_PATH="/opt/odoo/venv"
ODOO_PORT="8069"
LONGPOLLING_PORT="8072"
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
            echo "  --odoo-bin       Ruta de odoo-bin (defecto: /opt/odoo/odoo/odoo-bin)"
            echo "  --odoo-port      Puerto Odoo (defecto: 8069)"
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

if [[ "$DOMAIN" == "tu-dominio.com" ]]; then
    log_error "Debes especificar un dominio válido con --domain"
    exit 1
fi

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
sudo systemctl start odoo > /dev/null 2>&1
log_success "Odoo iniciado"

# Esperar un poco para que Odoo inicie
sleep 2

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

sudo tee /etc/nginx/sites-available/odoo > /dev/null <<'EOF'
# ============================================================================
# Configuración de Nginx para Odoo
# ============================================================================
# Generado automáticamente por setup_services.sh

upstream odoo {
    server 127.0.0.1:ODOO_PORT;
}

upstream odoochat {
    server 127.0.0.1:LONGPOLLING_PORT;
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

# Reemplazar placeholders
sed -i "s|DOMAIN|$DOMAIN|g" /etc/nginx/sites-available/odoo
sed -i "s|ODOO_PORT|$ODOO_PORT|g" /etc/nginx/sites-available/odoo
sed -i "s|LONGPOLLING_PORT|$LONGPOLLING_PORT|g" /etc/nginx/sites-available/odoo
sed -i "s|SSL_CERT|$SSL_CERT_PATH/$DOMAIN/fullchain.pem|g" /etc/nginx/sites-available/odoo
sed -i "s|SSL_KEY|$SSL_CERT_PATH/$DOMAIN/privkey.pem|g" /etc/nginx/sites-available/odoo

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
echo "Puedes acceder a Odoo en: https://$DOMAIN"
echo ""
log_warning "Si falta el certificado SSL, ejecuta:"
log_warning "  sudo ./configure_nginx_ssl.sh --domain $DOMAIN --email tu-email@ejemplo.com"