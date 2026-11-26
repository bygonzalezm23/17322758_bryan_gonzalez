# POL-01 — Acceso

## Objetivo:        Reducir el riesgo de acceso indebido a los datos por privilegios excesivos o sin dueño.
## Alcance:         PostgreSQL y MongoDB, tablas y colecciones de clientes, auditoría y bitácoras; ambientes de producción y práctica.
## Regla:           Todo acceso se solicita por escrito al propietario del dato, que lo aprueba; el DBA solo lo implementa con el mínimo privilegio necesario. Los privilegios se revisan cada 6 meses y se retiran los que ya no se justifiquen.
## Responsable:     Decide: propietario del dato (Gerencia Comercial; Seguridad/Cumplimiento para auditoría y bitácoras). Ejecuta: DBA.
## Excepciones:     Acceso de emergencia por incidente, temporal (máximo 24 horas), autorizado por Seguridad/Cumplimiento y regularizado después.
## Evidencia:       Solicitud y aprobación en gobierno.solicitudes_cambio, sentencias GRANT/REVOKE en la bitácora e informe de la revisión semestral.
## Revisión:        Anual.