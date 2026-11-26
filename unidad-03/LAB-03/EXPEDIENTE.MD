# Expediente de auditoría interna — Base comercial

## 1. Alcance
| Elemento | Detalle |
|---|---|
| Sistema principal | PostgreSQL, base `comercial`, servidor local en Windows, puerto 5434, autenticación `scram-sha-256` solo por loopback (`::1` y `127.0.0.1`). |
| Versión | **Por confirmar con `SELECT version();`.** La bitácora muestra la ruta `C:/Program Files/PostgreSQL/19/data/`, el cliente `psql` usado es de la carpeta `18` y el catálogo (Actividad 4) dice PostgreSQL 16. |
| Sistema secundario | MongoDB 7, base `comercial` (según el catálogo). **No se recibió evidencia de MongoDB (E6)**, por lo que no se concluye nada sobre él. |
| Periodo cubierto por la bitácora E5 | 2026-11-25 09:15:27 a 12:14:27. El registro de conexiones y de sentencias empieza hacia las 10:05–10:12, así que lo anterior no está cubierto. |
| Fuentes | E1 a E5, diccionario CSV y documentos de las Actividades 1 a 6. Índice y hashes en la sección 10. |


## 2. Configuración de auditoría (A3)
| Mecanismo | Valor / estado | Evidencia |
|---|---|---|
| Colector de registros | `logging_collector = on` (archivo de configuración) | E1 |
| Conexiones y desconexiones | `log_connections = on`, `log_disconnections = on` | E1 |
| Prefijo de línea | `%m [%p] user=%u db=%d app=%a client=%h` (hora, proceso, usuario, base, aplicación, cliente) | E1 |
| Sentencias registradas | `log_statement = mod`. Historia en E5: `ddl` desde 10:12:05 y `mod` desde 10:51:48. | E1, E5 |
| Sentencias con error | `log_min_error_statement = error` (por defecto) | E1 |
| Disparador de auditoría | `trg_auditoria_clientes` activo (`tgenabled = O`) sobre `clientes` | E3 |
| Tabla de auditoría | `auditoria.cambios_clientes` con usuario, aplicación, operación y cliente; 30 eventos hasta las 11:08:42 | E4 |
| Privilegios vigentes | `app_ventas`: SELECT, UPDATE en `clientes`. `soporte_ana`: SELECT, TRIGGER, UPDATE en `clientes` y SELECT en `dba.bitacora`. | E2 |
| Aislamiento de esquemas | `REVOKE ALL ... FROM PUBLIC` en `auditoria` y `gobierno`; el acceso denegado de `app_ventas` y `soporte_ana` a `auditoria` y `dba` confirma que funciona. | E5 |
| MongoDB (LAB-02) | Perfilado, instantáneas de privilegios y bitácora de `mongod`: **pendiente de evidencia (E6)**. | — |

