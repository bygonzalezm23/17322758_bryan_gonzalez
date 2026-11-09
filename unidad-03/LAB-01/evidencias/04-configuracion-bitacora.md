# Actividad 4 — Configurar la bitácora

## Preguntas

### ¿Por qué el proceso que registra el cambio es el principal y no tu sesión?
Porque la recarga de configuración la aplica el proceso principal del servidor (PID 1), no tu sesión. Ese proceso registra el cambio sin pertenecer a ninguna conexión de cliente, por eso la línea no tiene `user=`, `db=` ni `app=`.

### ¿Qué pasaría si alguien ejecutara ALTER SYSTEM SET log_statement = 'none'? ¿Quedaría rastro?
La sentencia `ALTER SYSTEM` quedaría registrada si `log_statement` aún captura DDL en ese momento. Pero el cambio se aplica de inmediato, así que lo que haga después ya no se registra. El evento `parameter "log_statement" changed to "none"` sí queda, porque se registra aparte.

### ¿Por qué no se recomienda editar postgresql.auto.conf a mano?
Es un archivo generado por PostgreSQL y un error de sintaxis puede impedir que arranque. `ALTER SYSTEM` valida el parámetro y el valor, y queda registrado en el historial SQL; editar el archivo a mano no deja ese rastro y cualquiera con acceso al sistema de archivos podría modificarlo sin privilegios de superusuario en la base.