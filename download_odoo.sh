#!/bin/bash

# ============================================================================
# Script de Descarga de Odoo
# ============================================================================
# Descarga Odoo Community o Enterprise desde fuentes oficiales
# Parámetros: tipo (community/enterprise), versión
# Uso: ./download_odoo.sh --type community --version 16.0 [--path /ruta]
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TYPE="community"
VERSION="18.0"
TARGET_PATH="./odoo"
CLEAN_FIRST=false

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
        --type)
            TYPE="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --path)
            TARGET_PATH="$2"
            shift 2
            ;;
        --clean)
            CLEAN_FIRST=true
            shift
            ;;
        --help)
            echo "Uso: ./download_odoo.sh [OPCIONES]"
            echo ""
            echo "Opciones:"
            echo "  --type       Tipo de Odoo: community o enterprise (defecto: community)"
            echo "  --version    Versión a descargar (defecto: 16.0)"
            echo "  --path       Ruta donde extraer (defecto: ./odoo)"
            echo "  --clean      Limpiar directorio anterior si existe"
            echo "  --help       Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  ./download_odoo.sh --type community --version 16.0"
            echo "  ./download_odoo.sh --type community --version 16.0 --path /opt/odoo"
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            exit 1
            ;;
    esac
done

# Validaciones
if [[ "$TYPE" != "community" ]] && [[ "$TYPE" != "enterprise" ]]; then
    log_error "Tipo inválido. Usa 'community' o 'enterprise'."
    exit 1
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]$ ]]; then
    log_warning "Versión podría no ser válida: $VERSION"
fi

log_info "Descargando Odoo $TYPE versión $VERSION..."
log_info "Ruta destino: $TARGET_PATH"

echo ""
read -p "¿Deseas continuar? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_error "Descarga cancelada"
    exit 1
fi

if [[ "$TYPE" == "community" ]]; then
    URL="https://github.com/odoo/odoo/archive/refs/tags/$VERSION.zip"
    FILENAME="odoo-$VERSION.zip"
elif [[ "$TYPE" == "enterprise" ]]; then
    log_error "Para Odoo Enterprise, descarga desde: https://www.odoo.com/my/download"
    log_error "Asegúrate de tener credenciales válidas"
    echo ""
    read -p "¿Has descargado el archivo manualmente? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
    read -p "Ingresa la ruta del archivo descargado: " FILENAME
    if [[ ! -f "$FILENAME" ]]; then
        log_error "Archivo no encontrado: $FILENAME"
        exit 1
    fi
fi

if [[ "$TYPE" == "community" ]]; then
    log_info "Descargando desde: $URL"
    if ! wget -O "$FILENAME" "$URL" 2>&1; then
        log_error "Error descargando Odoo"
        rm -f "$FILENAME"
        exit 1
    fi
    # Verificar que el archivo se descargó correctamente
    if ! unzip -t "$FILENAME" > /dev/null 2>&1; then
        log_error "Archivo descargado pero no es un ZIP válido"
        rm -f "$FILENAME"
        exit 1
    fi
    log_success "Descarga completada"
fi

if [[ ! -f "$FILENAME" ]]; then
    log_error "Error: No se encontró el archivo $FILENAME"
    exit 1
fi

if [[ -d "$TARGET_PATH" ]] && [[ "$CLEAN_FIRST" == true ]]; then
    log_warning "Eliminando directorio anterior: $TARGET_PATH"
    rm -rf "$TARGET_PATH"
elif [[ -d "$TARGET_PATH" ]]; then
    log_error "El directorio $TARGET_PATH ya existe. Usa --clean para reemplazarlo"
    exit 1
fi

log_info "Extrayendo Odoo..."
mkdir -p "$TARGET_PATH"
if ! unzip -q "$FILENAME" -d "/tmp/odoo_extract_$$"; then
    log_error "Error extrayendo archivo"
    exit 1
fi

# Encontrar la carpeta principal extraída
EXTRACTED_DIR=$(find "/tmp/odoo_extract_$$" -maxdepth 1 -type d | tail -n 1)
if [[ -z "$EXTRACTED_DIR" ]] || [[ "$EXTRACTED_DIR" == "/tmp/odoo_extract_$$" ]]; then
    log_error "Error encontrando archivos extraídos"
    rm -rf "/tmp/odoo_extract_$$"
    exit 1
fi

mv "$EXTRACTED_DIR"/* "$TARGET_PATH"/
rm -rf "/tmp/odoo_extract_$$"
rm -f "$FILENAME"

log_success "Odoo $TYPE $VERSION descargado y extraído"
echo ""
echo "Ubicación: $(cd "$TARGET_PATH" && pwd)"
echo "Contenido: $(ls -la "$TARGET_PATH" | head -n 5)"