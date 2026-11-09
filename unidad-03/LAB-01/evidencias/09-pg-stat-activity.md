# Actividad 9 — Sesiones activas con `pg_stat_activity`

## Preguntas

### ¿Qué columna permite relacionar una sesión con sus líneas de bitácora?
El `pid` (PID del proceso). Cada backend tiene un PID único mientras dura la conexión, y ese mismo número aparece entre corchetes en cada línea que PostgreSQL escribe en la bitácora para esa sesión (gracias a `%p` en `log_line_prefix`).

### Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?
La bitácora. `pg_stat_activity` solo muestra sesiones **en curso**: en cuanto la sesión termina y se desconecta, desaparece de esa vista. La bitácora, en cambio, queda como registro permanente (mientras no se rote o elimine el archivo), con las líneas de conexión, autenticación y desconexión de ese PID.

### ¿Por qué client_addr aparece vacío en la sesión del administrador?
Porque esa sesión (`postgres` ejecutando `psql`) se conectó por un **socket local** (Unix socket o named pipe), no por TCP/IP. Las conexiones locales no tienen una dirección IP de cliente, así que `client_addr` queda `NULL`/vacío. Solo las conexiones por red (TCP), como la de `soporte_ana` desde `127.0.0.1`, muestran una IP en esa columna.