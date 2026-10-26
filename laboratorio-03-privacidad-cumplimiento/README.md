# Laboratorio 03 — Privacidad y cumplimiento



## Introducción

La organización almacena datos personales de sus clientes en la tabla `clientes` (nombre, correo, teléfono, RFC, edad, ciudad, código postal y fecha de alta). El problema de privacidad es que estos datos pueden quedar expuestos o usarse de forma indebida si no se controlan bien: acceso excesivo del personal, uso para finalidades no informadas (como marketing), copias en desarrollo, conservación sin límite de tiempo y falta de documentación.


---

## Inventario de datos

Se identificaron los campos de `clientes`, si son datos personales, su finalidad, necesidad, nivel de acceso y retención.

| Campo | ¿Dato personal? | Finalidad | ¿Necesario? | Nivel de acceso | Retención |
|---|---|---|---|---|---|
| `id` | Sí (indirecto) | Enlazar el registro con otras tablas | Sí | Restringido: administración y sistemas autorizados | Mientras exista el cliente |
| `nombre` | Sí | Identificar y atender al cliente | Sí | Soporte y administración | 5 años desde `fecha_alta` |
| `correo` | Sí | Contacto y notificaciones | Sí | Soporte (enmascarado) y administración | 5 años desde `fecha_alta` |
| `telefono` | Sí | Contacto directo y atención | Sí | Soporte (enmascarado) y administración | 5 años desde `fecha_alta` |
| `rfc` | Sí | Facturación y obligaciones fiscales | Solo si se factura | Muy restringido: administración y fiscal; cifrado | 5 años (plazo fiscal) |
| `edad` | Sí (cuasi-identificador) | Análisis y segmentación | Opcional | Analítica, en rangos | 5 años desde `fecha_alta` |
| `ciudad` | Sí (cuasi-identificador) | Análisis geográfico y logística | Opcional | Analítica, en zona o estado | 5 años desde `fecha_alta` |
| `codigo_postal` | Sí (cuasi-identificador) | Envíos y análisis regional | Sí si hay envíos; si no, opcional | Analítica, solo primeros dígitos | 5 años desde `fecha_alta` |
| `fecha_alta` | Sí (cuasi-identificador) | Antigüedad y cálculo de retención | Sí | Administración y analítica (solo año) | 5 años; define la retención |

**Clasificación:**

- **Identificadores directos:** `nombre`, `correo`, `telefono`, `rfc`.
- **Identificador indirecto:** `id`.
- **Cuasi-identificadores:** `edad`, `ciudad`, `codigo_postal`, `fecha_alta`. Por sí solos no identifican, pero combinados pueden reidentificar a una persona.

---

## Finalidades

Los datos solo deben usarse para las finalidades informadas en el aviso de privacidad y por las que se recabaron (principio de finalidad). Que la organización ya tenga los datos no significa que pueda usarlos para cualquier fin.

- **Atención al cliente:** `nombre`, `correo`, `telefono`.
- **Facturación y obligaciones fiscales:** `rfc`, `nombre`.
- **Analítica y segmentación:** `edad` (en rangos), `ciudad`, `codigo_postal` (generalizado).
- **Logística y envíos:** `codigo_postal`, `ciudad`.
- **Control de antigüedad y retención:** `fecha_alta`.
- **Marketing (finalidad secundaria):** solo con consentimiento verificado (`acepta_promociones = true`).

Antes de implementar una finalidad secundaria, la organización debe preguntarse:

- ¿Está prevista en el aviso de privacidad? ¿Se requiere nuevo consentimiento?
- ¿Es compatible con la finalidad original?
- ¿Qué datos se necesitan realmente y por cuánto tiempo?
- ¿Quién tendrá acceso y con qué controles?
- ¿Los titulares pueden negarse o revocar su consentimiento?
- ¿Qué riesgo corren los titulares si los datos se filtran o se usan mal?

Para marketing bastarían un identificador o correo, edad en rangos, ciudad e historial de compra, mediante una vista con campos mínimos, solo de clientes que aceptaron promociones.

---

## Minimización


**Atención al cliente (soporte):**

- No necesita `rfc`, salvo para movimientos de facturación.
- No necesita `edad`, porque las solicitudes importantes las realizan clientes mayores de edad.
- El `codigo_postal` solo sería útil para ubicar mejor una dirección difícil de localizar.

**Analítica:**

- Obtiene los patrones que necesita sin ver `nombre`, `correo`, `telefono` ni `rfc`, y sin poder señalar a una persona concreta.
- La edad se generaliza en rangos y la ubicación en zona o estado.

