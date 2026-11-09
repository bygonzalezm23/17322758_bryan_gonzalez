# Actividad 6 — Cambios de privilegios y de estructura

## Preguntas

### ¿Qué tipo de evento es cada una de las tres primeras sentencias (privilegio o estructura)?
- `REVOKE UPDATE ON clientes FROM soporte_ana` → **privilegio** (autorización).
- `GRANT UPDATE ON clientes TO app_ventas` → **privilegio** (autorización).
- `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)` → **estructura** (cambio de esquema).

### ¿Por qué GRANT y REVOKE quedan registrados con log_statement = 'ddl'?
Porque PostgreSQL clasifica `GRANT` y `REVOKE` como sentencias de definición de datos (DDL), igual que `CREATE`, `ALTER` y `DROP`, ya que modifican el catálogo del sistema (los permisos), no los datos de las tablas.

### Si la bitácora contiene contraseñas, ¿quién debería poder leerla? Relaciónalo con la gestión de secretos de la Unidad II.
Solo el DBA o un rol de auditoría estrictamente necesario, nunca roles de aplicación ni soporte. Se relaciona directamente con la gestión de secretos: la bitácora debe tratarse como un almacén de secretos en potencia, con acceso restringido (como ya hace `REVOKE ALL ON SCHEMA dba FROM PUBLIC`), y cualquier contraseña que aparezca en texto claro debe considerarse comprometida y rotarse, igual que si se hubiera filtrado en un repositorio. Por eso se prefiere `\password` o `ALTER USER ... PASSWORD` con el hash ya calculado, que evita escribir la contraseña en claro en el log.