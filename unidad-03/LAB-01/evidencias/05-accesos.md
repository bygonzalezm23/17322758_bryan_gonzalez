# Actividad 5 — Accesos exitosos y fallidos

## Preguntas

### La bitácora registra el usuario app_ventas en el intento fallido. ¿Eso prueba que la aplicación de ventas intentó entrar? ¿Qué prueba realmente?
No. Solo prueba que **alguien** escribió el nombre de usuario `app_ventas` al intentar conectarse desde `127.0.0.1`. El campo `user=` es el valor que el cliente envió antes de autenticarse, no una identidad verificada: PostgreSQL lo registra tal como llega, incluso si la contraseña es incorrecta. Lo que realmente prueba es que desde esa IP alguien intentó autenticarse con ese nombre de usuario y falló.

### ¿Qué información adicional registra PostgreSQL cuando el rol no existe? ¿Por qué aparece en la bitácora y no en el mensaje que recibe el cliente?
Registra `DETAIL: Role "usuario_inexistente" does not exist.` Al cliente solo le llega `password authentication failed`, el mismo mensaje genérico que con una contraseña incorrecta. Esto es intencional: si el servidor dijera "el usuario no existe", un atacante podría usar la respuesta para enumerar qué cuentas son válidas. La bitácora sí guarda el detalle porque solo la ve el administrador.

### ¿Por qué app=[unknown] en el intento fallido, pero app=app-ventas-web en la desconexión?
`application_name` lo envía el cliente **después** de autenticarse, como parte de los parámetros de sesión. En un intento fallido, la autenticación nunca se completa, así que el servidor no llega a conocer ese valor y lo registra como `[unknown]`. En la conexión exitosa, la sesión sí se establece y el parámetro llega, por eso aparece en las líneas posteriores (autorización y desconexión).

### ¿Qué patrón de varias líneas te haría sospechar de un ataque de fuerza bruta? Escribe la consulta que contaría los intentos fallidos por usuario.
Varias líneas `FATAL: password authentication failed` para el mismo usuario, en poco tiempo, desde la misma IP (o desde IP distintas), especialmente si prueban usuarios comunes o secuenciales.

```sql
SELECT
  substring(linea FROM 'user=(\S+)') AS usuario,
  count(*) AS intentos_fallidos
FROM dba.bitacora
WHERE linea LIKE '%FATAL:%password authentication failed%'
GROUP BY usuario
ORDER BY intentos_fallidos DESC;
```

Para verlo también por IP y ventana de tiempo:

```sql
SELECT
  substring(linea FROM 'client=(\S+)') AS ip_origen,
  substring(linea FROM 'user=(\S+)') AS usuario,
  count(*) AS intentos
FROM dba.bitacora
WHERE linea LIKE '%FATAL:%password authentication failed%'
GROUP BY ip_origen, usuario
ORDER BY intentos DESC;
```