**Diseño de la tabla (privacidad por diseño).** Se detectaron datos que deberían eliminarse: `salario`, `estado_civil`, `ocupacion`, `fecha_nacimiento` (o `edad`, no ambos) y `direccion`. Además:

- `edad` y `fecha_nacimiento` son datos duplicados.
- No hay llave primaria, restricciones ni tipos adecuados (todo es `TEXT`).
- Faltan cifrado del RFC, retención y control de acceso.

Datos que requieren justificación adicional: `rfc` (solo si se factura), `direccion` y `codigo_postal` (solo si hay envíos), `telefono` (si es canal necesario), `edad` (si hay finalidad analítica o legal). `salario` y `estado_civil` casi nunca se justifican.

**Privacidad por defecto:** recolectar solo campos mínimos, dejar opcionales los demás, desactivar el uso secundario (`acepta_promociones BOOLEAN DEFAULT false`), restringir el acceso por defecto, cifrar el RFC y definir la retención desde el diseño.

---

## Control de acceso


- **Rol de analítica:** solo puede consultar la vista `v_analitica_clientes`. No tiene privilegios sobre la tabla `clientes`, por lo que no puede obtener `nombre`, `correo` ni `rfc`. Esta vista entrega la edad en rangos.
- **Soporte:** accede a una vista enmascarada de correo y teléfono.
- **Facturación:** único rol con acceso al RFC, que está cifrado (`pgp_sym_encrypt()`).
- **Marketing:** rol `marketing` sin acceso a `clientes`, con `SELECT` solo sobre una vista filtrada por consentimiento, sin `rfc`, `telefono` ni nombre completo.
- **Auditor:** solo lectura sobre la bitácora.

**Principios aplicados:**

- **Privacidad:** minimización de datos y finalidad.
- **Seguridad:** privilegio mínimo.

**Controles técnicos y administrativos:**

| Medida | Técnico | Administrativo |
|---|---|---|
| Crear roles de PostgreSQL | X | |
| Política de retención | | X |
| Cifrado de datos | X | |
| Procedimiento para solicitudes ARCO | | X |
| Vista con información limitada | X | |
| Clasificación de información | | X |
| Registro de auditoría | X (bitácoras, triggers, logs) | X (qué se registra, quién revisa, cada cuánto) |
| Política de control de acceso | X (roles, `GRANT`, `REVOKE`) | X (quién accede a qué y con qué aprobación) |

---

## Derechos ARCO

### Acceso

Además del resultado de la consulta, la organización debe informar: finalidades, origen de los datos, destinatarios, plazo de conservación, otros lugares donde existen los datos (tablas relacionadas, vistas, `pii.mapa_cliente`, esquema `analitica`, respaldos) y el aviso de privacidad vigente con la forma de ejercer los demás derechos.

Implicaciones técnicas:

- Verificar la identidad del solicitante antes de entregar datos.
- Localizar todos los datos del titular (no solo `clientes`), usando el `id` o el token.
- Entregar solo los datos de ese titular, en formato legible (CSV o PDF) y por un canal seguro.
- Registrar la solicitud y la respuesta como evidencia.
- Ejecutar con un rol de privilegio limitado y con aprobación del área de privacidad.
- Si el RFC está cifrado, descifrarlo solo para la entrega, sin exponer la clave.

### Rectificación

- Se comprueba la autorización con una solicitud formal (ticket o formulario) y verificación de identidad, vinculada al cambio, con el nombre de quien lo aprobó y la fecha.
- Debe registrarse quién hizo el `UPDATE`, fecha y hora, `id` afectado, campo modificado, valor anterior y nuevo (tabla de auditoría o trigger).
- El cambio debe replicarse en todos los lugares donde exista el dato (tablas relacionadas, esquema `analitica`, `pii.mapa_cliente`).
- El `UPDATE` se ejecuta en una transacción con `WHERE id = ...` para no afectar otros registros.

### Cancelación

Eliminar un registro de `clientes` no significa que la información haya desaparecido: los datos están en tablas relacionadas, copias analíticas, respaldos, réplicas, bitácoras, reportes, archivos exportados y sistemas de terceros. Un `DELETE` solo afecta a la tabla donde se ejecuta; el resto debe localizarse y tratarse por separado.

### Oposición

- **Se mantiene:** `nombre`, `rfc` y registros de compras o facturas (plazo fiscal), además de un registro de la oposición para respetar la decisión.
- **Deja de usarse para esa finalidad:** `correo`, `edad`, `ciudad` y comportamiento de compra para promociones personalizadas.
- **Mecanismos técnicos:** columna o tabla de preferencias (`acepta_promociones = false`), vistas por finalidad que excluyan a quienes se opusieron, roles con acceso solo a la vista de su finalidad y exclusión del titular en listas y sistemas externos.


