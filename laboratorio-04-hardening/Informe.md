## Actividad 1 — Identificar la superficie de ataque
| Elemento | Estado actual | ¿Es necesario? | Riesgo |
|---|---|---|---|
| Puerto PostgreSQL | `5434` (distinto al estándar 5432) | Sí, para recibir conexiones; el puerto no estándar solo reduce escaneos automáticos | Bajo: cambiar el puerto no sustituye otros controles; sigue siendo detectable con un escaneo |
| Interfaces de escucha | `listen_addresses = *` (todas las interfaces) | No. Debería limitarse a `localhost` o a la IP necesaria | Alto: el servidor acepta conexiones desde cualquier interfaz de red, lo que amplía la superficie de ataque |
| Conexiones remotas | Habilitadas en la práctica por `listen_addresses = *`; el acceso real depende de `pg_hba.conf` | Solo si hay clientes en otras máquinas, y limitadas a IP y usuarios específicos | Medio/alto: sin reglas restrictivas en `pg_hba.conf`, cualquier equipo con acceso a la red puede intentar autenticarse |
| Usuarios administrativos | Existe el superusuario `postgres`; revisar con `\du` o `pg_roles` si hay otros con `rolsuper` | Solo los estrictamente necesarios (DBA) | Alto: un superusuario ignora todos los permisos; si se compromete, se expone toda la base |
| SSL/TLS | `ssl = off` | Sí, sobre todo con conexiones remotas | Alto: consultas, resultados y credenciales viajan en texto legible; posible intercepción o ataque de intermediario |
| Métodos de autenticación | `password_encryption = scram-sha-256` (almacenamiento de contraseñas); revisar `pg_hba.conf` para ver el método de conexión | Sí, SCRAM-SHA-256 es el recomendado | Bajo en el almacenamiento. Alto si `pg_hba.conf` usa `trust` o `md5`; debe usar `scram-sha-256` |

### ¿Por qué conocer la superficie de ataque debe preceder al hardening?
Porque no se puede proteger lo que no se conoce. La superficie de ataque es el conjunto de puntos por los que alguien podría entrar o dañar el sistema (puertos, interfaces de escucha, conexiones remotas, usuarios administrativos, TLS, métodos de autenticación).

## Actividad 2 — Identificar los archivos de configuración

### `config_file:` C:/Program Files/PostgreSQL/18/data/postgresql.conf
### `hba_file:` C:/Program Files/PostgreSQL/18/data/pg_hba.conf
### `ident_file:` C:/Program Files/PostgreSQL/18/data/pg_ident.conf


### ¿Por qué es importante conocer la ubicación física de estos archivos?
Conocer las rutas permite aplicar permisos del sistema operativo, monitorear cambios, incluirlos en respaldos con protección y auditar el sistema. Sin esa ubicación, el hardening dentro de PostgreSQL queda incompleto, porque el control puede evadirse desde el sistema de archivos.

## Actividad 3 — Revisar listen_addresses

```
Configuración encontrada:
listen_addresses = '*' (todas las interfaces, puerto 5434)

Interfaces necesarias:
localhost (127.0.0.1) y, si hay clientes remotos autorizados,
únicamente la IP de la interfaz privada que los atiende.

Interfaces innecesarias:
Cualquier interfaz pública o de otras redes (Wi-Fi, VPN, adaptadores
virtuales) que no se usen para llegar a la base de datos.
```

La **segunda arquitectura**:

- **Reduce la superficie de ataque:** el puerto de PostgreSQL no es visible desde Internet, así que no se puede escanear ni atacar directamente.
- **Defensa en profundidad:** para llegar a la base, un atacante primero tendría que comprometer otro componente (aplicación, VPN o equipo de la red privada), y no depende de un solo control.
- **Menos impacto por errores:** si `listen_addresses` o `pg_hba.conf` quedaran demasiado permisivos, la red privada sigue limitando quién puede alcanzar el servidor.
- **Acceso controlado:** solo pasan los orígenes autorizados, con auditoría y reglas específicas.

