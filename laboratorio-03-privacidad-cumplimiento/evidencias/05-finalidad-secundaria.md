## Actividad 5 — Analizar una finalidad secundaria

### ¿El hecho de que la organización ya tenga los datos significa automáticamente que puede utilizarlos para cualquier finalidad?
No. Los datos solo deben usarse para las finalidades informadas en el aviso de privacidad y por las que se recabaron (principio de finalidad).

### ¿Qué preguntas debería realizar la organización antes de implementar este tratamiento?
- ¿La finalidad está prevista en el aviso de privacidad? ¿Se necesita nuevo consentimiento?
- ¿Es compatible con la finalidad original?
- ¿Qué datos se necesitan realmente y por cuánto tiempo?
- ¿Quién tendrá acceso y con qué controles?
- ¿Los titulares pueden negarse o revocar su consentimiento?
- ¿Cuál es el riesgo para los titulares si los datos se filtran o se usan mal?

### ¿Qué datos serían realmente necesarios?
Un identificador o medio de contacto (`id` o `correo`), la edad en rangos, la ciudad y el historial de compra.

### ¿Necesitaría el área de marketing acceso directo a clientes?
No. Bastaría con una vista con los campos mínimos, solo de clientes que aceptaron recibir promociones, y con el correo accesible únicamente para el envío.

### ¿Qué controles técnicos podrían limitar la información entregada?
- Un rol `marketing` sin acceso a `clientes`, con `SELECT` solo sobre una vista.
- Vista con edad en rangos y sin `rfc`, `telefono` ni `nombre` completo si no son necesarios.
- Filtro por consentimiento, por ejemplo una columna `acepta_promociones = true`.
- Enmascaramiento o seudonimización, de modo que el envío lo haga la plataforma de correo sin exponer los datos al analista.
- Registro de accesos (auditoría) y plazo de retención definido.

## Actividad 6 — Derechos ARCO y la base de datos

### ¿Qué información adicional debería proporcionar la organización además del resultado de esta consulta?

- **Finalidades del tratamiento:** para qué se usan sus datos (atención, facturación, analítica, marketing).
- **Origen de los datos:** si los proporcionó el titular o se obtuvieron de otra fuente.
- **Destinatarios:** a qué áreas, proveedores o terceros se comunican o transfieren.
- **Plazo de conservación:** cuánto tiempo se guardarán (por ejemplo, cinco años desde `fecha_alta`).
- **Otros lugares donde existen sus datos:** tablas relacionadas (pedidos, pagos), vistas, el mapa `pii.mapa_cliente`, esquema `analitica` y respaldos.
- **Aviso de privacidad vigente** y cómo ejercer los demás derechos (rectificación, cancelación y oposición).

### Implicaciones técnicas

- **Verificar la identidad** del solicitante antes de entregar datos, para no exponer información a un tercero.
- **Localizar todos los datos del titular**, no solo los de `clientes`: usar el `id` o el token para buscar en otras tablas y esquemas.
- **Entregar solo los datos de ese titular**, sin incluir información de otras personas.
- **Entregar en formato legible** (por ejemplo, CSV o PDF) y por un canal seguro.
- **Registrar la solicitud** y la respuesta como evidencia (fecha, quién atendió, qué se entregó).
- **Ejecutar con un rol de privilegio limitado** y con aprobación del área de privacidad, no con acceso libre a la tabla.
- Si el RFC está cifrado, descifrarlo solo para esta entrega, sin exponer la clave.

## Actividad 7 — Derecho de rectificación

### ¿Cómo podría comprobarse que el cambio fue autorizado?
Con una solicitud formal del titular (ticket o formulario) y verificación de su identidad antes de modificar nada. La solicitud debe quedar vinculada al cambio, con el nombre de quien lo aprobó y la fecha.

### ¿Debería registrarse quién realizó el cambio?
Sí. Debe quedar registrado el usuario que ejecutó el `UPDATE`, la fecha y hora, el registro afectado (`id`), el campo modificado y el valor anterior y el nuevo. Puede hacerse con una tabla de auditoría o un trigger.

### ¿Por qué la trazabilidad será importante?

**Detalle técnico:** el correo corregido debe actualizarse también en otros lugares donde exista (tablas relacionadas, esquema `analitica`, `pii.mapa_cliente`), y se debe ejecutar el `UPDATE` dentro de una transacción con `WHERE id = 1` para no afectar otros registros.