---

## Retención

La conservación indefinida (o "por si acaso") no es compatible con la minimización: se debe conservar solo lo necesario para una finalidad definida y solo mientras dure.

**Riesgos de conservar información innecesaria:**

- Mayor impacto en caso de fuga o acceso indebido.
- Incumplimiento de la LFPDPPP.
- Datos desactualizados o inexactos que se siguen usando.
- Más costos de almacenamiento, respaldo y administración.
- Mayor dificultad para atender solicitudes ARCO, por haber más copias.

**Cómo determinar el periodo.** Antes de fijarlo, la organización debe definir:

- La finalidad de cada dato y cuánto tiempo es necesario.
- Las obligaciones legales, fiscales o contractuales de conservación.
- Posibles litigios o requerimientos de autoridad.
- Qué ocurre al terminar el plazo: eliminación, bloqueo o anonimización.

**Qué documentar para justificarlo:**

- Finalidad y base legal o normativa del plazo.
- Periodo por categoría de dato y momento desde el que se cuenta (por ejemplo, `fecha_alta`).
- Quién lo aprobó y cuándo.
- Procedimiento al vencer el plazo y excepciones.
- Fecha de la próxima revisión de la política.

---

##  Gobierno de datos

Matriz de responsabilidades de la tabla `clientes`:

| Dato | Finalidad | Responsable | Usuarios autorizados | Protección | Retención | Acción al finalizar |
|---|---|---|---|---|---|---|
| `nombre` | Identificar y atender al cliente | Atención al cliente | Atención al cliente, Facturación, DBA | Control de acceso por roles | 5 años desde `fecha_alta` | Eliminar o anonimizar |
| `correo` | Contacto y notificaciones | Atención al cliente | Atención al cliente (enmascarado), Facturación, DBA | Enmascaramiento en vistas y control de acceso | 5 años desde `fecha_alta` | Eliminar |
| `telefono` | Contacto directo y atención | Atención al cliente | Atención al cliente (enmascarado), DBA | Enmascaramiento en vistas y control de acceso | 5 años desde `fecha_alta` | Eliminar |
| `rfc` | Facturación y obligaciones fiscales | Facturación | Facturación, DBA | Cifrado (`pgp_sym_encrypt()`), acceso muy restringido y enmascaramiento | 5 años (plazo fiscal) | Eliminar de forma segura, previa aprobación y respaldo |
| `edad` | Análisis y segmentación | Analítica | Analítica (en rangos), Dirección (agregados), DBA | Generalización en rangos y vista de analítica | 5 años desde `fecha_alta` | Anonimizar (conservar solo rangos agregados) |
| `ciudad` | Análisis geográfico y logística | Analítica | Analítica, Dirección (agregados), DBA | Generalización (zona o estado) y vista de analítica | 5 años desde `fecha_alta` | Anonimizar o eliminar |
| `codigo_postal` | Envíos y análisis regional | Analítica | Analítica (solo primeros dígitos), DBA | Generalización y supresión de grupos pequeños | 5 años desde `fecha_alta` | Eliminar o conservar solo la región |

---

## Evaluación integral

Principales riesgos encontrados en el escenario integral:

