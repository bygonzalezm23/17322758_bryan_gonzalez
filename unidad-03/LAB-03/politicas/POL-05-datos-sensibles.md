# POL-05 — Uso de datos sensibles
## Objetivo:        Reducir la exposición de datos personales (RFC, correo, teléfono) y de secretos.
## Alcance:         Columnas personales de clientes, auditoria.cambios_clientes, bitácoras, dba.bitacora y respaldos.
## Regla:           Solo accede a datos sensibles quien tiene justificación aprobada por el propietario, y siempre mediante vistas enmascaradas o generalizadas, salvo autorización expresa. Las contraseñas no se escriben en sentencias (se usa \password) y la bitácora solo la leen Seguridad/Cumplimiento y el DBA.
## Responsable:     Decide: propietario del dato. Ejecuta: DBA. Vigila: Seguridad/Cumplimiento.
## Excepciones:     Acceso al dato sin enmascarar por facturación o auditoría, con aprobación escrita y por tiempo limitado.
## Evidencia:       Aprobaciones de acceso, registros de log_statement y de auditoría, y lista de roles con acceso a dba.bitacora.
## Revisión:        Semestral.