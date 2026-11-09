# Actividad 11 — Crear la función y el disparador

## Preguntas

¿Por qué se ejecuta REVOKE ALL ON FUNCTION ... FROM PUBLIC si el disparador seguirá funcionando para app_ventas?
En PostgreSQL, las funciones nuevas dan `EXECUTE` a `PUBLIC` por defecto. Se revoca para que nadie pueda invocarla por su cuenta (defensa en profundidad). El disparador sigue funcionando porque el permiso `EXECUTE` sobre una función de trigger se comprueba al **crear** el trigger, no al dispararlo. Además, al ser `SECURITY DEFINER`, se ejecuta con los privilegios de su dueño, no los de `app_ventas`.

¿Qué pasaría si la función no fuera SECURITY DEFINER? Formula una hipótesis antes de la Actividad 12.
**Hipótesis:** se ejecutaría con los permisos de `app_ventas`, que no tiene `USAGE` sobre el esquema `auditoria` ni `INSERT` sobre la tabla. El `INSERT` de auditoría fallaría con `permission denied` y **revertiría la operación original sobre `clientes`**: la aplicación dejaría de poder modificar clientes. La alternativa sería darle `INSERT` a `app_ventas` sobre la bitácora, lo que le permitiría falsificarla.

### Consulta dba.bitacora. ¿Quedó registrada la creación del esquema, la tabla, la función y el disparador? ¿Por qué?
Sí. La consulta SELECT * FROM dba.bitacora ORDER BY 1 DESC; devuelve 134 filas, y entre ellas aparecen las sentencias de creación, como el CREATE TRIGGER sobre clientes, cada una con su encabezado de log (fecha, user=postgres, db=bitacora, app=pgAdmin 4).

¿Por qué? Porque dba.bitacora se alimenta del log del servidor, no de un disparador de tabla. Con log_statement = 'ddl' (o 'all'), PostgreSQL escribe cada sentencia de definición (CREATE SCHEMA, CREATE TABLE, CREATE FUNCTION, CREATE TRIGGER). Las sentencias de varias líneas se guardan en varias filas.

# Actividad 12 — El incidente auditado

## Preguntas

### Compara tu hipótesis de la Actividad 11 con este resultado.
La hipótesis era que, sin `SECURITY DEFINER`, el `INSERT` de auditoría se ejecutaría con los permisos de `app_ventas`, fallaría con `permission denied` y revertiría el `UPDATE` sobre `clientes`.

El resultado confirma la lógica inversa. Con `SECURITY DEFINER`:
- El `UPDATE 1` de `app_ventas` se completó.
- El evento quedó registrado, aunque `app_ventas` **no** tiene acceso al esquema (`permission denied for schema auditoria` al intentar leerlo).
- `usuario_efectivo = postgres` (dueño de la función) y `usuario_sesion = app_ventas` conserva quién se conectó.

### Escribe la sentencia UPDATE que restauraría el valor anterior.
```sql
UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;
```
La restauración también dispara el trigger y genera un nuevo evento en la auditoría, así que la corrección queda trazada y el historial no se borra.

### ¿Qué columna conserva más valor para una investigación: aplicacion o ip_cliente?  ¿Cuál puede falsificar el cliente con más facilidad?
- **Más valor:** `ip_cliente`. La obtiene el servidor de la conexión de red real, y permite ubicar el equipo o la red de origen.
- **Más fácil de falsificar:** `aplicacion`. Es un valor que declara el propio cliente; en tu prueba bastó con `?application_name=app-ventas-web` en la cadena de conexión, y cualquiera puede poner el nombre que quiera.