# =========================================================
# SCRIPT 08: TABLAS Y FIGURAS FINALES
# Proyecto: Cohorte-ERC_Analisis
# Autor: Wendy Paola Rodríguez Pugliesse
# Descripción: Genera automáticamente, a partir de la base analítica,
#              las tablas y figuras finales de los análisis estadísticos
#              y las guarda en output/tables y output/figures.
# Requiere: data/processed/base_analitica_v1.0.rds
#           (generada por code/02_limpieza_preparacion.R)
# =========================================================

library(tidyverse)
library(here)
library(survival)
library(survminer)
library(gtsummary)
library(flextable)
library(logistf)
library(broom)

# 1. CARGA DE DATOS -------------------------------------------------------

base <- readRDS(here("data", "processed", "base_analitica_v1.0.rds")) %>%
  # Factor nominal: G2 como categoría de referencia
  mutate(estadio_basal = factor(estadio_basal, ordered = FALSE),
         tfg_10 = tfg_ml_min_basal / 10)

base_lineal <- base %>% filter(!is.na(tasa_declive_tfg))

etiquetas <- list(
  tfg_10                 ~ "TFG basal (por 10 mL/min/1.73m²)",
  estadio_basal          ~ "Estadio de ERC (ref: G2)",
  edad                   ~ "Edad (por año)",
  sexo                   ~ "Sexo",
  diabetes               ~ "Diabetes mellitus",
  hipertension           ~ "Hipertensión arterial",
  log_proteinuria_basal  ~ "Log-proteinuria",
  hemoglobina_g_dl_basal ~ "Hemoglobina (por g/dL)",
  pas_mmhg_basal         ~ "PAS (por mmHg)",
  ieca_o_ara2            ~ "IECA o ARA2"
)

guardar_tabla <- function(tabla, archivo) {
  tabla %>%
    as_flex_table() %>%
    save_as_docx(path = here("output", "tables", archivo))
}

# 2. MODELOS --------------------------------------------------------------
# Decisión analítica (ver docs/memo_decisiones_analiticas.txt): por la
# separación completa (sin eventos en G2 ni G3a), los modelos logístico y
# de Cox se reportan con TFG basal continua; el estadio se reporta con
# regresión de Firth.

modelo_log_tfg <- glm(
  progresion_g5_o_trr ~ tfg_10 + edad + sexo + diabetes + hipertension +
    log_proteinuria_basal + hemoglobina_g_dl_basal,
  data = base, family = binomial()
)

modelo_firth <- logistf(
  as.numeric(progresion_g5_o_trr) ~ estadio_basal + edad + sexo +
    diabetes + hipertension + log_proteinuria_basal + hemoglobina_g_dl_basal,
  data = base
)

modelo_lineal <- lm(
  tasa_declive_tfg ~ estadio_basal + edad + sexo + diabetes + hipertension +
    log_proteinuria_basal + hemoglobina_g_dl_basal + pas_mmhg_basal +
    ieca_o_ara2,
  data = base_lineal
)

modelo_cox_tfg <- coxph(
  Surv(tiempo_seguimiento_dias, progresion_g5_o_trr) ~ tfg_10 + edad + sexo +
    diabetes + hipertension + log_proteinuria_basal + hemoglobina_g_dl_basal,
  data = base
)

# 3. TABLAS ---------------------------------------------------------------

# Tabla 2. Regresión logística (TFG continua)
tabla_02 <- tbl_regression(modelo_log_tfg, exponentiate = TRUE,
                           label = etiquetas[c(1, 3:8)]) %>%
  bold_p(t = 0.05) %>% bold_labels() %>%
  modify_caption("**Tabla 2. Factores asociados a la progresión a G5/TRR — regresión logística (OR ajustados)**")
guardar_tabla(tabla_02, "tabla_02_regresion_logistica.docx")

# Tabla 3. Regresión logística de Firth (estadio)
tabla_03 <- tibble(
  Variable = names(coef(modelo_firth)),
  OR       = exp(coef(modelo_firth)),
  IC_inf   = exp(modelo_firth$ci.lower),
  IC_sup   = exp(modelo_firth$ci.upper),
  p        = modelo_firth$prob
) %>%
  filter(Variable != "(Intercept)") %>%
  mutate(across(c(OR, IC_inf, IC_sup), ~ round(., 2)),
         p = format.pval(p, digits = 2, eps = 0.001))

flextable(tabla_03) %>%
  set_header_labels(IC_inf = "IC 95% inf.", IC_sup = "IC 95% sup.") %>%
  set_caption("Tabla 3. Progresión a G5/TRR según estadio basal — regresión logística de Firth") %>%
  autofit() %>%
  save_as_docx(path = here("output", "tables", "tabla_03_regresion_firth_estadio.docx"))

# Tabla 4. Regresión lineal (tasa de declive de TFG)
tabla_04 <- tbl_regression(modelo_lineal, label = etiquetas[2:10]) %>%
  add_glance_source_note(include = c(r.squared, adj.r.squared, nobs)) %>%
  bold_p(t = 0.05) %>% bold_labels() %>%
  modify_caption("**Tabla 4. Factores asociados a la tasa de declive de la TFG (mL/min/año) — regresión lineal**")
