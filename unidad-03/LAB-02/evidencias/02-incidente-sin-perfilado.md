# Actividad 2 — El incidente sin perfilado

## Preguntas

### ¿Puedes demostrar qué cambió? ¿Y quién se conectó a esa hora?
No. `db.system.profile.countDocuments()` es `0` porque el perfilador está apagado (`was: 0`), así que la operación `updateOne` nunca quedó registrada. Solo sabes que el RFC cambió porque tú mismo lo ejecutaste y viste la respuesta (`modifiedCount: 1`); sin esa presencia, no habría forma de demostrarlo después. La bitácora sí muestra conexiones autenticadas a esa hora, pero esos eventos no indican qué usuario ni qué operación ejecutó, así que tampoco puedes vincular con certeza una conexión con el cambio del RFC.

### ¿Por qué mongosh abre varias conexiones (conn8, conn9, …) para una sola instrucción? ¿Cuál es la que se autentica?
Porque el driver de MongoDB usa un pool de conexiones: abre varios sockets para tareas internas (monitoreo de topología, handshake con metadata del cliente) además del que ejecuta el comando. Por eso aparecen varias líneas `client metadata` en distintos `ctx`. La conexión que importa es la que muestra `Successfully authenticated`: esa es la que usó las credenciales de `app_ventas` y por la que corrió el `updateOne`. Las demás son conexiones auxiliares del propio cliente.
