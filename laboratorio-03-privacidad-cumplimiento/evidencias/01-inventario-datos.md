## `Actividad 1`
### Inventario de datos de la tabla `clientes`

| Campo | ¿Es dato personal? | Finalidad | ¿Es necesario? | Nivel de acceso | Retención |
|---|---|---|---|---|---|
| `id` | Sí (indirecto) | Identificador interno para enlazar el registro con otras tablas | Sí | Restringido: administración y sistemas autorizados | Mientras exista el registro del cliente |
| `nombre` | Sí | Identificar al cliente y atenderlo | Sí | Soporte y administración | 5 años desde `fecha_alta` |
| `correo` | Sí | Contacto y notificaciones | Sí | Soporte (enmascarado) y administración | 5 años desde `fecha_alta` |
| `telefono` | Sí | Contacto directo y atención | Sí | Soporte (enmascarado) y administración | 5 años desde `fecha_alta` |
| `rfc` | Sí | Facturación y obligaciones fiscales | Sí, solo si se factura | Muy restringido: administración y área fiscal; cifrado | 5 años (plazo fiscal) |
| `edad` | Sí (cuasi-identificador) | Análisis y segmentación | Opcional | Analítica, generalizada en rangos | 5 años desde `fecha_alta` |
| `ciudad` | Sí (cuasi-identificador) | Análisis geográfico y logística | Opcional | Analítica, generalizada en zona o estado | 5 años desde `fecha_alta` |
| `codigo_postal` | Sí (cuasi-identificador) | Envíos y análisis regional | Sí, si hay envíos; si no, opcional | Analítica, solo los primeros dígitos | 5 años desde `fecha_alta` |
| `fecha_alta` | Sí (cuasi-identificador) | Control de antigüedad y base para calcular la retención | Sí | Administración y analítica (solo año) | 5 años; es el campo que define la retención |

## `Actividad 2 — Principio de minimización`

### ¿Todos los campos son necesarios para atención al cliente?
No. `rfc , edad y codgo postal` no son necesarios para las funciones de atencion al cliente.
### ¿Por qué soporte necesitaría conocer el RFC?
No lo necesitaria en la mayoria de ocasiones. Solo seria necesario si se necesita hacer un movimiento de facturación.
### ¿Necesita conocer la edad?
No es necesario. Debido a que la mayoria de solicitudes importantes lo realizan clientes mayores de edad.
### ¿Necesita conocer el código postal?
Lo unico que se podria necesitar es para ubicar de mejor manera la direccion si dado caso es algo dificil guiarse con esa unica información.
### ¿Qué principio de privacidad está relacionado con esta decisión?

## `Actividad 3 — Separación por finalidad`

### ¿Por qué esta información puede ser más apropiada para analítica que entregar directamente la tabla completa de clientes?
Analítica obtiene lo que necesita para encontrar patrones, sin ver `nombre`, `correo`, `telefono` ni `rfc`, y sin poder señalar a una persona concreta.

## `Actividad 4 — Control de acceso relacionado con la finalidad`

### ¿Qué información puede consultar el rol?
Solo de la vista `v_analitica_clientes`
### ¿Puede consultar directamente clientes?
No, no se le dio privilegios para consultar la visualizar la información de la tabla `clientes`
### ¿Puede obtener nombre, correo y RFC?
No. Debido a que la tabla con los privilegios para visualizar no contiene esos apartados.
### ¿Qué principio de privacidad estás aplicando?
`Minimización de datos`: se entrega solo lo necesario para la finalidad analítica, con la edad generalizada en rangos. También se relaciona con el principio de finalidad.
### ¿Qué principio de seguridad estás aplicando?
`Privilegio Minimo`: el rol recibe únicamente los permisos indispensables para su función, y el acceso a los datos completos queda restringido.

