# 📦 Guía de Despliegue Profesional de Odoo

Solución **completa, productiva y escalable** de scripts bash para desplegar Odoo en servidor Ubuntu/Debian con PostgreSQL, Nginx con SSL, venv Python dedicado y configuración profesional.

---

## 📋 Requisitos Previos

- **SO:** Ubuntu 20.04 LTS o superior / Debian 10+
- **Acceso:** Root o usuario con permisos sudo
- **Dominio:** Configurado y apuntando al servidor (DNS resuelto)
- **Conexión:** Internet (150MB+ para descargas)
- **Hardware mínimo:** 2 CPUs, 4GB RAM, 20GB disco

---

## 📦 Scripts Incluidos

| Script | Descripción | Parámetros Dinámicos |
|--------|-------------|-----------|
| **install_postgres.sh** | Instalación y configuración de PostgreSQL | `--user`, `--password`, `--verbose` |
| **install_nginx.sh** | Instalación de Nginx | `--verbose` |
| **configure_nginx_ssl.sh** | Configuración de SSL con Let's Encrypt | `--domain`, `--email`, `--renew-only` |
| **download_odoo.sh** | Descarga de Odoo Community/Enterprise | `--type`, `--version`, `--path`, `--clean` |
| **install_odoo_dependencies.sh** | Instalación de dependencias y venv Python | `--path`, `--user`, `--requirements` |
| **configure_odoo.sh** | Configuración de Odoo y archivo .conf | `--user`, `--db-name`, `--workers`, `--log-level` |
| **setup_services.sh** | Configuración de servicios systemd y Nginx | `--domain`, `--user`, `--odoo-port` |

---

## 🚀 Proceso de Despliegue Paso a Paso

### **Paso 1: Instalar PostgreSQL**

```bash
sudo ./install_postgres.sh \
  --user odoo \
  --password tu_contraseña_muy_segura
```

**Parámetros disponibles:**
```
  --user <nombre_usuario>           Usuario PostgreSQL (defecto: odoo)
  --password <contraseña>           Contraseña (defecto: generada aleatoria)
  --verbose                         Mostrar logs detallados
  --help                            Mostrar ayuda
```

**Salida esperada:**
```
[✓] PostgreSQL instalado y configurado exitosamente

Credenciales:
  Usuario: odoo
  Contraseña: tu_contraseña_muy_segura
  Host: localhost
  Puerto: 5432
```

**Qué hace:**
- ✅ Actualiza sistema
- ✅ Instala PostgreSQL 12+
- ✅ Crea usuario y base de datos
- ✅ Configura permisos

---

### **Paso 2: Instalar Nginx**

```bash
sudo ./install_nginx.sh --verbose
```

**Qué hace:**
- ✅ Instala Nginx (motor web)
- ✅ Lo habilita como servicio
- ✅ Lo inicia automáticamente

---

### **Paso 3: Configurar Nginx con SSL**

```bash
sudo ./configure_nginx_ssl.sh \
  --domain ejemplo.com \
  --email admin@ejemplo.com
```

**Parámetros:**
```
  --domain <dominio>                Tu dominio (requerido)
  --email <email>                   Email para Let's Encrypt (requerido)
  --renew-only                      Solo renovar certificado existente
  --help                            Mostrar ayuda
```

**Validaciones automáticas:**
- ✅ Verifica que el dominio exista
- ✅ Obtiene certificado SSL
- ✅ Configura renovación automática
- ✅ Recarga Nginx

**Notas importantes:**
- Esperar a que DNS resuelva correctamente
- El dominio debe apuntar a la IP del servidor
- Certbot renueva automáticamente cada 60 días

---

### **Paso 4: Descargar Odoo**

**Opción A: Community (recomendado para comenzar)**
```bash
./download_odoo.sh \
  --type community \
  --version 16.0 \
  --path ./odoo
```

**Opción B: Enterprise (requiere crédito)**
```bash
./download_odoo.sh --type enterprise
# Seguir instrucciones interactivas para ruta del archivo
```

**Parámetros:**
```
  --type <community|enterprise>     Tipo de Odoo (defecto: community)
  --version <versión>               Versión (defecto: 16.0)
  --path <ruta>                     Dónde descargar (defecto: ./odoo)
  --clean                           Limpiar descarda anterior
  --help                            Mostrar ayuda
```

