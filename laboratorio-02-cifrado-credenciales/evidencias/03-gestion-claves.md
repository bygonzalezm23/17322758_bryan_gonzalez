## Actividad 3: Problema de gestion de claves

###  ¿Qué ocurriría si esta clave fuera real y el archivo se publicara en un repositorio Git?

Cualquiera con acceso al repositorio podría descifrar todos los datos protegidos con esa clave (como `rfc_cifrado`), siempre que obtenga también una copia de la base de datos o de un respaldo. El cifrado dejaría de servir, porque la protección depende totalmente de que la clave sea secreta.

