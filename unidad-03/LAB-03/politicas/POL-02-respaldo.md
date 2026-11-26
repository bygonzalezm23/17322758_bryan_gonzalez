# POL-02 — Respaldo

## Objetivo:        Reducir el riesgo de pérdida de datos por falla, borrado o corrupción.
## Alcance:         Base comercial (PostgreSQL), colecciones de MongoDB, esquema de auditoría y copias archivadas de bitácoras.
## Regla:           Se hace un respaldo completo diario y una copia fuera del servidor, cifrada, con retención de 30 días. Cada mes se prueba una restauración en un ambiente aparte y se documenta el resultado.
## Responsable:     Decide: Responsable de TI / Seguridad. Ejecuta y verifica: DBA; la verificación la valida Seguridad/Cumplimiento.
## Excepciones:     Se puede omitir un respaldo por mantenimiento programado, con autorización de TI y reposición en las 24 horas siguientes.
## Evidencia:       Bitácora del trabajo de respaldo, huella (hash) de cada copia y acta de la prueba mensual de restauración.
## Revisión:        Anual, o cuando cambie la infraestructura.