**Versiones disponibles:**
- `16.0` (Actual estable)
- `15.0, 14.0, 13.0, 12.0` (Versiones antiguas)

**Salida esperada:**
```
[✓] Odoo community 16.0 descargado y extraído

Ubicación: /ruta/actual/odoo
Contenido: lista de archivos
```

---

### **Paso 5: Instalar Dependencias**

```bash
sudo ./install_odoo_dependencies.sh \
  --path /opt/odoo \
  --user odoo
```

**Parámetros:**
```
  --path <ruta>                     Ruta de Odoo (defecto: /opt/odoo)
  --user <usuario>                  Usuario propietario (defecto: odoo)
  --requirements <archivo>          Ruta requirements.txt
  --help                           Mostrar ayuda
```

**Instala:**
- ✅ Herramientas de sistema (libxml2, libxslt, libevent, etc.)
- ✅ Python 3 y develop headers
- ✅ wkhtmltopdf (para reportes PDF)
- ✅ Virtual environment en `/opt/odoo/venv`

**Tiempo estimado:** 5-10 minutos

---

### **Paso 6: Configurar Odoo**

```bash
sudo ./configure_odoo.sh \
  --user odoo \
  --db-name odoo \
  --db-user odoo \
  --db-password contraseña_segura \
  --admin-passwd admin_super_seguro \
  --workers 4 \
  --log-level info
```

**Parámetros principales:**
```
  --user <usuario>                  Usuario del sistema (defecto: odoo)
  --odoo-path <ruta>                Ruta de Odoo (defecto: /opt/odoo/odoo)
  --db-host <host>                  Host PostgreSQL (defecto: localhost)
  --db-port <puerto>                Puerto PostgreSQL (defecto: 5432)
  --db-name <nombre>                Nombre BD (defecto: odoo)
  --db-user <usuario>               Usuario PostgreSQL (defecto: odoo)
  --db-password <contraseña>        Contraseña PostgreSQL
  --admin-passwd <contraseña>       Contraseña administrador Odoo
  --workers <número>                Workers (defecto: 2) - Fórmula: (CPUs * 2) + 1
  --xmlrpc-port <puerto>            Puerto Odoo (defecto: 8069)
  --log-level <nivel>               debug|info|warn|error (defecto: info)
  --help                            Mostrar ayuda
```

**Cálculo de Workers:**
```
Para servidor de 2 CPUs:  workers = (2 * 2) + 1 = 5
Para servidor de 4 CPUs:  workers = (4 * 2) + 1 = 9
Para servidor de 8 CPUs:  workers = (8 * 2) + 1 = 17
```

**Genera:**
- ✅ Usuario del sistema `odoo`
- ✅ Directorios necesarios con permisos correctos
- ✅ Archivo `/etc/odoo.conf` con toda la configuración

**Vista previa del archivo /etc/odoo.conf:**
```ini
[options]
admin_passwd = admin_super_seguro
db_host = localhost
db_port = 5432
db_user = odoo
db_password = contraseña_segura
db_name = odoo
addons_path = /opt/odoo/odoo/addons
logfile = /var/log/odoo/odoo.log
log_level = info
xmlrpc_port = 8069
xmlrpc_interface = 127.0.0.1
workers = 4
max_cron_threads = 1
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
```

---

### **Paso 7: Configurar Servicios Systemd y Nginx**

```bash
sudo ./setup_services.sh \
  --domain ejemplo.com \
  --user odoo \
  --odoo-port 8069
```

**Parámetros:**
```
  --domain <dominio>                Tu dominio (requerido)
  --user <usuario>                  Usuario Odoo (defecto: odoo)
  --odoo-path <ruta>                Ruta Odoo (defecto: /opt/odoo)
  --venv-path <ruta>                Ruta venv (defecto: /opt/odoo/venv)
  --odoo-bin <ruta>                 Ruta odoo-bin
  --odoo-port <puerto>              Puerto interno (defecto: 8069)
  --help                            Mostrar ayuda
```

