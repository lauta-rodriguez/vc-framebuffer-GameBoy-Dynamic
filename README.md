# Lab Org. y Arq. de Computadoras

- Configuración de pantalla: `640x480` pixels, formato `ARGB` 32 bits.
- El registro `X0` contiene la dirección base del FrameBuffer (Pixel 1)
- El código de cada consigna debe ser escrito en el archivo _app.s_
- El archivo _start.s_ contiene la inicialización del FrameBuffer, al finalizar llama a _app.s_ **(NO EDITAR)**

## Estructura

- **[app.s](app.s)** Este archivo contiene la aplicación. Todo el hardware ya está inicializado anteriormente.
- **[gameboy.s](gameboy.s)** Este archivo contiene los procedimientos necesarios para construir el gameboy.
- **[utils.s](utils.s)** Este archivo contiene los procedimientos que implementan figuras geometricas, entre otras cosas 'útiles'.
- **[start.s](start.s)** Este archivo realiza la inicialización del hardware
- **[Makefile](Makefile)** Archivo que describe como construir el software _(que ensamblador utilizar, que salida generar, etc)_
- **[memmap](memmap)** Este archivo contiene la descripción de la distribución de la memoria del programa y donde colocar cada sección.
- **README.md** este archivo

## Uso

El archivo _Makefile_ contiene lo necesario para construir el proyecto.

**Para correr el proyecto ejecutar**

```bash
$ make remake
```

Esto construirá el código y ejecutará qemu para su emulación
