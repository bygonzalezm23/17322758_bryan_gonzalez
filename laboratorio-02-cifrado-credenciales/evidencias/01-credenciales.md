## Actividad 1

### ¿Qué ocurriría si una persona obtiene acceso de lectura a esta tabla?

 Podrian utilizar la contraseña para entrar en su cuenta y suplantar su identidad.

###  ¿Son iguales?

No. Aunque la contraseña es la misma (`Password123`), cada ejecución produce un hash diferente.

###  Si no son iguales, ¿por qué?

Porque `gen_salt('bf')` genera una **sal aleatoria nueva** en cada llamada. Como la sal cambia, el hash resultante también cambia, aunque la contraseña sea idéntica.

###  ¿Qué función cumple `gen_salt()`?

Genera una cadena aleatoria (la **sal**) y define el algoritmo (`bf` = Blowfish/bcrypt) y su costo. La sal evita que dos usuarios con la misma contraseña tengan el mismo hash y dificulta los ataques con tablas precalculadas (rainbow tables).

###  ¿Qué función cumple `crypt()`?

Calcula el hash de la contraseña usando la sal indicada. El resultado incluye el algoritmo, el costo, la sal y el hash. Para verificar una contraseña se vuelve a llamar a `crypt()` usando como sal el hash guardado:

```sql
SELECT crypt('Password123', hash_guardado) = hash_guardado;
```

###  ¿Esto es cifrado reversible?

No. Es un **hash unidireccional**: no existe una función para recuperar la contraseña original a partir del resultado. Solo se puede comprobar si una contraseña coincide con el hash. Un atacante únicamente podría intentar adivinarla probando contraseñas una por una, y el costo de bcrypt hace ese proceso lento.


### ¿Qué resultado obtuviste con la contraseña correcta?
 El dato tipo boolean aparecio como resultado True indicando que si estaba correcto.
### ¿Qué resultado obtuviste con la contraseña incorrecta? 
El dato tipo boolean aparecio como resultado false indicando que estaba erroneo. 
### ¿Por qué no es necesario recuperar la contraseña original?
Porque el sistema solo necesita verificar que la contraseña ingresada es correcta, no conocerla. Se calcula el hash de lo que escribe el usuario y se compara con el guardado. 
### ¿Por qué un hash no debe confundirse con cifrado?

Porque el cifrado es reversible (con la clave se recupera el dato original) y el hash es unidireccional (no se puede recuperar el original). El cifrado se usa cuando hay que volver a leer el dato; el hash, cuando solo hay que comprobarlo.