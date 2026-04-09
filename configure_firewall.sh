#!/bin/bash

# Script para configurar UFW (Firewall)
# Uso: ./configure_firewall.sh [enable|disable] [ports]
# Ejemplo: ./configure_firewall.sh enable "22,80,443,8069"

set -e

ACTION=${1:-enable}
PORTS=${2:-"22,80,443,8069"}

echo "Instalando UFW si no está instalado..."
sudo apt install -y ufw

echo "Configurando UFW..."

# Permitir SSH primero para no bloquearse
sudo ufw allow ssh

# Permitir puertos especificados
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
for port in "${PORT_ARRAY[@]}"; do
    sudo ufw allow "$port"
done

if [ "$ACTION" == "enable" ]; then
    echo "Habilitando UFW..."
    sudo ufw --force enable
elif [ "$ACTION" == "disable" ]; then
    echo "Deshabilitando UFW..."
    sudo ufw disable
else
    echo "Acción inválida. Usa 'enable' o 'disable'."
    exit 1
fi

echo "Estado de UFW:"
sudo ufw status