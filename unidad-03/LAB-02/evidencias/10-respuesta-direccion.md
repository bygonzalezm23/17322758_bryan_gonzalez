# Actividad 10 — Responder a Dirección

## Preguntas

### ¿Quién cambió el RFC de María García en la Actividad 2? ¿Y en la Actividad 3?
- **Actividad 2:** no se puede demostrar. En ese momento el perfilador estaba apagado (nivel 0) y la bitácora por defecto no registra los `update`. El cambio ocurrió sin dejar autor.
- **Actividad 3:** con el perfilador activo, `system.profile` registró la operación con `user: "app_ventas@comercial"`. El autor fue la cuenta **`app_ventas`**, autenticada contra la base `comercial`.

> Esto identifica una **cuenta**, no a una persona. Si varias personas o procesos usan `app_ventas`, la evidencia no distingue entre ellos.

---

### ¿Cuándo y desde qué aplicación?
- **Actividad 2:** no hay evidencia de fecha ni de aplicación.
- **Actividad 3:**
  - **Cuándo:** `ts: 2026-11-17T04:51:51.976Z` en UTC. En hora de Culiacán (UTC-7) son las **21:51 del 16/11/2026**.
  - **Desde dónde:** `client: 127.0.0.1` (conexión local).
  - **Aplicación:** `appName: "app-ventas-web"`.

> `appName` lo **declara el cliente** en la cadena de conexión y no está verificado. Sirve como pista, no como prueba de identidad. Lo que sí está verificado es el usuario autenticado.

---
### ¿Qué valor tenía antes?
El perfilador guarda el filtro (`q: { _id: 1 }`) y el cambio (`u: { $set: { telefono: "6670000000" } }`), es decir, el **valor nuevo**, pero no la imagen anterior del documento. Para conocer el valor previo haría falta otra fuente: una copia de seguridad, una instantánea de los datos o un mecanismo que guarde el valor anterior (como la tabla `valores_antes` del disparador en PostgreSQL, LAB-01).

---

### ¿Cambió alguien los privilegios de app_ventas?

**Sí, los privilegios cambiaron, pero no se puede saber quién ni cuándo exactamente.**

- **Qué cambió:** entre las dos instantáneas, `app_ventas` pasó de `readWrite@comercial` a **`dbAdmin@comercial` + `readWrite@comercial`**. Se agregó `dbAdmin`.
- **Cuándo:** solo se sabe que ocurrió **entre** `22:53:12.105Z` y `22:53:12.220Z`.
- **Quién:** la búsqueda de `grantRolesToUser` dio **0** resultados en `system.profile` y **0** en la bitácora. El campo `tomada_por: admin` solo dice quién tomó la instantánea, no quién otorgó el rol.

> La ausencia de rastro en el perfilador y la bitácora **no prueba que no ocurriera**: la segunda instantánea demuestra que sí. Para atribuir este tipo de cambio hace falta auditoría nativa (MongoDB Enterprise/Atlas).