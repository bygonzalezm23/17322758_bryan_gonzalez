# Actividad 16 — Exportar y conservar la bitácora

## Preguntas
### Un resumen SHA-256, ¿impide que alguien modifique la bitácora? ¿Qué permite demostrar?
No lo impide: el archivo se puede editar igual. Lo que permite es **detectar** la modificación, porque cualquier cambio, aunque sea de un carácter, produce un hash distinto. Si el hash recalculado coincide con el guardado, se demuestra que el archivo es idéntico al que se exportó en ese momento (integridad). No prueba por sí solo que el contenido original fuera verdadero ni quién lo exportó.

### ¿Dónde debería guardarse el hash para que sea útil como control de integridad?
Fuera del alcance de quien puede modificar la bitácora: en un sistema distinto y controlado por otra área (por ejemplo, el repositorio con control de versiones, el informe entregado, un correo a auditoría o un sistema de custodia con acceso de solo lectura). Si el hash está junto al archivo, en el mismo equipo y con los mismos permisos, quien altera el log puede recalcular y reemplazar también el hash.

### La guía NIST SP 800-92 trata la conservación y protección de bitácoras (REF-U3-03). ¿Qué riesgos tiene conservar la bitácora solo en el servidor que la produce?
- **Pérdida:** reinstalación, falla de disco, recreación del servidor o rotación de archivos sin respaldo eliminan la evidencia.
- **Manipulación:** quien controla el servidor puede alterar o borrar el log para ocultar sus acciones (como se vio al desactivar el disparador).
- **Disponibilidad:** si el servidor se compromete o cae, justo cuando se necesita la evidencia no se puede acceder a ella.
- **Saturación:** si el disco se llena, el servidor puede dejar de registrar o dejar de funcionar.
- **Falta de separación de funciones:** el operador y el custodio de la evidencia son la misma persona.
### Propón durante cuánto tiempo conservarías esta bitácora y justifica tu criterio. No existe una cifra única correcta.
Propongo **12 meses** en línea (consultables rápido) y un total de **2 a 3 años** archivadas, con el hash conservado todo ese tiempo. Criterio:
- Cubre un ciclo completo de auditoría anual y deja margen para detectar incidentes que se descubren tarde.
- Debe alinearse con las obligaciones legales y fiscales aplicables (el RFC y los datos fiscales pueden implicar plazos mayores) y con lo que defina el área legal.
- La bitácora contiene datos personales, así que conservarla más de lo necesario contradice el principio de minimización; pasado el plazo se destruye de forma segura o se anonimiza.
- El plazo debe estar documentado en una política aprobada por Dirección, y suspenderse si hay una investigación o proceso legal abierto.

# Actividad 17 — Reconstruir la cronología y responder a Dirección

## Tabla 

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

## Preguntas

 ### ¿Quién cambió el RFC la primera vez (Actividad 3)? ¿Y en las Actividades 7, 12 y 14?
 | Actividad | Quién | Evidencia |
|---|---|---|
| 3 | `app_ventas` (la simulación del incidente) | Ninguna: `log_statement = none` y `log_connections = off`. Es imposible demostrarlo con las bitácoras. |
| 7 | La línea de la bitácora muestra `UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3` | La bitácora indica usuario, aplicación e IP en el encabezado de esa línea. El archivo no los transcribe, así que léelos de `user=` y `client=`. |
| 12 | `app_ventas`, app `app-ventas-web`, IP 127.0.0.1 | Auditoría, evento 1 (`usuario_sesion = app_ventas`). |
| 14 | `postgres`, app `psql`, `[local]` | Solo `dba.bitacora`: `DISABLE TRIGGER`, `UPDATE ... 'GAMA780912GHI'` y `ENABLE TRIGGER`. No hay evento en la auditoría. |

### ¿Quién cambió el teléfono?
No se modifico el telefono

### ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?
**Sí, en la Actividad 5** (autenticación fallida, `FATAL: password authentication failed`):
- `app_ventas`, desde `127.0.0.1`, con contraseña incorrecta.
- `usuario_inexistente`: el cliente solo recibió el mensaje genérico, pero la bitácora guarda `Role "usuario_inexistente" does not exist`. El origen no está en el archivo; sale de `client=` en la línea.

### ¿Qué valor tenía el RFC antes de cada cambio?

| Actividad | Antes | Después |
|---|---|---|
| 3 | No consta en los archivos | No consta |
| 7 | No consta: la bitácora solo guarda el valor nuevo | `GAMA780912GHI` (según la línea) |
| 12 | `GAMA780912XYZ` | `GAMA780912ZZZ` |
| 14 | `GAMA780912ZZZ` (deducido, no registrado) | `GAMA780912GHI` |