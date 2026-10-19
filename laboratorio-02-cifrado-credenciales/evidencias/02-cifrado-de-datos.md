## Actividad 2: Cifrado de datos

### 1. ¿Qué diferencia existe entre `crypt()` y `pgp_sym_encrypt()`?

`crypt()` genera un hash unidireccional, pensado para contraseñas, y no se puede revertir. `pgp_sym_encrypt()` cifra el dato con una clave y es reversible: con la misma clave se puede recuperar el valor original.

### 2. ¿Cuál de los dos mecanismos permite recuperar el dato original?

`pgp_sym_encrypt()`, mediante `pgp_sym_decrypt()` y la clave correcta. Con `crypt()` solo se puede comprobar si una contraseña coincide con el hash.

### 3. ¿Qué ocurre si se utiliza una clave incorrecta?

`pgp_sym_decrypt()` falla y devuelve un error (por ejemplo, `Wrong key or corrupt data`), sin mostrar el dato. El valor cifrado no se modifica.

### 4. ¿Qué problema de seguridad representa colocar la clave directamente en una consulta?

La clave queda expuesta en texto plano: puede aparecer en el historial de comandos, en los logs del servidor, en `pg_stat_activity`, en scripts y en el repositorio. Quien la vea puede descifrar todos los datos. La clave debe manejarse fuera de la base de datos (gestor de secretos, variables de entorno o un servicio de gestión de claves), con acceso restringido y rotación periódica.

