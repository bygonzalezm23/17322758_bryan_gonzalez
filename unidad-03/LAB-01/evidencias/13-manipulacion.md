# Actividad 14 — Intentar manipular la auditoría

## Preguntas

### ¿Qué evidencia permite detectar que hubo un cambio sin auditar?
La **bitácora del servidor** (`dba.bitacora`). Ahí quedan, con usuario, aplicación, origen y orden (`num`), las tres sentencias del administrador: `DISABLE TRIGGER`, el `UPDATE ... rfc = 'GAMA780912GHI'` y `ENABLE TRIGGER`. Además, `auditoria.cambios_clientes` no tiene ningún evento para ese `UPDATE` (el conteo sigue en 3). Que el log muestre un `UPDATE` sobre `clientes` y la tabla de auditoría no, es la prueba del cambio sin auditar.

También se detecta comparando el RFC actual del cliente 3 con el último `valores_despues` auditado, que ya no coinciden.

### ¿Qué control administrativo (no técnico) reduciría este riesgo?
**Separar a quien opera la base de quien custodia la evidencia:** que las bitácoras se envíen a un sistema externo administrado por otra área (seguridad o auditoría interna), con revisión periódica obligatoria. Complementos administrativos:
- Procedimiento de control de cambios: todo `DISABLE TRIGGER` o cambio directo de datos requiere ticket y autorización previa.
- Política de que el administrador no use cuentas compartidas ni trabaje sin registro.
- Revisión periódica de la bitácora por alguien distinto al DBA.

### Relaciona esta actividad con el principio de separación de funciones de la Unidad II.

El principio dice que una misma persona no debe poder ejecutar una acción y también controlar o borrar la evidencia de que la ejecutó. En la práctica:
- **`app_ventas`** modifica datos, pero no puede leer ni alterar la auditoría ni apagar el disparador (`permission denied` y `must be owner`). Aquí el control funciona.
- **El administrador** (`postgres`) opera la base y a la vez controla el disparador y el log, así que reúne funciones incompatibles. Por eso pudo cambiar un dato sin dejar registro en la auditoría.
