#!/bin/bash

# ============================================================================
# INSTRUCCIONES DE DESPLIEGUE RÁPIDO
# ============================================================================

# Color para output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        DESPLIEGUE PROFESIONAL DE ODOO - GUÍA RÁPIDA           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo "📋 OPCIÓN 1: AUTOMATIZADO (Recomendado para la mayoría)"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "El script maestro lo hace TODO automáticamente:"
echo ""
echo "  sudo chmod +x deploy_odoo_master.sh"
echo "  sudo ./deploy_odoo_master.sh"
echo ""
echo "El script te pedirá:"
echo "  • Tu dominio (ejemplo.com)"
echo "  • Tu email (para Let's Encrypt)"
echo "  • Número de workers"
echo "  • Contraseña PostgreSQL"
echo "  • Contraseña administrador Odoo"
echo ""
echo "Tiempo estimado: 20-30 minutos"
echo ""

echo ""
echo "📋 OPCIÓN 2: PASO A PASO (Para mayor control)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Paso 1: PostgreSQL"
echo "  $ sudo chmod +x install_postgres.sh"
echo "  $ sudo ./install_postgres.sh --user odoo --password tu_contraseña"
echo ""

echo "Paso 2: Nginx"
echo "  $ sudo chmod +x install_nginx.sh"
echo "  $ sudo ./install_nginx.sh"
echo ""

echo "Paso 3: Descargar Odoo"
echo "  $ sudo chmod +x download_odoo.sh"
echo "  $ ./download_odoo.sh --type community --version 16.0"
echo ""

echo "Paso 4: Dependencias"
echo "  $ sudo chmod +x install_odoo_dependencies.sh"
echo "  $ sudo ./install_odoo_dependencies.sh"
echo ""

echo "Paso 5: Configurar Odoo"
echo "  $ sudo chmod +x configure_odoo.sh"
echo "  $ sudo ./configure_odoo.sh --workers 4 --db-password tu_contraseña"
echo ""

echo "Paso 6: Servicios"
echo "  $ sudo chmod +x setup_services.sh"
echo "  $ sudo ./setup_services.sh --domain tu-dominio.com"
echo ""

echo "Paso 7: SSL"
echo "  $ sudo chmod +x configure_nginx_ssl.sh"
echo "  $ sudo ./configure_nginx_ssl.sh --domain tu-dominio.com --email tu@email.com"
echo ""

echo ""
echo -e "${GREEN}✓ ¡Todo listo!${NC}"
echo "  Accede a: https://tu-dominio.com"
echo ""

echo ""
echo "📋 INFORMACIÓN RÁPIDA"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Archivos importantes:"
echo "  /etc/odoo.conf              - Configuración principal"
echo "  /var/log/odoo/odoo.log      - Logs"
echo "  /opt/odoo/odoo              - Código fuente"
echo "  /opt/odoo/venv              - Virtual environment"
echo ""

echo "Comandos útiles:"
echo "  Ver estado:       sudo systemctl status odoo"
echo "  Logs en tiempo real: sudo tail -f /var/log/odoo/odoo.log"
echo "  Reiniciar:        sudo systemctl restart odoo"
echo "  Ver procesos:     ps aux | grep odoo"
echo ""

echo "Documentación completa:"
echo "  Ver: README_COMPLETO.md"
echo ""

echo ""
echo -e "${CYAN}Nota: Asegúrate de que tu dominio apunta a esta IP del servidor.${NC}"
echo ""