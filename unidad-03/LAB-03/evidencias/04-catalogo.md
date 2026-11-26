# Actividad 4 — Catálogo mínimo de datos

## Preguntas


### ¿Por qué CAT-02 y CAT-05 contienen datos personales aunque su propósito sea la auditoría?
Porque la auditoría registra lo que ocurre con los datos, y para eso copia los datos mismos. `auditoria.cambios_clientes` guarda el valor anterior y el nuevo de cada columna (nombre, correo, RFC, teléfono, etc.), así que es en la práctica una segunda copia de `clientes`, incluso con datos que ya fueron corregidos o eliminados de la tabla original. `system.profile` de MongoDB guarda el texto de las operaciones, y estas pueden incluir valores de clientes en los filtros (por ejemplo, `{ rfc: "LOAA850315AB" }`). Lo que importa para clasificar un dato es su contenido, no su propósito. Por eso heredan la clasificación (confidencial), el acceso restringido y los plazos de retención del dato que registran.

### ¿Qué pasa si CAT-01 y CAT-04 tienen propietarios distintos y el RFC de un cliente difiere entre ambos motores?
Nadie puede decidir cuál es el valor correcto. Cada propietario defendería su copia, y el DBA, que solo es custodio, no debe elegir por su cuenta. El resultado es una inconsistencia que se propaga: facturación puede emitir con un RFC y la tienda atender con otro, con riesgo fiscal y de calidad de datos. Además, una corrección en un motor no llega al otro. Lo adecuado es definir un **único propietario** para el dato (o una fuente de verdad designada), que decida el valor correcto con apoyo del cliente, y que el DBA aplique la corrección en ambos motores con solicitud formal y evidencia.

### ¿Qué información del catálogo cambia con más frecuencia y quién debe actualizarla?
- **Propietario y custodio:** cambian con reorganizaciones, rotación de personal o nuevos roles. Lo actualiza el responsable de gobierno de datos, con confirmación del área involucrada.
- **Conservación y finalidad:** cambian cuando se modifican leyes, políticas o procesos. Las actualiza el propietario del dato, con apoyo del área legal o de cumplimiento.
- **Ubicación y motor:** cambian con migraciones, nuevas versiones o nuevos servidores. Las actualiza el custodio (DBA), porque es quien conoce la infraestructura.
- **Diccionario:** cambia cada vez que se modifica la estructura (por ejemplo, al agregar `segmento`). Lo regenera el DBA, y el propietario valida que el significado sea correcto.




## Tabla
| ID | Conjunto de datos | Motor | Ubicación | Propietario | Custodio | Clasificación | Contiene datos personales | Finalidad | Conservación | Diccionario |
|---|---|---|---|---|---|---|---|---|---|---|
| CAT-01 | Clientes | PostgreSQL 16 | `<servidor-pg>` / `comercial` / `public.clientes` | Gerencia Comercial | DBA | Confidencial | Sí | Gestionar la relación comercial, facturación y análisis de clientes | 5 años desde `fecha_alta` | `diccionario-clientes.csv` |
| CAT-02 | Auditoría de clientes | PostgreSQL 16 | `<servidor-pg>` / `comercial` / `auditoria.cambios_clientes` | Seguridad / Cumplimiento | DBA | Confidencial | Sí (copia de valores anteriores y nuevos) | Evidencia de quién cambió qué y cuándo en `clientes` | 5 años (igual que el dato auditado) | Pendiente |
| CAT-03 | Registro de cambios | PostgreSQL 16 | `<servidor-pg>` / `comercial` / `gobierno.solicitudes_cambio` | Seguridad / Cumplimiento | DBA | Interna | No (solo referencias a registros) | Trazar solicitudes y aprobaciones de correcciones y accesos | 5 años | Pendiente |
| CAT-04 | Clientes (tienda) | MongoDB 7 | `<servidor-mongo>` / `comercial` / `clientes` | Gerencia Comercial | DBA | Confidencial | Sí | Consulta de clientes por la tienda y sus aplicaciones | 5 años desde el alta | Pendiente |
| CAT-05 | Perfilado | MongoDB 7 | `<servidor-mongo>` / `comercial` / `system.profile` | TI / Seguridad | DBA | Confidencial | Posible (las consultas pueden incluir valores de clientes) | Diagnóstico de rendimiento y revisión de operaciones | Corta (por ejemplo, 30 días) y luego se rota | Pendiente |