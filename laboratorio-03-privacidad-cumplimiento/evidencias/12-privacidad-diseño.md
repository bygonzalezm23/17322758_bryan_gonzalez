## Actividad 12 — Privacidad por diseño

### ¿Qué problemas identificas?
- Se recolectan datos sin una finalidad definida ("por si acaso").
- Hay datos innecesarios y de mayor riesgo (`salario`, `estado_civil`, `ocupacion`, `fecha_nacimiento`, `direccion`).
- Datos duplicados: `edad` y `fecha_nacimiento` dicen lo mismo.
- No hay llave primaria (`id` sin `PRIMARY KEY`), restricciones ni tipos adecuados (todo es `TEXT`).
- No se contemplan protección (cifrado del RFC), retención ni control de acceso.
- Mayor impacto si hay una fuga y más complejidad para atender solicitudes ARCO.

### ¿Qué principio de privacidad se está ignorando?
La **minimización de datos**, junto con el principio de **finalidad**: solo se debe recolectar lo necesario para una finalidad concreta y declarada.

### ¿Qué preguntas realizarías antes de aprobar el diseño?
- ¿Para qué se usa cada campo y qué proceso falla si no existe?
- ¿Está cada finalidad prevista en el aviso de privacidad?
- ¿Quién tendrá acceso a cada dato?
- ¿Por cuánto tiempo se conservará cada campo?
- ¿Qué impacto tendría una fuga de cada dato?
- ¿Se puede lograr lo mismo con un dato menos invasivo (por ejemplo, un rango de edad en lugar de la fecha de nacimiento)?

### ¿Qué datos eliminarías?

`salario`, `estado_civil`, `ocupacion`, `fecha_nacimiento` (o `edad`, no ambos) y `direccion`

### ¿Qué datos requerirían una justificación adicional?
- `rfc`: solo si se factura.
- `direccion` y `codigo_postal`: solo si hay envíos.
- `telefono`: si es un canal de contacto necesario.
- `edad` o `fecha_nacimiento`: solo si hay una finalidad analítica o legal (por ejemplo, verificar mayoría de edad).
- `salario` y `estado_civil`: casi nunca se justifican.

### ¿Cómo aplicarías privacidad por defecto?
- Recolectar solo los campos mínimos y dejar opcionales los demás.
- Opciones de uso secundario (como promociones) desactivadas por defecto (`acepta_promociones BOOLEAN DEFAULT false`).
- Acceso restringido por defecto: sin permisos para ningún rol hasta que se justifiquen, y vistas por finalidad.
- Cifrado del RFC y enmascaramiento para quien no necesite el valor completo.
- Retención definida desde el diseño, con `fecha_alta` para calcularla.

## Actividad 13 — Diferenciar controles técnicos y administrativos

### Clasificación de medidas

| Medida | Técnico | Administrativo | Justificación |
|---|---|---|---|
| Crear roles de PostgreSQL | X | |  |
| Política de retención | | X | |
| Cifrado de datos | X | |  |
| Procedimiento para solicitudes ARCO | | X |  |
| Vista con información limitada | X | | |
| Clasificación de información | | X |  |
| Registro de auditoría | X | X | Técnico: bitácoras, triggers o logs que registran accesos y cambios. Administrativo: definir qué se registra, quién lo revisa, cada cuánto y cuánto se conserva. |
| Política de control de acceso | X | X | Administrativo: define quién debe acceder a qué, con qué aprobación (mínimo privilegio). Técnico: se implementa con roles, `GRANT` y `REVOKE`. |