guardar_tabla(tabla_04, "tabla_04_regresion_lineal.docx")

# Tabla 5. Modelo de Cox (TFG continua)
tabla_05 <- tbl_regression(modelo_cox_tfg, exponentiate = TRUE,
                           label = etiquetas[c(1, 3:8)]) %>%
  bold_p(t = 0.05) %>% bold_labels() %>%
  modify_caption("**Tabla 5. Factores asociados al tiempo hasta la progresión a G5/TRR — modelo de Cox (HR ajustados)**")
guardar_tabla(tabla_05, "tabla_05_modelo_cox.docx")

# Tabla 6. Verificación de supuestos (resumen)
ph <- cox.zph(modelo_cox_tfg)
tabla_06 <- tibble(
  Modelo = c("Logístico", "Lineal", "Lineal", "Cox"),
  Supuesto = c("Bondad de ajuste (Hosmer-Lemeshow)",
               "Normalidad de residuos (Shapiro-Wilk)",
               "Homocedasticidad (Breusch-Pagan)",
               "Riesgos proporcionales (Schoenfeld, global)"),
  p = c(ResourceSelection::hoslem.test(as.numeric(base$progresion_g5_o_trr),
                                       fitted(modelo_log_tfg), g = 10)$p.value,
        shapiro.test(residuals(modelo_lineal))$p.value,
        lmtest::bptest(modelo_lineal)$p.value,
        ph$table["GLOBAL", "p"])
) %>%
  mutate(p = round(p, 3),
         Conclusión = ifelse(p > 0.05, "Supuesto cumplido", "Revisar"))

flextable(tabla_06) %>%
  set_caption("Tabla 6. Resumen de la verificación de supuestos") %>%
  autofit() %>%
  save_as_docx(path = here("output", "tables", "tabla_06_verificacion_supuestos.docx"))

# 4. FIGURAS --------------------------------------------------------------

colores_estadio <- c("#93C6E0", "#4A90D9", "#2E75B6", "#1F5C99")

# Figura 2. Curvas de Kaplan-Meier por estadio
km_estadio <- survfit(Surv(tiempo_seguimiento_dias, progresion_g5_o_trr) ~
                        estadio_basal, data = base)

fig_km <- ggsurvplot(km_estadio, data = base,
                     pval = TRUE, risk.table = TRUE,
                     palette = colores_estadio,
                     legend.labs = c("G2", "G3a", "G3b", "G4"),
                     legend.title = "Estadio de ERC",
                     xlab = "Tiempo (días)",
                     ylab = "Probabilidad libre de progresión",
                     title = "Curvas de Kaplan-Meier por estadio basal de ERC",
                     ggtheme = theme_minimal(base_size = 12))

png(here("output", "figures", "fig_02_kaplan_meier_estadio.png"),
    width = 9, height = 7, units = "in", res = 300)
print(fig_km)
dev.off()

# Figura 3. Forest plot del modelo de Cox
fig_forest <- tidy(modelo_cox_tfg, exponentiate = TRUE, conf.int = TRUE) %>%
  mutate(term = dplyr::recode(term,
    "tfg_10" = "TFG basal (por 10 mL/min)",
    "edad" = "Edad (por año)",
    "sexoMasculino" = "Sexo masculino",
    "diabetesTRUE" = "Diabetes",
    "hipertensionTRUE" = "Hipertensión",
    "log_proteinuria_basal" = "Log-proteinuria",
    "hemoglobina_g_dl_basal" = "Hemoglobina (por g/dL)")) %>%
  ggplot(aes(x = estimate, y = fct_rev(fct_inorder(term)))) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.2,
                orientation = "y", color = "#2E75B6") +
  geom_point(size = 3, color = "#1F5C99") +
  scale_x_log10() +
  labs(title = "Factores asociados al tiempo hasta la progresión",
       subtitle = "Modelo de Cox ajustado — HR e IC 95% (escala logarítmica)",
       x = "Hazard ratio", y = NULL) +
  theme_minimal(base_size = 12)

ggsave(here("output", "figures", "fig_03_forest_plot_cox.png"),
       plot = fig_forest, width = 8, height = 5, dpi = 300)

# Figura 4. Tasa de declive de la TFG por estadio
fig_declive <- ggplot(base_lineal,
                      aes(x = estadio_basal, y = tasa_declive_tfg,
                          fill = estadio_basal)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  scale_fill_manual(values = colores_estadio) +
  labs(title = "Tasa anual de declive de la TFG por estadio basal",
       x = "Estadio de ERC", y = "Tasa de declive (mL/min/año)") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave(here("output", "figures", "fig_04_declive_tfg_estadio.png"),
       plot = fig_declive, width = 8, height = 5, dpi = 300)

# 5. INFORMACIÓN DE SESIÓN ------------------------------------------------

capture.output(sessioninfo::session_info(),
               file = here("docs", "session_info_analisis.txt"))

cat("Tablas y figuras finales generadas en output/tables y output/figures\n")
