#!/bin/bash

# Script para backup de Odoo (PostgreSQL y archivos)
# Uso: ./backup_odoo.sh [db|files|all] [backup_dir]
# Ejemplo: ./backup_odoo.sh all /opt/odoo/backups

set -e

TYPE=${1:-all}
BACKUP_DIR=${2:-/opt/odoo/backups}
DATE=$(date +%Y%m%d_%H%M%S)

sudo mkdir -p "$BACKUP_DIR"

if [ "$TYPE" == "db" ] || [ "$TYPE" == "all" ]; then
    echo "Haciendo backup de la base de datos PostgreSQL..."
    sudo -u postgres pg_dump odoo > "$BACKUP_DIR/odoo_db_$DATE.sql"
    echo "Backup de DB guardado en $BACKUP_DIR/odoo_db_$DATE.sql"
fi

if [ "$TYPE" == "files" ] || [ "$TYPE" == "all" ]; then
    echo "Haciendo backup de archivos de Odoo..."
    sudo tar -czf "$BACKUP_DIR/odoo_files_$DATE.tar.gz" /opt/odoo/odoo /var/lib/odoo
    echo "Backup de archivos guardado en $BACKUP_DIR/odoo_files_$DATE.tar.gz"
fi

echo "Backup completado. Archivos en $BACKUP_DIR"
echo "Para restaurar DB: sudo -u postgres psql odoo < backup.sql"
echo "Para restaurar archivos: sudo tar -xzf backup.tar.gz -C /"