## Actividad 5 — Analizar una regla permisiva
```
Regla actual:
host    all    all    0.0.0.0/0    scram-sha-256

Problema:
Permite que cualquier usuario intente conectarse a cualquier base desde
cualquier dirección IP. La contraseña es la única barrera, y la conexión
puede ir sin cifrar (host acepta conexiones con o sin TLS).

Origen que realmente necesita acceso:
Solo la IP o red privada del servidor de aplicación o del equipo de
administración (por ejemplo, 192.168.1.10/32 o 10.0.0.0/24).

Base de datos:
Solo la base que se usa en la práctica (db_17322758_bryan_gonzalez).

Usuario:
Solo el usuario de la aplicación o práctica (u_17322758_bryan_gonzalez).
Los superusuarios (postgres) no deberían conectarse de forma remota.

Regla propuesta:
hostssl    db_17322758_bryan_gonzalez    u_17322758_bryan_gonzalez    192.168.1.10/32    scram-sha-256
```
## Actividad 6 — Aplicar mínimo privilegio a conexiones
```
# TIPO      BASE DE DATOS                 USUARIO                       ORIGEN           MÉTODO
host        db_17322758_bryan_gonzalez    u_17322758_bryan_gonzalez     127.0.0.1/32     scram-sha-256
```

Si el cliente está en otra máquina (por ejemplo, la IP que devuelva `inet_client_addr()`):

```
host        db_17322758_bryan_gonzalez    u_17322758_bryan_gonzalez     192.168.1.25/32  scram-sha-256
```

## Actividad 7 — Revisar autenticación
### ¿Qué diferencia existe entre autenticación y autorización?
La **autenticación** verifica quién es el usuario (contraseña, certificado). La **autorización** define qué puede hacer una vez dentro (`GRANT`, `REVOKE`, roles). 
### ¿Qué protege scram-sha-256?
Protege la contraseña y el proceso de autenticación. En la base se guarda un verificador derivado (con sal e iteraciones), no la contraseña. 

### ¿Por qué una contraseña almacenada mediante un mecanismo de autenticación no debe confundirse con cifrado reversible?
Porque lo almacenado es un verificador unidireccional, no la contraseña cifrada. No existe una clave para recuperar el original: el servidor solo comprueba si lo que escribe el usuario coincide. 

### ¿Qué sucede si una cuenta tiene permisos excesivos aunque utilice una contraseña fuerte?
La contraseña fuerte solo dificulta que alguien entre, pero si la cuenta se compromete (phishing, malware, uso indebido interno o error), el atacante hereda todos sus permisos. 

## Actividad 8 — Revisar usuarios y privilegios

## Inventario de roles de PostgreSQL

| Rol | LOGIN | SUPERUSER | CREATEROLE | CREATEDB | Función |
|---|---|---|---|---|---|
| `postgres` | Sí | Sí | Sí | Sí | Superusuario administrador. Ignora todos los permisos. |
| `analista` | No | No | No | No | Rol de grupo para analítica, con acceso solo a la vista o esquema analítico. |
| `soporte` | No | No | No | No | Rol de grupo para atención al cliente, con acceso solo a la vista enmascarada. |
| `pg_checkpoint` | No | No | No | No | Rol predefinido: permite ejecutar `CHECKPOINT`. |
| `pg_create_subscription` | No | No | No | No | Rol predefinido: permite crear suscripciones de replicación lógica. |
| `pg_database_owner` | No | No | No | No | Rol predefinido: representa al dueño de la base de datos. |
| `pg_execute_server_program` | No | No | No | No | Rol predefinido: permite ejecutar programas en el servidor (alto riesgo). |
| `pg_maintain` | No | No | No | No | Rol predefinido: permite tareas de mantenimiento (`VACUUM`, `ANALYZE`, `REINDEX`). |
| `pg_monitor` | No | No | No | No | Rol predefinido: lectura de estadísticas y monitoreo. |
| `pg_read_all_data` | No | No | No | No | Rol predefinido: lectura de todas las tablas (alto riesgo). |
| `pg_read_all_settings` | No | No | No | No | Rol predefinido: lectura de todos los parámetros de configuración. |
| `pg_read_all_stats` | No | No | No | No | Rol predefinido: lectura de todas las vistas de estadísticas. |
| `pg_read_server_files` | No | No | No | No | Rol predefinido: lectura de archivos del servidor (alto riesgo). |
| `pg_signal_autovacuum_worker` | No | No | No | No | Rol predefinido: enviar señales a procesos de autovacuum. |
| `pg_signal_backend` | No | No | No | No | Rol predefinido: cancelar o terminar sesiones de otros usuarios. |
| `pg_stat_scan_tables` | No | No | No | No | Rol predefinido: ejecutar funciones de monitoreo que pueden bloquear tablas. |
| `pg_use_reserved_connections` | No | No | No | No | Rol predefinido: usar conexiones reservadas. |
| `pg_write_all_data` | No | No | No | No | Rol predefinido: escritura en todas las tablas (alto riesgo). |
| `pg_write_server_files` | No | No | No | No | Rol predefinido: escritura de archivos en el servidor (alto riesgo). |

