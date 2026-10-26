## Actividad 11 — Diseñar una matriz de gobierno de datos

### Matriz de gobierno de datos de la tabla `clientes`

| Dato | Finalidad | Responsable | Usuarios autorizados | Protección | Retención | Acción al finalizar |
|---|---|---|---|---|---|---|
| `nombre` | Identificar al cliente y atenderlo | Atención al cliente | Atención al cliente, Facturación, DBA | Control de acceso por roles | 5 años desde `fecha_alta` | Eliminar o anonimizar |
| `correo` | Contacto y notificaciones | Atención al cliente | Atención al cliente (enmascarado), Facturación, DBA | Enmascaramiento en vistas y control de acceso | 5 años desde `fecha_alta` | Eliminar |
| `telefono` | Contacto directo y atención | Atención al cliente | Atención al cliente (enmascarado), DBA | Enmascaramiento en vistas y control de acceso | 5 años desde `fecha_alta` | Eliminar |
| `rfc` | Facturación y obligaciones fiscales | Facturación | Facturación, DBA | Cifrado (`pgp_sym_encrypt()`), acceso muy restringido y enmascaramiento | 5 años (plazo fiscal) | Eliminar de forma segura, previa aprobación y respaldo |
| `edad` | Análisis y segmentación | Analítica | Analítica (en rangos), Dirección (agregados), DBA | Generalización en rangos y vista de analítica | 5 años desde `fecha_alta` | Anonimizar (conservar solo rangos agregados) |
| `ciudad` | Análisis geográfico y logística | Analítica | Analítica, Dirección (agregados), DBA | Generalización (zona o estado) y vista de analítica | 5 años desde `fecha_alta` | Anonimizar o eliminar |
| `codigo_postal` | Envíos y análisis regional | Analítica | Analítica (solo primeros dígitos), DBA | Generalización y supresión de grupos pequeños | 5 años desde `fecha_alta` | Eliminar o conservar solo la región |
