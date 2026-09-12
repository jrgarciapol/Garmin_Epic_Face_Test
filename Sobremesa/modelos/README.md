# Modelos 3D

Deja aquí los `.fbx` (o `.glb` / `.obj`).

## Cómo subirlos

**Por GitHub**, arrastrando el archivo a esta carpeta desde la web. Es la vía
buena: el contenedor donde trabajo **se recicla** y se lleva por delante todo lo
que no esté en el repositorio.

## Qué puedo leer

FBX binario y ASCII, vía `assimp` → glTF → `trimesh`. Comprobado con una ida y
vuelta completa. También `.glb`, `.obj`, `.ply`, `.dae`, `.stl` y bastantes más.

Si exportar en **`.glb`** te resulta igual de cómodo, mejor: es un formato
abierto y me ahorro el paso de conversión.

## Qué ayuda al exportar

- **Los brazos, como objetos separados y con nombre** (`brazo_izq`,
  `brazo_der`, `lanza`…). Es lo más útil de todo: si van a marcar las horas
  necesito poder girarlos por separado.
- Si el modelo tiene **esqueleto**, consérvalo — leo los huesos y sus pivotes,
  que es aún mejor que separar objetos.
- Aplica las transformaciones antes de exportar (escala y rotación a 1 y 0).
- El eje arriba (Y o Z) da igual, lo corrijo yo.

## Inspeccionarlo

    python3 inspeccionar.py mi_modelo.fbx

Escupe mallas, vértices, caras, materiales, jerarquía de nodos y huesos.
