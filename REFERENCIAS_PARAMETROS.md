# 📚 ÍNDICE DE SCRIPTS Y REFERENCIA RÁPIDA

## 🎯 Scripts por Propósito

### 🚀 Despliegue Completo
- **deploy_odoo_master.sh** - Script único que automatiza TODO
  - Uso: `sudo ./deploy_odoo_master.sh`
  - Tiempo: 20-30 minutos
  - Mejor para: Despliegues rápidos en clientes

### 🗄️ Base de Datos
- **install_postgres.sh** - Instala PostgreSQL
  - Parámetros: `--user`, `--password`, `--verbose`
  - Ejemplo: `sudo ./install_postgres.sh --user odoo --password "P@ssw0rd123!"`

### 🌐 Servidor Web
- **install_nginx.sh** - Instala Nginx
  - Parámetros: `--verbose`
  - Ejemplo: `sudo ./install_nginx.sh`

- **configure_nginx_ssl.sh** - Configura SSL con Let's Encrypt
  - Parámetros: `--domain`, `--email`, `--renew-only`
  - Ejemplo: `sudo ./configure_nginx_ssl.sh --domain ejemplo.com --email admin@ejemplo.com`
  - Nota: Ejecutar después de setup_services.sh

### 📦 Descargas
- **download_odoo.sh** - Descarga Odoo Community/Enterprise
  - Parámetros: `--type`, `--version`, `--path`, `--clean`
  - Community: `./download_odoo.sh --type community --version 16.0`
  - Enterprise: `./download_odoo.sh --type enterprise`

### 🐍 Dependencias
- **install_odoo_dependencies.sh** - Instala dependencias Python y del sistema
  - Parámetros: `--path`, `--user`, `--requirements`
  - Ejemplo: `sudo ./install_odoo_dependencies.sh --path /opt/odoo --user odoo`

### ⚙️ Configuración
- **configure_odoo.sh** - Configura Odoo y genera /etc/odoo.conf
  - Parámetros: `--user`, `--db-name`, `--db-user`, `--db-password`, `--admin-passwd`, `--workers`, `--log-level`
  - Ejemplo: `sudo ./configure_odoo.sh --workers 8 --db-password "P@ssw0rd123!"`

### 🔧 Servicios
- **setup_services.sh** - Configura systemd y Nginx como proxy
  - Parámetros: `--domain`, `--user`, `--odoo-port`
  - Ejemplo: `sudo ./setup_services.sh --domain ejemplo.com --user odoo`

## 📖 Documentación

- **README_COMPLETO.md** - Guía profesional completa (150+ líneas)
- **INICIO_RAPIDO.sh** - Instrucciones rápidas
- **REFERENCIAS_PARAMETROS.md** - Este archivo

---

## 🔑 Parámetros Globales

Todos los scripts soportan:
```bash
--help      Mostrar ayuda del script
--verbose   Modo verboso (logs detallados)
```

---

## 📊 Matriz de Parámetros por Script

### install_postgres.sh
```
--user <nombre>              Nombre usuario PostgreSQL (defecto: odoo)
--password <contraseña>      Contraseña (defecto: generada aleatoria)
--verbose                    Logs detallados
--help                       Mostrar ayuda
```

### install_nginx.sh
```
--verbose                    Logs detallados
--help                       Mostrar ayuda
```

### configure_nginx_ssl.sh
```
--domain <dominio>          Dominio a certificar (REQUERIDO)
--email <email>             Email Let's Encrypt (REQUERIDO)
--renew-only                Solo renovar certificado existente
--help                      Mostrar ayuda
```

### download_odoo.sh
```
--type <community|enterprise>    Tipo de Odoo (defecto: community)
--version <versión>              Versión (defecto: 16.0)
--path <ruta>                    Ruta de extracción (defecto: ./odoo)
--clean                          Limpiar descarga anterior
--help                           Mostrar ayuda
```

### install_odoo_dependencies.sh
```
--path <ruta>                Ruta de instalación (defecto: /opt/odoo)
--user <usuario>             Usuario propietario (defecto: odoo)
--requirements <archivo>     Ruta requirements.txt
--help                       Mostrar ayuda
```

### configure_odoo.sh
```
--user <usuario>             Usuario sistema (defecto: odoo)
--odoo-path <ruta>          Ruta Odoo (defecto: /opt/odoo/odoo)
--db-host <host>            Host PostgreSQL (defecto: localhost)
--db-port <puerto>          Puerto PostgreSQL (defecto: 5432)
--db-name <nombre>          Nombre BD (defecto: odoo)
--db-user <usuario>         Usuario PostgreSQL (defecto: odoo)
--db-password <contraseña>  Contraseña PostgreSQL (REQUERIDO)
--admin-passwd <contraseña> Contraseña admin Odoo (defecto: admin_password)
--workers <número>          Número de workers (defecto: 2)
--xmlrpc-port <puerto>      Puerto Odoo (defecto: 8069)
--log-level <nivel>         Nivel de log: debug|info|warn|error (defecto: info)
--help                      Mostrar ayuda
```