| # | Problema | Principio afectado | Riesgo | Control propuesto |
|---|---|---|---|---|
| 1 | Todo el personal de analítica consulta directamente `clientes` | Mínimo privilegio | Acceso innecesario a nombre, correo, teléfono y RFC; fuga o abuso interno | Rol `analista` con acceso solo a una vista agregada o seudonimizada; `REVOKE` sobre `clientes` |
| 2 | Analítica solo genera estadísticas pero ve datos identificables | Minimización | Exposición de datos que no necesita | Datos anonimizados o agregados (rangos, región, supresión de grupos pequeños) |
| 3 | Datos conservados 12 años | Limitación del plazo de conservación | Mayor impacto de fuga e incumplimiento de la LFPDPPP | Definir plazo (ej. 5 años), identificar registros vencidos y eliminar o anonimizar con aprobación |
| 4 | No existe política de retención documentada | Responsabilidad proactiva | No se puede justificar la conservación ni demostrar cumplimiento ante auditoría | Elaborar y aprobar una política de retención con plazos, responsables y acciones al finalizar |
| 5 | Desarrolladores reciben copias completas con datos reales | Confidencialidad y mínimo privilegio | Fuga desde entornos con menos controles | Datos sintéticos o enmascarados en desarrollo; prohibir copias de producción |
| 6 | Desarrollo sin protección equivalente a producción | Seguridad | Copias sin cifrado ni auditoría, difíciles de rastrear y eliminar | Cifrar copias, restringir acceso, registrar entregas y eliminarlas al terminar |
| 7 | Marketing usa correos sin finalidad documentada ni consentimiento verificado | Finalidad y consentimiento | Uso para finalidad no informada; sanciones | Revisar aviso de privacidad, registrar consentimiento (`acepta_promociones`), vista de marketing filtrada |
| 8 | No hay documentación de la finalidad de cada dato | Finalidad y transparencia | No se puede justificar el tratamiento | Matriz de gobierno de datos |
| 9 | RFC y otros datos en texto claro para todos con acceso | Seguridad (confidencialidad) | Fraude fiscal, suplantación de identidad y robo | Cifrado del RFC (`pgp_sym_encrypt()`), enmascaramiento y acceso restringido a facturación |
| 10 | No hay clasificación de información ni niveles de acceso | Responsabilidad y mínimo privilegio | Todos los datos se tratan igual, sin controles proporcionales al riesgo | Clasificar campos (identificadores directos, cuasi-identificadores) y asignar controles por nivel |

### Arquitectura propuesta: separación por finalidad

| Aspecto | Operación | Analítica | Auditoría |
|---|---|---|---|
| Datos | id, nombre, correo, teléfono, RFC cifrado, fecha_alta | Agregados: rangos de edad, región, grupos de 5 o más registros | Bitácora: quién, qué, cuándo y sobre qué registro |
| Acceso | soporte: vista enmascarada; facturación: RFC | analista: solo vista agregada | auditor: solo lectura |
| Minimización | sin salario, estado civil ni ocupación | sin nombre, correo ni RFC; edad en rangos | sin copiar datos personales completos |
| Protección | RFC cifrado, TLS, claves fuera de scripts | datos generalizados y enmascarados | solo lectura, sin borrado de bitácoras |
| Retención | 5 años desde `fecha_alta` | según política aprobada | plazo propio definido |
| Trazabilidad | cambios y accesos registrados en Auditoría | consultas registradas en Auditoría | registro inmutable |
| Eliminación | respaldo previo, borrado y depuración de copias y externos | se regenera sin el titular | evidencia conservada sin datos eliminados |
| Solicitudes ARCO | acceso, rectificación, cancelación, oposición | excluir al titular que se opuso | guarda evidencia de cada solicitud |

---

## Conclusiones

Aprendí que la privacidad, la seguridad y la administración de bases de datos están estrechamente relacionadas, pero no son lo mismo. La **seguridad** protege los datos contra accesos no autorizados (cifrado, roles, auditoría). La **privacidad** decide qué datos se recolectan, para qué, quién los usa y por cuánto tiempo. La **administración de la base de datos** es el medio técnico que hace posible ambas: roles, vistas, cifrado, triggers, respaldos y procesos de eliminación.

También aprendí que:

- Un dato no se debe usar solo porque ya esté disponible: debe existir una finalidad informada.
- Entregar menos datos (vistas, rangos, enmascaramiento) reduce el impacto de cualquier fuga.
- Los derechos ARCO exigen saber dónde están todos los datos de una persona, no solo en una tabla.
- La retención y la eliminación forman parte del ciclo de vida del dato.
- Los controles técnicos no bastan: necesitan controles administrativos (políticas, procedimientos, responsables) y la participación de áreas como privacidad y jurídica.
- Es mucho más fácil aplicar privacidad desde el diseño de la base de datos que corregirla después.

---

##  Preguntas de reflexión

### ¿Una base de datos técnicamente segura necesariamente cumple con todos los requisitos de privacidad?

No. Una base puede estar cifrada, con roles y auditoría, y aun así incumplir la privacidad: recolectar datos innecesarios, usarlos para finalidades no informadas, conservarlos más tiempo del debido o no poder atender solicitudes ARCO. La seguridad protege los datos; la privacidad regula si deberían existir y cómo se usan.

### ¿Por qué el principio de mínimo privilegio también contribuye a la privacidad?

Porque limita quién puede ver los datos personales. Si cada rol solo accede a lo que necesita para su función (por ejemplo, analítica solo a una vista sin nombre ni RFC), se reduce la exposición, el riesgo de abuso interno y el impacto de una fuga. Así, un control de seguridad también aplica la minimización.

