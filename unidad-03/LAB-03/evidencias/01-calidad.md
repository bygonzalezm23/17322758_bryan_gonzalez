# Actividad 1 — Calidad de datos desde la operación

## Preguntas
### ¿Por qué el DBA no debe corregir por su cuenta el RFC del registro 7?
Porque el DBA no sabe cuál es el RFC correcto. El dueño del dato es el negocio y la fuente de la verdad es el cliente. Si el DBA "adivina" o completa el RFC, puede dejar un dato falso con apariencia de válido, y además estaría actuando fuera de su rol. La corrección la decide el área comercial y el DBA solo la ejecuta con una solicitud formal.

### ¿Qué restricción (CHECK, UNIQUE) habría evitado cada hallazgo? ¿Quién debería aprobar agregarla?
| Hallazgo | Restricción |
|----------|-------------|
| C1 Cliente duplicado | `UNIQUE (correo)` |
| C2 RFC incompleto | `CHECK (rfc ~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$')` |
| C3 Correo inválido | `CHECK (correo ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')` |
| C4 Edad fuera de rango | `CHECK (edad BETWEEN 18 AND 120)` |
| C5 RFC faltante | `NOT NULL` en `rfc` (si el negocio lo exige) |

La aprobación debe ser del dueño de los datos (área comercial o responsable de datos de clientes), con el DBA como implementador. Son reglas de negocio: por ejemplo, solo el negocio sabe si el RFC es obligatorio o si se aceptan clientes menores de 18.

### Si el DBA corrige un dato, ¿qué mecanismo del LAB-01 (Parte B) dejará evidencia del cambio?
El trigger de auditoría `trg_auditoria_clientes`, que ejecuta `auditoria.registrar_cambio_cliente()` en cada INSERT, UPDATE o DELETE. Registra el cambio en la tabla de auditoría, incluyendo quién lo hizo, cuándo y, según cómo esté construida la función, el valor anterior y el nuevo. Complementa a la bitácora del servidor (con `log_statement = 'mod'`), que registra la sentencia pero no el valor anterior.



## Tabla
| # | Hallazgo | Registros | Regla de calidad | ¿Quién decide la corrección? | Acción propuesta |
|---|----------|-----------|------------------|------------------------------|------------------|
| C1 | Posible cliente duplicado | 1, 7 | Unicidad del correo | Responsable de datos de clientes (área comercial), no el DBA | Confirmar si son la misma persona, conservar un registro, fusionar los datos útiles y eliminar el otro. Después agregar una restricción UNIQUE sobre `correo`. |
| C2 | RFC incompleto (12 caracteres en lugar de 13) | 7 | Formato del RFC | Área comercial, con el cliente como fuente de la verdad | Pedir el RFC completo al cliente y validarlo. Luego agregar una restricción CHECK de formato. |
| C3 | Correo con formato inválido (`sin-correo`) | 8 | Formato del correo | Área comercial / atención al cliente | Contactar al cliente para obtener un correo válido y reemplazar el marcador de posición. Luego agregar una restricción CHECK de formato. |
| C4 | Edad fuera de rango (-3) | 8 | Rango válido de edad (18 a 120) | Dueño del dato (captura / ventas) | Corregir con la fuente original (por ejemplo, fecha de nacimiento). Si no se puede verificar, dejar `NULL`. Después agregar `CHECK (edad BETWEEN 18 AND 120)`. |
| C5 | RFC faltante (`NULL`) | 8 | Completitud del RFC | Área comercial | Solicitar el RFC al cliente. Definir si el RFC será obligatorio y, en ese caso, aplicar `NOT NULL`. |