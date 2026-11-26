# POL-06 — Cambios en producción
## Objetivo:        Reducir el riesgo de errores, cambios no autorizados e interrupciones en producción.
## Alcance:         Cambios de estructura (ALTER TABLE), privilegios, configuración del servidor, triggers y correcciones de datos en producción.
## Regla:           Todo cambio se solicita y se aprueba antes de ejecutarse, y se prueba antes en un ambiente aparte. Antes se hace un respaldo; durante, se ejecuta solo lo aprobado; después se verifica el resultado y se revisa que quedó registrado en la bitácora y en la auditoría.
## Responsable:     Decide: propietario del dato (y Responsable de TI en cambios de infraestructura). Ejecuta: DBA.
## Excepciones:     Cambio urgente por incidente crítico, autorizado por TI, con solicitud formal posterior en un máximo de 24 horas.
## Evidencia:       Solicitud en gobierno.solicitudes_cambio, script ejecutado, bitácora con log_statement = 'ddl' o 'mod' y registro del trigger de auditoría.
## Revisión:        Anual, y después de cualquier incidente causado por un cambio.