### setup_services.sh
```
--domain <dominio>          Tu dominio (REQUERIDO)
--user <usuario>            Usuario Odoo (defecto: odoo)
--odoo-path <ruta>         Ruta Odoo (defecto: /opt/odoo)
--venv-path <ruta>         Ruta venv (defecto: /opt/odoo/venv)
--odoo-bin <ruta>          Ruta odoo-bin
--odoo-port <puerto>       Puerto interno (defecto: 8069)
--help                     Mostrar ayuda
```

---

## 🎓 Ejemplos Comunes

### Ejemplo 1: Despliegue Básico
```bash
sudo ./install_postgres.sh --user odoo --password "secure123"
sudo ./install_nginx.sh
./download_odoo.sh --type community --version 16.0
sudo ./install_odoo_dependencies.sh
sudo ./configure_odoo.sh --db-password "secure123" --workers 4
sudo ./setup_services.sh --domain ejemplo.com
sudo ./configure_nginx_ssl.sh --domain ejemplo.com --email admin@ejemplo.com
```

### Ejemplo 2: Despliegue en Ruta Personalizada
```bash
sudo ./download_odoo.sh --type community --version 16.0 --path /srv/odoo
sudo ./install_odoo_dependencies.sh --path /srv/odoo
sudo ./configure_odoo.sh --odoo-path /srv/odoo/odoo --workers 8
sudo ./setup_services.sh --domain ejemplo.com
```

### Ejemplo 3: Despliegue Enterprise
```bash
# 1. Descargar manualmente archivo ZIP desde odoo.com
# 2. Colocar en directorio actual
./download_odoo.sh --type enterprise
# 3. Seguir instrucciones interactivas
```

### Ejemplo 4: Base de Datos Remota
```bash
sudo ./configure_odoo.sh \
    --db-host 192.168.1.100 \
    --db-port 5432 \
    --db-user odoo_user \
    --db-password "secure_password" \
    --workers 4
```

### Ejemplo 5: Aumentar Workers Después del Despliegue
```bash
sudo ./configure_odoo.sh --workers 16
sudo systemctl restart odoo
```

---

## ✅ Checklists

### Pre-Despliegue
- [ ] Servidor Ubuntu/Debian accesible
- [ ] Acceso SSH como root o con sudo
- [ ] Dominio configurado apuntando a servidor
- [ ] DNS propagado (nslookup resonador)
- [ ] Firewall permite puertos 22, 80, 443
- [ ] Mínimo 20GB de espacio en disco
- [ ] Mínimo 4GB de RAM
- [ ] Python 3.7+ disponible

### Post-Despliegue
- [ ] Servicios corriendo (systemctl status)
- [ ] Odoo accesible en https://dominio.com
- [ ] Certificado SSL válido
- [ ] Credenciales de administrador funcionando
- [ ] Logs sin errores críticos
- [ ] Backup de BD realizado
- [ ] Firewall habilitado correctamente
- [ ] Monitoreo configurado (opcional pero recomendado)

---

## 🐛 Troubleshooting Rápido

### Odoo no inicia
```bash
sudo systemctl status odoo -n 50
sudo tail -f /var/log/odoo/odoo.log
```

### PostgreSQL no conecta
```bash
sudo systemctl status postgresql
sudo -u postgres psql -U odoo -d odoo -c "SELECT 1"
```

### SSL no funciona
```bash
sudo certbot certificates
sudo nginx -t
sudo systemctl reload nginx
```

### 502 Bad Gateway
```bash
sudo systemctl restart odoo
sudo tail -f /var/log/nginx/odoo.error.log
```

---

## 🔒 Cambios Recomendados Post-Despliegue

1. **Cambiar contraseña admin Odoo**
   ```
   Odoo UI: Settings > Users & Companies > Users > admin
   ```

2. **Cambiar contraseña PostgreSQL**
   ```bash
   sudo -u postgres psql
   ALTER USER odoo WITH PASSWORD 'nueva_contraseña';
   # Actualizar /etc/odoo.conf
   sudo nano /etc/odoo.conf
   # Reiniciar Odoo
   sudo systemctl restart odoo
   ```

3. **Habilitar Firewall**
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

4. **Configurar Backup Automático**
   ```bash
   # Crear script en /opt/odoo/backup.sh
   sudo crontab -e
   # Agregar línea para backup diario
   ```

---

## 📞 Soporte Rápido

**Documentación:** Ver README_COMPLETO.md
**Logs:** `/var/log/odoo/odoo.log`
**Configuración:** `/etc/odoo.conf`
**Código:** `/opt/odoo/odoo`

---

*Última actualización: 2024*