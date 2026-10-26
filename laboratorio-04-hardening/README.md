# Laboratorio 04 — Hardening

## Objetivo

Evaluar la seguridad de una instalación de PostgreSQL, identificando su superficie de ataque inicial, revisando su configuración (red, autenticación, autorización, TLS, extensiones, conexiones y sistema operativo) y proponiendo controles de hardening basados en defensa en profundidad y mínimo privilegio. El resultado se resume en una comparación antes/después, un checklist de verificación y una línea base de seguridad.

## Entorno

| Elemento | Valor |
|---|---|
| Motor | PostgreSQL 18.6 sobre Windows x64 |
| Archivo de configuración | `C:/Program Files/PostgreSQL/18/data/postgresql.conf` |
| Archivo de reglas de acceso | `C:/Program Files/PostgreSQL/18/data/pg_hba.conf` |
| Archivo de identidades | `C:/Program Files/PostgreSQL/18/data/pg_ident.conf` |
| Puerto | `5434` (no estándar) |
| Escucha | `0.0.0.0` y `::` (todas las interfaces IPv4 e IPv6) |
| Base de práctica | `db_17322758_bryan_gonzalez` |
| Usuario de práctica | `u_17322758_bryan_gonzalez` |
| Roles propios | `postgres` (superusuario), `analista` y `soporte` (`NOLOGIN`) |
| Extensiones | `plpgsql` 1.0 y `pgcrypto` 1.4 |
| Conexiones | `max_connections = 100`, `superuser_reserved_connections = 3` |
| Timeouts | `statement_timeout = 0` e `idle_in_transaction_session_timeout = 0` |
| Cifrado de contraseñas | `password_encryption = scram-sha-256` |
| TLS | `ssl = off` |
| Diseño de red propuesto | Red DBA `10.10.10.0/24` hacia el servidor `10.10.10.20` |

## Superficie de ataque inicial

| Elemento | Estado inicial | Riesgo |
|---|---|---|
| Puerto | `5434`, no estándar | Bajo. Solo reduce escaneos automáticos y sigue siendo detectable. |
| Interfaces de escucha | `listen_addresses = '*'` | Alto. El servidor acepta conexiones por cualquier interfaz. |
| Conexiones remotas | Habilitadas en la práctica; solo las limitan el firewall de Windows y `pg_hba.conf` | Medio/alto. Sin reglas restrictivas, cualquier equipo con acceso a la red puede intentar autenticarse. |
| Usuarios administrativos | `postgres` es el único `SUPERUSER`, con `LOGIN`, `CREATEROLE` y `CREATEDB` | Alto. Un superusuario ignora todos los permisos. |
| TLS | `ssl = off`, sin cifrado en la conexión | Alto. Consultas, resultados y credenciales viajan en texto legible. |
| Autenticación | `scram-sha-256` para el almacenamiento de contraseñas | Bajo en almacenamiento; alto si `pg_hba.conf` usa `trust` o `md5`. |
| Regla de `pg_hba.conf` | `host all all 0.0.0.0/0 scram-sha-256` | Alto. La contraseña es la única barrera y la conexión puede ir sin TLS. |
| Timeouts de sesión | Ambos en `0` | Medio. Consultas colgadas y sesiones inactivas pueden agotar recursos. |
| Extensiones | `pgcrypto` instalada para prácticas | Bajo. Es funcionalidad adicional que podría no ser necesaria. |

Conocer la superficie de ataque debe preceder al hardening porque no se puede proteger lo que no se conoce.

## Hallazgos

1. **Exposición de red:** el servidor escucha en todas las interfaces (`*`, `0.0.0.0` y `::`), aunque para la práctica solo hace falta `localhost`.
2. **Regla de acceso permisiva:** `pg_hba.conf` permite `all/all` desde `0.0.0.0/0`, con el método `host` que acepta conexiones con o sin TLS.
3. **Sin cifrado en tránsito:** `ssl = off`, `pg_stat_ssl` muestra `ssl = false` y el cipher es `NULL`.
4. **Cuenta administrativa única:** `postgres` es el único superusuario y no existe una cuenta DBA nominal ni una cuenta de aplicación dedicada.
5. **Sin límites de sesión:** `statement_timeout` e `idle_in_transaction_session_timeout` valen `0`.
6. **Extensión no esencial:** `pgcrypto` es innecesaria si la aplicación cifra por su cuenta.
7. **Permisos del sistema operativo sin verificar:** falta revisar con `icacls` el directorio de datos, `postgresql.conf` y `pg_hba.conf`.
8. **Puntos correctos:** `password_encryption = scram-sha-256`, `postgres` como único superusuario, `analista` y `soporte` como `NOLOGIN` con acceso solo a vistas, y rutas de configuración documentadas.
9. **Caso integral:** se identificaron 13 problemas (firewall abierto, `all/all`, aplicación con cuenta administrativa, secretos en la cadena de conexión, sin auditoría, entre otros). La conclusión es que una contraseña fuerte no es suficiente.