### ¿Por qué no debería utilizarse una cuenta SUPERUSER como cuenta normal de una aplicación?

Porque un SUPERUSER ignora todos los permisos de PostgreSQL, así que cualquier fallo en la aplicación se convierte en un compromiso total del servidor.

## Actividad 9 — Separar cuentas administrativas y de aplicación

| Cuenta | Propósito | LOGIN | Privilegios |
|---|---|---|---|
| DBA | Administración | Sí | Administrativos |
| APP | Aplicación | Sí | Mínimos |
| CONSULTA | Consulta | Sí | Solo lectura |


### ¿Qué riesgo existe si la aplicación se conecta utilizando una cuenta administrativa?
Si la aplicación usa una cuenta administrativa, cualquier fallo en ella se convierte en un compromiso total de la base de datos. Una inyección SQL o una credencial filtrada daría al atacante el mismo poder que el administrador: leer, modificar o borrar cualquier dato, crear roles y cambiar permisos.

## Actividad 10 — Revisar extensiones 

### qué extensiones existen
`pgcrypto` (1.4) y `plpgsql` (1.0).

### cuáles son necesarias
`plpgsql`
### cuáles fueron instaladas para prácticas
`pgcrypto`
### cuáles podrían representar funcionalidad innecesaria en otro entorno
`pgcrypto`, si la aplicación cifra en su propio código o ya no usa esas funciones.

## Actividad 11 — Revisar configuración relacionada con conexiones

### `max_connections:` 100
### `superuser_reserved_connections:` 3
### `statement_timeout:` 0
### `idle_in_transaction_session_timeout:` 0

### **max_connections:** limita cuántos clientes pueden conectarse a la vez. Si es demasiado alto, consume memoria y facilita la saturación del servidor. Si es demasiado bajo, las aplicaciones legítimas son rechazadas. Debe ajustarse a la carga real, idealmente con un pool de conexiones.

### **superuser_reserved_connections:** garantiza que un administrador pueda conectarse aunque las conexiones normales se hayan agotado (por ejemplo, durante un ataque de denegación de servicio o un fallo de la aplicación), para diagnosticar y liberar el servidor.

### **statement_timeout:** cancela consultas que tardan demasiado. Con `0` una consulta mal escrita o maliciosa puede ocupar recursos indefinidamente. Se suele configurar por rol

### **idle_in_transaction_session_timeout:** cierra sesiones que abrieron una transacción (`BEGIN`) y quedaron inactivas. Una transacción abierta mantiene bloqueos y retiene versiones antiguas de filas, lo que degrada el rendimiento y puede bloquear a otros usuarios.

### ¿Por qué mantener conexiones indefinidamente abiertas puede representar un problema de disponibilidad o consumo de recursos?
Porque cada conexión consume recursos del servidor aunque no esté haciendo nada, y el número de conexiones es limitado.

## Actividad 12 — Revisar permisos del sistema operativo

### ¿Por qué no es suficiente proteger PostgreSQL mediante GRANT y REVOKE si cualquier usuario del sistema operativo puede leer archivos sensibles?
Porque `GRANT` y `REVOKE` solo controlan el acceso **a través del servidor PostgreSQL**. Los archivos están en el sistema de archivos, y quien los lea directamente se salta la base de datos por completo.

