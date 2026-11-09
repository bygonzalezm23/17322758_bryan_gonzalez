# Informe LAB-01: Bitácoras y auditoría en PostgreSQL

##  Despliegue y situación inicial
**Despliegue:** PostgreSQL 18 local (puerto 5434) con las bases `bitacora` y `comercial`, y un contenedor Docker con pgaudit para las lecturas. `[Ajusta si desplegaste el servidor de la Actividad 1 de otra forma.]`

**Configuración por defecto:**
- `log_connections = off` y `log_disconnections = off`.
- `log_statement = none`.
- `log_line_prefix = '%m [%p]'`, sin usuario, base, aplicación ni IP.
- `logging_collector = off`; la salida iba a `stderr` y dependía de cómo se lanzó el servidor.
- Zona horaria UTC, difícil de cruzar con fuentes en hora local.

**Por qué no permitía responder a Dirección:** tras un `UPDATE` del RFC, la bitácora no tenía conexión, sentencia, usuario ni origen. No se podía demostrar quién lo cambió ni descartar a `soporte_ana`. Los privilegios previenen, pero no registran qué se hizo.

##  Configuración aplicada

| Parámetro | Valor | Aplicación | Justificación |
|---|---|---|---|
| `logging_collector` | `on` | **Reinicio** | El colector es un proceso que solo arranca con el servidor. |
| `log_connections` / `log_disconnections` | `on` | Recarga | Saber quién entra, desde dónde y cuánto dura. |
| `log_statement` | `ddl`, luego `mod` | Recarga | `ddl` registra privilegios y estructura; `mod` añade `INSERT`, `UPDATE` y `DELETE`. |
| `log_line_prefix` | `'%m [%p] user=%u db=%d app=%a client=%h '` | Recarga | Cada línea identifica usuario, base, aplicación e IP. |
| `shared_preload_libraries` | `pgaudit` (contenedor) | **Reinicio** | La extensión debe cargarse al arrancar. |
| `pgaudit.role` | `auditor_lecturas` | Recarga | Auditoría de objeto para lecturas de RFC y teléfono. |

La bitácora se lee con SQL desde `dba.bitacora`, con acceso restringido (`REVOKE ALL ... FROM PUBLIC`).

##  Eventos observados

| Tipo | Ejemplo | Interpretación |
|---|---|---|
| Configuración | `parameter "log_statement" changed to "ddl"`, sin `user=` ni `app=` | Lo aplica el proceso principal al recargar, no una sesión. |
| Acceso | `FATAL: password authentication failed` de `app_ventas` desde 127.0.0.1, con `app=[unknown]` | Solo prueba que alguien usó ese nombre; `user=` no es una identidad verificada. |
| Privilegio | `GRANT UPDATE ON clientes TO app_ventas` | `GRANT` y `REVOKE` son DDL: cambian la autorización, no los datos. |
| Estructura | `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)` | Cambia el esquema; también queda `CREATE TRIGGER` (21:49:16). |
| Datos | `UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3` | Muestra el valor nuevo, pero no el anterior. |
| Error | `DELETE` de `soporte_ana` rechazado por falta de permiso | No causó daño, pero revela una intención que hay que investigar. |

##  Auditoría del dato
**Tabla `auditoria.cambios_clientes`** (esquema sin acceso público): `id_evento`, `momento` (TIMESTAMPTZ), `usuario_sesion`, `usuario_efectivo`, `aplicacion`, `ip_cliente`, `operacion`, `id_cliente`, `valores_antes` y `valores_despues` (JSONB). Los únicos nulos permitidos son los que tienen razón técnica (por ejemplo, no hay IP en conexiones locales).

**Papel de `SECURITY DEFINER` y `session_user`:**
- El disparador se ejecuta con los privilegios del dueño, así `app_ventas` registra eventos sin tener acceso al esquema ni poder falsificar la bitácora.
- Dentro de la función, `current_user` es `postgres`; por eso `usuario_efectivo = postgres`.
- `session_user` conserva quién se conectó realmente (`app_ventas`), que es el dato útil para atribuir.

