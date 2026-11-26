# POL-04 — Restauración
## Objetivo:        Reducir el riesgo de que una restauración sobrescriba datos válidos o destruya evidencia.
## Alcance:         Restauración total o parcial de PostgreSQL y MongoDB, en producción y en ambientes de prueba.
## Regla:           Toda restauración en producción requiere solicitud escrita y aprobación del propietario del dato; antes se respalda el estado actual. Se restaura primero en un ambiente aparte, se valida y después se aplica.
## Responsable:     Autoriza: propietario del dato y Responsable de TI. Ejecuta: DBA.
## Excepciones:     Si el servicio está caído, TI puede autorizar la restauración de inmediato y se regulariza la solicitud dentro de las 24 horas siguientes.
## Evidencia:       Solicitud y aprobación, respaldo previo, bitácora de la restauración y acta de validación posterior.
## Revisión:        Anual, y después de cada restauración real.