# Cohorte-ERC_Analisis
Proyecto Reproducible:Analisis Cohorte ERC
# Cohorte ERC: proyecto analítico reproducible

## Descripción

Proyecto analítico reproducible desarrollado en el Módulo 2 del Seminario de
Epidemiología Clínica II (Maestría en Epidemiología Clínica). Utiliza una cohorte
prospectiva sintética de pacientes con enfermedad renal crónica (ERC) en estadios
G2 a G4, seguidos durante 24 meses, con el objetivo de practicar la gestión
reproducible de datos, el análisis descriptivo, los modelos de regresión y el
análisis de supervivencia. El desenlace primario es la progresión a estadio G5 o
el inicio de terapia de reemplazo renal (TRR).

## Fuente de datos

- **Base:** `base_erc_cohorte.csv` (300 participantes, 47 variables; medición basal,
  mes 12 y mes 24).
- **Origen:** base de datos sintética del curso, distribuida por la plataforma
  institucional. No contiene información de participantes reales.
- **Ubicación local:** `data/raw/` (excluida del repositorio mediante `.gitignore`).
- **Documentación:** ver `docs/fuentes_datos.md` y `docs/diccionario_variables.csv`.

## Estructura del repositorio

```
Cohorte-ERC_Analisis/
├── README.md                          # Este archivo
├── Cohorte-ERC_Analisis.Rproj         # Archivo de proyecto de RStudio
├── .gitignore                         # Exclusión de datos y archivos locales
├── data/
│   ├── raw/                           # Datos originales, solo lectura (no incluidos)
│   └── processed/                     # Datos procesados (no incluidos)
├── code/
│   ├── 01_importacion_revision.R      # Importación y revisión inicial de datos
│   └── diccionario_variables.R        #