**Incidente auditado:** `app_ventas`, aplicación `app-ventas-web`, IP 127.0.0.1, cambió el RFC del cliente 3 de `GAMA780912XYZ` a `GAMA780912ZZZ` (evento 1). Con `valores_antes` se restaura con certeza:
```sql
UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;
```
La restauración también queda auditada.

##  Limitaciones
- **Lecturas:** el `SELECT` de RFC y teléfono por `soporte_ana` no dejó rastro (no hay disparador para `SELECT`). `pgaudit` con auditoría de objeto lo resuelve y registra solo las columnas sensibles. No se pudo instalar en Windows, por lo que se usó un contenedor Docker con PostgreSQL 18.
- **Volumen:** un `UPDATE` sin `WHERE` genera un evento por fila (cinco en la práctica; un millón en una tabla grande) con la fila completa dos veces, mientras que la bitácora del servidor guarda una sola línea.
- **Administrador con control total:** `postgres` ejecutó `DISABLE TRIGGER`, cambió el RFC a `GAMA780912GHI` y lo volvió a activar sin dejar evento en la auditoría. Solo `dba.bitacora` lo delata. `app_ventas` no pudo hacerlo (`must be owner of table clientes`).

##  Riesgos de la bitácora
- **Secretos expuestos:** la bitácora contiene contraseñas y datos personales en texto claro (`Temporal_Practica_2026`, RFC). Se exportó con `replace(..., '<REDACTED>')` y toda contraseña que aparezca debe rotarse.
- **Pérdida:** si el servidor se reinstala, se recrea o rota sus archivos, la evidencia desaparece. Hay que exportarla y calcular su SHA-256, guardado fuera del servidor.
- **Acceso de terceros:** la bitácora y la auditoría deben ser accesibles solo para el DBA o un rol de auditoría (mínimo privilegio), con registro de quién las consulta. `log_statement = 'all'` las convertiría en otro depósito de datos sensibles.
- **Retención:** la auditoría conserva datos personales de clientes ya eliminados (Pedro Ruiz), lo que choca con la política de retención y debe resolverlo Dirección con legal y protección de datos.

##  Cronología y conclusión

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió |
|---|---|---|---|---|---|
| 1 | 2026-11-08 19:40:00 (estimada) | postgres | — | Configuración | Se activó `log_statement = 'ddl'` y se recargó la configuración para registrar las sentencias de definición. |
| 2 | 2026-11-08 21:39:25 | soporte_ana | — | Acceso | Conexión de la aplicación `reporte-mensual` desde 127.0.0.1. |
| 3 | 2026-11-08 21:49:10 (estimada) | postgres | — | Privilegio | `REVOKE ALL ON FUNCTION auditoria.registrar_cambio_cliente() FROM PUBLIC`, ejecutado antes de crear el disparador. |
| 4 | 2026-11-08 21:49:16 | postgres | — | Estructura | `CREATE TRIGGER trg_auditoria_clientes` sobre `clientes`. |
| 5 | 2026-11-08 21:55:25 | app_ventas | 3 | Datos | `UPDATE` del RFC de `GAMA780912XYZ` a `GAMA780912ZZZ`. Quedó en la auditoría (evento 1). |
| 6 | 2026-11-08 22:00:00 (estimada) | postgres | 6 | Datos | `INSERT` y `DELETE` del cliente Pedro Ruiz; quedan en la auditoría con la fila completa. |
| 7 | 2026-11-08 22:03:00 (estimada) | app_ventas | — | Error | `permission denied for schema auditoria` al leer la auditoría, y `must be owner of table clientes` al intentar desactivar el disparador. |
| 8 | 2026-11-08 22:05:00 (estimada) | postgres | 3 | Datos | `DISABLE TRIGGER`, `UPDATE` del RFC a `GAMA780912GHI` y `ENABLE TRIGGER`. **No dejó evento en la auditoría**; solo lo revela la bitácora. |
| 9 | 2026-11-08 22:13:15 | postgres | 5 clientes | Datos | `UPDATE` masivo de `segmento` a `regular`: una línea en la bitácora y cinco eventos en la auditoría (ids 6 a 10). |
| 10 | 2026-11-08 22:20:08 | postgres | — | Error | `ERROR: secuencia de bytes no válida para codificación «UTF8»` al exportar el log con `pg_read_file`. |

