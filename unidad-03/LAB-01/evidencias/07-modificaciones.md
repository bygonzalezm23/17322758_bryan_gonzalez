# Actividad 7 — Modificaciones de datos: ddl frente a `mod`

## Preguntas

¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría en un servidor con miles de consultas por minuto?
`log_statement = 'all'`, que registra cualquier sentencia, incluidos los `SELECT`. El costo sería alto en un servidor con miles de consultas por minuto: cada lectura generaría una línea, lo que dispara el volumen de la bitácora, el uso de disco y de E/S, y puede afectar el rendimiento del servidor. Además, registrar todos los `SELECT` multiplicaría la exposición de datos sensibles dentro de los logs.

¿Qué le falta a esta bitácora para revertir el cambio con certeza?
Le falta el **valor anterior**. La bitácora del servidor solo guarda el texto de la sentencia (`UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3`), es decir, el valor **nuevo**, pero no cómo estaba el dato antes. Con eso se sabe qué se hizo, quién y cuándo, pero no a qué valor volver.

También le faltan:
- **Las filas afectadas:** en un `UPDATE` masivo o sin `WHERE`, el log solo muestra una línea y no dice qué filas cambiaron ni cuántas.
- **El resultado de la sentencia:** no indica si se confirmó (`COMMIT`) o se revirtió (`ROLLBACK`), ni si falló.

Esa información sí está en `auditoria.cambios_clientes` (`valores_antes` y `valores_despues`), pero solo cuando el disparador estaba activo. Por eso, para revertir con certeza se necesitan ambas fuentes: la tabla de auditoría para el valor anterior y la bitácora del servidor para detectar cambios hechos sin disparador.