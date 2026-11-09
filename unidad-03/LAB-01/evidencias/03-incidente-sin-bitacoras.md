# Actividad 3 — El incidente sin bitácora

## Preguntas

### ¿Puedes demostrar quién modificó el RFC?
No. El `UPDATE` se ejecutó (`UPDATE 1`), pero la bitácora no registró nada: `log_connections = off` (no hay rastro de la conexión de `app_ventas`) y `log_statement = none` (no hay rastro de la sentencia). Lo único que existe es el dato modificado, sin autor, hora ni origen.
### ¿Puedes demostrar que el cambio no lo hizo soporte_ana?
No. Sin registro de conexiones ni de sentencias, no hay forma de descartar a nadie. Que `app_ventas` haya hecho la simulación no prueba que fuera la única cuenta capaz de hacerlo. Una ausencia de evidencia no es evidencia de ausencia.
### Los privilegios de la Unidad II, ¿impidieron el cambio? ¿Debían impedirlo?
No lo impidieron, y no debían: `app_ventas` es la cuenta de la aplicación y tiene `UPDATE` sobre `clientes` porque lo necesita para operar. Los privilegios (autorización) definen **qué se puede hacer**, no **registran qué se hizo**. Un cambio permitido y legítimo en términos de permisos puede ser aun así incorrecto o indebido, y solo la bitácora permite investigarlo. Los privilegios previenen; la bitácora permite detectar y reconstruir.
### ¿Qué tendría que haber estado configurado antes del incidente?
- `log_connections = on` y `log_disconnections = on`, para saber quién se conectó, desde dónde y cuándo.
- `log_statement = 'mod'` (o `'ddl'` como mínimo), para registrar `INSERT`, `UPDATE` y `DELETE`.
- `log_line_prefix` con usuario, base, aplicación e IP, por ejemplo `'%m [%p] %u@%d %a %h '`.
- `logging_collector = on`, para que la bitácora se guarde en archivo.
- Retención y rotación de logs definidas, y copia en un lugar de solo lectura para que no se pueda alterar.
- Una auditoría a nivel de dato para cambios sensibles (por ejemplo, `pgaudit` o un trigger que guarde valor anterior y nuevo del RFC).
- Cuentas individuales y nominales, no compartidas, para atribuir cada acción a una persona o aplicación.