## 3. Bitácora interpretada (A3, A5)
| ID | Cuándo | Quién | Desde dónde | Qué ocurrió | Tipo de evento | Qué prueba |
|---|---|---|---|---|---|---|
| EV-1 | 10:09–10:12 | `postgres` | pgAdmin 4, `::1` | `ALTER SYSTEM` de `log_connections`, `log_disconnections`, `log_line_prefix` y `log_statement = 'ddl'`. A las 10:07:52 falló el intento en bloque (ALTER SYSTEM no admite transacciones) y se repitió una sentencia por vez. | Cambio de configuración de auditoría | La auditoría de DDL y conexiones rige desde ~10:12. Lo anterior no se puede afirmar. |
| EV-2 | 10:15:17 a 10:36:41 | `postgres` y `app_ventas` | `::1` y `127.0.0.1` | Dos fallos de contraseña de `postgres` en el mismo segundo (IPv6 e IPv4), éxito a las 10:15:32. Dos fallos de `app_ventas` (10:23:40 y 10:24:53) y éxito a las 10:36:41. | Autenticación fallida | `scram-sha-256` aplica (`pg_hba.conf` líneas 115 y 117). Patrón de errores de digitación, no de fuerza bruta. PostgreSQL no bloquea cuentas por sí solo. |
| EV-3 | 10:36:53 y 10:38:54 | `app_ventas` | `app-ventas-web`, `::1` | `SELECT` sobre `auditoria.cambios_clientes`: permiso denegado. `ALTER TABLE clientes DISABLE TRIGGER ...`: error "debe ser dueño de la tabla". | Acceso denegado / intento de manipular la auditoría | Un usuario de aplicación no puede leer ni apagar la auditoría. Contrasta con EV-4. |
| **EV-4** | **10:39:32 y 11:01:13–11:01:24** | **`postgres`** | pgAdmin 4, `::1` (sesiones CONN:3711570 y CONN:7394430) | **`DISABLE TRIGGER trg_auditoria_clientes`, `UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3` y `ENABLE TRIGGER`.** Ocurrió dos veces: la primera en un solo lote (E5, ln. 230–234), la segunda en tres sentencias separadas (ln. 327–330). | **Cambio de dato con la auditoría apagada** | El RFC del cliente 3 (María García, según el enunciado del laboratorio; la bitácora solo registra el id) se modificó sin pasar por `auditoria.cambios_clientes`. Solo la bitácora del servidor lo revela. Ver H-02. |
| EV-5 | 10:51:09 a 11:02:24 | `postgres` | pgAdmin 4, `::1` | `REVOKE UPDATE` a `soporte_ana` (10:51:09), `GRANT UPDATE` a `app_ventas` (10:51:19), `ALTER TABLE ... ADD COLUMN segmento` (10:51:27), `log_statement = 'mod'` (10:51:48), `DROP ROLE soporte_ana` rechazado por dependencias (10:52:16), nuevo `GRANT UPDATE` a `soporte_ana` (10:54:06), `GRANT SELECT ON dba.bitacora` (10:59:23 y 10:59:54) y `GRANT TRIGGER` (11:02:24). | Cambios de privilegios y estructura | El mínimo privilegio se erosionó dentro de la misma sesión de trabajo, sin folio. Ver H-04. |
| EV-6 | 11:46:17 a 11:46:55 | `postgres` | pgAdmin 4, `::1` | Creación del esquema `gobierno`, inserción del folio CAM-2026-014 (11:46:36), `ALTER TABLE clientes ADD COLUMN canal_alta` (11:46:53) y su `COMMENT` (11:46:55). | Cambio estructural con folio | El cambio cae dentro de la ventana del folio (≈11:41 a 12:46). Pero el folio lo insertó la misma cuenta 17 segundos antes. Ver H-07. |
| EV-7 | 11:02:45, 11:03:12 y 11:08:42 | `soporte_ana` y `postgres` | pgAdmin 4, `::1` | Los `UPDATE`/`INSERT` de la bitácora coinciden con los eventos 21–23, 24–28 y 29–30 de E4, con la misma hora al milisegundo. | Correlación entre dos fuentes | Con el disparador activo, la tabla de auditoría y la bitácora concuerdan. Por eso la **ausencia** de eventos del RFC durante EV-4 es significativa. |

**Incidente del RFC (resumen).** Quien lo ejecutó fue la cuenta `postgres`, que es dueña de la tabla y superusuario. La bitácora no identifica a la persona. La conexión CONN:7394430 de pgAdmin también la usó `soporte_ana` entre 10:41 y 11:03, de modo que el nombre de aplicación no identifica a nadie.

**Verificación pendiente.** E4 solo contiene los últimos 10 eventos, así que no permite probar la ausencia. Ejecutar y anexar el resultado (se espera 0 filas):

```sql
SELECT id_evento, momento, usuario_sesion, operacion
FROM auditoria.cambios_clientes
WHERE id_cliente = 3
  AND momento BETWEEN '2026-11-25 10:39:00' AND '2026-11-25 11:02:00'
ORDER BY momento;
```

## 4. Elementos de gobierno (A1, A2)
**Responsables (Actividad 2)**

