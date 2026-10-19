## Actividad 8: Analizar un escenario de seguridad

### ¿Cuáles son los principales riesgos?
- Contraseñas en texto claro
- RFC en texto claro
- Conexiones sin validación adecuada del servidor
- Claves criptográficas en archivos SQL
- Respaldos sin protección
### ¿Qué mecanismo utilizarías para cada elemento?
- **Nombre y correo:** control de acceso por roles y enmascaramiento con vistas.
- **Contraseña:** hash con sal (`crypt()` y `gen_salt('bf')`).
- **RFC:** cifrado simétrico (`pgp_sym_encrypt()`).
- **Información financiera:** cifrado de columnas y acceso restringido por rol.
- **Claves criptográficas:** gestor de secretos o KMS, fuera del código, con rotación.
- **Conexiones:** TLS con validación del servidor (`sslmode=verify-full`).
- **Respaldos:** cifrado del archivo (por ejemplo, GPG) y acceso restringido.
### ¿Cuál de los problemas consideras más crítico y por qué?
Las claves criptográficas en archivos SQL. Si la clave se expone, todo lo cifrado con ella (RFC, información financiera, respaldos) puede descifrarse y el cifrado deja de servir. Además, en Git permanece en el historial aunque se borre el archivo.

### ¿Tener correctamente configurados los usuarios y permisos elimina estos riesgos?
No. El control de acceso solo decide quién entra a través de la base de datos. No protege datos en texto claro, respaldos robados, tráfico de red sin validación ni claves expuestas. Se necesita defensa en profundidad: permisos, cifrado o hash, TLS, gestión segura de claves y respaldos protegidos.
