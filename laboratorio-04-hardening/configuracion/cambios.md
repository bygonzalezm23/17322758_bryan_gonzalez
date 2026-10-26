## Cambios

- **`listen_addresses`:** `localhost` o solo la IP privada necesaria (por ejemplo `10.10.10.20`).
- **`pg_hba.conf`:** `hostssl db_17322758_bryan_gonzalez u_17322758_bryan_gonzalez 10.10.10.0/24 scram-sha-256`.
- **Método de autenticación:** `scram-sha-256`, sin reglas `trust` ni `md5`.
- **Usuarios administrativos:** `postgres` solo desde `localhost`; cuenta `dba_admin` sin `SUPERUSER` para el trabajo diario.
- **Cuentas de aplicación:** `app_clientes` con `LOGIN` y `SELECT`, `INSERT`, `UPDATE` solo sobre lo necesario; `consulta_ro` de solo lectura.
- **Puerto:** `5434` o el definido por el entorno, con acceso limitado por firewall.
- **TLS:** `ssl = on`, `ssl_min_protocol_version = TLSv1.2` y clientes con `sslmode=verify-full`.
- **Permisos SO:** solo la cuenta del servicio, `Administrators` y `SYSTEM` (en Linux, `700` en `data` y `600` en los archivos).
- **Extensiones:** `plpgsql`; `pgcrypto` solo si se sigue usando.
- **Conexiones:** `statement_timeout = 30s`, `idle_in_transaction_session_timeout = 60s` y `max_connections` ajustado a la carga.