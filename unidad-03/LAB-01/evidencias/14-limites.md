# Actividad 15 — Límites: lecturas y volumen

## Preguntas

### Si clientes tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un UPDATE sin WHERE?
- La operación se vuelve mucho más lenta, porque cada fila ejecuta un `INSERT` adicional dentro de la misma transacción.
- La tabla de auditoría crece de golpe (espacio, WAL, respaldos).
- En la bitácora del servidor seguiría apareciendo **una sola línea** (la sentencia), como se vio con las 5 filas.
- La auditoría sirve para reconstruir el daño, pero también se vuelve difícil de consultar y de depurar.
### Propón quién podría autorizar la depuración de auditoria.cambios_clientes.
No debe autorizarla el DBA solo, porque es quien podría querer ocultar sus acciones. Una propuesta:
- **Autoriza:** el comité o responsable de **auditoría interna / seguridad de la información**, con visto bueno del **área legal o responsable de protección de datos** (plazos de retención) y de **Dirección**.
- **Ejecuta:** el DBA, con ticket de cambio y registro de la depuración.
- **Condición:** que la depuración siga la política de retención aprobada y deje evidencia (qué rango se eliminó, cuándo y quién).

### ¿Por qué log_statement = 'all' puede convertir la bitácora en un nuevo depósito de datos sensibles?
Porque el log guarda el **texto completo de cada sentencia**, incluidos los valores que contiene. Por ejemplo, un `UPDATE clientes SET rfc = 'GAMA780912GHI'` deja el RFC en claro en el log, y un `INSERT` con datos de clientes deja nombre, correo, RFC, etc. Con `'all'` esto ocurre en **todas las tablas y consultas**, de todos los usuarios, y puede incluir contraseñas o datos de otras áreas.

El resultado es una segunda (o tercera) copia de datos personales sin los controles de la tabla original: normalmente con acceso más amplio, sin cifrado, sin política de retención y replicada en respaldos y herramientas de monitoreo. Por eso hay que tratar el log con la misma clasificación y control de acceso que los datos que contiene.