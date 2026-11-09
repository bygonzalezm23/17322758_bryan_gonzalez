# Actividad 19 — Auditoría de objeto sobre columnas sensibles

## Preguntas

### ¿Por qué no apareció SELECT nombre, ciudad ...? ¿Por qué sí apareció SELECT * ...?
`auditor_datos` solo tiene `SELECT` sobre las columnas `rfc` y `telefono`, y ese privilegio funciona como filtro. `SELECT nombre, ciudad` no toca ninguna de esas columnas, así que no se registra. `SELECT *` lee todas las columnas, incluidas `rfc` y `telefono`, por lo que sí coincide con el filtro y queda en la bitácora. `SELECT nombre, rfc` también apareció por leer `rfc`.

### ¿Por qué no apareció UPDATE ... ciudad ...?
Porque `auditor_datos` tiene `UPDATE` solo sobre `rfc` y `telefono`, y ese `UPDATE` modifica únicamente `ciudad`. Al no afectar una columna vigilada, no se audita. El `UPDATE` del `rfc` sí quedó registrado.

### ¿Qué diferencia de volumen esperarías frente a log_statement = 'all'?
Mucho menor. `log_statement = 'all'` registra toda sentencia de todas las tablas y usuarios, incluidas consultas irrelevantes como `SELECT nombre, ciudad`. La auditoría de objeto registra solo las operaciones sobre las columnas sensibles, así que en una tabla con miles de consultas por minuto genera una fracción de las líneas. Esto reduce el costo de disco y E/S, y también la exposición de datos en el log, aunque las líneas `AUDIT` siguen guardando el texto de la sentencia con sus valores.

### El README oficial advierte que pgaudit no puede auditar de forma confiable a los superusuarios (REF-U3-09). ¿Qué implica para la separación de funciones?
Un superusuario puede desactivar pgaudit, cambiar `pgaudit.role` o `log_statement`, o modificar la configuración, así que la auditoría no se sostiene frente a quien opera la base. Es la misma lección de la Actividad 14: nadie puede auditarse a sí mismo. Implica:
- Quien tenga superusuario no debe ser quien custodie ni revise la bitácora.
- Las bitácoras deben enviarse a un sistema externo, administrado por otra área, y revisarse por alguien distinto al DBA.
- Se debe limitar el número de superusuarios, con cuentas nominales, y exigir autorización previa para cambios de configuración.
- pgaudit controla bien a los usuarios comunes (`app_ventas`, `soporte_ana`), pero el control sobre el administrador es administrativo, no técnico.