## Línea base de hardening de PostgreSQL



- **`listen_addresses`:** `*` (todas las interfaces, IPv4 e IPv6).
- **`pg_hba.conf`:** `host all all 0.0.0.0/0 scram-sha-256`.
- **Método de autenticación:** `password_encryption = scram-sha-256`.
- **Usuarios administrativos:** `postgres` es el único `SUPERUSER`, con `LOGIN`, `CREATEROLE` y `CREATEDB`.
- **Cuentas de aplicación:** sin cuenta de aplicación dedicada; roles `analista` y `soporte` como `NOLOGIN`.
- **Puerto:** `5434`.
- **TLS:** `ssl = off`; la conexión usa `ssl = false`.
- **Permisos SO:** por verificar con `icacls` sobre el directorio de datos, `postgresql.conf` y `pg_hba.conf`.
- **Extensiones:** `pgcrypto` 1.4 y `plpgsql` 1.0.
- **Conexiones:** valores por defecto sin verificar (`statement_timeout = 0` e `idle_in_transaction_session_timeout = 0`).

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