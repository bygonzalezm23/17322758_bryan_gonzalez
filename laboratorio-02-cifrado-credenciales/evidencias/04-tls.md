## Actividad 4, 5 y 6
### ¿La conexión actual utiliza TLS?
No, debido que la consulta da resultado off, indicando que no se utiliza tsl.

### ¿Qué versión de TLS se está utilizando?
No se pudo visualizar la version debido a que me aparece que debo ser superusuario para ejecutarlo.

### ¿Qué algoritmo de cifrado aparece?
El que muestra la columna `cipher`, por ejemplo `TLS_AES_256_GCM_SHA384` (TLS 1.3) o `ECDHE-RSA-AES256-GCM-SHA384` (TLS 1.2). Indica el algoritmo con el que se cifra el tráfico. Si no hay TLS, sale vacío.

### ¿Qué diferencia existe entre una conexión protegida con TLS y una conexión sin TLS? 
Con TLS, el tráfico entre el cliente y PostgreSQL va cifrado: un observador de la red no puede leer consultas, resultados ni credenciales, se detecta si alguien los modifica y se puede verificar que el servidor es el legítimo. Sin TLS, todo viaja en texto legible, así que cualquiera que vea el tráfico puede leerlo o alterarlo, y no hay forma de comprobar la identidad del servidor.

