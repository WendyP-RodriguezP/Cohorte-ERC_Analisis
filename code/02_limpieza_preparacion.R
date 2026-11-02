# =========================================================
# SCRIPT 02: LIMPIEZA Y PREPARACIÓN DE DATOS
# Proyecto: Cohorte ERC — Seminario de Epiclínica II
# Autor: Wendy Paola Rodríguez Pugliesse
# Fecha: 2026-11-01
# Descripción: Transforma la base de datos cruda en la base
#              analítica lista para análisis estadísticos.
# =========================================================

library(tidyverse)
library(here)
library(skimr)
library(naniar)

# 1. CONFIGURACIÓN INICIAL ------------------------------------------------

# Cargar datos crudos (solo lectura)
base_raw <- read.csv(
  here("data", "raw", "base_erc_cohorte.csv"),
  encoding = "UTF-8"
)

cat("Base cargada:", nrow(base_raw), "participantes,",
    ncol(base_raw), "variables\n")

# 2. CORRECCIÓN DE TIPOS DE VARIABLES -------------------------------------

base <- base_raw %>%
  mutate(
    # Variables categóricas ordinales (con orden definido)
    estadio_basal = factor(estadio_basal,
                           levels  = c("G2", "G3a", "G3b", "G4"),
                           ordered = TRUE),
    nivel_educativo = factor(nivel_educativo,
                             levels  = c("Ninguno", "Primaria", "Secundaria",
                                         "Tecnico", "Universitario"),
                             ordered = TRUE),
    
    # Variables categóricas nominales
    sexo          = factor(sexo),
    etnia         = factor(etnia),
    procedencia   = factor(procedencia),
    etiologia_erc = factor(etiologia_erc),
    
    # Variables lógicas (0/1)
    diabetes                = as.logical(diabetes),
    hipertension            = as.logical(hipertension),
    cardiopatia_isquemica   = as.logical(cardiopatia_isquemica),
    tabaquismo_actual       = as.logical(tabaquismo_actual),
    tabaquismo_previo       = as.logical(tabaquismo_previo),
    ieca_o_ara2             = as.logical(ieca_o_ara2),
    estatinas               = as.logical(estatinas),
    perdida_seguimiento_m12 = as.logical(perdida_seguimiento_m12),
    perdida_seguimiento_m24 = as.logical(perdida_seguimiento_m24),
    progresion_g5_o_trr     = as.logical(progresion_g5_o_trr)
  )

# Verificar
cat("\nTipos de variables después de la corrección:\n")
sapply(base, class) %>% print()

# 3. IDENTIFICACIÓN DE VALORES FUERA DE RANGO -----------------------------

# Rangos esperados según el diccionario de variables
rangos <- list(
  edad                   = c(30, 85),
  peso_kg_basal          = c(35, 180),
  talla_cm               = c(145, 185),
  imc_basal              = c(15, 50),
  pas_mmhg_basal         = c(80, 220),
  pad_mmhg_basal         = c(40, 120),
  tfg_ml_min_basal       = c(10, 89),
  creatinina_mg_dl_basal = c(0.4, 15),
  hemoglobina_g_dl_basal = c(5, 18),
  albumina_g_dl_basal    = c(1.5, 5.5),
  proteinuria_mg_g_basal = c(20, 5500)
)

cat("=== VALORES FUERA DE RANGO IDENTIFICADOS ===\n")
atipicos_encontrados <- list()

for (var in names(rangos)) {
  fuera <- base %>%
    filter(!is.na(.data[[var]])) %>%
    filter(.data[[var]] < rangos[[var]][1] |
             .data[[var]] > rangos[[var]][2]) %>%
    select(id_estudio, all_of(var))
  
  if (nrow(fuera) > 0) {
    cat("\n[!]", var, ":\n")
    print(fuera)
    atipicos_encontrados[[var]] <- fuera
  }
}

if (length(atipicos_encontrados) == 0) {
  cat("No se encontraron valores fuera de rango.\n")
}

# Contexto clínico de los atípicos (para justificar cada corrección)
ids_atipicos <- unique(unlist(lapply(atipicos_encontrados, `[[`, "id_estudio")))
base %>%
  filter(id_estudio %in% ids_atipicos) %>%
  select(id_estudio, sexo, edad, estadio_basal, tfg_ml_min_basal,
         creatinina_mg_dl_basal, creatinina_mg_dl_m12,
         peso_kg_basal, peso_kg_m12, talla_cm, imc_basal) %>%
  print()

