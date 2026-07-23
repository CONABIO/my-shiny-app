# Plantilla para Aplicacion Shiny con Contenedor

Este repositorio esta preparado para ejecutar una aplicacion Shiny dentro de un
contenedor, con dependencias reproducibles desde renv.lock y despliegue sencillo
con Podman Compose o Docker Compose.

## Objetivo del proyecto

- Reproducibilidad de paquetes de R mediante renv.lock.
- Construccion de imagen lista para ejecutar en entorno local o servidor.
- Arranque estable en Shiny Server evitando bootstrap de renv en runtime.

## Estructura relevante

```text
my-shiny-app/
|- app.R
|- compose.yml
|- Dockerfile
|- renv.lock
|- .Rprofile
|- rocker_scripts/install_reqs.sh
`- renv/
```

## Trabajo con RStudio (desarrollo local)

Si deseas trabajar primero en local con R o RStudio:

```r
renv::restore()
shiny::runApp()
```

Este flujo es recomendado para iterar rapido en desarrollo antes de construir
la imagen de contenedor.

## Flujo recomendado de dependencias

Instalar paquete nuevo:

```r
renv::install("nombre_del_paquete")
```

Actualizar lockfile:

```r
renv::snapshot()
```

## Como funciona el contenedor

Durante build:

- Se usa la imagen base rocker/shiny:4.5.2.
- Se copia renv.lock al contenedor.
- El script rocker_scripts/install_reqs.sh instala dependencias del sistema y
  luego ejecuta renv::restore() en la libreria global del contenedor.

Durante runtime:

- Shiny Server sirve la app en el puerto interno 3838.
- RENV_CONFIG_AUTOLOADER_ENABLED=FALSE evita que renv intente reinstalarse al
  iniciar workers.
- .Rprofile incluye un guard para no activar renv dentro de Shiny Server.

## Requisitos

- Opcion A: Podman + podman compose
- Opcion B: Docker + docker compose

## Despliegue rapido

### Con Podman

```bash
podman compose up -d --build
podman compose logs -f app
```

### Con Docker

```bash
docker compose up -d --build
docker compose logs -f app
```
> [!IMPORTANT]
> Cada que se incluya una nueva dependencia en la aplicación es necesario volver
> a construir la imagen del contenedor

La app quedara disponible en:

- http://localhost:3838

## Variables de entorno para despliegue

La variable principal configurable desde compose.yml es:

- MY_SHINY_APP_EXTERNAL_PORT

Descripcion:

- Define el puerto externo del host que se publica hacia el puerto interno 3838
  del contenedor.
- Valor por defecto: 3838

### Cambiar el puerto de escucha externo

Ejemplo para publicar la app en 8080:

```bash
MY_SHINY_APP_EXTERNAL_PORT=8080 podman compose up -d --build
```

o con Docker:

```bash
MY_SHINY_APP_EXTERNAL_PORT=8080 docker compose up -d --build
```

Acceso esperado:

- http://localhost:8080

### Usar archivo .env

Puedes crear un archivo .env en la raiz del proyecto:

```dotenv
MY_SHINY_APP_EXTERNAL_PORT=8080
```

Luego levantar normalmente:

```bash
podman compose up -d --build
```

## Operacion y mantenimiento

Detener servicios:

```bash
podman compose down
```

Recrear desde cero cuando cambie Dockerfile, renv.lock o scripts de instalacion:

```bash
podman compose down
podman compose up -d --build
```

Ver logs recientes:

```bash
podman compose logs --tail=200 app
```

## Troubleshooting rapido

- Si ves un contenedor viejo reutilizado, ejecuta podman compose down antes de
  subir.
- Si cambiaste dependencias de R y no se reflejan, reconstruye con --build.
- Si necesitas validar servicio, prueba:

```bash
curl -I http://localhost:${MY_SHINY_APP_EXTERNAL_PORT:-3838}
```