## Actividad 13 — Revisar exposición de red

```
Dirección de escucha:
0.0.0.0 (todas las interfaces IPv4) y :: (todas las interfaces IPv6)

Puerto:
5434

¿Está expuesto fuera de la interfaz necesaria?
Sí. PostgreSQL escucha en todas las interfaces, lo que coincide con
listen_addresses = '*'. Para la práctica solo se necesita localhost
(127.0.0.1 / ::1). Cualquier equipo que alcance la IP de este servidor
puede intentar conectarse al puerto 5434; solo lo limitarían el firewall
de Windows y pg_hba.conf.
```

## Actividad 14 — Diseñar una política de firewall
```
Red DBA 10.10.10.0/24 ──────► Firewall ──► PostgreSQL 10.10.10.20:5432   ✔ Permitido

Cualquier otro origen ──────► Firewall ──► PostgreSQL 10.10.10.20:5432   ✘ Denegado
```

### ¿Por qué pg_hba.conf y el firewall no son controles equivalentes?
Porque actúan en capas distintas y deciden con información diferente.

El firewall trabaja en la red. Solo ve IP de origen, IP de destino y puerto. Decide si un paquete llega o no al puerto de PostgreSQL, pero no sabe nada de bases de datos, usuarios ni contraseñas. Si deja pasar a un equipo, ese equipo puede intentar conectarse con cualquier usuario.

pg_hba.conf trabaja dentro del servidor. Se evalúa cuando la conexión ya llegó a PostgreSQL y decide con base de datos, usuario, origen, uso de SSL y método de autenticación.

## Actividad 15 — Revisar TLS

```
¿La conexión actual utiliza TLS?
No (ssl = false)..

Versión:
No hay tls activado pero tiene una version que dice TLSv1.2.

Cipher:
Ninguno (NULL), porque la conexión viaja sin cifrar.
```
## Actividad 16 — Comparar configuración antes y después


| Control | Antes | Después | Justificación |
|---|---|---|---|
| `listen_addresses` | `*` (todas las interfaces, IPv4 e IPv6) | `localhost` o solo la IP privada necesaria (por ejemplo `10.10.10.20`) | Reduce la superficie de ataque: el servidor solo acepta conexiones por la interfaz que realmente se usa. |
| `pg_hba.conf` | Regla conceptual abierta: `host all all 0.0.0.0/0 scram-sha-256` | `hostssl db_17322758_bryan_gonzalez u_17322758_bryan_gonzalez 10.10.10.0/24 scram-sha-256` | Restringe base de datos, usuario, origen y exige TLS, en lugar de permitir cualquier combinación desde cualquier IP. |
| Método de autenticación | `password_encryption = scram-sha-256` | `scram-sha-256` (se mantiene); sin reglas `trust` ni `md5` | Es el mecanismo recomendado: almacena un verificador con sal e iteraciones y evita enviar la contraseña en claro. |
| Usuarios administrativos | `postgres` es el único `SUPERUSER`, con `LOGIN`, `CREATEROLE` y `CREATEDB` | `postgres` solo desde `localhost`; cuenta `dba_admin` sin `SUPERUSER` para el trabajo diario | Un superusuario ignora todos los permisos; se reserva para casos excepcionales y se limita su origen. |
| Cuentas de aplicación | Sin cuenta de aplicación dedicada; roles `analista` y `soporte` como `NOLOGIN` | `app_clientes` con `LOGIN`, sin privilegios administrativos y con `SELECT`, `INSERT` y `UPDATE` solo sobre lo necesario; `consulta_ro` de solo lectura | Mínimo privilegio: si la aplicación se compromete, el daño queda limitado. |
| Puerto | `5434` (no estándar) | `5434` (se mantiene) o el definido por el entorno; acceso limitado por firewall | Cambiar el puerto solo reduce escaneos automáticos; el control real es el firewall y `pg_hba.conf`. |
| TLS | `ssl = off`; la conexión usa `ssl = false` | `ssl = on`, `ssl_min_protocol_version = TLSv1.2` (o superior) y clientes con `sslmode=verify-full` | Protege consultas, resultados y credenciales en tránsito y permite verificar la identidad del servidor. |
| Permisos SO | Por verificar con `icacls` (o `ls -l` en Linux) sobre el directorio de datos, `postgresql.conf` y `pg_hba.conf` | Solo la cuenta del servicio, `Administrators` y `SYSTEM` (en Linux, `700` en `data` y `600` en los archivos) | Quien lea los archivos se salta `GRANT` y `REVOKE`; los permisos del sistema operativo protegen la capa inferior. |
| Extensiones | `pgcrypto` 1.4 y `plpgsql` 1.0 | `plpgsql`; `pgcrypto` solo si se sigue usando, o `DROP EXTENSION pgcrypto;` si no | Cada extensión añade funcionalidad y superficie de ataque; se mantiene solo lo justificado. |
| Conexiones | Valores por defecto sin verificar (por ejemplo `statement_timeout = 0` e `idle_in_transaction_session_timeout = 0`) | `statement_timeout` y `idle_in_transaction_session_timeout` con valores definidos (por ejemplo `30s` y `60s`), y `max_connections` ajustado a la carga | Protege la disponibilidad frente a consultas colgadas, sesiones abiertas y agotamiento de conexiones. |

