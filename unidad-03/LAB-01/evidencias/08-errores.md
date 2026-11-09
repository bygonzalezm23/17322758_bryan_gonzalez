# Actividad 8 — Errores y operaciones rechazadas

## Preguntas 

### ¿El intento de soporte_ana causó algún daño? ¿Por qué debe auditarse de todos modos?
No causó daño; el `DELETE` fue rechazado. Debe auditarse porque muestra una intención de borrar un dato sin permiso, lo cual puede ser error, mal uso o un intento malicioso.

### ¿Qué diferencia hay entre un error de autorización (esta actividad) y uno de autenticación (Actividad 5)?
La autenticación falla antes de entrar (identidad no verificada, la sesión no se establece). La autorización falla ya dentro de la sesión, cuando el rol no tiene privilegio para esa acción.

### ¿Qué indica el error de DROP ROLE sobre el orden correcto para dar de baja a un usuario?
Que primero hay que revocar sus privilegios (y reasignar o eliminar sus objetos) y solo después ejecutar `DROP ROLE`.