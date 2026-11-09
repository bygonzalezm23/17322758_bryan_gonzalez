# Actividad 10 — Diseñar y crear el registro de auditoría

## Tabla 

| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
|---|---|---|---|
| `id_evento` | BIGSERIAL | **Identificación y orden:** ¿qué evento fue y en qué secuencia ocurrió? Distingue cada registro y permite ordenarlos sin ambigüedad. | **No.** Es la clave primaria y se genera automáticamente. |
| `momento` | TIMESTAMPTZ | **¿Cuándo ocurrió?** Con zona horaria, para evitar ambigüedades entre sedes u horarios de verano. | **No.** Sin fecha y hora el registro no sirve como evidencia. Se llena con `DEFAULT now()`. |
| `usuario_sesion` | TEXT | **¿Quién se conectó?** Es el usuario con el que se abrió la conexión (`session_user`), la identidad "real" de quien entró. | **No.** Toda conexión tiene un usuario, así que siempre hay un valor. |
| `usuario_efectivo` | TEXT | **¿Con qué identidad y permisos se ejecutó?** Es `current_user`, que puede diferir de `usuario_sesion` por `SET ROLE` o funciones `SECURITY DEFINER`. Detecta escalada de privilegios o uso de roles compartidos. | **No.** PostgreSQL siempre tiene un usuario efectivo (a menudo igual al de sesión). |
| `aplicacion` | TEXT | **¿Desde qué programa se hizo?** Es `application_name` (app web, psql, script de carga, etc.). Distingue un cambio hecho por el sistema de uno hecho a mano en consola. | **Sí.** Depende de que el cliente declare su nombre; si no lo hace, queda vacío o NULL. |
| `ip_cliente` | INET | **¿Desde dónde se conectó?** Es `inet_client_addr()`, que permite ubicar el equipo o red de origen. | **Sí.** En conexiones locales por socket Unix no hay IP y la función devuelve NULL. |
| `operacion` | TEXT | **¿Qué se hizo?** `INSERT`, `UPDATE` o `DELETE` (`TG_OP`). Se acompaña de un `CHECK` que restringe esos valores. | **No.** Todo evento auditado es una operación concreta. |
| `id_cliente` | BIGINT | **¿Sobre qué registro se actuó?** Es el cliente afectado, para consultar todo el historial de uno en particular. | **No.** Siempre hay un cliente afectado: se toma de `NEW.id` en INSERT/UPDATE y de `OLD.id` en DELETE. |
| `valores_antes` | JSONB | **¿Cómo estaba el registro antes?** Es la fila anterior (`to_jsonb(OLD)`), necesaria para reconstruir o revertir el cambio. | **Sí.** En un `INSERT` no existía fila previa, así que es NULL. |
| `valores_despues` | JSONB | **¿Cómo quedó el registro después?** Es la fila resultante (`to_jsonb(NEW)`). Comparada con `valores_antes` muestra exactamente qué campos cambiaron. | **Sí.** En un `DELETE` ya no existe fila posterior, así que es NULL. |

## Preguntas

### ¿Por qué momento usa TIMESTAMPTZ y no TIMESTAMP?
`TIMESTAMPTZ` guarda un instante absoluto (en UTC) y lo muestra en la zona de la sesión. `TIMESTAMP` guarda solo la hora de reloj, sin zona. Con sesiones en distintas zonas, migraciones o cambios de horario de verano, no se podría reconstruir el orden real de los eventos. En una auditoría, la fecha debe ser evidencia sin ambigüedad.

### ¿Por qué se guarda el registro completo en JSONB y no solo la columna que cambió?
- Da contexto completo: permite saber qué cliente y en qué estado estaba, no solo qué campo cambió.
- Permite reconstruir o revertir un `UPDATE` o recuperar un `DELETE`.
- Resiste cambios de estructura: si `clientes` gana o pierde columnas, el JSON conserva lo que existía en ese momento.
- El trigger no necesita saber de antemano qué columna cambió.
### La tabla de auditoría también contendrá RFC. ¿Qué implica eso para su clasificación y su control de acceso?
**Clasificación:** el RFC es dato personal, así que la auditoría hereda al menos la clasificación de `clientes` (confidencial) y queda sujeta a la normativa de protección de datos. Es una segunda copia de esos datos y puede ser más sensible, porque conserva valores históricos y de clientes eliminados.

**Control de acceso:**
- Mínimo privilegio: sin acceso para `PUBLIC`; `SELECT` solo para un rol de auditoría.
- Bitácora de solo agregar: nadie con `UPDATE` ni `DELETE`; inserción mediante trigger `SECURITY DEFINER`.
- Separación de funciones: quien administra los datos operativos no administra la auditoría.
- Vistas que enmascaren el RFC para quien no necesite verlo completo.
- Cifrado en reposo y en respaldos, y definir plazo de retención.

