SELECT count(*) FROM dba.bitacora;


INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal) VALUES
('Ana Lopez', 'ANA.LOPEZ@example.test', '6671234567', 'LOAA850315AB', 41, 'Culiacan', '80000'),
('Jorge Díaz', 'sin-correo', '667', NULL, -3, 'Culiacán', '8000');


SELECT lower(correo) AS correo_normalizado,
       count(*) AS registros,
       string_agg(id::text, ', ') AS ids
FROM clientes
GROUP BY lower(correo)
HAVING count(*) > 1;

SELECT id, nombre, rfc
FROM clientes
WHERE rfc IS NULL
   OR rfc !~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$';


   SELECT id, nombre, correo
FROM clientes
WHERE correo !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$';

SELECT id, nombre, edad
FROM clientes
WHERE edad IS NOT NULL AND (edad < 18 OR edad > 120);

SELECT count(*) AS total,
       count(*) FILTER (WHERE telefono IS NULL) AS sin_telefono,
       count(*) FILTER (WHERE rfc IS NULL) AS sin_rfc
FROM clientes;