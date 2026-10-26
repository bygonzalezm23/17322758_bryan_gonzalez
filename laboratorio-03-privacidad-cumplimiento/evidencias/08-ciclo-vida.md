## Actividad 8 — Derecho de cancelación y ciclo de vida

### ¿Por qué eliminar un registro de una tabla no necesariamente significa que toda la información relacionada con esa persona haya desaparecido de la organización?

Porque los datos de una persona están distribuidos en muchos lugares además de `clientes`: tablas relacionadas, copias analíticas, respaldos, réplicas, bitácoras, reportes, archivos exportados y sistemas de terceros. Un `DELETE` solo afecta a la tabla donde se ejecuta; el resto debe localizarse y tratarse por separado. 

## Actividad 9 — Derecho de oposición

### qué información podría necesitar mantenerse
Los datos necesarios para la relación con el cliente y para cumplir obligaciones legales: `nombre`, `rfc` y registros de compras o facturas (plazo fiscal), además de un registro de que el titular se opuso, para poder respetar su decisión. 

### qué información podría dejar de utilizarse para determinada finalidad
Los datos usados para la finalidad secundaria, como `correo`, `edad`, `ciudad` y el comportamiento de compra para promociones personalizadas. Siguen existiendo, pero se excluyen de ese tratamiento.

### qué mecanismos técnicos podrían separar finalidades
- Columna o tabla de preferencias (`acepta_promociones = false`).
- Vistas por finalidad que filtren a quienes se opusieron.
- Roles con acceso solo a la vista de su finalidad.
- Exclusión del titular en listas de envío y sistemas externos.

### por qué la decisión final no debe ser tomada únicamente por el DBA
Porque implica criterios jurídicos y de negocio (qué se debe conservar, qué finalidades son compatibles). Corresponde a privacidad, jurídica y cumplimiento; el DBA implementa la decisión técnicamente.

