# Actividad 2 — Que el servidor administre su propia bitácora

## Preguntas

### ¿Por qué logging_collector requiere reinicio y log_statement solo recarga?
`logging_collector` arranca un proceso en segundo plano (el colector) y redirige `stderr` hacia él. Eso solo puede hacerse cuando el servidor inicia, por eso se necesita reinicio. `log_statement` es un parámetro que cada proceso consulta al ejecutar sentencias, así que basta con `pg_reload_conf()` para que lo lean de nuevo.


### ¿Qué ventaja tiene que la bitácora se lea con SQL y no con una herramienta del sistema operativo o del contenedor? ¿Qué riesgo introduce?
**Ventaja:** no se necesita acceso al sistema operativo ni al contenedor. El servidor lee su propio archivo, y se puede filtrar, ordenar y citar líneas con SQL (`ILIKE`, expresiones regulares, `num`).

### ¿Quién debería poder consultar dba.bitacora?
Solo el DBA o un rol de auditoría, por mínimo privilegio. Por eso el esquema `dba` tiene `REVOKE ALL ... FROM PUBLIC`. No debe darse acceso a roles de aplicación, soporte ni analítica, ni asignarles `pg_read_server_files`. Conviene también registrar quién consulta la bitácora.