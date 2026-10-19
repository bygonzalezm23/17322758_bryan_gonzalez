Actividad 7 — Comparar protección en reposo y protección en tránsito

| Situación | Mecanismo apropiado | ¿Qué protege? |
|---|---|---|
| Contraseña de usuario | Hash con sal (`crypt()` y `gen_salt('bf')`) | Protege la contraseña en reposo: no se puede recuperar el original, solo verificar que coincide. Si la base se filtra, no se exponen las contraseñas reales. |
| RFC almacenado en una tabla | Cifrado simétrico (`pgp_sym_encrypt()`) o enmascaramiento y control de acceso | Protege la confidencialidad del dato en reposo. Con cifrado se recupera solo con la clave. |
| Consulta enviada desde un cliente al servidor | TLS (`sslmode=require` o `verify-full`) | Protege los datos en tránsito: confidencialidad, integridad y autenticación del servidor frente a quien observe la red. |
| Respaldo de una base de datos | Cifrado del archivo de respaldo (por ejemplo, GPG) y acceso restringido | Protege los datos en reposo dentro del respaldo si el archivo se pierde, se copia o se roba. |
| Clave criptográfica | Gestor de secretos o KMS, variables de entorno fuera del código, acceso restringido y rotación | Protege la clave que a su vez protege los datos. Si se expone, el cifrado pierde su valor. |