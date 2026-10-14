# Reglas de Desarrollo para Agentes de IA (AGENTS.md)

Este documento define las directrices, convenciones y flujos de trabajo que cualquier agente de IA o desarrollador debe seguir rigurosamente al trabajar en este repositorio.

---

## 1. Visión General del Proyecto

Esta es una aplicación Shiny escrita en **R** preparada para ejecutarse de manera local y en contenedores reproducibles mediante **Podman Compose** / **Docker Compose** sobre la imagen base `rocker/shiny:4.5.2` (Ubuntu 24.04 Noble), gestionando dependencias mediante **`renv`** y binarios de Posit Public Package Manager (PPPM).

### Estructura de Archivos Principal

- `app.R`: Archivo principal de la aplicación Shiny (UI y Server).
- `Dockerfile`: Definición de la imagen de producción/desarrollo en contenedor.
- `compose.yml`: Orquestación de servicios para despliegue local o servidor.
- `renv.lock`: Registro exacto de versiones de paquetes de R.
- `.Rprofile`: Control de activación de `renv` (con guard para Shiny Server).
- `rocker_scripts/install_reqs.sh`: Script de instalación automática de paquetes del sistema (sysreqs) y dependencias de R.
- `.env.example`: Plantilla de variables de entorno (no versionar secretos en `.env`).

---

## 2. Arquitectura de la Aplicación Shiny

- **Enfoque actual**: Diseño flexible centrado en `app.R` mientras el proyecto se encuentre en fase inicial de crecimiento.
- **Organización interna de `app.R`**:
  - Encabezado: Carga explícita de librerías (`library(...)`).
  - Configuración y utilidades: Lectura de variables de entorno y funciones puras auxiliares.
  - Definición de UI: Componentes de interfaz estructurados y legibles.
  - Lógica del Server: Manejo limpio de reactividad (`reactive`, `observeEvent`, `render*`), evitando efectos secundarios innecesarios.
  - Inicialización: `shinyApp(ui, server)`.
- **Ecosistema UI**: Selección abierta según el caso de uso del proyecto (e.g. `bslib`, `shiny` estándar, `shinydashboard`, `tabler`, etc.).
- **Escalabilidad futura**: Si la aplicación crece en complejidad, se adoptará una separación modular (`R/mod_*.R`) sin romper el flujo de dependencias existente.

---

## 3. Entorno de Ejecución y Flujo de Trabajo

Los agentes deben priorizar el desarrollo rápido en el entorno local de R y reservar los contenedores para validación de despliegue:

1. **Desarrollo Rápido (Local en R / RStudio)**:
   ```r
   renv::restore()
   shiny::runApp()
   ```
2. **Validación de Despliegue en Contenedores**:
   - En esta máquina se prioriza **Podman** (`podman compose`):
     ```bash
     podman compose up -d --build
     podman compose logs -f app
     ```
   - Alternativa con Docker:
     ```bash
     docker compose up -d --build
     docker compose logs -f app
     ```
   - Comprobación de salud:
     ```bash
     curl -I http://localhost:${MY_SHINY_APP_EXTERNAL_PORT:-3838}
     ```

---

## 4. Gestión Estricta de Dependencias (`renv`)

> [!IMPORTANT]
> **REGLA DE ORO**: Nunca utilices `install.packages()` de forma aislada sin registrar el cambio en `renv`. Todas las dependencias deben quedar inmortalizadas en `renv.lock`.

### Protocolo para agregar o actualizar paquetes:

1. Instalar el paquete dentro del entorno `renv`:
   ```r
   renv::install("nombre_del_paquete")
   ```
2. Actualizar el archivo de bloqueo:
   ```r
   renv::snapshot()
   ```
3. Reconstruir la imagen de contenedor si se valida en contenedor:
   ```bash
   podman compose down
   podman compose up -d --build
   ```

### Particularidades del Contenedor:
- **Sysreqs automáticos**: El script `rocker_scripts/install_reqs.sh` consulta la API de PPPM usando `pak::pkg_sysreqs` para instalar automáticamente las dependencias del sistema operativo (apt) requeridas por los paquetes en `renv.lock`. No instales librerías de sistema manualmente en el Dockerfile a menos que sea estrictamente indispensable.
- **Evitar bucles de renv en runtime**: 
  - `ENV RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` en `Dockerfile` evita que `renv` intente reinstalar librerías al arrancar workers de Shiny.
  - `.Rprofile` contiene un condicional que detecta si corre dentro de Shiny Server (`is_shiny_server`) para no activar `renv` en runtime, ya que las librerías se restauraron en la librería global durante el `build`. **No eliminar ni alterar este guard**.

---

## 5. Variables de Entorno y Configuración

- **Cero secretos en código**: Ninguna clave de API, contraseña o dato confidencial debe escribirse en el código fuente ni subirse a Git.
- **Uso de `.env` y `.env.example`**:
  - Mantener un archivo `.env.example` en la raíz como documentación de las variables disponibles.
  - El archivo `.env` real debe estar en `.gitignore` y no debe versionarse.
- **Lectura en R**:
  - Utilizar siempre `Sys.getenv()` con valores de respaldo (*fallback*) seguros:
    ```r
    puerto <- as.integer(Sys.getenv("MY_SHINY_APP_EXTERNAL_PORT", unset = "3838"))
    ```
- **Variables disponibles en Compose**:
  - `MY_SHINY_APP_EXTERNAL_PORT`: Puerto expuesto en el host hacia el contenedor (por defecto: `3838`).

---

## 6. Aseguramiento de Calidad y Verificación

- **Nivel de QA**: No se requiere un framework formal de pruebas automatizadas (`testthat` o `shinytest2`) en esta fase.
- **Regla de Aceptación del Agente**:
  - Todo cambio introducido debe ser sintácticamente válido en R.
  - Verificar que no existan errores de referencia o reactividad circular.
  - Comprobar que la aplicación inicie limpiamente con `shiny::runApp()` o responda HTTP 200 en el puerto asignado.

---

## 7. Control de Versiones y Mensajes de Commit

Los agentes deben seguir la convención de **Conventional Commits** al preparar cambios en Git:

- `feat:` Nuevas funcionalidades en la aplicación o contenedor.
- `fix:` Correcciones de errores o bugs reactivos.
- `docs:` Cambios o mejoras en documentación (README, AGENTS, etc.).
- `chore:` Mantenimiento de dependencias (`renv.lock`, `.gitignore`, scripts).
- `refactor:` Reestructuración de código sin alterar funcionalidad.

Ejemplo:
```bash
git commit -m "feat: agregar visualizacion de datos con ggplot2"
git commit -m "chore: actualizar dependencias con renv::snapshot"
```