### ¿Por qué el DBA no debería decidir por sí solo la finalidad del tratamiento de los datos?

Porque la finalidad implica criterios jurídicos y de negocio: qué se informó en el aviso de privacidad, qué consentimiento existe, qué se debe conservar por ley y qué usos son compatibles. Eso corresponde a privacidad, jurídica y cumplimiento. El DBA implementa técnicamente la decisión, pero no la define.

###  ¿Por qué los desarrolladores no deberían recibir automáticamente copias completas de bases de datos productivas?

Porque no necesitan datos reales de clientes para desarrollar y probar. Recibir copias completas amplía el acceso a datos personales (incluido el RFC en claro), viola el mínimo privilegio y la confidencialidad, y aumenta el riesgo de fuga. Lo adecuado es usar datos sintéticos, enmascarados o anonimizados.

###  ¿Por qué una copia utilizada para desarrollo también puede representar un riesgo de privacidad?

Porque los entornos de desarrollo suelen tener menos controles que producción: sin cifrado, sin auditoría y con más personas con acceso. Las copias son difíciles de rastrear y eliminar, pueden quedar olvidadas después de las pruebas y complican atender solicitudes ARCO (cancelación) al multiplicar los lugares donde existen los datos.

### ¿Por qué la retención debe formar parte del ciclo de vida de los datos?

Porque los datos solo deben conservarse mientras sean necesarios para su finalidad. Si la retención se define desde el diseño (por ejemplo, con `fecha_alta`), cada dato tiene un momento de eliminación, bloqueo o anonimización. Sin ella, los datos se acumulan, aumentan el impacto de una fuga, se desactualizan y generan incumplimiento normativo.

###  ¿Qué relación existe entre privacidad por diseño y diseño de bases de datos?

La privacidad por diseño se materializa en las decisiones de diseño: qué columnas existen, sus tipos y restricciones, qué datos se omiten (`salario`, `estado_civil`), qué se cifra, qué vistas y roles se crean, cómo se calcula la retención y cómo se registra el consentimiento. Es más barato y efectivo incorporarla desde el inicio que corregirla después, y debe aplicarse también por defecto (por ejemplo, `acepta_promociones DEFAULT false`).

###  ¿Qué controles técnicos implementarías para reducir el riesgo de exposición de datos personales?

- Roles de PostgreSQL con mínimo privilegio, `GRANT` y `REVOKE` sobre tablas y `SELECT` solo sobre vistas.
- Vistas por finalidad con datos mínimos, generalizados (edad en rangos) y filtradas por consentimiento.
- Cifrado del RFC (`pgp_sym_encrypt()`), TLS y claves fuera de los scripts.
- Enmascaramiento y seudonimización en vistas y entornos no productivos.
- Supresión de grupos pequeños en analítica.
- Auditoría con bitácoras y triggers, con registro inmutable.
- Datos sintéticos o enmascarados para desarrollo.
- Procesos automatizados para identificar y eliminar o anonimizar registros vencidos.

###  ¿Qué información debería conocer un DBA para responder técnicamente a una solicitud ARCO?

- Quién es el titular y su identificador (`id` o token), con la identidad ya verificada.
- Todas las tablas, esquemas, vistas, copias analíticas, mapas (`pii.mapa_cliente`), respaldos, réplicas, bitácoras y sistemas de terceros donde existen sus datos.
- Qué datos están cifrados y cómo descifrarlos de forma controlada.
- Los plazos de retención y las obligaciones legales de conservación.
- El tipo de derecho solicitado y quién aprobó la solicitud.
- Cómo registrar la evidencia (fecha, quién atendió, qué se entregó o cambió).

### ¿Qué responsabilidades deberían corresponder al DBA, al responsable de privacidad, al área jurídica y al propietario de los datos?

| Rol | Responsabilidades |
|---|---|
| **DBA** | Implementar técnicamente las decisiones: roles, vistas, cifrado, auditoría, respaldos, localización de datos, ejecución de cambios y eliminaciones con registro. |
| **Responsable de privacidad** | Definir y vigilar finalidades, aviso de privacidad, consentimiento, clasificación, políticas y procedimiento ARCO; aprobar solicitudes y evaluar riesgos. |
| **Área jurídica** | Determinar obligaciones legales, fiscales y contractuales (plazos de conservación), validar la compatibilidad de finalidades y atender litigios, autoridades y sanciones. |
| **Propietario de los datos** | Responder por los datos de su área: justificar la finalidad y necesidad de cada campo, autorizar accesos de sus usuarios, validar su calidad y participar en las decisiones de retención y eliminación. |