## Cambios realizados



| Control | Antes | Después |
|---|---|---|
| `listen_addresses` | `*` | `localhost` o solo la IP privada (p. ej. `10.10.10.20`) |
| `pg_hba.conf` | `host all all 0.0.0.0/0 scram-sha-256` | `hostssl db_17322758_bryan_gonzalez u_17322758_bryan_gonzalez 10.10.10.0/24 scram-sha-256` |
| Autenticación | `scram-sha-256` | Se mantiene; sin reglas `trust` ni `md5` |
| Administración | Solo `postgres` | `postgres` solo desde `localhost`; `dba_admin` sin `SUPERUSER` para el trabajo diario |
| Cuentas de aplicación | Sin cuenta dedicada | `app_clientes` con `SELECT`, `INSERT` y `UPDATE` solo sobre lo necesario; `consulta_ro` de solo lectura |
| Puerto | `5434` | Se mantiene o el definido por el entorno, con acceso limitado por firewall |
| TLS | `ssl = off` | `ssl = on`, `ssl_min_protocol_version = TLSv1.2` o superior, y clientes con `sslmode=verify-full` |
| Permisos del SO | Sin verificar | Solo cuenta de servicio, `Administrators` y `SYSTEM` |
| Extensiones | `pgcrypto` y `plpgsql` | `plpgsql`; `DROP EXTENSION pgcrypto;` si no se usa |
| Conexiones | Timeouts en `0` | `statement_timeout = 30s`, `idle_in_transaction_session_timeout = 60s` y `max_connections` ajustado |
| Firewall (diseño) | Puerto abierto a cualquier origen | Permitir `10.10.10.0/24` hacia `10.10.10.20:5432` y denegar el resto |

Reglas propuestas de `pg_hba.conf` para la práctica:

```
host        db_17322758_bryan_gonzalez    u_17322758_bryan_gonzalez    127.0.0.1/32      scram-sha-256
host        db_17322758_bryan_gonzalez    u_17322758_bryan_gonzalez


## Justificación de los cambios

- **Limitar `listen_addresses`:** reduce la superficie de ataque, porque el servidor solo acepta conexiones por la interfaz que realmente se usa.
- **Regla específica con `hostssl`:** restringe base, usuario y origen, y exige TLS, en lugar de permitir cualquier combinación desde cualquier IP.
- **Mantener `scram-sha-256`:** guarda un verificador unidireccional con sal e iteraciones, no la contraseña, y no existe una clave para recuperarla.
- **Separar cuentas:** un `SUPERUSER` ignora todos los permisos. Si la aplicación lo usa, una inyección SQL o una credencial filtrada equivale a un compromiso total. Con mínimo privilegio, el daño queda limitado.
- **Activar TLS:** protege consultas, resultados y credenciales en tránsito, y `verify-full` permite verificar la identidad del servidor.
- **Firewall y `pg_hba.conf` juntos:** no son equivalentes. El firewall decide por IP y puerto, sin saber de usuarios ni bases. `pg_hba.conf` decide dentro del servidor, con base, usuario, origen, SSL y método. Se necesitan ambos (defensa en profundidad).
- **Timeouts y `max_connections`:** protegen la disponibilidad frente a consultas colgadas, transacciones abiertas y agotamiento de conexiones. `superuser_reserved_connections` garantiza que un administrador pueda entrar para diagnosticar.
- **Permisos del sistema operativo:** `GRANT` y `REVOKE` solo controlan el acceso a través del servidor. Quien lea los archivos directamente se salta la base de datos.
- **Quitar extensiones innecesarias:** cada extensión añade funcionalidad y superficie de ataque.
- **Puerto:** cambiarlo solo reduce escaneos automáticos. El control real es el firewall y `pg_hba.conf`.

## Verificación

| Aspecto | Comando o fuente | Resultado |
|---|---|---|
| Puerto | `SHOW port;` | `5434` |
| Interfaces | `SHOW listen_addresses;` | `*` (escucha en `0.0.0.0` y `::`) |
| Autenticación | `SHOW password_encryption;` | `scram-sha-256` |
| Superusuarios | Consulta a `pg_roles` (`rolsuper`) | Solo `postgres` |
| Extensiones | `pg_extension` | `pgcrypto` 1.4 y `plpgsql` 1.0 |
| TLS | `SHOW ssl;` y `pg_stat_ssl` | `off`, `ssl = false` y cipher `NULL` |
| Conexiones | `SHOW max_connections;` y relacionados | `100`, `3`, `0` y `0` |
| Rutas de configuración | `SHOW config_file;`, `hba_file` e `ident_file` | Rutas en `C:/Program Files/PostgreSQL/18/data/` |
| Versión | `SELECT version();` | PostgreSQL 18.6 sobre Windows x64 |
| Permisos del SO | `icacls` | Pendiente |
| Reglas de `pg_hba.conf` | Revisión del archivo | Pendiente |



## Checklist de hardening

| # | Control | Verificado | Evidencia |
|---|---|---|---|
| 1 | Puerto documentado | Sí | `SHOW port;` → `5434` |
| 2 | Interfaces de escucha justificadas | No | `listen_addresses = *`; pendiente limitar |
| 3 | `pg_hba.conf` revisado | Pendiente | Ruta con `SHOW hba_file;` y revisión de reglas |
| 4 | Redes autorizadas restringidas | No | Regla abierta `0.0.0.0/0`; diseño propuesto `10.10.10.0/24` |
| 5 | Autenticación segura | Sí | `password_encryption = scram-sha-256` |
| 6 | Superusuarios identificados | Sí | Solo `postgres` con `rolsuper = true` |
| 7 | Cuentas de aplicación separadas | No | Diseño `app_clientes` y `consulta_ro`; pendiente crearlas |
| 8 | Privilegios mínimos | Parcial | `analista` y `soporte` como `NOLOGIN` con acceso solo a vistas; `REVOKE` sobre `clientes` |
| 9 | Extensiones revisadas | Sí | `pgcrypto` 1.4 y `plpgsql` 1.0 |
| 10 | TLS verificado | Sí (resultado negativo) | `ssl = off`; `pg_stat_ssl` → `ssl = false` |
| 11 | Configuración protegida | Pendiente | `icacls` sobre `postgresql.conf` y `pg_hba.conf` |
| 12 | Directorio de datos protegido | Pendiente | `icacls` sobre `data_directory` |
| 13 | Firewall documentado | Sí (conceptual) | Permitir `10.10.10.0/24` y denegar el resto; firewall institucional sin modificar |
| 14 | Actualizaciones documentadas | Sí | PostgreSQL 18.6 sobre Windows x64 |
| 15 | Configuración registrada | Sí | `config_file`, `hba_file` e `ident_file` |



## Conclusiones

1. La instalación inicial tiene una superficie de ataque amplia: escucha en todas las interfaces, tiene una regla `all/all` desde `0.0.0.0/0`, no usa TLS y no tiene cuentas separadas ni límites de sesión.
2. Lo que ya cumple es la base: `scram-sha-256` para las contraseñas, un único superusuario identificado, roles de grupo `NOLOGIN` con acceso por vistas y configuración documentada.
3. Una contraseña fuerte no es suficiente. La seguridad depende de varias capas (autenticación, autorización, red, configuración, sistema operativo y monitoreo), de modo que si una falla, las demás limiten el daño.
4. Los controles prioritarios son restringir `listen_addresses` y `pg_hba.conf`, activar TLS, crear cuentas separadas con mínimo privilegio y limitar el firewall a las redes autorizadas.
5. Quedan pendientes la verificación de permisos del sistema operativo, la revisión de `pg_hba.conf`, la creación de las cuentas `app_clientes` y `consulta_ro`, la aplicación del firewall y los límites de sesión.
6. La línea base (Actividad 19) sirve como referencia para auditorías periódicas, con revisión trimestral y evidencia guardada.