| Conjunto | Propietario | Custodio | Aprueba accesos y correcciones |
|---|---|---|---|
| `public.clientes` (PostgreSQL) | Gerencia Comercial | DBA | Propietario; el DBA ejecuta con solicitud formal |
| `auditoria.cambios_clientes` | Seguridad / Cumplimiento | DBA | Seguridad / Cumplimiento; nadie corrige la evidencia |
| Bitácora de PostgreSQL | Seguridad / Cumplimiento | DBA | Seguridad / Cumplimiento; no se edita |
| `clientes` y `system.profile` (MongoDB) | Gerencia Comercial / TI-Seguridad | DBA | Propietario del dato |

**Catálogo (Actividad 4).** CAT-01 Clientes y CAT-04 Clientes (tienda) son confidenciales y de Gerencia Comercial. CAT-02 Auditoría, CAT-03 Registro de cambios y CAT-05 Perfilado pertenecen a Seguridad / Cumplimiento o TI. CAT-02 y CAT-05 son confidenciales porque copian valores de clientes. Detalle en `04-catalogo.md`.

**Diccionario (Actividad 3).** `diccionario-clientes.csv` documenta 10 columnas con descripción, finalidad y responsable. **Está desactualizado:** la bitácora muestra que `canal_alta` se agregó y comentó a las 11:46, y el CSV no la incluye (H-09). CAT-02 a CAT-05 siguen "Pendiente".

## 5. Conservación (A3)
Criterio de la Actividad 5, resumido:

| Registro | Periodo | Almacenamiento y control |
|---|---|---|
| Accesos de PostgreSQL | 12 meses | Copia externa de solo lectura |
| Cambios de privilegios y estructura | 24 meses | Copia cifrada, fuera del servidor, solo Seguridad |
| Modificaciones de datos (`mod`) | 12 meses | Copia cifrada fuera del servidor |
| `auditoria.cambios_clientes` | 5 años | Misma tabla más respaldo cifrado |
| Bitácora de `mongod` | 12 meses | Archivo con rotación y copia externa |
| `system.profile` | 30 días | Exportación periódica |
| Instantáneas de privilegios (MongoDB) | 24 meses | Colección protegida más respaldo cifrado |

**Aplicación a E5.** El archivo exportado mezcla accesos, DDL y modificaciones. Debe conservarse con el **plazo más largo (24 meses)** y acceso solo para Seguridad / Cumplimiento, porque contiene cambios de privilegios. Integridad: hash SHA-256 en el índice de la sección 10, que debe custodiar Seguridad y no el DBA.


## 6. Políticas (A4)
Se contrasta lo que exige cada política (POL-01 a POL-06) con lo observado en E1–E5. "No verificable" significa que no hay evidencia en el expediente, no que se incumpla.

| Política | Qué exige | Evidencia revisada | Resultado | Hallazgo |
|---|---|---|---|---|
| POL-01 Acceso | Solicitud escrita al propietario, mínimo privilegio, revisión semestral. La evidencia debe ser la solicitud en `gobierno.solicitudes_cambio`, los GRANT/REVOKE en la bitácora y el informe de revisión. | E2 y E5 (EV-5): se concedieron UPDATE, TRIGGER y SELECT sobre `dba.bitacora` a `soporte_ana` y UPDATE a `app_ventas`, sin folio. El único folio existente (CAM-2026-014) es de otro cambio. No se recibió informe de revisión semestral. | **Incumple** | H-04 |
| POL-02 Respaldo | Respaldo diario cifrado fuera del servidor (30 días), hash de cada copia, prueba mensual de restauración. | Sin bitácora de respaldos, hashes de copias ni acta de prueba. | **No verificable** | H-11 |
| POL-03 Retención | 5 años para clientes y su auditoría; bitácoras de 12 a 24 meses; `system.profile` 30 días; registro de bajas y manifiesto de hashes. | Los periodos de `05-conservacion.md` y el catálogo coinciden con la política. Falta el manifiesto `.sha256` de E5 y no hay registro de bajas. | **Cumple parcialmente** | H-08, H-11 |
| POL-04 Restauración | Solicitud, aprobación, respaldo previo y validación en ambiente aparte. | No aparece ninguna restauración en la bitácora del periodo (09:15 a 12:14). | **No aplica en el periodo** | — |
| POL-05 Datos sensibles | Acceso con justificación y vistas enmascaradas; contraseñas fuera de las sentencias; la bitácora solo la leen Seguridad/Cumplimiento y el DBA. | E2: `soporte_ana` tiene SELECT sobre `dba.bitacora`. E5 (ln. 456 y 463): una credencial temporal quedó escrita en una sentencia registrada. Las vistas enmascaradas no se revisaron. | **Incumple** | H-04, H-05 |
| POL-06 Cambios en producción | Solicitud y aprobación antes de ejecutar, prueba previa, respaldo previo y verificación posterior en bitácora y auditoría. El alcance incluye triggers, privilegios, configuración y correcciones de datos. | Ver abajo. | **Incumple** | H-02, H-04, H-07 |

