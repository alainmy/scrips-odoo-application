# Guía de Despliegue Profesional de Odoo

Esta guía proporciona un paso a paso para desplegar Odoo en un servidor Ubuntu/Debian, incluyendo PostgreSQL, Nginx con SSL, y descarga de Odoo Community o Enterprise.

## Requisitos Previos
- Servidor Ubuntu/Debian 20.04 o superior
- Acceso root o sudo
- Dominio configurado apuntando al servidor

## Pasos de Despliegue

### 1. Instalar PostgreSQL
Ejecuta el script `install_postgres.sh` para instalar y configurar PostgreSQL.
```bash
sudo ./install_postgres.sh
```

### 2. Instalar Nginx
Ejecuta el script `install_nginx.sh` para instalar Nginx.
```bash
sudo ./install_nginx.sh
```

### 3. Configurar Nginx con SSL
Ejecuta el script `configure_nginx_ssl.sh` para obtener un certificado SSL con Let's Encrypt.
- Edita el script para cambiar `DOMAIN` y `EMAIL`.
```bash
sudo ./configure_nginx_ssl.sh
```

### 4. Descargar Odoo
Ejecuta el script `download_odoo.sh` para descargar Odoo.
- Para Community: `./download_odoo.sh community 16.0`
- Para Enterprise: Descarga manualmente desde https://www.odoo.com/my/download (requiere credenciales)
```bash
./download_odoo.sh community 16.0
```

### 5. Instalar Dependencias de Odoo
Ejecuta el script `install_odoo_dependencies.sh` para instalar dependencias y crear un venv de Python en `/opt/odoo/venv`.
```bash
sudo ./install_odoo_dependencies.sh
```

### 6. Configurar Odoo
Ejecuta el script `configure_odoo.sh` para configurar Odoo.
```bash
sudo ./configure_odoo.sh
```

### 7. Configurar Servicios
Ejecuta el script `setup_services.sh` para configurar servicios systemd y Nginx.
- Edita el script para cambiar `tu-dominio.com`.
```bash
sudo ./setup_services.sh
```

## Notas Importantes
- Se crea un usuario dedicado 'odoo' para ejecutar el servicio.
- Las dependencias de Python se instalan en un venv aislado en `/opt/odoo/venv` para evitar conflictos.
- La ruta por defecto para Odoo es `/opt/odoo/odoo`; puedes cambiarla editando los scripts si es necesario.
- Cambia todas las contraseñas y configuraciones por defecto en producción.
- Para Odoo Enterprise, descarga manualmente y coloca en `/opt/odoo/odoo`.
- Verifica logs en `/var/log/odoo/odoo.log` y `/var/log/nginx/`.
- Asegúrate de que el firewall permita puertos 80, 443 y 8069.

## Verificación
- Accede a https://tu-dominio.com para verificar Odoo.
- Usa `sudo systemctl status odoo` para verificar el servicio.# scrips-odoo-application