**Conclusión:** con esta configuración **sí** puede demostrarse quién cambió un dato sensible y qué valor tenía antes, **siempre que el disparador esté activo**: `usuario_sesion`, `ip_cliente` y `valores_antes` responden ambas preguntas (evento 1). **No** puede demostrarse en estos casos:
- Cuando un administrador desactiva el disparador (solo queda la sentencia en la bitácora, sin valor anterior).
- Para las lecturas, si no se usa pgaudit.
- Si la bitácora se pierde o se altera por no estar custodiada fuera del servidor.

## Preguntas de Reflexión

### ¿Por qué la auditoría no puede configurarse después de un incidente para investigarlo?
Porque la bitácora solo registra lo que ocurre **desde que se configura**; no es retroactiva. En la Actividad 3 el `UPDATE` del RFC se ejecutó con `log_statement = none` y `log_connections = off`, y no quedó autor, hora ni origen. Configurar el registro después ayuda a lo futuro, pero el incidente ya pasó sin evidencia. Por eso hay que configurar antes, no después.

### ¿Por qué conviene que la bitácora la administre el propio servidor y no el mecanismo de despliegue?
Con `logging_collector = off`, PostgreSQL solo escribe a `stderr` y el servicio, contenedor o sistema operativo decide a dónde va (consola, archivo o nada). Con el colector, el servidor controla archivo, nombre, rotación y retención de forma consistente y no depende de cómo se lanzó. Además puede leerse con SQL (`dba.bitacora`) sin acceso al sistema operativo. El riesgo es que quien controla el servidor también controla la bitácora, por lo que conviene exportarla a un sitio externo.

### ¿Por qué el prefijo de línea es tan importante como el nivel de log_statement?
`log_statement` define **qué** se registra; el prefijo define **quién, desde dónde y cuándo**. Con el prefijo por defecto (`%m [%p]`) solo hay hora y PID: una sentencia registrada no se puede atribuir a nadie. Con `'%m [%p] user=%u db=%d app=%a client=%h '`, cada línea indica usuario, base, aplicación e IP, y el PID permite unir las líneas de una misma sesión. Sin ese contexto, la bitácora cuenta qué pasó pero no quién lo hizo.

### ¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?
- **Sentencia (bitácora del servidor):** guarda el texto, por ejemplo `UPDATE ... rfc = 'GAMA780912GHI'`. Dice qué se intentó, pero no el valor anterior, ni las filas afectadas, ni si se confirmó.
- **Cambio en el dato (auditoría por disparador):** guarda `valores_antes` y `valores_despues` de cada fila, así que permite saber qué cambió y revertirlo con certeza.
### ¿Qué evidencia ofrece pg_stat_activity que no ofrece la bitácora, y viceversa?
- **`pg_stat_activity`:** muestra las sesiones **actuales** (usuario, aplicación, IP, consulta en curso, estado), por ejemplo `soporte_ana` con `reporte-mensual` en ese momento. Sirve para ver qué ocurre ahora y puede cancelarse una sesión.
- **Bitácora:** conserva el **historial**: conexiones y desconexiones pasadas, errores, sentencias y fallos de autenticación. Una sesión que ya terminó desaparece de `pg_stat_activity` pero sigue en la bitácora. Se relacionan por el `pid`.
### Si el administrador puede cambiar log_statement a none y desactivar el disparador, ¿quién audita al administrador?
Nadie dentro del propio servidor: ningún mecanismo interno protege contra un administrador con control total. Lo audita **otra parte distinta de él**:
- Bitácoras enviadas en tiempo casi real a un sistema externo, administrado por otra área (seguridad o auditoría interna), de solo lectura para el DBA.
- Revisión periódica de esas bitácoras por alguien distinto al DBA.
- Procedimiento de control de cambios: todo `DISABLE TRIGGER` o `ALTER SYSTEM` requiere autorización previa.
- Menos cuentas con superusuario, nominales y no compartidas.
- Hashes de la evidencia guardados fuera del servidor.