**Detalle de POL-06.**

- **Sin folio:** `DISABLE TRIGGER`, `UPDATE rfc` y `ENABLE TRIGGER` (10:39:32 y 11:01:13), los GRANT/REVOKE, `ADD COLUMN segmento` y el cambio de `log_statement`. Todos entran en el alcance de la política.
- **Con folio dudoso:** CAM-2026-014 lo registró la misma cuenta que ejecutó el cambio, 17 segundos antes, con aprobación retroactiva.
- **Verificación posterior fallida:** la política exige comprobar que el cambio quedó en la auditoría. El cambio del RFC no dejó evento en `auditoria.cambios_clientes`, así que ese control no detectó nada.
- **Excepción de urgencia:** permite actuar sin aprobación previa si TI lo autoriza, con solicitud formal dentro de 24 horas. Ese plazo corre hasta 2026-11-26 10:39 (primer cambio) y 11:01 (segundo). No hay autorización de TI ni incidente crítico en la evidencia. Antes de cerrar el hallazgo conviene preguntar al Responsable de TI si alguien invocó la excepción.

**Huecos en las propias políticas.**

- POL-06 acepta `log_statement = 'ddl'` como evidencia, pero bajo `ddl` no se registran los `UPDATE` de correcciones de datos. Solo `mod` los cubre.

## 7. Conciliación de cambios (A5)
Se comparan las sentencias de E5 con los folios de `gobierno.solicitudes_cambio` (único folio: CAM-2026-014).

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

**Corrección al borrador `06-conciliacion.md`.** Ese borrador estimaba el apagado del disparador el 2026-11-08 a las 22:05, desde `psql` por `[local]`. La bitácora real indica **2026-11-25 10:39:32 y 11:01:13, desde pgAdmin 4 por `::1`**, y además muestra el `ALTER TABLE ... canal_alta`, que el borrador daba como no constante. Debe actualizarse. La separación entre "preparación" y "hallazgo" es un juicio del autor, porque no hay lista de cambios planeados.

**Limitación.** La conciliación solo cubre lo registrado. Antes de ~10:12 no hay registro, y bajo `ddl` (10:12 a 10:51) un `UPDATE` suelto no se registraba. El apagado de las 10:39 solo quedó visible porque iba dentro de un lote con `ALTER TABLE`.

