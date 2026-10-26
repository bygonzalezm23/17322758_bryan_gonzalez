## Actividad 14 — Escenario integral

| # | Problema | Principio afectado | Riesgo | Control propuesto |
|---|---|---|---|---|
| 1 | Todo el personal de analítica consulta directamente `clientes` | Mínimo privilegio | Acceso innecesario a nombre, correo, teléfono y RFC; fuga o abuso interno | Rol `analista` con acceso solo a una vista agregada o seudonimizada; `REVOKE` sobre `clientes` |
| 2 | Analítica solo genera estadísticas pero ve datos identificables | Minimización | Exposición de datos que no necesita para su finalidad | Entregar datos anonimizados o agregados (rangos de edad, región, supresión de grupos pequeños) |
| 3 | Datos conservados 12 años | Limitación del plazo de conservación | Mayor impacto de una fuga e incumplimiento de la LFPDPPP | Definir plazo (por ejemplo, 5 años), identificar registros vencidos y eliminar o anonimizar con aprobación |
| 4 | No existe política de retención documentada | Responsabilidad proactiva (rendición de cuentas) | No se puede justificar la conservación ni demostrar cumplimiento ante una auditoría | Elaborar y aprobar una política de retención con plazos, responsables y acciones al finalizar |
| 5 | Desarrolladores reciben copias completas con datos reales | Confidencialidad y mínimo privilegio | Fuga desde entornos con menos controles; acceso no autorizado a datos personales | Usar datos sintéticos o enmascarados/anonimizados en desarrollo; prohibir copias de producción |
| 6 | Entornos de desarrollo sin protección equivalente a producción | Seguridad | Copias sin cifrado ni auditoría, difíciles de rastrear y eliminar | Cifrar copias, restringir acceso, registrar entregas y eliminarlas al terminar las pruebas |
| 7 | Marketing usa correos sin finalidad documentada ni consentimiento verificado | Finalidad y consentimiento | Uso de datos para una finalidad no informada en el aviso de privacidad; sanciones | Revisar el aviso de privacidad, registrar consentimiento (`acepta_promociones`), vista de marketing filtrada |
| 8 | No hay documentación de la finalidad de cada dato | Finalidad y transparencia | No se puede saber qué datos son necesarios ni justificar su tratamiento | Matriz de gobierno de datos (dato, finalidad, responsable, retención) |
| 9 | El RFC y otros datos están en texto claro para todos los usuarios con acceso | Seguridad (confidencialidad) | Fraude fiscal, suplantación de identidad y robo si hay una fuga | Cifrado del RFC (`pgp_sym_encrypt()`), enmascaramiento y acceso restringido a facturación |
| 10 | No hay clasificación de información ni niveles de acceso | Responsabilidad y mínimo privilegio | Todos los datos se tratan igual, sin controles proporcionales al riesgo | Clasificar campos (identificadores directos, cuasi-identificadores) y asignar controles por nivel |