**Genera:**
- ✅ Servicio systemd `/etc/systemd/system/odoo.service`
- ✅ Configuración Nginx `/etc/nginx/sites-available/odoo`
- ✅ Proxy reverso con SSL
- ✅ Soporte para WebSocket
- ✅ Caché estática

**Salida esperada:**
```
[✓] Servicios configurados exitosamente

Resumen:
  Dominio: ejemplo.com
  Usuario Odoo: odoo
  Puerto Odoo: 8069
  SSL habilitado: true

Puedes acceder a Odoo en: https://ejemplo.com
```

---

## ⚡ Resumen: Orden de Ejecución Completo

### Opción A: Ejecución Rápida (Todo en secuencia)

```bash
#!/bin/bash
# deploy.sh - Script maestro

set -e

echo "=== Iniciando despliegue de Odoo ==="

# 1. PostgreSQL
echo ">>> Paso 1: PostgreSQL"
sudo ./install_postgres.sh --user odoo --password "$(openssl rand -base64 16)"

# 2. Nginx
echo ">>> Paso 2: Nginx"
sudo ./install_nginx.sh

# 3. Descargar Odoo
echo ">>> Paso 3: Descargar Odoo"
./download_odoo.sh --type community --version 16.0

# 4. Dependencias
echo ">>> Paso 4: Dependencias"
sudo ./install_odoo_dependencies.sh

# 5. Configurar Odoo
echo ">>> Paso 5: Configurar Odoo"
sudo ./configure_odoo.sh --workers 4

# 6. Servicios
echo ">>> Paso 6: Servicios"
read -p "Ingresa tu dominio: " DOMAIN
sudo ./setup_services.sh --domain "$DOMAIN"

# 7. SSL
echo ">>> Paso 7: SSL"
read -p "Ingresa tu email: " EMAIL
sudo ./configure_nginx_ssl.sh --domain "$DOMAIN" --email "$EMAIL"

echo "=== Despliegue completado ==="
```

### Opción B: Ejecución Manual (Paso a Paso

```bash
# Ir al directorio de scripts
cd deployment/odoo-scripts

# 1.
sudo ./install_postgres.sh

# 2.
sudo ./install_nginx.sh

# 3.
./download_odoo.sh

# Etc...
```

---

## 🔒 Seguridad - Configuración Producción

### 1️⃣ Cambiar Contraseñas Predeterminadas

```bash
sudo nano /etc/odoo.conf
```

Cambiar:
```ini
admin_passwd = tu_contraseña_muy_segura_aqui
db_password = tu_db_password_muy_segura_aqui
```

Reiniciar:
```bash
sudo systemctl restart odoo
```

### 2️⃣ Configurar Firewall

```bash
# Instalar UFW (si no está instalado)
sudo apt install -y ufw

# Configurar reglas
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp                 # SSH
sudo ufw allow 80/tcp                 # HTTP
sudo ufw allow 443/tcp                # HTTPS
sudo ufw enable

# Verificar
sudo ufw status
```

### 3️⃣ Verificar SSL

```bash
# Certificado válido
sudo certbot certificates

# Prueba de renovación (no afecta)
sudo certbot renew --dry-run

# Forzar renovación (si es necesario)
sudo certbot renew --force-renewal
```

### 4️⃣ Permisos de Archivos

```bash
# Verificar permisos
ls -la /etc/odoo.conf
ls -la /var/log/odoo/

# Restringir acceso al archivo de configuración
sudo chmod 640 /etc/odoo.conf
```

---

## 📊 Monitoreo y Verificación

### Estado de Servicios

```bash
# Odoo
sudo systemctl status odoo

# Nginx
sudo systemctl status nginx

# PostgreSQL
sudo systemctl status postgresql

# Todo junto
sudo systemctl status odoo nginx postgresql
```

### Ver Logs

```bash
# Logs de Odoo (tiempo real)
sudo tail -f /var/log/odoo/odoo.log

# Logs de Nginx
sudo tail -f /var/log/nginx/odoo.error.log

# Logs de PostgreSQL
sudo journalctl -u postgresql -f

# Líneas últimas 50 (sin tiempo real)
sudo tail -n 50 /var/log/odoo/odoo.log
```

### Comandos Útiles

