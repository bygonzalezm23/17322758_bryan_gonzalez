# Laboratorio 02 — Cifrado y credenciales

## Informe

### 1. Introducción

El problema abordado es la protección de datos personales y credenciales en PostgreSQL, tanto almacenados como en tránsito. Configurar bien usuarios y permisos no basta: los datos pueden quedar expuestos por contraseñas en texto claro, claves mal gestionadas, conexiones sin cifrar o respaldos sin protección.

### 2. Protección de credenciales

- **Texto claro:** el dato se guarda tal cual y cualquiera con acceso lo lee.
- **Hash:** transformación unidireccional (`crypt()` con `gen_salt('bf')`); solo permite verificar, no recuperar el original.
- **Cifrado:** transformación reversible con una clave (`pgp_sym_encrypt()`); se usa cuando el dato debe poder leerse de nuevo.

### 3. Protección de datos sensibles

Se protegieron los campos de `clientes` (nombre, correo, teléfono, RFC y cuasi-identificadores) porque permiten identificar a una persona y su mal uso puede causar fraude o suplantación. Se aplicó enmascaramiento para `soporte`, seudonimización para `analista`, anonimización para estadísticas y cifrado simétrico para el RFC.

### 4. TLS

TLS evita que un observador de la red lea o altere consultas, resultados y credenciales, y permite verificar al servidor. En PostgreSQL se consultó `SHOW ssl;` y `pg_stat_ssl`; el resultado fue `ssl = false`, es decir, la conexión no estaba cifrada.

### 5. Gestión de claves

Las claves no deben guardarse con los scripts porque quien acceda al repositorio, logs o respaldos podría descifrar los datos, y en Git permanecen en el historial aunque se borre el archivo. Deben guardarse en un gestor de secretos con acceso restringido y rotación.

### 6. Resultados

- Vista enmascarada para `soporte` con acceso directo a la tabla revocado.
- Separación de `analitica` y `pii`, con acceso de `analista` restringido.
- Generalización y supresión de grupos menores a cinco registros.
- Retención a cinco años diseñada; la consulta devolvió cero registros.
- Comprobación de `crypt()` y `pgp_sym_encrypt()`, y de que la conexión no usa TLS.

### 7. Problemas encontrados

- `CREATE ROLE` falló porque los roles ya existían.
- `SET ROLE analista` dio `permission denied` hasta conceder la membresía al usuario.
- `psql` no resolvió el host `postgres-server` desde la terminal.
- `SHOW ssl_min_protocol_version;` falló por falta de privilegios.

### 8. Conclusiones

Cada técnica resuelve un problema distinto y ninguna sustituye al control de acceso. En producción aplicaría TLS con `verify-full`, hash para contraseñas, cifrado de columnas sensibles, claves en un gestor de secretos con rotación, respaldos cifrados, mínimo privilegio y una política de retención aprobada.

## Preguntas de análisis

### 1. ¿Por qué una contraseña no debe almacenarse como texto claro?

Porque cualquiera con acceso a la tabla, a un respaldo o a una filtración puede leerla y usarla.

### 2. ¿Por qué un hash no es equivalente a un cifrado?

El cifrado es reversible con la clave; el hash es unidireccional y solo permite verificar.

### 3. ¿Por qué el cifrado de una columna no sustituye al control de acceso?

Porque el cifrado solo protege el valor; el control de acceso decide quién llega a los datos y a la clave o función de descifrado.

### 4. ¿Por qué TLS no sustituye a los mecanismos de autorización de PostgreSQL?

Porque TLS solo protege la comunicación; no define qué puede consultar o modificar cada usuario.

### 5. ¿Qué ocurriría si una organización pierde una clave utilizada para cifrar información?

Los datos cifrados quedarían irrecuperables.

### 6. ¿Qué ocurriría si una clave criptográfica se publica accidentalmente en GitLab?

Se debe considerar comprometida: permanece en el historial aunque se borre, así que hay que rotarla y volver a cifrar los datos.

### 7. ¿Por qué un repositorio privado no debe considerarse un almacén de secretos?

Porque muchas personas pueden clonarlo, el historial conserva todo y no ofrece rotación, auditoría ni control por secreto.

### 8. ¿Qué diferencia existe entre proteger información almacenada y proteger información durante su transmisión?

La primera cuida los datos guardados en tablas, discos y respaldos; la segunda, los datos mientras viajan por la red (TLS).

### 9. ¿Por qué la gestión de claves es tan importante como el algoritmo criptográfico?

Porque un algoritmo fuerte con una clave expuesta, perdida o débil no protege nada.

### 10. ¿Qué mecanismo adicional implementarías para proteger los respaldos?

Cifrar los archivos de respaldo (por ejemplo, con GPG), con la clave en un gestor de secretos separado y acceso restringido.