# 4. CORRECCIÓN DE VALORES ATÍPICOS ---------------------------------------
# Documentación detallada en: docs/memo_preparacion_datos.txt
#
# CREATININA BASAL:
# ERC-0058: 0.08 → 0.84 mg/dL. Error de punto decimal. G2, TFG 77,
#           creatinina mes 12 = 0.92 mg/dL.
# ERC-0064: 142 → 1.61 mg/dL. Valor registrado en µmol/L (142 / 88.4).
#           G2, creatinina mes 12 = 1.03 mg/dL.
# ERC-0122: 18.5 → NA. Incompatible con TFG basal de 25 (CKD-EPI 2021
#           estimaría ~3 mL/min) y con creatinina mes 12 = 4.33 mg/dL.
#           No es posible reconstruir el valor real.
#
# PESO BASAL:
# ERC-0152: 198 → 52.2 kg. Reconstruido con IMC registrado (22.9) y talla
#           (151 cm); coherente con peso mes 12 = 42.9 kg.
# ERC-0234: 8.5 → 49.9 kg. Reconstruido con IMC registrado (20.5) y talla
#           (156 cm); coherente con peso mes 12 = 47.4 kg.

base <- base %>%
  mutate(
    creatinina_mg_dl_basal = case_when(
      id_estudio == "ERC-0058" ~ 0.84,          # error de punto decimal
      id_estudio == "ERC-0064" ~ 142.0 / 88.4,  # µmol/L → mg/dL
      id_estudio == "ERC-0122" ~ NA_real_,      # no plausible ni recuperable
      TRUE ~ creatinina_mg_dl_basal
    ),
    peso_kg_basal = case_when(
      id_estudio %in% c("ERC-0152", "ERC-0234") ~
        round(imc_basal * (talla_cm / 100)^2, 1),  # reconstruido desde IMC
      TRUE ~ peso_kg_basal
    )
  )

# Verificar que las correcciones fueron aplicadas
base %>%
  filter(id_estudio %in% c("ERC-0058", "ERC-0064", "ERC-0122",
                           "ERC-0152", "ERC-0234")) %>%
  select(id_estudio, creatinina_mg_dl_basal, peso_kg_basal) %>%
  print()

# 5. VERIFICACIONES DE CONSISTENCIA LÓGICA --------------------------------

# 5.1 PAD debe ser menor que PAS
inconsistencia_pa <- base %>%
  filter(!is.na(pas_mmhg_basal) & !is.na(pad_mmhg_basal)) %>%
  filter(pad_mmhg_basal >= pas_mmhg_basal)
cat("Inconsistencia PA (PAD >= PAS):", nrow(inconsistencia_pa), "casos\n")

# 5.2 Tabaquismo actual y previo mutuamente excluyentes
inconsistencia_tabaco <- base %>%
  filter(tabaquismo_actual == TRUE & tabaquismo_previo == TRUE)
cat("Inconsistencia tabaquismo (actual Y previo = TRUE):",
    nrow(inconsistencia_tabaco), "casos\n")

# 5.3 IMC coherente con peso y talla
base <- base %>%
  mutate(
    imc_calculado    = round(peso_kg_basal / (talla_cm / 100)^2, 1),
    discrepancia_imc = abs(imc_basal - imc_calculado)
  )

inconsistencia_imc <- base %>%
  filter(!is.na(discrepancia_imc) & discrepancia_imc > 2)
cat("Discrepancia IMC > 2 kg/m²:", nrow(inconsistencia_imc), "casos\n")

# 6. VARIABLES DERIVADAS --------------------------------------------------

base <- base %>%
  mutate(
    grupo_edad = cut(edad,
                     breaks = c(0, 45, 60, 75, Inf),
                     labels = c("<45 años", "45–59 años",
                                "60–74 años", "≥75 años"),
                     right  = FALSE),
    estadio_agrupado = case_when(
      estadio_basal %in% c("G2", "G3a") ~ "Leve-moderado (G2-G3a)",
      estadio_basal %in% c("G3b", "G4") ~ "Moderado-severo (G3b-G4)"
    ) %>% factor(levels = c("Leve-moderado (G2-G3a)",
                            "Moderado-severo (G3b-G4)")),
    etiologia_agrupada = case_when(
      etiologia_erc == "Diabetica"    ~ "Diabética",
      etiologia_erc == "Hipertensiva" ~ "Hipertensiva",
      TRUE                            ~ "Otras / Desconocida"
    ) %>% factor(levels = c("Diabética", "Hipertensiva",
                            "Otras / Desconocida")),
    log_proteinuria_basal = log(proteinuria_mg_g_basal),
    cambio_tfg_m12   = tfg_ml_min_m12 - tfg_ml_min_basal,
    cambio_tfg_m24   = tfg_ml_min_m24 - tfg_ml_min_basal,
    tasa_declive_tfg = (tfg_ml_min_m24 - tfg_ml_min_basal) / 2,
    anemia_basal = case_when(
      sexo == "Femenino"  & hemoglobina_g_dl_basal < 12 ~ TRUE,
      sexo == "Masculino" & hemoglobina_g_dl_basal < 13 ~ TRUE,
      TRUE ~ FALSE
    )
  )

