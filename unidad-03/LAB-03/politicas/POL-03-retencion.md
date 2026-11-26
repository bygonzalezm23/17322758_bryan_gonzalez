# POL-03 — Retención

## Objetivo:        Evitar conservar datos más tiempo del necesario y asegurar que las bitácoras existan cuando se necesiten como evidencia.
## Alcance:         Datos de clientes, auditoria.cambios_clientes, bitácoras de PostgreSQL y mongod, system.profile e instantáneas de privilegios.
## Regla:           Los datos de clientes y su auditoría se conservan 5 años desde fecha_alta. Las bitácoras se conservan de 12 a 24 meses según su sensibilidad, y system.profile 30 días con exportación periódica. Al vencer el plazo se elimina o anonimiza de forma segura y se registra la baja.
## Responsable:     Decide: propietario del dato con apoyo de Cumplimiento. Ejecuta: DBA.
## Excepciones:     Retención extendida por investigación o requerimiento legal, autorizada por Cumplimiento y documentada con fecha de fin.
## Evidencia:       Catálogo de datos con plazos vigentes, registro de bajas y manifiesto de hashes de las bitácoras archivadas.
## Revisión:        Anual, o cuando cambie la normativa.