```bash
# ¿Está Odoo corriendo?
ps aux | grep odoo-bin

# ¿Qué puerto está usando Odoo?
sudo netstat -tulpn | grep 8069

# ¿Cuánta memoria usa Odoo?
ps aux | grep -i odoo | awk '{print $6}' | tail -1

# Procesos de Odoo
ps aux | grep -i odoo | wc -l
```

### Prueba de Conectividad

```bash
# Verificar que Odoo responde localmente
curl -k http://localhost:8069 -H "Host: tu-dominio.com"

# Verificar que Nginx está en frente
curl -k https://tu-dominio.com | head -n 20

# Verificar que DNS resuelve
nslookup tu-dominio.com
```

---

## 🛠️ Mantenimiento y Operaciones

### Reiniciar Servicios

```bash
# Reiniciar solo Odoo
sudo systemctl restart odoo

# Reiniciar Nginx (sin downtime)
sudo systemctl reload nginx

# Reiniciar PostgreSQL (cuidado: desconecta usuarios)
sudo systemctl restart postgresql

# Reiniciar todo
sudo systemctl restart odoo postgresql nginx
```

### Editar Configuración

```bash
# Editar configuración de Odoo
sudo nano /etc/odoo.conf

# Editar configuración de Nginx
sudo nano /etc/nginx/sites-available/odoo

# Luego recargar
sudo systemctl restart odoo
sudo systemctl reload nginx
```

### Backup de Base de Datos

```bash
# Backup completo
sudo -u postgres pg_dump -U odoo odoo > odoo_backup_$(date +%Y%m%d_%H%M%S).sql

# Backup comprimido (recomendado)
sudo -u postgres pg_dump -U odoo odoo | gzip > odoo_backup_$(date +%Y%m%d).sql.gz

# Backup con estadísticas
sudo -u postgres pg_dump -U odoo --verbose odoo > odoo_backup_verbose_$(date +%Y%m%d).sql
```

### Restaurar Base de Datos

```bash
# Restaurar desde archivo
sudo -u postgres psql -U odoo odoo < odoo_backup_20240101.sql

# Restaurar comprimido
gunzip < odoo_backup_20240101.sql.gz | sudo -u postgres psql -U odoo odoo
```

### Renovar Certificado SSL

```bash
# Renovación automática (ya configurada)
sudo certbot renew --quiet

# Renovación forzada
sudo certbot renew --force-renewal

# Ver próxima renovación
sudo certbot certificates
```

### Cambiar Número de Workers

```bash
# Editar configuración
sudo nano /etc/odoo.conf

# Cambiar línea:
workers = 8

# Reiniciar
sudo systemctl restart odoo
```

---

## ❌ Solución de Problemas

### PROBLEMA: Odoo no inicia

```bash
# Verificar error
sudo systemctl status odoo -l

# Ver logs
tail -f /var/log/odoo/odoo.log

# Causas comunes:
# 1. Puerto 8069 ocupado
sudo lsof -i :8069

# 2. Errores de permisos
stat /etc/odoo.conf
stat /var/log/odoo/

# 3. Problemas de base de datos
sudo -u postgres psql -U odoo -d odoo -c "SELECT 1"
```

### PROBLEMA: PostgreSQL no conecta

```bash
# Verificar que PostgreSQL está corriendo
sudo systemctl status postgresql

# Verificar conexión
sudo -u postgres psql -l

# Verificar usuario y permisos
sudo -u postgres psql -c "\du odoo"

# Recrear usuario si es necesario
sudo -u postgres psql -c "DROP USER IF EXISTS odoo;"
sudo -u postgres psql -c "CREATE USER odoo WITH PASSWORD 'contraseña';"
sudo -u postgres psql -c "ALTER USER odoo CREATEDB;"
```

### PROBLEMA: SSL/HTTPS no funciona

```bash
# Verificar certificado
sudo certbot certificates

# Validar configuración de Nginx
sudo nginx -t

# Ver logs de Nginx
sudo tail -f /var/log/nginx/odoo.error.log

# Renovar certificado
sudo certbot renew --force-renewal

# Recargar Nginx
sudo systemctl reload nginx
```

### PROBLEMA: 502 Bad Gateway

