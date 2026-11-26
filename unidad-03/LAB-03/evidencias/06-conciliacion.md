# Actividad 6 — Políticas prácticas de datos

## Tabla: 
| Momento | Usuario | Sentencia | Folio | ¿Autorizado? | Hallazgo |
|---|---|---|---|---|---|
| 11:46:53 | `postgres` | `ALTER TABLE clientes ADD COLUMN canal_alta` | CAM-2026-014 | Sí, dentro de la ventana | Folio autoaprobado (H-07) |
| **10:39:32** | `postgres` | `DISABLE TRIGGER` + `UPDATE rfc` (id 3) + `ENABLE TRIGGER` | Ninguno | **No** | **H-02** |
| **11:01:13–11:01:24** | `postgres` | Mismas tres sentencias | Ninguno | **No** | **H-02** |
| 10:51:09 a 10:54:06 | `postgres` | `REVOKE`/`GRANT UPDATE` a `soporte_ana` y `app_ventas` | Ninguno | No consta | Preparación de la guía; sin folio (H-04) |
| 10:59:23, 10:59:54 y 11:02:24 | `postgres` | `GRANT SELECT ON dba.bitacora` y `GRANT TRIGGER ON clientes` a `soporte_ana` | Ninguno | No consta | Tratar como hallazgo salvo confirmación del propietario (H-04) |
| 10:51:27 y 10:51:48 | `postgres` | `ADD COLUMN segmento`; `log_statement = 'mod'` | Ninguno | No consta | Preparación de la guía |
| 10:33 y 11:46:17 | `postgres` | Creación de `auditoria` y `gobierno` | Ninguno | No consta | Preparación de la guía |
| 10:54, 11:02:45 y 11:03:12 | `soporte_ana`, `postgres` | `UPDATE clientes SET segmento = 'regular'` | Ninguno | No consta | Ejercicio; sí quedó en auditoría |
| 11:08:42 | `postgres` | `INSERT` de Ana López y Jorge Díaz | Ninguno | No consta | Datos de prueba de la Actividad 1 |

## Preguntas

### ¿Qué cambios de la bitácora no tienen folio? Clasifícalos: ¿son de preparación del laboratorio o representan hallazgos?
| Cambio | Clasificación | Justificación |
|---|---|---|
| `CREATE SCHEMA/TABLE/FUNCTION`, `REVOKE ALL ON FUNCTION ... FROM PUBLIC`, `CREATE TRIGGER` (Act. 10-11) | Preparación | Montan la auditoría que pide la guía. |
| `ALTER SYSTEM` / ajuste de `log_statement` (Act. 4) | Preparación | Configuración inicial de la bitácora. |
| `REVOKE UPDATE ... FROM soporte_ana`, `GRANT UPDATE ... TO app_ventas`, `ALTER TABLE ... ADD COLUMN segmento` (Act. 6) | Preparación | Son pasos de la guía, aunque en un entorno real también necesitarían folio. |
| `INSERT` y `DELETE` de Pedro Ruiz, `UPDATE` masivo de `segmento` (Act. 13 y 15) | Preparación | Ejercicios dirigidos. |
| `DISABLE TRIGGER`, `UPDATE ... rfc = 'GAMA780912GHI'` y `ENABLE TRIGGER` (Act. 14) | **Hallazgo** | Cambio de datos con la auditoría apagada, sin folio y sin evento en `auditoria.cambios_clientes`. |

El `GRANT UPDATE` a `app_ventas` es el caso dudoso. En este laboratorio es preparación, pero en una conciliación real sería un cambio de privilegios sin folio y habría que pedir justificación. La división entre "preparación" y "hallazgo" es un juicio mío, porque los archivos no incluyen una lista de cambios planeados.

### La desactivación del disparador del LAB-01 (Actividad 14), ¿qué tan grave es como hallazgo? ¿Por qué? ¿Qué distingue la línea 163 de la 169?
Es **grave**, porque:

- Rompe el control que sostiene la trazabilidad. Mientras el disparador estuvo apagado, cualquier cambio en `clientes` quedó fuera de `auditoria.cambios_clientes`.
- Se aprovechó: el RFC del cliente 3 cambió a `GAMA780912GHI` sin dejar evento. Solo la bitácora del servidor lo revela.
- No tiene folio ni autorización, y lo hizo quien opera la base y controla la evidencia. Es una falla de separación de funciones.
- Su causa es una decisión humana, no un fallo técnico: puede ser intencional.

**Sobre las líneas 163 y 169:** los archivos no traen números de línea, solo `num` en `dba.bitacora`, así que no puedo confirmar a qué sentencia corresponde cada una. Mi hipótesis es que la 163 es el `DISABLE TRIGGER` (inicio de la ventana ciega) y la 169 el `ENABLE TRIGGER` (cierre). Las sentencias de varias líneas ocupan varias filas, lo que explicaría el hueco entre ellas. En ese caso, la distinción sería que la 163 es el hallazgo (abre la ventana sin auditoría) y la 169 es una acción de restauración que no justifica nada: reactivar el disparador no borra lo ocurrido entre ambas. Lo que debe revisarse es todo lo que ocurrió entre esas dos líneas. Si me pasas ambas líneas de `dba.bitacora`, lo confirmo.

### ¿Qué limitación tiene esta conciliación si log_statement estuvo en none durante algún periodo?
La conciliación compara lo registrado contra lo autorizado, así que solo sirve para lo que quedó registrado. Con `none`:

- Los cambios hechos en ese periodo no aparecen y no se pueden conciliar. Es la misma situación de la Actividad 3: no hay evidencia, pero eso no prueba que no hubiera cambios.
- La conciliación puede dar una falsa sensación de "todo en orden" en esos periodos.
- Solo se puede detectar el hueco de forma indirecta: la línea `parameter "log_statement" changed to ...` marca cuándo empezó y terminó el periodo ciego. Para ver qué pasó dentro habría que recurrir a otras fuentes: la tabla de auditoría, respaldos, `pg_stat_activity` o los logs de conexión.

### ¿Quién debería realizar la conciliación: el DBA que hizo los cambios u otra persona?

**Otra persona**, de auditoría interna o seguridad de la información, no el DBA que hizo los cambios. Quien ejecuta los cambios no debe verificar que estén autorizados, porque tendría un conflicto de intereses y podría omitir o justificar sus propias acciones. Es el principio de separación de funciones de las Actividades 14 y 19.

El DBA sí puede aportar: explicar cada cambio, proporcionar los folios y apoyar con la consulta técnica. Además, el revisor debe trabajar con una copia de la bitácora fuera del servidor y con su hash verificado (Actividad 16), para que los registros no hayan podido ser alterados antes de conciliarlos.
