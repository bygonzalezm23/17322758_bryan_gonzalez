# Actividad 13 — Altas y bajas

## Preguntas

### El cliente Pedro Ruiz ya no existe en clientes. ¿Dónde queda evidencia de que existió y de sus datos?
En `auditoria.cambios_clientes`. El evento 2 (`INSERT`, `id_cliente` 6) guarda en `valores_despues` la fila completa con que se creó, y el evento 3 (`DELETE`) guarda en `valores_antes` la fila completa tal como estaba al borrarse (nombre, correo, RFC, edad, ciudad y código postal). Además registran quién (`postgres`), cuándo (`momento`) y desde qué programa (`psql`). Con esos datos se podría recuperar al cliente. También queda el texto de las sentencias en `dba.bitacora`, si el log está cargado.

### ¿Por qué ip_cliente está vacía en los eventos 2 y 3?
Porque el administrador se conectó por **socket Unix local** o por una conexión que no es TCP/IP, y en ese caso `inet_client_addr()` devuelve `NULL`. Los eventos de `app_ventas` sí tienen IP porque se conectó por red a `127.0.0.1`. Por eso `ip_cliente` se definió como campo que admite nulos.

### La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?
**Conflicto:** al borrar a Pedro Ruiz de `clientes`, sus datos personales (incluido el RFC) **siguen existiendo** en la auditoría, en `valores_antes` y `valores_despues`. Es una bitácora inmutable que choca con la eliminación de datos y con el derecho del titular a la cancelación. Además, esas copias también están en respaldos y en el log del servidor.

**Quién debe resolverlo:** no es una decisión solo técnica. Corresponde a **Dirección con el responsable de protección de datos y el área legal/cumplimiento**, con apoyo del DBA para implementarlo. Deben definir:
- El plazo de retención de la auditoría y su fundamento (obligación legal, seguridad).
- Qué se hace al vencer: borrado, anonimización o enmascaramiento del RFC y otros datos en el JSON.
- Cómo se atienden solicitudes de cancelación sin destruir la trazabilidad (por ejemplo, conservar el evento pero sin los datos personales).