## 8. Hallazgos
| ID | Hallazgo | Fuente | Severidad | Impacto | Recomendación | Decisión requerida de |
|---|---|---|---|---|---|---|
| H-01 | Calidad de datos: posible duplicado (1 y 7), RFC de 12 caracteres (7), correo `sin-correo` (8), edad −3 (8) y RFC nulo (8) | Act. 1, E5 (INSERT 11:08:42) | Media | Facturación con datos inválidos y riesgo fiscal | Corregir con la fuente (el cliente) y luego agregar `UNIQUE`, `CHECK` y `NOT NULL` | Gerencia Comercial (propietario) |
| **H-02** | **Disparador de auditoría apagado dos veces para cambiar el RFC del cliente 3, sin folio y sin evento de auditoría (por confirmar con la consulta de la sección 3)** | E5 ln. 230–234 y 327–330; E3; E4 | **Crítica** | Se rompe la trazabilidad de un dato fiscal; la evidencia principal no registra el cambio | Investigar con Seguridad. Restaurar el valor correcto con folio. Quitar al DBA la propiedad práctica sobre el disparador (alerta sobre `ALTER TABLE ... TRIGGER`) | Seguridad / Cumplimiento y Gerencia Comercial |
| H-03 | Una sola cuenta (`postgres`, superusuario) hizo DDL, DML, exportación de la bitácora y apagado del disparador; no hay cuentas nominales | E5 | Alta | No se puede atribuir una acción a una persona | Cuentas nominales para cada DBA, `postgres` solo para emergencias, `application_name` no es identidad | Dirección de TI y Seguridad |
| H-04 | Cambios de privilegios sin folio: `soporte_ana` recibió de nuevo UPDATE tras un REVOKE, además de TRIGGER y SELECT sobre `dba.bitacora` (E2). Hoy no puede leer la bitácora por falta de permiso en `pg_read_binary_file`, pero el permiso quedó concedido. | E5 EV-5; E2 | Alta | La bitácora contiene datos de clientes y secretos; contradice la Actividad 2 (solo auditor y DBA) | Revocar TRIGGER y SELECT sobre `dba.bitacora`; exigir folio para todo GRANT | Seguridad / Cumplimiento |
| H-05 | La bitácora contiene datos personales (correos, RFC, edades) y, por el registro de sentencias con error, una credencial temporal del laboratorio | E5 (INSERT 11:08:42; ln. 456 y 463) | Alta | Fuga de datos o secretos a quien lea el log | Redactar copias, restringir lectura, cambiar la credencial expuesta | Seguridad / Cumplimiento |
| H-06 | Cobertura de auditoría incompleta: sin registro antes de ~10:12, solo DDL hasta 10:51, lecturas (`SELECT`) no registradas y creación de los roles no evidenciada | E1, E5 | Media | Hay periodos y acciones que no se pueden conciliar | Fijar `log_statement` desde el arranque, evaluar `pgaudit`, conservar los logs rotados (`pg_ls_logdir()`) | Seguridad / Cumplimiento |
| H-07 | Folio CAM-2026-014 autoaprobado: lo insertó `postgres` a las 11:46:36 con aprobación retroactiva (`now() - 1 día`) y ventana que empezaba 5 minutos antes, 17 segundos antes del cambio | E5 EV-6 | Media | El control de cambios lo puede escribir quien lo ejecuta | Que solo el Comité de cambios pueda escribir en `gobierno.solicitudes_cambio` | Comité de cambios |
| H-08 | Integridad de E5: mezcla de codificaciones (acentos corruptos en sentencias UTF-8), redacción que alteró las propias líneas de la exportación y bitácora autorreferencial | E5 | Media | Reduce el valor probatorio de la copia | Conservar el original en custodia cifrada, hash del original y de la copia redactada, documentar la redacción | Seguridad / Cumplimiento |
| H-09 | Documentación desactualizada o inconsistente: el CSV no incluye `canal_alta`; versión (16 / 18 / 19) inconsistente; borrador 06 con fechas y origen incorrectos; catálogo con "Pendiente" | CSV, Act. 3, 4, 6 | Baja | Decisiones basadas en información errónea | Regenerar el diccionario y corregir los documentos | Propietario del dato y DBA |
| H-10 | Fallos de autenticación (2 de `postgres`, 2 de `app_ventas`) sin bloqueo posible | E5 EV-2 | Baja | Sin bloqueo, un ataque de fuerza bruta no se frena | Monitorear fallos; evaluar `auth_delay` o bloqueo en el cliente | Seguridad / Cumplimiento |


Incluye, como mínimo: calidad de datos (Actividad 1), cambios no autorizados (Actividad 7)
y limitaciones de los controles.