```bash
# Causa: Odoo no está respondiendo

# 1. Verificar que Odoo corre
sudo systemctl status odoo

# 2. Ver logs
tail -f /var/log/odoo/odoo.log

# 3. Reiniciar Odoo
sudo systemctl restart odoo

# 4. Ver logs de Nginx
tail -f /var/log/nginx/odoo.error.log
```

### PROBLEMA: Lentitud/Alto uso de CPU

```bash
# Ver procesos
top -p $(pgrep -f odoo-bin)

# Aumentar workers
sudo nano /etc/odoo.conf
# workers = (actualizar a número más alto)
sudo systemctl restart odoo

# Aumentar memoria
# limit_memory_hard = 5368709120  # 5GB
```

---

## 📝 Archivos Principales Generados

```
/opt/odoo/                          # Directorio principal
├── odoo/                           # Código fuente de Odoo
│   ├── odoo-bin                    # Binario ejecutable
│   ├── addons/                     # Módulos de Odoo
│   └── ...
├── venv/                           # Virtual environment Python
│   ├── bin/
│   │   ├── python                 # Intérprete Python
│   │   └── pip
│   └── lib/
│
/etc/odoo.conf                      # Configuración principal de Odoo

/etc/systemd/system/odoo.service    # Servicio systemd

/etc/nginx/sites-available/odoo     # Configuración Nginx
/etc/nginx/sites-enabled/odoo       # Link de habilitación

/var/log/odoo/                      # Logs de Odoo
.odoo.log

/var/lib/odoo/                      # Datos adicionales

/etc/letsencrypt/live/              # Certificados SSL
└── tu-dominio.com/
    ├── fullchain.pem
    └── privkey.pem
```

---

## 🎯 Checklist Post-Despliegue

Verificar que completaste:

- [ ] PostgreSQL instalado y corriendo
- [ ] Usuario PostgreSQL `odoo` creado con contraseña
- [ ] Nginx instalado y habilitado
- [ ] Certificado SSL válido obtenido
- [ ] Odoo descargado en `/opt/odoo/odoo`
- [ ] Venv creado en `/opt/odoo/venv`
- [ ] Archivo `/etc/odoo.conf` configurado correctamente
- [ ] Servicio systemd `odoo` habilitado y corriendo
- [ ] Odoo accesible en `https://tu-dominio.com`
- [ ] Credenciales administrativas cambiadas
- [ ] Firewall habilitado con reglas correctas
- [ ] Certificado SSL se renueva automáticamente
- [ ] Backup de BD existe
- [ ] Logs sin errores críticos
- [ ] Acceso SSH restringido correctamente

---

## 📞 Recursos y Enlaces Útiles

- **Documentación Odoo:** https://www.odoo.com/documentation
- **GitHub Odoo Community:** https://github.com/odoo/odoo
- **PostgreSQL Manual:** https://www.postgresql.org/docs/
- **Nginx Docs:** https://nginx.org/en/docs/
- **Let's Encrypt:** https://letsencrypt.org/docs/
- **Systemd Manual:** https://www.freedesktop.org/software/systemd/man/
- **Ubuntu Server Guide:** https://ubuntu.com/server/docs

---

## 📄 Versión y Licencia

**Versión:** 2.0  
**Fecha:** 2024  
**Licencia:** Código abierto - Libre para usar y modificar

---

## 🎓 Notas Finales

### Para Principiantes
- Ejecuta los scripts **en orden** (1 a 7)
- **Confirma** cada pregunta interactiva
- **Guarda** las contraseñas en lugar seguro
- **Verifica** logs después de cada paso
- **Haz backup** regularmente

### Para Administradores Experimentados
- Personaliza parámetros según tu infraestructura
- Ajusta workers según CPUs disponibles
- Implementa monitoreo (Prometheus, Datadog, etc.)
- Configura alertas de logs
- Planifica rotación de backup
- Considera réplicas de BD para HA

### Mejoras Futuras Posibles
- [ ] Script de automatización completa (una ejecución)
- [ ] Integración con Docker
- [ ] Configuración de Odoo multiinstancia
- [ ] Monitoreo integrado con Prometheus
- [ ] Backup automático con AWS S3
- [ ] High Availability (cluster)

---

¡Tu despliegue de Odoo está listo! 🚀