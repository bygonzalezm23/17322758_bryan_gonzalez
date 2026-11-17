# Actividad 5 — Accesos en la bitácora de `mongod`

## Preguntas
### ¿Qué campo distingue un acceso fallido de uno exitoso?
Hay dos campos que lo distinguen, y conviene mirarlos juntos:

- **`msg`**: `"Failed to authenticate"` frente a `"Successfully authenticated"`.
- **`id`**: `5286307` (fallido) frente a `5286306` (exitoso).
- **`attr.result`**: es el código de resultado. En el acceso exitoso vale **`0`** (sin error). En los fallidos es distinto de cero (`18` y `11` en la evidencia).
### ¿Qué diferencia hay entre el error de contraseña incorrecta y el de usuario inexistente? ¿Por qué el cliente recibe el mismo mensaje en ambos casos?
**Diferencia en la bitácora del servidor:**

| Caso | `attr.error` | `attr.result` |
|---|---|---|
| Contraseña incorrecta | `AuthenticationFailed: SCRAM authentication failed, storedKey mismatch` | `18` |
| Usuario inexistente | `UserNotFound: Could not find user "usuario_inexistente" for db "comercial"` | `11` |

- En el primer caso **el usuario existe**, pero la prueba criptográfica (SCRAM) no coincide con la `storedKey` guardada.
- En el segundo caso **el usuario ni siquiera existe** en la base `comercial`.

**Por qué el cliente ve el mismo mensaje (`Authentication failed.`):**

- Es una medida de seguridad para evitar la **enumeración de usuarios**. Si el servidor dijera "usuario no existe" o "contraseña incorrecta" por separado, un atacante podría descubrir qué cuentas son válidas y concentrarse en adivinar sus contraseñas.
- El detalle real **solo queda en la bitácora**, a la que únicamente tiene acceso el DBA. Así se conserva la capacidad de investigar sin dar pistas al atacante.

---

### ¿Por qué el nombre de la aplicación del intento fallido es mongosh 2.10.0 y no app-ventas-web?
- El campo `app` sale de `attr.doc.application.name`, que es el metadato que **el cliente declara** al conectarse (`appName`).
- En los intentos fallidos se usaron cadenas de conexión **sin `appName`**:

  ```
  mongodb://app_ventas:incorrecta@127.0.0.1:27017/comercial
  ```

  Al no especificarlo, `mongosh` usa su valor por defecto: **`mongosh 2.10.0`** (nombre y versión del cliente).
- En cambio, el acceso exitoso de la aplicación incluía `?appName=app-ventas-web` en la URI, por eso aparece ese nombre.

