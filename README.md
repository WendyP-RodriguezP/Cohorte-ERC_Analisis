# Cohorte ERC: proyecto analítico reproducible

## Descripción

Proyecto analítico reproducible desarrollado en el Módulo 2 del Seminario de
Epidemiología Clínica II (Maestría en Epidemiología Clínica). Utiliza una cohorte
prospectiva sintética de 300 pacientes con enfermedad renal crónica (ERC) en
estadios G2 a G4, seguidos durante 24 meses.

**Pregunta de investigación:** ¿Cuáles son los factores basales asociados con la
progresión de la enfermedad renal crónica en pacientes con estadios G2-G4?

**Desenlace primario:** progresión a estadio G5 o inicio de terapia de reemplazo
renal (TRR).

## Fuente de datos

- **Base:** `base_erc_cohorte.csv` (300 participantes, 47 variables; medición
  basal, mes 12 y mes 24). Base sintética del curso, sin información de
  participantes reales.
- **Datos crudos:** `data/raw/`, excluidos del repositorio mediante `.gitignore`.
- **Base analítica:** `data/processed/base_analitica_v1.0.rds` (seudonimizada;
  la tabla de correspondencia de identificadores no se incluye).
- **Documentación:** `docs/fuentes_datos.md` y `docs/diccionario_variables.csv`.

## Plan de análisis

| # | Análisis | Desenlace | Documento |
|---|----------|-----------|-----------|
| 1 | Regresión logística | Progresión a G5/TRR (sí/no) | `code/04_regresion_logistica.Rmd` |
| 2 | Regresión lineal | Tasa de declive de la TFG (mL/min/año) | `code/05_regresion_lineal.Rmd` |
| 3 | Kaplan-Meier y modelo de Cox | Tiempo hasta progresión a G5/TRR | `code/06_analisis_supervivencia.Rmd` |

Exposición principal: estadio basal de ERC (referencia G2). Covariables
pre-especificadas: edad, sexo, diabetes, hipertensión, log-proteinuria y
hemoglobina (más PAS e IECA/ARA2 en el modelo lineal).

**Decisión analítica principal:** no hubo eventos en G2 ni en G3a, lo que
produce separación completa en los modelos logístico y de Cox. Por ello, el
efecto de la función renal basal se reporta con la TFG basal continua y con
regresión logística de Firth (ver `docs/memo_decisiones_analiticas.txt`).

## Estructura del repositorio

```
Cohorte-ERC_Analisis/
├── README.md                              # Este archivo
├── Cohorte-ERC_Analisis.Rproj             # Proyecto de RStudio
├── .gitignore                             # Exclusión de datos crudos y archivos locales
├── data/
│   ├── raw/                               # Datos originales, solo lectura (no incluidos)
│   └── processed/                         # Base analítica seudonimizada v1.0
├── code/
│   ├── 01_importacion_revision.R          # Importación y revisión inicial
│   ├── diccionario_variables.R            # Construcción del diccionario de variables
│   ├── 02_descripcion_base.Rmd            # Reporte descriptivo de la base
│   ├── 02_limpieza_preparacion.R          # Limpieza, seudonimización y base analítica
│   ├── 03_analisis_exploratorio.Rmd       # Análisis exploratorio y control de calidad
│   ├── 04_regresion_logistica.Rmd         # Regresión logística (+ Firth, TFG continua)
│   ├── 05_regresion_lineal.Rmd            # Regresión lineal (declive de la TFG)
│   ├── 06_analisis_supervivencia.Rmd      # Kaplan-Meier y modelo de Cox
│   ├── 07_validacion_resultados.Rmd       # Validación crítica y análisis de sensibilidad
│   ├── 08_tablas_figuras_finales.R        # Exportación de tablas y figuras finales
│   └── *.html                             # Reportes renderizados
├── output/
│   ├── figures/                           # Figuras generadas por el código (.png)
│   └── tables/                            # Tablas generadas por el código (.docx)
└── docs/
    ├── diccionario_variables.csv          # Diccionario de variables (47 variables)
    ├── fuentes_datos.md                   # Descripción de la fuente de datos
    ├── memo_preparacion_datos.txt         # Decisiones de limpieza y seudonimización
    ├── memo_decisiones_analiticas.txt     # Decisiones analíticas y supuestos
    ├── session_info_limpieza.txt          # Versiones de paquetes (limpieza)
    └── session_info_analisis.txt          # Versiones de paquetes (análisis)
```

## Productos analíticos

**Tablas** (`output/tables/`):
- `tabla_01_caracteristicas_basales.docx`: características basales por estadio
- `tabla_02_regresion_logistica.docx`: OR ajustados (TFG continua)
- `tabla_03_regresion_firth_estadio.docx`: OR ajustados por estadio (Firth)
- `tabla_04_regresion_lineal.docx`: coeficientes para la tasa de declive de la TFG
- `tabla_05_modelo_cox.docx`: HR ajustados (TFG continua)
- `tabla_06_verificacion_supuestos.docx`: resumen de la verificación de supuestos

**Figuras** (`output/figures/`):
- `fig_evolucion_tfg_seguimiento.png`: evolución de la TFG por estadio
- `fig_02_kaplan_meier_estadio.png`: curvas de Kaplan-Meier por estadio
- `fig_03_forest_plot_cox.png`: HR del modelo de Cox
- `fig_04_declive_tfg_estadio.png`: tasa de declive de la TFG por estadio

## Requisitos

R 4.5.2 y RStudio. Paquetes:

```r
install.packages(c("tidyverse", "here", "skimr", "janitor", "naniar",
                   "rmarkdown", "knitr", "gtsummary", "flextable", "officer",
                   "corrplot", "survival", "survminer", "broom", "car",
                   "lmtest", "ResourceSelection", "logistf", "sessioninfo"))
```

Las versiones exactas están en `docs/session_info_analisis.txt`.

## Cómo reproducir el análisis

1. Clone este repositorio y abra `Cohorte-ERC_Analisis.Rproj` en RStudio.
2. Descargue `base_erc_cohorte.csv` de la plataforma del curso y cópielo, sin
   modificarlo, en `data/raw/`.
3. Ejecute en este orden:
   1. `code/01_importacion_revision.R`
   2. `code/diccionario_variables.R`
   3. `code/02_limpieza_preparacion.R` (genera la base analítica)
   4. `code/02_descripcion_base.Rmd` (Knit)
   5. `code/03_analisis_exploratorio.Rmd` (Knit)
   6. `code/04_regresion_logistica.Rmd` (Knit)
   7. `code/05_regresion_lineal.Rmd` (Knit)
   8. `code/06_analisis_supervivencia.Rmd` (Knit)
   9. `code/07_validacion_resultados.Rmd` (Knit)
   10. `code/08_tablas_figuras_finales.R`

Todas las rutas se construyen con `here()`, por lo que el proyecto funciona en
cualquier computador.

## Contacto

Wendy Paola Rodríguez Pugliesse — wendyp-rodriguez@javeriana.edu.co
