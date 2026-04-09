#!/bin/bash

# ============================================================================
# Script de Configuración de Nginx con SSL (Let's Encrypt)
# ============================================================================
# Instala Certbot y obtiene un certificado SSL para el dominio
# Parámetros requeridos: dominio, email
# Uso: sudo ./configure_nginx_ssl.sh --domain ejemplo.com --email admin@ejemplo.com
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="rodferco.com"
EMAIL="rrferrer5588@gmail.com"
RENEW_ONLY=false

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
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --renew-only)
            RENEW_ONLY=true
            shift
            ;;
        --help)
            echo "Uso: sudo ./configure_nginx_ssl.sh --domain DOMINIO --email EMAIL [OPCIONES]"
            echo ""
            echo "Argumentos requeridos:"
            echo "  --domain     Dominio a certificar (ej: ejemplo.com)"
            echo "  --email      Email para notificaciones de Let's Encrypt"
            echo ""
            echo "Opciones:"
            echo "  --renew-only Solo renovar certificado existente"
            echo "  --help       Mostrar esta ayuda"
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            exit 1
            ;;
    esac
done

# Validaciones
if [[ $EUID -ne 0 ]]; then
    log_error "Este script debe ejecutarse con sudo"
    exit 1
fi

if [[ $RENEW_ONLY == false ]] && [[ -z "$DOMAIN" ]]; then
    log_error "--domain es requerido"
    exit 1
fi

if [[ $RENEW_ONLY == false ]] && [[ -z "$EMAIL" ]]; then
    log_error "--email es requerido"
    exit 1
fi

if [[ $RENEW_ONLY == false ]]; then
    log_info "Configurando SSL para: $DOMAIN"
    log_info "Email: $EMAIL"
    echo ""
    read -p "¿Deseas continuar? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_error "Configuración cancelada"
        exit 1
    fi
fi

log_info "Instalando Certbot y plugin de Nginx..."
sudo apt install -y certbot python3-certbot-nginx > /dev/null 2>&1
log_success "Certbot instalado"

if [[ $RENEW_ONLY == false ]]; then
    log_info "Obteniendo certificado SSL para $DOMAIN..."
    sudo certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive --no-eff-email 2>&1 | grep -E 'WARNING|error|SUCCESS|Congratulations' || true
    log_success "Certificado SSL obtenido"
else
    log_info "Renovando certificados SSL..."
    sudo certbot renew --quiet 2>&1 | grep -E 'WARNING|error|renewed' || log_success "Certificados actualizados"
fi

log_info "Configurando renovación automática..."
sudo systemctl enable certbot.timer > /dev/null 2>&1
sudo systemctl start certbot.timer > /dev/null 2>&1
log_success "Renovación automática habilitada"

echo ""
log_success "Configuración SSL completada"
echo ""
echo "Estado del certificado:"
sudo certbot certificates 2>/dev/null | grep -E 'Domain|Expiry' || log_warning "No hay certificados instalados"
echo ""