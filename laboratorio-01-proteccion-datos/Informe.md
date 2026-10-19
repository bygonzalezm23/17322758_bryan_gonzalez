##  Actividad 1 — Clasificación de los datos

| Campo | ¿Identifica directamente? | ¿Puede contribuir a identificar? | ¿Requiere protección? | Justificación |
|---|---|---|---|---|
| `id` | No (indirectamente sí, si se vincula con otras tablas) | Sí | Sí (moderada) | Es un identificador interno; por sí solo no dice quién es, pero permite enlazar el registro con pedidos, pagos y otras tablas, y rastrear a una persona. |
| `nombre` | Sí | Sí | Sí | Es un dato personal básico; identifica a la persona, sobre todo combinado con otros campos. |
| `correo` | Sí | Sí | Sí | Suele ser único por persona y contiene a menudo el nombre. Sirve para contactar y para suplantar identidad o hacer phishing. |
| `telefono` | Sí | Sí | Sí | Es único y está asociado a una persona; permite contacto directo, fraude y ataques de ingeniería social. |
| `rfc` | Sí | Sí | Sí (alta) | Identificador fiscal oficial; con homoclave está ligado a una persona específica y es muy sensible por su uso en trámites y fraude fiscal. |
| `edad` | No | Sí | Sí (baja/moderada) | Por sí sola no identifica, pero combinada con ciudad, código postal y otros datos reduce mucho el grupo de personas posibles. |
| `ciudad` | No | Sí | Sí (baja) | Dato de ubicación general; es un cuasi-identificador que, junto con edad o código postal, ayuda a reidentificar. |
| `codigo_postal` | No | Sí | Sí (moderada) | Ubicación más precisa que la ciudad; es un cuasi-identificador clásico para reidentificar personas en conjuntos "anonimizados". |
| `fecha_alta` | No | Sí (limitado) | Sí (baja) | Es un dato de comportamiento; por sí sola no identifica, pero combinada con otros campos o registros externos puede ayudar a correlacionar a una persona. |

### Conclusión

- **Identificadores directos:** `nombre`, `correo`, `telefono`, `rfc`. Apuntan a una persona por sí solos y requieren controles fuertes (cifrado, enmascaramiento, acceso restringido).
- **Cuasi-identificadores:** `edad`, `ciudad`, `codigo_postal`, `fecha_alta` (y `id` en cierta medida). Individualmente no identifican, pero combinados pueden reidentificar a alguien. Requieren controles como generalización (rangos de edad, solo los primeros dígitos del código postal) o minimización.
- Todos los campos requieren algún nivel de protección, aunque con distinta intensidad.


## Preguntas de análisis

### 1. ¿Qué campos identifican directamente a una persona?

`nombre`, `correo`, `telefono` y `rfc`. Cada uno apunta a una persona específica sin necesidad de otra información.

### 2. ¿Qué campos no identifican por sí solos pero podrían contribuir a hacerlo?

`edad`, `ciudad`, `codigo_postal` y `fecha_alta` (y `id`, si se vincula con otras tablas). Son cuasi-identificadores: cada uno reduce el grupo de personas posibles y, combinados con otros datos, pueden identificar a alguien.

### 3. ¿Qué combinación de campos podría incrementar el riesgo de reidentificación?

`edad` + `codigo_postal` + `ciudad`, o `edad` + `codigo_postal` + `fecha_alta`, ya que pueden dejar a una sola persona como coincidencia. También cualquier combinación con datos externos (redes sociales, directorios, filtraciones). Se mitiga generalizando, minimizando datos y restringiendo el acceso.

### 4. ¿Todos los datos que deben protegerse son necesariamente datos personales sensibles desde el punto de vista jurídico?

No. Todos los datos personales deben protegerse, pero solo una categoría específica es sensible (salud, origen étnico, religión, preferencia sexual, etc.). En `clientes` los campos son datos personales, pero ninguno es sensible en sentido jurídico; el `rfc` tiene alto riesgo de fraude y merece controles fuertes aunque no sea legalmente sensible.


