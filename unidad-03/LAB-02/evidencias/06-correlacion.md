# Actividad 6 — Correlacionar un cambio de configuración con su autor

## Preguntas 

### ¿Qué usuario cambió la configuración del perfilador? ¿Qué dos eventos lo demuestran?
El usuario fue **`admin`** (autenticado contra la base `admin`).

Los dos eventos que lo demuestran son:

1. **`Profiler settings changed`** (`ctx: 'conn31'`, `t: 22:52:56.999`): registra el cambio de `level: 0` a `level: 1` con el filtro `op: { $in: [insert, remove, update] }` sobre la base `comercial`. Prueba **qué** se cambió y **cuándo**, pero **no quién**.
2. **`Successfully authenticated`** (`ctx: 'conn31'`, `t: 22:52:56.959`, `user: 'admin'`, `db: 'admin'`, `client: 127.0.0.1:37200`): prueba **quién** abrió esa conexión.

El vínculo entre ambos es el **`ctx`** (`conn31`): la misma conexión se autenticó como `admin` (40 ms antes) y luego cambió el perfilador.

---
### ¿Qué condición debe cumplirse para que esta correlación sea válida? (Piensa en qué pasa si el servidor se reinicia y los números de conexión vuelven a empezar.)
El identificador `conn31` debe referirse a **la misma conexión** en ambos eventos. Para eso:

- **Ambos eventos deben pertenecer a la misma ejecución del servidor (`mongod`) y al mismo archivo/rango de bitácora.** Los números de conexión (`connN`) son un contador que **vuelve a empezar tras un reinicio**, así que `conn31` de hoy puede ser una conexión distinta de otra `conn31` anterior al reinicio.
- La autenticación debe ser **anterior** al cambio de configuración (secuencia temporal coherente) y estar **cercana en el tiempo**.
- La conexión **no debe haberse cerrado y reutilizado el número** entre ambos eventos (dentro de un mismo proceso no se reutiliza, pero sí tras reinicio o rotación mal interpretada).
- Idealmente, confirmar con el mismo **`client`** (`ip:puerto`), que debería coincidir en los eventos de conexión/autenticación de esa sesión.

> En la práctica: acotar la búsqueda por **ventana de tiempo** y verificar que no hay un evento de inicio del servidor (`Starting up` / `Process Details`) entre los dos eventos.
### ¿Por qué es relevante que quede registrado un cambio de configuración del propio mecanismo de registro?
- **Detecta la manipulación de la evidencia:** quien quiere ocultar su actividad primero intenta **apagar o reducir el perfilador** (por ejemplo, bajarlo a nivel 0 o aplicar un filtro que excluya lecturas). Si ese cambio no quedara registrado, la ausencia de datos sería indistinguible de "no pasó nada".
- **Explica los huecos en la evidencia:** permite saber **desde cuándo** y **por qué** ciertas operaciones (como las lecturas) ya no aparecen en `system.profile`. Aquí, justifica por qué el `find` no está en el perfil.
- **Garantiza trazabilidad y responsabilidad:** al poder atribuir el cambio a `admin` mediante `ctx`, se puede pedir cuentas y comprobar si fue un cambio autorizado.
- **Los registros viven en un lugar distinto:** `system.profile` puede borrarse con `drop()`, pero la **bitácora del servidor** (archivo de log) es un registro independiente que sobrevive a ese borrado, por lo que sirve como segunda fuente de verdad.

> **Principio de auditoría:** un buen sistema de auditoría debe registrar **también los cambios a sí mismo**; de lo contrario, quien tenga permisos para modificarlo puede borrar sus huellas sin que nadie lo note.