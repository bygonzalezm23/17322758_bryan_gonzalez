# Actividad 3 — Activar el perfilador y registrar operaciones

## Preguntas

### ¿Puedes saber cuál era el RFC antes del cambio con la información de system.profile?
No. El documento del `update` solo muestra el filtro (`q: { _id: 3 }`) y la operación aplicada (`u: { $set: { rfc: 'GAMA780912XYZ' } }`), es decir, el **valor nuevo**. No guarda el valor que tenía antes. Para eso se necesitaría un mecanismo adicional (change streams, un trigger de aplicación, o Change Data Capture) que capture el estado previo.

### 2. ¿Puedes saber qué datos tenía el documento eliminado?
No. El `remove` solo registra el filtro usado para encontrarlo (`q: { _id: 2 }`) y cuántos se eliminaron (`ndeleted: 1`), pero no el contenido del documento borrado. Una vez eliminado, su contenido no queda en ningún lado salvo que exista un respaldo previo.

### ¿Puedes saber qué datos tenía el documento eliminado?
**Ventaja:** se obtiene trazabilidad completa: quién, qué operación, sobre qué datos, desde dónde y cuándo, algo que `log_statement = 'mod'` en PostgreSQL no da para lecturas (`query`), solo para escrituras.

**Riesgo:** al registrar también las lecturas (`query`), el perfilador puede capturar **datos sensibles** dentro de los filtros y proyecciones (por ejemplo, un RFC o un correo usado como criterio de búsqueda), multiplicando la exposición de información personal dentro de la bitácora. Además, el volumen de registros crece mucho más rápido, con el consiguiente impacto en almacenamiento y rendimiento si el tráfico es alto.
### A diferencia de log_statement = 'mod' en PostgreSQL, el nivel 2 sí registró la consulta. ¿Qué ventaja y qué riesgo tiene eso?

### ¿Por qué el campo user incluye @comercial?
Porque en MongoDB la identidad de un usuario no es solo su nombre, sino el par **usuario + base de datos de autenticación** (`user@authenticationDatabase`). Un mismo nombre de usuario podría existir en distintas bases con distintos roles, así que `app_ventas@comercial` indica que ese usuario fue autenticado específicamente contra la base `comercial`, y no contra `admin` u otra.



## Tabla

| # | op | Usuario | Cliente | Aplicación | Momento |
|---|---|---|---|---|---|
| 1 | query | app_ventas@comercial | 127.0.0.1 | app-ventas-web | 2026-10-25T22:52:45.906Z |
| 2 | update | app_ventas@comercial | 127.0.0.1 | app-ventas-web | 2026-10-25T22:52:45.909Z |
| 3 | remove | app_ventas@comercial | 127.0.0.1 | app-ventas-web | 2026-10-25T22:52:45.915Z |