## Actividad 2 - Enmascaramiento

## Preguntas

### 1. ¿Qué información continúa existiendo en la tabla original?

Todos los datos completos y sin modificar. La vista no copia ni altera datos, solo los enmascara al consultarlos.

### 2. ¿Qué información puede visualizar el usuario `soporte`?

Solo lo que expone la vista: `id` y `nombre` completos, y `correo`, `telefono` y `rfc` parcialmente ocultos. No ve `edad`, `ciudad`, `codigo_postal` ni `fecha_alta`, y no puede consultar `clientes`.

### 3. ¿Por qué no es suficiente ocultar los datos únicamente en la aplicación?

Porque un usuario con credenciales puede conectarse con otra herramienta (psql, pgAdmin) y ver los datos reales. La protección debe estar en la base de datos.

### 4. ¿Qué ocurriría si `soporte` tuviera acceso directo a `clientes`?

Podría ver correo, teléfono y RFC completos, anulando el enmascaramiento y violando el mínimo privilegio.

## Actividad 4 — Separación de funciones

### 1. ¿Qué ocurriría si `analista` pudiera consultar también `pii.mapa_cliente`?

Podría relacionar cada token con la identidad real del cliente, anulando la seudonimización.

### 2. ¿Qué principio de seguridad se está aplicando al separar ambos accesos?

Mínimo privilegio y separación de funciones: `analista` solo accede a lo que necesita para su trabajo.

### 3. ¿Por qué la seudonimización no equivale a anonimización?

Porque es reversible: existe un mapa que permite volver a relacionar el token con la persona, por lo que los datos siguen siendo personales.

### 4. ¿Qué información permite volver a relacionar el token con una persona?

La tabla `pii.mapa_cliente`, que guarda la correspondencia entre el token y el identificador real.

##  Actividad 6 — Análisis del riesgo de reidentificación

### 1. ¿Qué identificadores directos fueron eliminados?

`nombre`, `correo`, `telefono`, `rfc` e `id`.

### 2. ¿Qué cuasi-identificadores permanecen?

`rango_edad` y `region`. En la tabla original también `ciudad` y `fecha_alta`.

### 3. ¿Qué combinaciones de atributos podrían reducir el anonimato?

`rango_edad` + `region`, y más aún si se agregan `ciudad`, `fecha_alta` o datos externos.

### 4. ¿Qué sucede cuando un grupo contiene pocos registros?

Sus integrantes son fáciles de distinguir y alguien que los conozca podría identificarlos.

### 5. ¿Qué atributos deberían generalizarse?

`edad` (rangos), `codigo_postal` (primeros dígitos), `ciudad` (zona o estado) y `fecha_alta` (solo año).

### 6. ¿Qué información debería suprimirse?

Los identificadores directos y los grupos con menos de cinco registros.

### 7. ¿Es correcto afirmar que el conjunto de datos es "100 % anónimo"? ¿Por qué?

No. k = 5 reduce el riesgo, pero no lo elimina: los cuasi-identificadores restantes, combinados con información externa, pueden reidentificar a alguien.

## Actividad 7 — Retención de datos

### Qué registros serían afectados

Los clientes con `fecha_alta` anterior a hoy menos cinco años. En esta ejecución no hay ninguno. Antes de eliminar, se deben contar los registros y confirmar que no tengan adeudos, litigios ni contratos vigentes.

### Justificación del periodo

Los datos personales solo deben conservarse mientras sean necesarios (LFPDPPP). Cinco años coincide con el plazo habitual de conservación fiscal y contable en México, y menos datos almacenados reducen el impacto de una fuga.

### Aprobación antes de eliminar

Autorización del responsable de datos personales, del área jurídica o de cumplimiento y del administrador de la base de datos, registrada en una solicitud formal.

### Respaldo

Un respaldo completo de la base (por ejemplo, con `pg_dump`), cifrado, con acceso restringido y con la restauración probada.

