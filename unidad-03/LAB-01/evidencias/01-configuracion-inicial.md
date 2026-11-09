# Actividad 1 — Revisar la configuración de registro por defecto

## Preguntas

### Con esta configuración, ¿se registra quién se conecta?
No. `log_connections = off` y `log_disconnections = off`, así que no quedan registradas conexiones ni desconexiones.

### ¿Se registran las sentencias UPDATE?
No. `log_statement = none`. Solo se registraría un `UPDATE` que cause un error (por `log_min_error_statement = error`).

### ¿La línea de bitácora incluye el usuario o la dirección IP del cliente?
No. El prefijo `%m [%p]` solo incluye la hora con milisegundos y el PID del proceso. Para incluirlos se necesitaría algo como `%m [%p] %u@%d %h`.

### ¿En qué zona horaria se registran los eventos? ¿Por qué importa al reconstruir una cronología?
En UTC (`Etc/UTC`). Importa porque, al comparar la bitácora con otras fuentes en hora local (por ejemplo, Mazatlán), los eventos se desfasan y la secuencia de un incidente puede quedar mal reconstruida. Hay que conocer la zona de cada fuente y convertirlas a una referencia común.

### Con logging_collector = off, ¿quién decide dónde termina la bitácora: PostgreSQL o el mecanismo con que se desplegó el servidor?
El mecanismo con que se desplegó el servidor. PostgreSQL solo escribe a `stderr`, y el servicio, contenedor o sistema operativo que lo lanzó decide si va a un archivo, a la consola o a un recolector de logs. `log_directory` y `log_filename` no se usan hasta activar el colector.