cat("Variables derivadas creadas: grupo_edad, estadio_agrupado,",
    "etiologia_agrupada, log_proteinuria_basal, cambio_tfg_m12,",
    "cambio_tfg_m24, tasa_declive_tfg, anemia_basal\n")

# 7. EVALUACIÓN DE DATOS FALTANTES ----------------------------------------

faltantes_resumen <- base %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(),
               names_to  = "variable",
               values_to = "n_faltantes") %>%
  mutate(pct = round(n_faltantes / nrow(base) * 100, 1)) %>%
  filter(n_faltantes > 0) %>%
  arrange(desc(n_faltantes))

cat("=== RESUMEN DE DATOS FALTANTES ===\n")
print(faltantes_resumen, n = Inf)

# Patrón de faltantes en variables de seguimiento
print(vis_miss(base %>%
                 select(tfg_ml_min_m12, hemoglobina_g_dl_m12, albumina_g_dl_m12,
                        proteinuria_mg_g_m12, tfg_ml_min_m24, hemoglobina_g_dl_m24,
                        albumina_g_dl_m24, proteinuria_mg_g_m24)))

# ¿Los faltantes de TFG al mes 12 se asocian con el estadio? (MCAR vs MAR)
base %>%
  mutate(faltante_tfg_m12 = is.na(tfg_ml_min_m12)) %>%
  group_by(estadio_basal) %>%
  summarise(n = n(),
            n_faltantes   = sum(faltante_tfg_m12),
            pct_faltantes = round(mean(faltante_tfg_m12) * 100, 1),
            .groups = "drop") %>%
  print()

# 7b. IDENTIFICADORES: SEUDONIMIZACIÓN Y ANONIMIZACIÓN ---------------------
# Variables potencialmente identificadoras revisadas:
#  - id_estudio: código de reclutamiento que permite enlazar con registros
#    originales → SEUDONIMIZACIÓN (nuevo código aleatorio id_analitico).
#  - fecha_reclutamiento: fecha exacta, cuasi-identificador
#    → GENERALIZACIÓN a año y semestre.
#  - edad, sexo, etnia, procedencia: cuasi-identificadores necesarios para
#    el análisis; se conservan. La base no contiene nombres, documentos de
#    identidad, direcciones ni teléfonos.

set.seed(2026)  # semilla fija: seudonimización reproducible

tabla_correspondencia <- tibble(
  id_estudio   = base$id_estudio,
  id_analitico = sprintf("P%03d", sample(seq_len(nrow(base))))
)

base <- base %>%
  left_join(tabla_correspondencia, by = "id_estudio") %>%
  mutate(
    fecha_reclutamiento    = lubridate::dmy(fecha_reclutamiento),
    anio_reclutamiento     = lubridate::year(fecha_reclutamiento),
    semestre_reclutamiento = lubridate::semester(fecha_reclutamiento)
  ) %>%
  select(id_analitico, everything(),
         -id_estudio, -fecha_reclutamiento)

# La tabla de correspondencia se guarda SOLO en data/processed/
# (excluida de GitHub por .gitignore); no se comparte.
write.csv(tabla_correspondencia,
          here("data", "processed", "tabla_correspondencia_ids.csv"),
          row.names = FALSE)

cat("Seudonimización aplicada: id_estudio → id_analitico;",
    "fecha_reclutamiento → año y semestre.\n")

# 8. CONSTRUCCIÓN Y EXPORTACIÓN DE LA BASE ANALÍTICA ----------------------
# Se conservan todos los participantes. Los análisis que requieren datos
# completos excluirán los faltantes según las variables de cada modelo.

base_analitica <- base %>%
  select(
    -imc_basal,        # reemplazado por imc_calculado
    -discrepancia_imc  # variable auxiliar de verificación
  )

cat("=== BASE ANALÍTICA FINAL ===\n")
cat("Participantes:", nrow(base_analitica), "\n")
cat("Variables:", ncol(base_analitica), "\n")
cat("Desenlace (progresión G5/TRR):",
    sum(base_analitica$progresion_g5_o_trr, na.rm = TRUE), "eventos\n")
cat("Con seguimiento completo (mes 24):",
    sum(!base_analitica$perdida_seguimiento_m24, na.rm = TRUE), "\n")

# Exportar (data/processed está excluida del repositorio por .gitignore)
saveRDS(base_analitica,
        here("data", "processed", "base_analitica_v1.0.rds"))
write.csv(base_analitica,
          here("data", "processed", "base_analitica_v1.0.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("\nBase analítica exportada en data/processed/base_analitica_v1.0.rds y .csv\n")

# Registrar información de sesión
capture.output(sessioninfo::session_info(),
               file = here("docs", "session_info_limpieza.txt"))
