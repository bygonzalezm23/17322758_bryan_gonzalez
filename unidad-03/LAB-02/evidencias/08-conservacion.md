# Actividad 8 — Conservación: exportar antes de perder

## Preguntas

### Menciona tres formas en que la evidencia del perfilador o de la bitácora puede perderse sin que nadie la borre deliberadamente.
1. **Reinicio del servicio:** el nivel del perfilador vuelve a `0` (deja de registrar) y la memoria de `getLog` se vacía. En la práctica, `bitacora().length` es menor después de reiniciar, y todo lo que no se exportó antes desaparece.
2. **Sobrescritura por tamaño limitado:** `system.profile` es una colección *capped* (de tamaño fijo, 1 MB por defecto). Cuando se llena, las operaciones nuevas **reemplazan a las más antiguas** sin avisar. Lo mismo ocurre con `getLog`, que solo guarda en memoria los últimos 1024 eventos.
3. **Bitácora sin persistencia en archivo:** si no se configura `systemLog.destination: file` con `logAppend: true`, la bitácora no sobrevive a los reinicios, o un reinicio puede **reemplazar** el archivo en lugar de agregar al final.
### ¿Por qué el tamaño de 1 MB de system.profile es un problema de conservación y no solo de espacio?
- Con 1 MB caben pocas operaciones. En un sistema con actividad real (nivel 2 o muchas escrituras), el perfil se llena rápido y **cada operación nueva borra una antigua**.
- Esto significa que la **antigüedad de la evidencia** que puedes recuperar depende de la carga del sistema, no de tu política de retención. Una operación importante de hace unos días puede haber desaparecido sin que nadie lo notara.
- El problema es de **conservación** porque la pérdida es **silenciosa e irreversible**: no hay error ni alerta, y la evidencia sobrescrita no se puede reconstruir.
- Además, un actor malicioso podría **generar mucha actividad** para empujar fuera del perfil la operación que quiere ocultar.
- Por eso hay que **exportar con regularidad** (como se hizo con `system-profile.json` y su hash) o aumentar el tamaño del perfil. Ampliar el espacio ayuda, pero no sustituye a una copia externa con hash.

---
### ¿Por qué getLog sirve para interpretar pero no para conservar?
**No sirve para conservar** porque:

- Solo guarda **los últimos 1024 eventos** en memoria; los más antiguos se descartan.
- Vive **en la memoria del proceso**: al reiniciar `mongod`, se vacía.
- No tiene **garantía de integridad** ni cadena de custodia: es una consulta en vivo, no un archivo fijado con hash.
- No contiene la **historia completa**. Esa solo está en el archivo definido por `systemLog.path`.