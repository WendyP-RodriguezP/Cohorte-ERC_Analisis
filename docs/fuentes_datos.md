# Fuentes de datos del proyecto

## Base de datos del curso: Cohorte ERC

**Descripción:** Base de datos sintética de una cohorte prospectiva de 300 pacientes
con enfermedad renal crónica (ERC) en estadios G2 a G4, seguidos durante 24 meses
con dos puntos de seguimiento (mes 12 y mes 24).

**Propósito:** Desarrollada específicamente para el Módulo 2 del Seminario de
Epidemiología Clínica II. Permite practicar limpieza de datos, análisis descriptivo,
modelos de regresión y análisis de supervivencia en un contexto clínico realista.

**Características del diseño:**

- 300 participantes, 47 variables
- Tres puntos de medición: basal, mes 12, mes 24
- Pérdida de seguimiento: ~12 % al mes 12, ~18 % al mes 24
- Datos faltantes adicionales en variables de laboratorio (~5–9 %)
- Valores atípicos intencionales en creatinina basal y peso basal (para ejercicios
  de detección y corrección)
- Desenlace primario: progresión a estadio G5 o inicio de terapia de reemplazo renal

**Archivo:** `data/raw/base_erc_cohorte.csv` (no incluido en el repositorio; se
distribuye por la plataforma del curso)

**Fecha de recepción:** 2026-11-01

**Nota:** Esta base de datos es sintética. No contiene información de participantes
reales. Los valores fueron generados con distribuciones estadísticas realistas
para los parámetros clínicos de pacientes con ERC.

## Hallazgos de la revisión inicial (script 01)

- Las variables basales no presentan datos faltantes.
- Mes 12: entre 12,3 % y 17,3 % de datos faltantes, coherente con la pérdida de
  seguimiento (~12 %) más faltantes de laboratorio.
- Mes 24: entre 18 % y 25 % de datos faltantes, coherente con la pérdida de
  seguimiento (~18 %) más faltantes de laboratorio.
- Los valores atípicos de creatinina y peso basal se identificarán y corregirán en
  la etapa de limpieza de datos.