## Actividad 17 — Elaborar checklist de hardening


| # | Control | Verificado | Evidencia |
|---|---|---|---|
| 1 | Puerto documentado | Sí | `SHOW port;` → `5434` |
| 2 | Interfaces de escucha justificadas | No | `SHOW listen_addresses;` → `*`; pendiente limitar a `localhost` o IP privada |
| 3 | `pg_hba.conf` revisado | Pendiente | Ruta con `SHOW hba_file;` y revisión de reglas |
| 4 | Redes autorizadas restringidas | No | Regla abierta `0.0.0.0/0`; diseño propuesto `10.10.10.0/24` |
| 5 | Autenticación segura | Sí | `SHOW password_encryption;` → `scram-sha-256` |
| 6 | Superusuarios identificados | Sí | Consulta a `pg_roles`: solo `postgres` con `rolsuper = true` |
| 7 | Cuentas de aplicación separadas | No | Diseño `app_clientes` y `consulta_ro`; pendiente crearlas |
| 8 | Privilegios mínimos | Parcial | `analista` y `soporte` como `NOLOGIN` con acceso solo a vistas; `REVOKE` sobre `clientes` |
| 9 | Extensiones revisadas | Sí | `pg_extension`: `pgcrypto` 1.4 y `plpgsql` 1.0 |
| 10 | TLS verificado | Sí (resultado negativo) | `SHOW ssl;` → `off`; `pg_stat_ssl` → `ssl = false` |
| 11 | Configuración protegida | Pendiente | `icacls` sobre `postgresql.conf` y `pg_hba.conf` |
| 12 | Directorio de datos protegido | Pendiente | `icacls` sobre `data_directory` |
| 13 | Firewall documentado | Sí (conceptual) | Regla permitir `10.10.10.0/24` y denegar el resto; firewall institucional sin modificar |
| 14 | Actualizaciones documentadas | Sí | `SELECT version();` → PostgreSQL 18.6 sobre Windows x64 |
| 15 | Configuración registrada | Sí | Rutas con `SHOW config_file;`, `hba_file` e `ident_file` |

## Actividad 18 — Caso integral