### Evidencia a conservar

La consulta ejecutada, el número de registros afectados, quién aprobó y cuándo, el usuario que ejecutó la eliminación y el respaldo asociado, sin guardar los datos eliminados.

### Procedimiento de recuperación

1. Detener modificaciones sobre la tabla afectada.
2. Restaurar el respaldo anterior a la eliminación en un entorno temporal.
3. Extraer solo los registros eliminados por error.
4. Reinsertarlos en la tabla original y validar cantidad e integridad.



### 1. Clasificación

Todos los campos de `clientes` requieren protección, con distinta intensidad. Los identificadores directos (`nombre`, `correo`, `telefono`, `rfc`) identifican a una persona por sí solos; el `rfc` es el más delicado por el riesgo de fraude. Los cuasi-identificadores (`edad`, `ciudad`, `codigo_postal`, `fecha_alta`) pueden reidentificar a alguien al combinarse. Son datos personales, pero ninguno es sensible en sentido jurídico.

### 2. Enmascaramiento

- **Qué se ocultó:** parte del correo, del teléfono y del RFC.
- **Para quién:** el rol `soporte`.
- **Por qué:** necesita atender clientes sin ver los valores completos (mínimo privilegio).
- **Mecanismo:** la vista `v_clientes_soporte` con `LEFT`, `RIGHT`, `SUBSTRING` y `CONCAT`, `SELECT` solo sobre la vista y `REVOKE ALL` sobre `clientes`.

### 3. Seudonimización

- **Tokens:** los identificadores reales se reemplazaron por un token sin relación evidente con la persona (indica el método que usaste, por ejemplo `gen_random_uuid()`).
- **Mapa de correspondencia:** `pii.mapa_cliente`, separado del esquema `analitica`.
- **Quién accede:** solo el administrador o el responsable de protección de datos.
- **Por qué se separaron los permisos:** quien tenga datos y mapa juntos puede revertir el proceso.

### 4. Anonimización

- **Identificadores eliminados:** `nombre`, `correo`, `telefono`, `rfc` e `id`.
- **Atributos generalizados:** edad en rangos y código postal en región.
- **Grupos suprimidos:** los de menos de cinco registros (`HAVING COUNT(*) >= 5`).
- **Riesgo que permanece:** los cuasi-identificadores restantes, combinados con información externa, pueden reidentificar.

### 5. Retención

- **Criterio:** cinco años desde `fecha_alta` (limitación del plazo, LFPDPPP). La consulta devolvió 0 registros.
- **Conservar:** datos con menos de cinco años y los que tengan obligación legal o contractual.
- **Eliminar:** registros con más de cinco años sin esas obligaciones.
- **Controles previos:** autorización formal, respaldo cifrado y probado, transacción, evidencia y plan de recuperación.

### 6.Conclusiones

- **Soporte:** enmascaramiento.
- **Analítica:** seudonimización.
- **Publicar estadísticas:** anonimización.
- **Por qué no sustituyen al control de acceso:** los datos originales y el mapa siguen existiendo; el control de acceso decide quién llega a ellos.

##  Preguntas de reflexión

1. El enmascaramiento oculta parte del dato al mostrarlo; la seudonimización lo reemplaza por un token con un mapa reversible.
2. Es reversible mediante el mapa, así que los datos siguen siendo personales.
3. Quedan cuasi-identificadores que, combinados con otros datos, pueden reidentificar.
4. Reducen el grupo de personas posibles y, combinados, permiten distinguir a un individuo.
5. Quien tenga datos y mapa juntos puede revertir la seudonimización.
6. Mínimo privilegio y separación de funciones.
7. La vista expone solo las columnas necesarias y ya enmascaradas.
8. Lo primero reduce lo que se ve; lo segundo impide llegar al dato.
9. Los datos solo deben conservarse mientras sean necesarios; lo que no existe no puede filtrarse.
10. Aumenta el impacto de una fuga e incumple la minimización y la normativa.