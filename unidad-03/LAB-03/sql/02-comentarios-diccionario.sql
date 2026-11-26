COMMENT ON TABLE clientes IS 'Clientes de Comercializadora Norte. Propietario: Gerencia Comercial. Custodio: DBA. Clasificación: confidencial (contiene datos personales).';
COMMENT ON COLUMN clientes.id IS 'Identificador interno del cliente. Generado por el sistema.';
COMMENT ON COLUMN clientes.nombre IS 'Nombre completo. Dato personal identificador directo.';
COMMENT ON COLUMN clientes.correo IS 'Correo de contacto. Dato personal. Uso: notificaciones al cliente.';
COMMENT ON COLUMN clientes.rfc IS 'RFC del cliente. Dato personal. Uso: facturación. Cambios auditados en auditoria.cambios_clientes.';
COMMENT ON COLUMN clientes.edad IS 'Edad en años cumplidos. Dato personal. Uso: analítica agregada.';
COMMENT ON COLUMN clientes.telefono IS 'Teléfono de contacto del cliente. Dato personal. Finalidad: contacto directo y atención. Responsable: Atención al cliente. Acceso enmascarado para usuarios no autorizados.';
COMMENT ON COLUMN clientes.ciudad IS 'Ciudad de residencia del cliente. Finalidad: análisis geográfico y logística. Responsable: Analítica. Se generaliza (zona o estado) en vistas de analítica.';
COMMENT ON COLUMN clientes.codigo_postal IS 'Código postal del cliente. Finalidad: envíos y análisis regional. Responsable: Analítica. Se generaliza (solo primeros dígitos) en vistas de analítica.';
COMMENT ON COLUMN clientes.fecha_alta IS 'Fecha de alta del cliente. Se asigna automáticamente con CURRENT_DATE. Base para calcular el plazo de retención (5 años).';
COMMENT ON COLUMN clientes.segmento IS 'Segmento comercial del cliente (VARCHAR(20)). Finalidad: segmentación y análisis comercial. Responsable: Gerencia Comercial. Valor definido por el negocio.';

SELECT c.ordinal_position          AS pos,
       c.column_name               AS columna,
       c.data_type                 AS tipo,
       c.character_maximum_length  AS longitud,
       c.is_nullable               AS acepta_nulos,
       c.column_default            AS valor_por_defecto,
       col_description('public.clientes'::regclass, c.ordinal_position) AS descripcion
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name = 'clientes'
ORDER BY c.ordinal_position;