| # | Problema | Riesgo | Control propuesto |
|---|---|---|---|
| 1 | PostgreSQL acepta conexiones desde cualquier dirección IPv4 | Cualquier equipo de Internet puede intentar conectarse; se amplía la superficie de ataque | Limitar el acceso a redes autorizadas (por ejemplo `10.10.10.0/24`) |
| 2 | El servidor escucha en todas las interfaces (`listen_addresses = '*'`) | Se expone el servicio por interfaces que no necesitan acceso a la base | `listen_addresses = 'localhost'` o solo la IP privada necesaria |
| 3 | El firewall permite el puerto 5432 desde cualquier origen | El puerto es visible y escaneable desde Internet; sin barrera de red previa a PostgreSQL | Regla de firewall: permitir solo la red DBA o del servidor de aplicación y denegar el resto (*default deny*) |
| 4 | `pg_hba.conf` permite `all/all` desde `0.0.0.0/0` | Cualquier usuario puede intentar entrar a cualquier base desde cualquier lugar; la contraseña es la única barrera | Regla específica por base, usuario, origen y método: `hostssl app_db app_user 10.10.10.0/24 scram-sha-256` |
| 5 | La aplicación web se conecta con un usuario administrativo | Una inyección SQL da control total: leer, modificar o borrar todo y crear roles | Cuenta de aplicación con mínimo privilegio (`SELECT`, `INSERT`, `UPDATE` solo sobre lo necesario), sin `SUPERUSER`, `CREATEROLE` ni `CREATEDB` |
| 6 | Posible uso de `SUPERUSER` en la aplicación | Acceso al sistema operativo (lectura y escritura de archivos, ejecución de programas) y anulación de todos los permisos | Reservar `SUPERUSER` a `postgres`, con acceso solo desde `localhost` |
| 7 | Cuentas privilegiadas (como `postgres`) alcanzables remotamente | Ataques de fuerza bruta y relleno de credenciales dirigidos al usuario más valioso | Regla aparte para administradores solo desde `localhost` o la red de administración |
| 8 | Se confía únicamente en contraseñas fuertes | Una contraseña no protege contra phishing, malware, filtraciones, inyección SQL ni uso indebido interno; el daño depende de los privilegios | Defensa en profundidad: red restringida, `pg_hba.conf`, mínimo privilegio, TLS y auditoría |
| 9 | No se menciona TLS (y es probable que no esté activo) | Consultas, resultados y credenciales viajan en texto legible; posible intercepción o ataque de intermediario | `ssl = on`, `hostssl` en `pg_hba.conf` y clientes con `sslmode=verify-full` |
| 10 | Credenciales administrativas en la cadena de conexión de la aplicación | Si se filtran por código, repositorio o logs, el atacante obtiene control total de la base | Guardar secretos en un gestor, con rotación, y usar una cuenta de aplicación de bajo privilegio |
| 11 | Sin límites de conexión ni de tiempo mencionados | Denegación de servicio por agotamiento de conexiones o consultas colgadas | `statement_timeout`, `idle_in_transaction_session_timeout`, `max_connections` ajustado y pool de conexiones |
| 12 | Sin evidencia de auditoría ni registro de conexiones | No se detectan ataques ni accesos indebidos, y no se puede investigar un incidente | `log_connections` y `log_disconnections` activos, registro de accesos y revisión periódica |
| 13 | Un solo control (la contraseña) sostiene toda la seguridad | Si falla, no hay otra capa que limite el daño; incumple la defensa en profundidad | Combinar firewall, `listen_addresses`, `pg_hba.conf`, roles, TLS, permisos del sistema operativo y monitoreo |

### ¿Es suficiente tener contraseñas fuertes?

**No.** Una contraseña fuerte es solo una parte de la autenticación, y la autenticación es solo una de seis capas. Si las demás fallan, una contraseña fuerte no evita el daño.

### Autenticación
La contraseña fuerte dificulta adivinar el acceso, pero no protege contra phishing, malware, filtraciones o credenciales expuestas en código. Se complementa con `scram-sha-256`, rotación y, si es posible, doble factor o certificados.

### Autorización
Define qué puede hacer una cuenta una vez dentro. Si el usuario tiene privilegios administrativos, quien obtenga esa contraseña (o explote una inyección SQL en la aplicación) controla toda la base. Se necesita mínimo privilegio con roles, `GRANT` y `REVOKE`.

### Red
Si el servidor escucha en todas las interfaces y el firewall permite cualquier origen, cualquiera puede intentar conectarse, hacer ataques de fuerza bruta o explotar vulnerabilidades antes de autenticarse. Se necesitan firewall restrictivo, redes privadas y TLS para proteger el tráfico.

### Configuración
`listen_addresses = '*'` y `pg_hba.conf` con `all/all` desde `0.0.0.0/0` dejan la contraseña como única barrera. Se necesitan reglas por base, usuario, origen y método (`hostssl`), además de `ssl = on` y límites de tiempo y conexiones.

