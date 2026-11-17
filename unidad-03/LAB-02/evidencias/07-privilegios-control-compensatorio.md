# Actividad 7 — Cambios de privilegios: el límite más importante

## Preguntas

### ¿Por qué un cambio de privilegios es uno de los eventos auditables más importantes?
- **Es la puerta de entrada a todo lo demás:** quien amplía sus propios privilegios o los de otra cuenta puede después leer, modificar o borrar datos que antes no podía. Es el paso previo de casi cualquier abuso.
- **Es el mecanismo típico de escalada de privilegios y de persistencia:** un atacante (o un interno) que consigue acceso temporal suele dejarse un rol más amplio para volver más tarde.
- **Multiplica el impacto:** un solo cambio (por ejemplo, `dbAdmin` a `app_ventas`) afecta a **todas** las operaciones futuras de esa cuenta, no a una sola.
- **Es poco frecuente y de alto valor:** en condiciones normales los privilegios cambian pocas veces, así que cada cambio debería ser explicable. Eso lo hace fácil de vigilar y muy revelador cuando es anómalo.
- **Afecta directamente a los principios de mínimo privilegio y separación de funciones**, y es un punto habitual de revisión en auditorías y normativas.
- **Pasa desapercibido:** como se vio en la práctica, el perfilador y la bitácora por defecto no lo registran, así que sin control específico no deja rastro.

---
### ¿Con qué frecuencia tomarías instantáneas? ¿Qué factores influyen?
**Propuesta:** como base, **una vez al día** (o cada pocas horas en sistemas críticos), más una instantánea **antes y después de cada cambio planificado** (ventana de mantenimiento, despliegue, alta/baja de personal).

**Factores que influyen:**

| Factor | Efecto sobre la frecuencia |
|---|---|
| **Criticidad de los datos** (personales, financieros) | Más críticos → más frecuente |
| **Tolerancia a la ventana de exposición** | Una instantánea cada 24 h implica hasta 24 h sin detectar un cambio indebido |
| **Frecuencia de cambios legítimos** | Si hay muchos cambios, hay más ruido y conviene comparar con cambios autorizados |
| **Número de usuarios y roles** | Más cuentas → instantáneas más grandes (coste de almacenamiento y comparación) |
| **Requisitos normativos o contractuales** | Pueden fijar un mínimo |
| **Recursos disponibles** | Es una consulta ligera, pero hay que revisar y conservar los resultados |
| **Existencia de auditoría de eventos** | Si ya hay auditoría, las instantáneas son un control complementario y pueden espaciarse más |

### ¿Quién debería poder escribir en auditoria.instantaneas_privilegios?
- **Solo una cuenta de servicio dedicada** (por ejemplo, `auditor_snapshot`) con permiso únicamente de `insert` sobre esa colección y `getUsers`/lectura de usuarios, ejecutada por un proceso automático.
- **No** debe poder escribir en ella:
  - La aplicación (`app_ventas`).
  - Los DBA que administran los privilegios (**separación de funciones**): quien puede cambiar privilegios no debería poder borrar o alterar la prueba de ese cambio.
- **Permisos de lectura:** auditoría/seguridad. Los DBA, como mucho, lectura.
- **Sin `update` ni `remove`** para nadie en operación normal: la colección debe ser de **solo anexar** (*append-only*).
- **Refuerzos recomendados:**
  - Guardar copias en un **sistema externo o inmutable** (WORM, SIEM, almacenamiento de solo lectura).
  - Añadir un **hash encadenado** a cada instantánea para detectar manipulaciones.
  - Registrar quién accede a esa colección.
### Redacta en tres líneas cómo comunicarías esta limitación a Dirección.
> Actualmente podemos **detectar** que los permisos de una cuenta cambiaron, comparando fotografías periódicas, pero **no podemos saber quién lo hizo ni a qué hora exacta**, porque el sistema no registra esos eventos por sí solo.
> Esto significa que un cambio indebido podría pasar sin atribución de responsabilidad durante el intervalo entre fotografías.
> Proponemos activar una **auditoría de eventos de gestión de usuarios** y proteger las fotografías fuera del alcance de los administradores para cerrar esta brecha.

## Tabla

| Pregunta | ¿La instantánea responde? |
|---|---|
| ¿Cambiaron los privilegios de `app_ventas`? | **Sí** |
| ¿Qué rol se agregó? | **Sí** |
| ¿Quién lo agregó? | **No** |
| ¿Cuándo exactamente? | **No**, solo que ocurrió entre dos instantáneas |