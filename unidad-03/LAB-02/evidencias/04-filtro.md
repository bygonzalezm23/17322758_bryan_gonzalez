# Actividad 4 — Reducir el volumen con un filtro

## Preguntas

### ¿Qué perdiste de evidencia al aplicar el filtro? ¿Qué ganaste?
**Qué perdí:**

- Todas las lecturas (`query`, `getmore`, `command`) quedan fuera del perfil. La consulta `db.clientes.find({ _id: 1 })` se ejecutó, pero **no dejó rastro** en `system.profile`.
- Ya no puedo saber **quién consultó qué datos**. Si alguien lee información sensible de `clientes`, no hay evidencia.
- Pierdo la capacidad de detectar **consultas lentas de lectura**, ya que cuando hay un filtro, `slowms` y `sampleRate` dejan de aplicarse.
- Las operaciones registradas antes de activar el filtro se perdieron al hacer `db.system.profile.drop()`, salvo que se hayan exportado antes (Actividad 8).
**Qué gané:**

- **Menos ruido:** el perfil solo contiene operaciones que modifican datos (`insert`, `update`, `remove`), que son las más relevantes para auditar cambios.
- **Menor sobrecarga:** se registran menos documentos, así que el impacto en rendimiento y almacenamiento de `system.profile` (colección capped de 1 MB por defecto) es menor.
- **Mayor retención útil:** al ser una colección capped, con menos entradas irrelevantes las operaciones de escritura importantes permanecen más tiempo antes de ser sobrescritas.
- **Evidencia más enfocada:** el `update` quedó registrado con `user`, `appName`, `ns`, filtro (`q`) y cambio (`u`), lo cual basta para rastrear quién cambió el teléfono y desde qué aplicación.

---

### ¿Qué filtro usarías si solo interesaran operaciones sobre la colección clientes?
Filtrando por el namespace `ns`:

```js
db.setProfilingLevel(1, { filter: { ns: "comercial.clientes" } })
```

Si además quisieras limitarlo a **escrituras** sobre esa colección:

```js
db.setProfilingLevel(1, {
  filter: {
    ns: "comercial.clientes",
    op: { $in: ["insert", "update", "remove"] }
  }
})
```

Para verificar:

```js
db.getProfilingStatus()
```