### Sistema operativo
Quien lea el directorio de datos, los respaldos o `pg_hba.conf` se salta la contraseña y los permisos de PostgreSQL. Se necesitan permisos restrictivos en archivos, cifrado de disco y de respaldos, y protección de los logs.

### Monitoreo
Sin registro de conexiones y auditoría, un acceso indebido pasa desapercibido, y no se puede investigar un incidente. Se necesitan `log_connections`, `log_disconnections`, auditoría de accesos y revisión periódica.

## Actividad 19 — Construcción de una línea base




| ID | Área | Elemento | Baseline |
|---|---|---|---|
| 1.1 | Red | Interfaces | `listen_addresses = '10.10.10.20'` (solo interfaz privada) más `localhost` para administración local. Nunca `*` ni interfaces públicas. |
| 1.2 | Red | Puerto | `5432` (o el definido por el entorno), documentado. Cambiarlo no se considera un control de seguridad. |
| 1.3 | Red | Firewall | *Default deny*. Permitir `5432/TCP` solo desde redes autorizadas. Lo administra el área de redes y el DBA solicita los cambios. |
| 1.4 | Red | Redes permitidas | Red DBA `10.10.10.0/24` y servidor de aplicación (p. ej. `10.10.20.15/32`). Ninguna otra. |
| 1.5 | Red | Exposición | No alcanzable desde Internet. Administración remota solo por VPN o red de gestión. |
| 2.1 | Autenticación | Método | `scram-sha-256` en `pg_hba.conf` y `password_encryption = scram-sha-256`. Prohibido `trust`, `password` y `md5`. |
| 2.2 | Autenticación | Reglas `pg_hba.conf` | Una regla por base, usuario y origen, con `hostssl` para exigir TLS. Sin reglas `all/all` ni `0.0.0.0/0`. |
| 2.3 | Autenticación | Credenciales | Contraseñas largas y únicas por cuenta, sin reutilización entre entornos. Rotación periódica y ante sospecha de compromiso. Almacenamiento en gestor de secretos, nunca en código ni repositorios. Valorar certificados de cliente o directorio para cuentas humanas. |
| 2.4 | Autenticación | Cuentas administrativas | `postgres` (superusuario) solo por `localhost`, para uso excepcional. Cuentas DBA nominales (`dba_nombre`) sin `SUPERUSER`, con trazabilidad individual. Sin cuentas compartidas. |
| 3.1 | Autorización | Roles | Roles de grupo `NOLOGIN` por función (`soporte`, `analista`, `marketing`) y cuentas `LOGIN` que son miembros de ellos. |
| 3.2 | Autorización | Privilegios | Mínimo privilegio: `REVOKE ALL` a `PUBLIC` sobre esquemas y tablas sensibles, y `GRANT` explícito solo de lo necesario. Acceso mediante vistas por finalidad (enmascarada para soporte, agregada para analítica). Separación de funciones: el analista no accede al mapa de seudonimización. |
| 3.3 | Autorización | Cuenta de aplicación | `app_user` con `LOGIN`, sin `SUPERUSER`, `CREATEROLE` ni `CREATEDB`. Tiene `SELECT`, `INSERT` y `UPDATE` (y `DELETE` solo si es necesario) sobre los objetos que usa. No es dueña de objetos ni ejecuta cambios de esquema. |
| 3.4 | Autorización | Cuenta de consulta | `consulta_ro` con `SELECT` solo sobre vistas autorizadas. |
| 3.5 | Autorización | Roles predefinidos | No asignar `pg_read_all_data`, `pg_write_all_data`, `pg_read_server_files`, `pg_write_server_files` ni `pg_execute_server_program` a cuentas de aplicación. |
| 3.6 | Autorización | Revisión | Inventario trimestral de roles y membresías con `pg_roles` y `pg_auth_members`. |
| 4.1 | Configuración | Parámetros relevantes | `ssl = on`, `ssl_min_protocol_version = 'TLSv1.2'` (preferible `TLSv1.3`), `password_encryption = 'scram-sha-256'`, `log_connections = on`, `log_disconnections = on`, `log_line_prefix` con usuario, base, origen y hora, `log_statement = 'ddl'` (o `'mod'` si se justifica) y `log_min_duration_statement` para consultas lentas. |
| 4.2 | Configuración | Límites de sesión | `statement_timeout` (p. ej. `30s`) e `idle_in_transaction_session_timeout` (p. ej. `60s`), preferentemente por rol con `ALTER ROLE ... SET`. |
| 4.3 | Configuración | Conexiones | `max_connections` ajustado a la carga real, `superuser_reserved_connections` mantenido y pool de conexiones para la aplicación. |
| 4.4 | Configuración | Extensiones | Solo las justificadas (`plpgsql` y, si se usa, `pgcrypto`). Prohibidas en producción `dblink`, `postgres_fdw` y `file_fdw` salvo necesidad documentada. Inventario con `pg_extension`. |
| 4.5 | Configuración | Parámetros sensibles | Los que solo cambia un superusuario (`ALTER SYSTEM`) se controlan por cambio formal. |
| 4.6 | Configuración | Datos de prueba | Desarrollo usa datos sintéticos o anonimizados, nunca copias de producción. |
| 5.1 | Sistema operativo | Propietario | Usuario `postgres` (cuenta de servicio sin shell interactiva) como propietario y grupo de `PGDATA`, `postgresql.conf`, `pg_hba.conf` y `pg_ident.conf`. |
| 5.2 | Sistema operativo | Permisos | Directorio de datos `700` (o `750` si el respaldo es por grupo) y archivos de configuración `600` (o `640`). Sin acceso para "otros". En Windows, solo la cuenta del servicio, `Administrators` y `SYSTEM`. |
| 5.3 | Sistema operativo | Directorio de datos | Cifrado de disco o volumen. Sin copias fuera de los procesos de respaldo. Acceso al servidor solo para personal autorizado. |
| 5.4 | Sistema operativo | Logs | Directorio fuera de `PGDATA` si es posible, con permisos restringidos, rotación y envío a un repositorio central de solo lectura. |
| 5.5 | Sistema operativo | Servidor | SO actualizado, servicios innecesarios deshabilitados y SSH o escritorio remoto limitados al personal autorizado. |
| 6.1 | Cifrado | TLS | `ssl = on` con certificado de una CA de confianza. Llave privada `600` y propiedad de `postgres`. Clientes con `sslmode=verify-full`. Reglas `hostssl`. Verificación con `pg_stat_ssl`. |
| 6.2 | Cifrado | Protección de credenciales | Contraseñas de roles con SCRAM. Contraseñas de usuarios de la aplicación con hash y sal (`crypt()` con `gen_salt('bf')` o, mejor, en la aplicación con bcrypt o Argon2). Nunca en texto claro ni con cifrado reversible. |
| 6.3 | Cifrado | Información sensible | RFC y datos financieros cifrados por columna (`pgp_sym_encrypt()` o en la aplicación). Enmascaramiento para soporte, seudonimización para analítica y anonimización para estadísticas publicadas. |
| 6.4 | Cifrado | Gestión de claves | Claves en gestor de secretos o KMS, fuera de scripts y repositorios. Acceso restringido, rotación periódica y procedimiento de revocación ante exposición. |
| 6.5 | Cifrado | Respaldos | Cifrados (p. ej. GPG), con acceso restringido, almacenados fuera del servidor y con restauración probada periódicamente. |
| 7.1 | Mantenimiento | Actualización | Última versión menor de PostgreSQL 16, con ventana de mantenimiento y prueba previa en entorno no productivo. Seguimiento de avisos de seguridad de PostgreSQL y extensiones. |
| 7.2 | Mantenimiento | Revisión periódica | Revisión trimestral del checklist (roles, `pg_hba.conf`, extensiones, permisos, TLS, límites y logs), de accesos y de logs de conexión. Prueba de restauración de respaldos al menos semestral. |
| 7.3 | Mantenimiento | Retención y datos | Política de retención aprobada, con identificación periódica de registros vencidos y eliminación controlada, con respaldo previo y evidencia. |
| 7.4 | Mantenimiento | Documentación | Registro de configuración vigente (rutas, parámetros, reglas `pg_hba.conf`), control de cambios con aprobación y fecha, inventario de cuentas y responsables.