# Actividad 3 — Diccionario de datos operativo dentro del motor

## Preguntas

### ¿Qué ventaja tiene guardar el significado en COMMENT en lugar de solo en un documento aparte?
El significado viaja con el dato. El comentario vive en el catálogo del motor, así que se consulta con `\d+`, `col_description()` o `information_schema` desde la misma base, y se respalda, restaura y migra junto con ella. Un documento aparte se desactualiza, se pierde o se separa de la tabla. Además, el diccionario se puede generar automáticamente (como el CSV que exportaste), por lo que siempre refleja el estado real de la tabla y no una copia manual.

### ¿Quedaron registrados los COMMENT en la bitácora? ¿Con qué nivel de log_statement?
Sí, siempre que `log_statement` estuviera en `ddl`, `mod` o `all`. `COMMENT ON` es una sentencia DDL, por lo que `ddl` ya la registra (y `mod` también, porque incluye todo `ddl`). Con `none` no queda rastro. Se puede comprobar con:

SELECT linea FROM dba.bitacora WHERE linea ILIKE '%COMMENT ON%' ORDER BY num;

Si no aparecen, revisa que `log_statement` estuviera activado antes de ejecutar los comentarios (la auditoría no se puede configurar "después" de los hechos).


### ¿Qué información del diccionario debe mantenerse fuera del motor? ¿Por qué?
- **Información sensible o de seguridad:** contraseñas, credenciales, llaves de cifrado y detalles de la configuración de protección. Los comentarios son legibles para cualquier rol con acceso al catálogo y quedan en la bitácora y en los respaldos en texto claro.
- **Decisiones y políticas de gobierno:** quién aprobó qué, fechas de aprobación, justificación legal de la retención y solicitudes de acceso o corrección. Son evidencia administrativa que debe tener control de versiones y firma, algo que un comentario no ofrece.
- **Contenido extenso o cambiante:** procedimientos, matrices completas y reglas de negocio detalladas. Un comentario debe ser breve; el documento externo es la fuente de la política y el comentario solo la resume.

Además, si el motor se pierde o se compromete, la documentación externa permite reconstruir el significado y verificar que los comentarios no fueron alterados.