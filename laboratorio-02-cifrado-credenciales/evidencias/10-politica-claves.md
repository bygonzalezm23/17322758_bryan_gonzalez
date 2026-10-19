## Actividad 10: Política mínima de protección de claves

## Política de gestión de claves criptográficas

1. **Generación:** las claves se generan con un generador criptográficamente seguro y algoritmos aprobados. Nunca se usan claves de ejemplo.

2. **Almacenamiento:** las claves se guardan en un gestor de secretos o KMS, nunca en código, scripts SQL ni repositorios Git.

3. **Acceso:** solo accede quien lo necesita, con identidad individual y registro de cada uso.

4. **Rotación:** las claves se rotan periódicamente y ante cualquier sospecha de compromiso.

5. **Respaldo:** las copias se guardan cifradas, separadas de los datos que protegen y con acceso restringido.

6. **Revocación:** ante un compromiso, la clave se revoca de inmediato y se reemplaza por una nueva.

7. **Exposición accidental:** una clave que aparezca en un repositorio, log o captura se considera comprometida y se rota, aunque se borre el archivo.

8. **Eliminación:** al terminar su vida útil, la clave y sus copias se destruyen de forma segura, solo si ningún dato depende de ella.

9. **Separación:** cada clave se usa para un solo propósito y entorno; las de producción nunca se usan en pruebas.