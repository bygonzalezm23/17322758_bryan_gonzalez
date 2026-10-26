## Actividad 15 — Propuesta de arquitectura de datos protegidos
## Propuesta conceptual: separación de datos por finalidad

### Diagrama
```
                                                       BASE DE DATOS
                                                             │
                                ┌────────────────────────────┼────────────────────────────┐
                                ▼                            ▼                            ▼
┌────────────────┬────────────────────────────┬────────────────────────────┬────────────────────────────┐
│                │         OPERACIÓN          │         ANALÍTICA          │         AUDITORÍA          │
├────────────────┼────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ DATOS          │ Datos necesarios para      │ Datos agregados: rangos    │ Bitácora: quién, qué,      │
│                │ operación: id, nombre,     │ de edad, región, grupos    │ cuándo y sobre qué         │
│                │ correo, teléfono, RFC      │ de 5 o más registros       │ registro                   │
│                │ cifrado, fecha_alta        │                            │                            │
├────────────────┼────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ ACCESO         │ soporte: vista enmascarada │ analista: solo vista       │ auditor: solo lectura      │
│                │ facturación: RFC           │ agregada                   │                            │
├────────────────┼────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ MINIMIZACIÓN   │ sin salario, estado civil  │ sin nombre, correo ni RFC  │ sin copiar datos           │
│                │ ni ocupación               │ edad en rangos             │ personales completos       │
├────────────────┼────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ PROTECCIÓN     │ RFC cifrado, TLS, hash     │ datos generalizados        │ solo lectura, sin          │
│                │ claves fuera de scripts    │ y enmascarados             │ borrado de bitácoras       │
├────────────────┼────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ RETENCIÓN      │ 5 años desde fecha_alta    │ según política             │ plazo propio               │
│                │                            │ aprobada                   │ definido                   │
├────────────────┼────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ TRAZABILIDAD   │ cambios y accesos se       │ consultas registradas      │ registro inmutable         │
│                │ registran en Auditoría     │ en Auditoría               │ para quien opera datos     │
├────────────────┼────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ ELIMINACIÓN    │ respaldo previo y borrado  │ se regenera sin el         │ evidencia conservada       │
│                │ depurar copias y externos  │ titular                    │ sin datos eliminados       │
├────────────────┼────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ SOLICITUDES    │ acceso, rectificación,     │ excluir al titular         │ guarda evidencia de        │
│ ARCO           │ cancelación, oposición     │ que se opuso               │ cada solicitud             │
└────────────────┴────────────────────────────┴────────────────────────────┴────────────────────────────┘
```