## 9. Limitaciones conocidas y riesgos aceptados (A6)
| Limitación | Efecto | Quién debe aceptarla formalmente |
|---|---|---|
| MongoDB Community no tiene auditoría nativa; solo perfilado (1 MB, se sobrescribe) y bitácora de `mongod` | Operaciones de MongoDB no auditables de forma fiable | Responsable de Seguridad / TI, con conocimiento de Gerencia Comercial |
| Sin `pgaudit` y con `log_statement = mod`, las lecturas no se auditan | No se sabe quién consultó datos personales | Seguridad / Cumplimiento |
| El administrador puede desactivar la auditoría (disparador, `log_statement`, borrar archivos) | Control débil frente a quien opera la base (H-02) | Seguridad / Cumplimiento y Dirección de TI; **no el DBA** |
| El disparador no registra `TRUNCATE` ni cambios con `session_replication_role = replica` | Vacíos de la tabla de auditoría | Seguridad / Cumplimiento |
| La bitácora vive en el mismo servidor y bajo el mismo administrador | Puede alterarse antes de exportarse | Seguridad / Cumplimiento |
| `application_name` y el usuario compartido no identifican personas | Atribución limitada (H-03) | Dirección de TI |
| Periodo anterior a ~10:12 y logs rotados sin evidencia | No hay conciliación posible | Seguridad / Cumplimiento |

Un riesgo que afecta a los datos de clientes debe aceptarlo además el propietario del dato (Gerencia Comercial). El DBA, que opera estos controles, no puede aceptar riesgos sobre ellos.

## 10. Índice de evidencias
| Archivo | Descripción | SHA-256 |
|---|---|---|
| `E1-configuracion-registro.txt` | Parámetros de registro | `312b3a1dfcb037a1f10c34a2e30e435d2ba4012f009065135bf4196c854e72b1` |
| `E2-privilegios.txt` | Privilegios por tabla | `6465817a559efade74e1e4c9d89cac55658180322244076315998f8c6e897b23` |
| `E3-disparadores.txt` | Estado del disparador | `594919242861aa57a2bfb96c70597f378eb4092c71fa72968b769ce199268817` |
| `E4-muestra-auditoria.txt` | Últimos 10 eventos de auditoría | `a4db9fcf3e4e2e32c363ce261ac1288c2db6fa15c990823ae050f06f6e4b9d19` |
| `E5-bitacora-postgresql.log` | Bitácora exportada y redactada | `885d811d03c89023b900d66133e29d4bb78cf1ddd5afa863247608066289ec30` |
| `E5-bitacora-postgresql.sha256` | Manifiesto de hashes | **No recibido**; comparar con el hash de arriba |
| `E6` (MongoDB) y logs rotados | Pendientes | — |
| `diccionario-clientes.csv` | Diccionario de `clientes` | `caf55b638399008580df047678cd3f16b813d5cdc9ca4d00e6ea654bba8b9415` |
| `01-calidad.md` | Actividad 1 | `43fe06ad5839c16894f8314bb1df2bbf84aa4f5c4cf564e3cad524843008aca5` |
| `02-responsables.md` | Actividad 2 | `cd88129e1a780f8b9e964f009778da1e7f6aed487853d475c2877aa8e9ef21ce` |
| `03-diccionario.md` | Actividad 3 | `c2d76f04c136b6373eb836f5ff3cf999b8ef5fc627fcbe98cf54f19eda800bfd` |
| `04-catalogo.md` | Actividad 4 | `0be30508a2674d28c0b0ec31e2332ce9b246075868b3e3802f33f9b8c6ff5796` |
| `05-conservacion.md` | Actividad 5 | `2fcadb76c6dd00f554cf129fa5e5264307309fcc78755af2c89def812ce61dfa` |
| `06-conciliacion.md` | Actividad 6 (a corregir, ver sección 7) | `f416cc2c3172b1922c4a02dd5e8bfe12f31a3ff3525124109c3674fff3e729c6` |

Los hashes de los `.md` cambiarán cuando se corrijan los documentos (H-09); recalcularlos al final con `Get-FileHash`.