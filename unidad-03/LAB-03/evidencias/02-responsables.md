# Actividad 2 — Propietarios, custodios y usuarios


## Tabla
| Conjunto de datos | Propietario | Custodio | Usuarios autorizados | Quién aprueba accesos | Quién aprueba correcciones |
|---|---|---|---|---|---|
| `comercial.public.clientes` (PostgreSQL) | Área comercial (responsable de datos de clientes) | DBA | Atención al cliente (vista enmascarada), Facturación (`rfc`), Analítica (vista generalizada), DBA | Propietario del dato (área comercial); el DBA solo implementa | Propietario del dato (área comercial); el DBA ejecuta con solicitud formal |
| `auditoria.cambios_clientes` (PostgreSQL) | Responsable de seguridad / cumplimiento | DBA | Auditor / seguridad (solo lectura). Ningún usuario de la aplicación; el DBA no debe poder modificarla | Responsable de seguridad / cumplimiento | Nadie: es evidencia y no se corrige. Si hay un error, se agrega un registro nuevo y se documenta |
| Bitácora de PostgreSQL | Responsable de seguridad / cumplimiento | DBA | Auditor / seguridad (solo lectura, vía `dba.bitacora`); DBA | Responsable de seguridad / cumplimiento | Nadie: no se edita. Solo se rota y se archiva según la política de retención |
| `comercial.clientes` (MongoDB) | Área comercial (responsable de datos de clientes) | DBA | Atención al cliente, Facturación, Analítica (según el campo), DBA | Propietario del dato (área comercial) | Propietario del dato (área comercial); el DBA ejecuta |
| `comercial.system.profile` (MongoDB) | Responsable de seguridad / TI | DBA | DBA y seguridad (solo lectura). Ningún usuario de la aplicación | Responsable de seguridad / TI | Nadie: es un registro técnico generado por el motor |

## Preguntas

### ¿Por qué el propietario de auditoria.cambios_clientes no debería ser el mismo que opera clientes?
Por separación de funciones. La auditoría existe para vigilar a quien opera los datos. Si el mismo rol o área administra `clientes` y también es dueño de su tabla de auditoría, podría modificar un dato y luego alterar o borrar el rastro, y la evidencia dejaría de ser confiable. El propietario de la auditoría (seguridad o cumplimiento) debe ser independiente del área comercial y del DBA que opera la tabla. Así, nadie revisa su propio trabajo y el registro tiene valor como prueba.

### ¿Quién debería poder leer las bitácoras y la vista dba.bitacora? Relaciónalo con lo observado en el LAB-01 (secretos en la bitácora).
Solo el responsable de seguridad / cumplimiento (auditor) y el DBA, con acceso de solo lectura y aprobado por el propietario de la bitácora. En el LAB-01 se observó que la bitácora puede guardar contraseñas en texto claro (por ejemplo, `CREATE ROLE rol_temporal LOGIN PASSWORD '...'` quedó registrada con `log_statement = 'ddl'`) y que eliminar el rol no borra esa línea. Por eso, quien lea la bitácora podría obtener secretos. Se debe aplicar mínimo privilegio: `REVOKE ALL ON SCHEMA dba FROM PUBLIC`, `GRANT` explícito solo a los roles autorizados, y usar `\password` en lugar de escribir contraseñas en las sentencias. Ningún usuario de aplicación ni de soporte debe poder leerla.

### ¿Qué ocurre con la responsabilidad sobre un dato cuando nadie la tiene  asignada? Relaciónalo con el problema inicial de la unidad.
Se diluye: todos suponen que otro se encarga y nadie decide ni responde. No hay quien apruebe accesos, corrija errores, defina cuánto tiempo conservar el dato ni responda ante un incidente. Esto se relaciona con el problema inicial de la unidad: los datos con errores (RFC incompleto, correo inválido, edad de -3, cliente duplicado) permanecieron en la tabla porque nadie era responsable de su calidad, y el DBA no podía corregirlos por su cuenta sin ser el dueño. Asignar propietario y custodio evita que los datos queden "huérfanos", con accesos de más, errores sin corregir y sin trazabilidad de quién decidió qué.