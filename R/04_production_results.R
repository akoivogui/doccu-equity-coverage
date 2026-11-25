# ==============================================================================
# PUBLIC REPOSITORY VERSION
# Analytical and production code only. Individual-level E-SIS data, derived
# caches and internal paths are not included. Configure DOCCU_ROOT_DERE,
# DOCCU_OUT_PRODUCTION and DOCCU_COMMUNES_SHP before running.
# ==============================================================================

# ==============================================================================
# DOCCU ILE-DE-FRANCE — EQUITE
# 04 — SCRIPT SYNTHETIQUE DE PRODUCTION DES RESULTATS
# ==============================================================================
#
# OBJET
# -----
# Produire, sans relancer les audits / QC / tests déjà effectués dans les scripts
# 01, 02 et 03, l'ensemble des sorties utiles :
#   - tableaux principaux de l'article ;
#   - tableaux supplémentaires ;
#   - figures principales ;
#   - figures supplémentaires ;
#   - cartographies destinées au manuscrit et à la Région Ile-de-France ;
#   - cartes bivariées FDep x couverture / gain documentaire ;
#   - exports techniques réutilisables ;
#   - éléments méthodologiques et légendes.
#
# SOURCES DE CODE
# ---------------
# Ce script est une synthèse stricte des trois scripts analytiques :
#   01_SYTX_DOCCU_EQUITE_RESULTATS_TABLEAUX_FIGURES.R
#   02_SYTX_DOCCU_EQUITE_RESULTATS_TABLEAUX_FIGURES.R
#   03_SYTX_DOCCU_EQUITE_EFFICACITE_ARTICLE_FINAL.R
#
# En cas de recouvrement, la définition finale du script 03 prévaut. Les sorties
# anciennes correspondant à une définition exploratoire ou remplacée ne sont pas
# reproduites. Le script 02 n'est repris que pour les produits encore utiles et
# non dupliqués (notamment la lecture par classe d'âge / département), recalculés
# ici avec la définition finale B.
#
# IMPORTANT
# ---------
# - AUCUN test statistique n'est recalculé.
# - AUCUN QC analytique n'est relancé.
# - AUCUNE sentinelle d'effectif n'est exécutée.
# - Les modèles ne sont PAS ré-estimés.
# - Les seuils des cartes bivariées ne sont PAS recalculés : ils sont relus dans
#   CACHE_21_CARTOGRAPHIES_BIVARIEES.rds.
# - Les résultats ajustés sont relus dans CACHE_17 / CACHE_18.
# - Les couches A/B/C finales sont relues dans les caches finaux du script 03.
#
# Le seul contrôle effectué par ce script est opérationnel : présence des fichiers
# indispensables à la production. Il ne s'agit pas d'un contrôle analytique.
#
# VERSION : 03/10/2026
# ==============================================================================

############# PACKAGES INSTALLES  ##############################################

# LIBRAIRIES A CHARGER POUR L'ELABORATION DES STATS DU RAPPORT D'ACTIVITE 2025

# Fixe le miroir CRAN pour éviter les erreurs de téléchargement
options(repos = c(CRAN = "https://cran.r-project.org"))
install.packages("svglite", type = "binary")
# Installer pkgbuild
install.packages("pkgbuild", type = "binary")

# Vérifier la présence des outils de compilation
pkgbuild::check_build_tools(debug = TRUE)


# Installer pacman si besoin, puis charger tous les packages utiles
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")

pacman::p_load(
  conflicted,   # Gestion des conflits entre package
  broom,        # mise en forme de modèles
  readr,        # import de données
  tools, 
  purrr         # programmation fonctionnelle
)
# MASS: modèles statistiques classiques et distributions
pacman::p_load(MASS)

# ROCnReg: analyse ROC non paramétrique avec régression
pacman::p_load(ROCnReg)

# boot: méthodes bootstrap pour estimation et IC
pacman::p_load(boot)

# cutpointr: détermination de seuils optimaux pour les variables continues
pacman::p_load(cutpointr)

# doParallel: backend pour l'exécution parallèle avec foreach
pacman::p_load(doParallel)

# dplyr: manipulation de données élégante et rapide
pacman::p_load(dplyr)

# flextable: création de tableaux personnalisés pour rapports
pacman::p_load(flextable)

# forcats: gestion des variables catégorielles (facteurs)
pacman::p_load(forcats)

# foreach: boucles parallèles avec backend compatible
pacman::p_load(foreach)

# ggeffects: effets marginaux des modèles (ggplot-friendly)
pacman::p_load(ggeffects)

# ggplot2: visualisation élégante avec la grammaire des graphiques
pacman::p_load(ggplot2)

# ggstats: tests statistiques intégrés dans les graphiques
pacman::p_load(ggstats)

# glmmrBase: modélisation GLMM spécifique à certaines structures
pacman::p_load(glmmrBase)

# gridExtra: organisation de plusieurs graphes dans une page
pacman::p_load(gridExtra)

# gtsummary: résumés statistiques propres et prêts pour publication
pacman::p_load(gtsummary)

# here: gestion de chemins de fichiers robustes et portables
pacman::p_load(here)

# janitor: nettoyage de données, noms de colonnes, doublons
pacman::p_load(janitor)

# labelled: gestion des labels d'importation (SPSS, STATA...)
pacman::p_load(labelled)

# lme4: modèles linéaires et mixtes (régression multi-niveaux)
pacman::p_load(lme4)

# magick: traitement et annotation d’images
pacman::p_load(magick)

# nlme: modèles linéaires et non-linéaires mixtes
pacman::p_load(nlme)

# parallel: fonctions natives pour le calcul parallèle
pacman::p_load(parallel)

# patchwork: agencement de plusieurs ggplots sur une page
pacman::p_load(patchwork)

# questionr: outils d’enquêtes, pondérations, tris croisés
pacman::p_load(questionr)

# readstata13: lecture des fichiers STATA (.dta) version 13+
pacman::p_load(readstata13)

# rmarkdown: génération de rapports dynamiques (HTML, PDF, Word)
pacman::p_load(rmarkdown)

# rstatix: tests statistiques simples et intuitifs
pacman::p_load(rstatix)

# skimr: résumés descriptifs complets et lisibles
pacman::p_load(skimr)

# survival: modélisation de survie (Cox, Kaplan-Meier)
pacman::p_load(survival)

# survminer: visualisation des analyses de survie
pacman::p_load(survminer)

# tiff: lecture et écriture de fichiers image TIFF
pacman::p_load(tiff)

pacman::p_load(docxtractr, officer,  kableExtra,
               # Manipulation de données
               dplyr, tidyr, purrr, stringr, tibble, janitor,
               # Visualisation
               ggplot2, scales, patchwork, plotly,
               # Tableaux & reporting
               flextable, officer, docxtractr, kableExtra,
               # Statistiques descriptives et modélisation
               epiDisplay, gtsummary, lme4, emmeans,
               # Dates et temps
               lubridate,
               # Lecture / écriture
               readr, readxl, writexl, openxlsx,
               ggspatial
)
pacman::p_load(broom.mixed, data.table, parallelly)

# ==============================================================================
# 0. PACKAGES DE PRODUCTION
# ==============================================================================

library(data.table)
library(ggplot2)
library(scales)
library(sf)
library(dplyr)
library(janitor)
library(flextable)
library(officer)
library(patchwork)
library(grid)


# ==============================================================================
# 1. PARAMETRES GENERAUX
# ==============================================================================

ANNEE_REF <- 2025L
DATE_REF <- as.Date("2025-12-31")
DATE_DEBUT_CYTO <- as.Date("2023-01-01")
DATE_DEBUT_HPV <- as.Date("2021-01-01")
SEUIL_N_CARTE <- 99L

DEPARTEMENTS_IDF <- c("75", "77", "78", "91", "92", "93", "94", "95")

NOMS_DEPARTEMENTS <- c(
  "75" = "Paris",
  "77" = "Seine-et-Marne",
  "78" = "Yvelines",
  "91" = "Essonne",
  "92" = "Hauts-de-Seine",
  "93" = "Seine-Saint-Denis",
  "94" = "Val-de-Marne",
  "95" = "Val-d'Oise"
)

GROUPES_AGE <- c("25–29 ans", "30–65 ans")
NIVEAUX_DOC <- c("A-CCAM", "A", "B", "C-strict", "C-broad")


# ==============================================================================
# 2. REPERTOIRES — AUTONOMIE DU SCRIPT
# ==============================================================================

repertoire_script <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  arg_file <- grep("^--file=", args, value = TRUE)

  if (length(arg_file) > 0L) {
    p <- sub("^--file=", "", arg_file[1])
    return(dirname(normalizePath(p, winslash = "/", mustWork = FALSE)))
  }

  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) "")
    if (nzchar(p)) {
      return(dirname(normalizePath(p, winslash = "/", mustWork = FALSE)))
    }
  }

  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

DIR_SCRIPT <- repertoire_script()

ROOT_DERE <- Sys.getenv(
  "DOCCU_ROOT_DERE",
  unset = file.path("PATH_TO_PROJECT_ROOT")
)

DIR_ARTICLE_FINAL_DEFAUT <- file.path(
  ROOT_DERE,
  "61_R/DOCCU_R/PROJET_BEH_DOCCU/EQUITE/ARTICLE_FINAL_2"
)

# Le script cherche d'abord les fichiers d'étape dans son propre répertoire,
# conformément à l'organisation retenue pour cette version de production.
DIR_ETAPES <- unique(c(
  DIR_SCRIPT,
  file.path(DIR_SCRIPT, "CACHE"),
  file.path(DIR_SCRIPT, "ARTICLE_FINAL_2", "CACHE"),
  file.path(DIR_ARTICLE_FINAL_DEFAUT, "CACHE")
))

DIR_OUT <- Sys.getenv(
  "DOCCU_OUT_PRODUCTION",
  unset = file.path(DIR_SCRIPT, "04_PRODUCTION_RESULTATS")
)

DIR_TABLEAUX <- file.path(DIR_OUT, "01_TABLEAUX_ARTICLE")
DIR_SUPPL_TABLEAUX <- file.path(DIR_OUT, "02_TABLEAUX_SUPPLEMENT")
DIR_FIGURES <- file.path(DIR_OUT, "03_FIGURES_ARTICLE")
DIR_SUPPL_FIGURES <- file.path(DIR_OUT, "04_FIGURES_SUPPLEMENT_ET_REGION_IDF")
DIR_REGION <- file.path(DIR_OUT, "05_CARTOGRAPHIES_REGION_IDF")
DIR_EXPORTS <- file.path(DIR_OUT, "06_EXPORTS_TECHNIQUES")
DIR_METHODES <- file.path(DIR_OUT, "07_METHODES_LEGENDES")
DIR_DOCUMENTS <- file.path(DIR_OUT, "08_DOCUMENTS_COMBINES")

for (d in c(
  DIR_OUT,
  DIR_TABLEAUX,
  DIR_SUPPL_TABLEAUX,
  DIR_FIGURES,
  DIR_SUPPL_FIGURES,
  DIR_REGION,
  DIR_EXPORTS,
  DIR_METHODES,
  DIR_DOCUMENTS
)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}


# ==============================================================================
# 3. LOCALISATION DES FICHIERS D'ETAPE
# ==============================================================================

trouver_etape <- function(nom_fichier) {
  candidats <- file.path(DIR_ETAPES, nom_fichier)
  candidats <- candidats[file.exists(candidats)]

  if (length(candidats) == 0L) {
    stop(
      paste0(
        "Fichier d'étape introuvable : ", nom_fichier,
        "\nRépertoires examinés :\n- ",
        paste(DIR_ETAPES, collapse = "\n- ")
      ),
      call. = FALSE
    )
  }

  candidats[1]
}

PATH_COMMUNES_SHP_DEFAUT <- file.path(
  ROOT_DERE,
  "63_BD/SHP/DATA_GAELLE/H_ADMINISTRATIF_IDF/communes-dile-de-france-au-01-janvier.shp"
)

PATH_COMMUNES_SHP <- Sys.getenv(
  "DOCCU_COMMUNES_SHP",
  unset = PATH_COMMUNES_SHP_DEFAUT
)

if (!file.exists(PATH_COMMUNES_SHP)) {
  shp_local <- file.path(
    DIR_SCRIPT,
    "communes-dile-de-france-au-01-janvier.shp"
  )
  if (file.exists(shp_local)) PATH_COMMUNES_SHP <- shp_local
}

VAR_INSEE_SHP <- "insee_1"


# ==============================================================================
# 4. CHARGEMENT DES CACHES FINAUX — AUCUN RECALCUL ANALYTIQUE
# ==============================================================================

FICHIERS_ETAPE_REQUIS <- c(
  "CACHE_10_BASE_FEMME_2025_FINAL.rds",
  "CACHE_12_BASE_COMMUNE_2025.rds",
  "CACHE_13_BASE_COMMUNE_FDEP_2025.rds",
  "CACHE_14_TABLEAU_1_REGIONAL.rds",
  "CACHE_15_TABLEAU_2_DEPARTEMENTAL.rds",
  "CACHE_16_TABLEAU_3_FDEP.rds",
  "CACHE_17_SII_RII.rds",
  "CACHE_18_MODELES_AJUSTES_FDEP.rds",
  "CACHE_21_CARTOGRAPHIES_BIVARIEES.rds",
  "CACHE_22_PROFONDEUR_DOCUMENTAIRE.rds",
  "CACHE_23_CCAM_VS_REFERENCE_VS_B.rds"
)

# Ce manifeste est documentaire seulement : il n'effectue aucun QC analytique.
MANIFESTE_ETAPES <- data.table(
  fichier = FICHIERS_ETAPE_REQUIS,
  role = c(
    "Base individuelle finale D0/D1/D2, A/B/C et niveaux N0-N3",
    "Base communale finale D0/D1/D2",
    "Base communale appariée au FDep",
    "Résultats régionaux et sensibilité des dénominateurs",
    "Résultats départementaux",
    "Résultats descriptifs par quintile FDep",
    "SII/RII déjà estimés",
    "Modèles ajustés et marginales déjà estimés",
    "Seuils, classes et palette des cartes bivariées",
    "Profondeur documentaire A vers B",
    "A-CCAM versus codes de référence versus B"
  )
)

BASE_FEMME_2025 <- readRDS(trouver_etape("CACHE_10_BASE_FEMME_2025_FINAL.rds"))
BASE_COMMUNE_2025 <- readRDS(trouver_etape("CACHE_12_BASE_COMMUNE_2025.rds"))
BASE_COMMUNE_FDEP_2025 <- readRDS(trouver_etape("CACHE_13_BASE_COMMUNE_FDEP_2025.rds"))
CACHE_14 <- readRDS(trouver_etape("CACHE_14_TABLEAU_1_REGIONAL.rds"))
CACHE_15 <- readRDS(trouver_etape("CACHE_15_TABLEAU_2_DEPARTEMENTAL.rds"))
CACHE_16 <- readRDS(trouver_etape("CACHE_16_TABLEAU_3_FDEP.rds"))
CACHE_17 <- readRDS(trouver_etape("CACHE_17_SII_RII.rds"))
CACHE_18 <- readRDS(trouver_etape("CACHE_18_MODELES_AJUSTES_FDEP.rds"))
CACHE_21 <- readRDS(trouver_etape("CACHE_21_CARTOGRAPHIES_BIVARIEES.rds"))
CACHE_22 <- readRDS(trouver_etape("CACHE_22_PROFONDEUR_DOCUMENTAIRE.rds"))
CACHE_23 <- readRDS(trouver_etape("CACHE_23_CCAM_VS_REFERENCE_VS_B.rds"))

setDT(BASE_FEMME_2025)
setDT(BASE_COMMUNE_2025)
setDT(BASE_COMMUNE_FDEP_2025)


# ==============================================================================
# 5. FONCTIONS DE FORMATAGE ET D'EXPORT
# ==============================================================================

fmt_n <- function(x) {
  format(x, big.mark = " ", scientific = FALSE, trim = TRUE)
}

fmt_num <- function(x, digits = 2L, signed = FALSE) {
  z <- formatC(
    as.numeric(x),
    format = "f",
    digits = digits,
    decimal.mark = ","
  )
  if (signed) {
    z <- ifelse(as.numeric(x) > 0, paste0("+", z), z)
  }
  z
}

fmt_pct <- function(x, digits = 2L) {
  paste0(fmt_num(x, digits), " %")
}

fmt_npct <- function(n, p, digits = 2L) {
  paste0(fmt_n(n), " (", fmt_num(p, digits), " %)")
}

fmt_pp <- function(x, digits = 2L, signed = FALSE) {
  paste0(fmt_num(x, digits, signed = signed), " pp")
}

fmt_ci <- function(est, inf, sup, digits = 2L) {
  paste0(
    fmt_num(est, digits),
    " [",
    fmt_num(inf, digits),
    " ; ",
    fmt_num(sup, digits),
    "]"
  )
}

fmt_ratio_ci <- function(est, inf, sup, digits = 3L) {
  paste0(
    fmt_num(est, digits),
    " [",
    fmt_num(inf, digits),
    " ; ",
    fmt_num(sup, digits),
    "]"
  )
}

style_table <- function(ft, size = 8.5) {
  ft <- theme_booktabs(ft)
  ft <- fontsize(ft, size = size, part = "all")
  ft <- font(ft, fontname = "Arial", part = "all")
  ft <- bold(ft, part = "header")
  ft <- align(ft, align = "center", part = "header")
  ft <- valign(ft, valign = "center", part = "all")
  ft <- autofit(ft)
  set_table_properties(ft, layout = "autofit", width = 1)
}

sauver_table_word <- function(ft, fichier) {
  flextable::save_as_docx(
    "Tableau" = ft,
    path = fichier
  )
}

sauver_figure <- function(p, stem, dir_out, width, height, dpi = 320) {
  ggsave(
    filename = file.path(dir_out, paste0(stem, ".png")),
    plot = p,
    width = width,
    height = height,
    units = "in",
    dpi = dpi,
    bg = "white"
  )

  ggsave(
    filename = file.path(dir_out, paste0(stem, ".pdf")),
    plot = p,
    width = width,
    height = height,
    units = "in",
    bg = "white"
  )
}

export_csv <- function(x, nom, dir_out = DIR_EXPORTS) {
  data.table::fwrite(
    data.table::as.data.table(x),
    file.path(dir_out, nom),
    sep = ";",
    bom = TRUE
  )
}


# ==============================================================================
# 6. TABLEAU 1 — COUVERTURE SELON LA PROFONDEUR DOCUMENTAIRE
# ==============================================================================
conflicts_prefer(flextable::font)

T1_CCAM <- as.data.table(CACHE_23$couverture)[
  ,
  .(
    groupe_age,
    N,
    A_CCAM,
    A = A_REFERENCE,
    B
  )
]

T1_C <- as.data.table(CACHE_14$tableau_1)[
  ,
  .(
    groupe_age,
    C_strict,
    C_broad
  )
]

TABLEAU_1_DATA <- merge(
  T1_CCAM,
  T1_C,
  by = "groupe_age",
  all.x = TRUE,
  sort = FALSE
)

TABLEAU_1_DATA[
  ,
  `:=`(
    A_CCAM_pct = 100 * A_CCAM / N,
    A_pct = 100 * A / N,
    B_pct = 100 * B / N,
    C_strict_pct = 100 * C_strict / N,
    C_broad_pct = 100 * C_broad / N
  )
]

TABLEAU_1_DATA[
  ,
  ordre := match(groupe_age, c("25–29 ans", "30–65 ans", "25–65 ans"))
]
setorder(TABLEAU_1_DATA, ordre)

TABLEAU_1_PRINT <- TABLEAU_1_DATA[
  ,
  .(
    `Age group` = fifelse(groupe_age == "25–29 ans", "25–29 years", fifelse(groupe_age == "30–65 ans", "30–65 years", fifelse(groupe_age == "25–65 ans", "25–65 years", groupe_age))),
    `Population, N` = fmt_n(N),
    `A-CCAM, n (%)` = fmt_npct(A_CCAM, A_CCAM_pct),
    `A, n (%)` = fmt_npct(A, A_pct),
    `B, n (%)` = fmt_npct(B, B_pct),
    `C-strict, n (%)` = fmt_npct(C_strict, C_strict_pct),
    `C-broad, n (%)` = fmt_npct(C_broad, C_broad_pct)
  )
]

ft_T1 <- flextable(TABLEAU_1_PRINT)
ft_T1 <- style_table(ft_T1, size = 8.3)
ft_T1 <- set_caption(
  ft_T1,
  caption = paste0(
    "Table 1. Cervical cancer screening coverage according to documentary depth, Île-de-France, ",
    ANNEE_REF
  )
)
ft_T1 <- add_footer_lines(
  ft_T1,
  values = c(
    "A-CCAM: expected test identified exclusively from the retained CCAM codes; A: expected test identified from the full set of reference codes; B: the same expected test directly documented, irrespective of the documentary pathway.",
    "C-strict: B supplemented, among women not meeting B, by an alternative cervical test explicitly documented as screening or by concordant evidence establishing strong cervical-care continuity; C-broad: C-strict supplemented by documented cervical pathways that are compatible but less specific.",
    "The expected test was cytology between 1 January 2023 and 31 December 2025 for women aged 25–29 years, and an HPV test between 1 January 2021 and 31 December 2025 for women aged 30–65 years.",
    "The C levels are documentary sensitivity analyses and should not be interpreted as estimates of guideline-concordant coverage."
  )
)

export_csv(TABLEAU_1_DATA, "TABLEAU_1_COUVERTURE_PROFONDEUR_DOCUMENTAIRE.csv", DIR_TABLEAUX)
sauver_table_word(ft_T1, file.path(DIR_TABLEAUX, "TABLEAU_1_COUVERTURE_PROFONDEUR_DOCUMENTAIRE.docx"))


# ==============================================================================
# 7. TABLEAU 2 — COUVERTURE DEPARTEMENTALE B / C-STRICT
# ==============================================================================

T2 <- as.data.table(CACHE_15$tableau_2)
T2 <- T2[groupe_age %in% GROUPES_AGE]
T2[, dep := as.character(dep)]
T2[, departement := ifelse(is.na(departement), unname(NOMS_DEPARTEMENTS[dep]), departement)]

T2_25 <- T2[
  groupe_age == "25–29 ans",
  .(
    dep,
    Departement = departement,
    N_25 = N,
    B_25 = fmt_npct(B, B_pct),
    CS_25 = fmt_npct(C_strict, C_strict_pct),
    Gain_25 = fmt_num(gain_B_Cstrict_pp, 2, signed = TRUE)
  )
]

T2_30 <- T2[
  groupe_age == "30–65 ans",
  .(
    dep,
    N_30 = N,
    B_30 = fmt_npct(B, B_pct),
    CS_30 = fmt_npct(C_strict, C_strict_pct),
    Gain_30 = fmt_num(gain_B_Cstrict_pp, 2, signed = TRUE)
  )
]

T2_PRINT <- merge(T2_25, T2_30, by = "dep", all = TRUE, sort = FALSE)
T2_PRINT[, ordre := match(dep, DEPARTEMENTS_IDF)]
setorder(T2_PRINT, ordre)
T2_PRINT <- T2_PRINT[
  ,
  .(
    `Department` = Departement,
    `N` = fmt_n(N_25),
    `B, n (%)` = B_25,
    `C-strict, n (%)` = CS_25,
    `Gain, pp` = Gain_25,
    `N ` = fmt_n(N_30),
    `B, n (%) ` = B_30,
    `C-strict, n (%) ` = CS_30,
    `Gain, pp ` = Gain_30
  )
]

ft_T2 <- flextable(T2_PRINT)
ft_T2 <- style_table(ft_T2, size = 7.8)
ft_T2 <- add_header_row(
  ft_T2,
  values = c("", "25–29 years — cytology", "30–65 years — HPV"),
  colwidths = c(1, 4, 4)
)
ft_T2 <- set_caption(
  ft_T2,
  caption = paste0(
    "Table 2. Documented screening coverage and sensitivity to broader documentary ascertainment by department, Île-de-France, ",
    ANNEE_REF
  )
)
ft_T2 <- add_footer_lines(
  ft_T2,
  values = c(
    "B: expected test directly documented within the coverage window; C-strict: B supplemented by an alternative cervical test explicitly documented as screening or by strong cervical-care continuity.",
    "The expected test was cytology in 2023–2025 for women aged 25–29 years and an HPV test in 2021–2025 for women aged 30–65 years.",
    "Gain: absolute difference C-strict − B, expressed in percentage points (pp). Values correspond to the primary denominator D0.",
    "C-strict is a documentary sensitivity analysis and should not be interpreted as an estimate of guideline-concordant coverage."
  )
)

export_csv(T2, "TABLEAU_2_COUVERTURE_DEPARTEMENTALE_B_CSTRICT.csv", DIR_TABLEAUX)
sauver_table_word(ft_T2, file.path(DIR_TABLEAUX, "TABLEAU_2_COUVERTURE_DEPARTEMENTALE_B_CSTRICT.docx"))


# ==============================================================================
# 8. TABLEAU 3 — INEGALITES FDEP B / C-STRICT
# ==============================================================================

T3_FDEP <- as.data.table(CACHE_16$tableau_fdep)
T3_SII <- as.data.table(CACHE_17$tableau_principal)[
  indicateur %in% c("B", "C_strict")
]

T3_LONG <- rbindlist(list(
  T3_FDEP[, .(groupe_age, quintile_fdep_num, definition = "B", couverture = B_pct)],
  T3_FDEP[, .(groupe_age, quintile_fdep_num, definition = "C-strict", couverture = C_strict_pct)]
))

T3_WIDE <- dcast(
  T3_LONG,
  groupe_age + definition ~ quintile_fdep_num,
  value.var = "couverture"
)
setnames(T3_WIDE, c("1", "2", "3", "4", "5"), paste0("Q", 1:5))
T3_WIDE[, `Q5-Q1` := Q5 - Q1]

T3_SII2 <- T3_SII[
  ,
  .(
    groupe_age,
    definition = fifelse(indicateur == "C_strict", "C-strict", indicateur),
    SII = SII_pp,
    RII
  )
]

T3_FINAL <- merge(
  T3_WIDE,
  T3_SII2,
  by = c("groupe_age", "definition"),
  all.x = TRUE,
  sort = FALSE
)
T3_FINAL[, ordre_age := match(groupe_age, GROUPES_AGE)]
T3_FINAL[, ordre_def := match(definition, c("B", "C-strict"))]
setorder(T3_FINAL, ordre_age, ordre_def)

T3_PRINT <- T3_FINAL[
  ,
  .(
    `Age group` = fifelse(groupe_age == "25–29 ans", "25–29 years", fifelse(groupe_age == "30–65 ans", "30–65 years", fifelse(groupe_age == "25–65 ans", "25–65 years", groupe_age))),
    `Definition` = definition,
    `Q1` = fmt_num(Q1, 2),
    `Q2` = fmt_num(Q2, 2),
    `Q3` = fmt_num(Q3, 2),
    `Q4` = fmt_num(Q4, 2),
    `Q5` = fmt_num(Q5, 2),
    `Q5 – Q1, pp` = fmt_num(`Q5-Q1`, 2),
    `SII, pp` = fmt_num(SII, 2),
    `RII` = fmt_num(RII, 3)
  )
]

ft_T3 <- flextable(T3_PRINT)
ft_T3 <- style_table(ft_T3, size = 8)
ft_T3 <- merge_v(ft_T3, j = 1)
ft_T3 <- valign(ft_T3, j = 1, valign = "top")
ft_T3 <- set_caption(
  ft_T3,
  caption = paste0(
    "Table 3. Socio-territorial inequalities in coverage according to municipal deprivation and documentary depth, Île-de-France, ",
    ANNEE_REF
  )
)
ft_T3 <- add_footer_lines(
  ft_T3,
  values = c(
    "B: expected test directly documented; C-strict: B supplemented by an alternative cervical test explicitly documented as screening or by strong cervical-care continuity.",
    "FDep: French Deprivation Index. Q1 corresponds to the least deprived municipalities and Q5 to the most deprived municipalities.",
    "SII: Slope Index of Inequality; RII: Relative Index of Inequality. The FDep ridit score was calculated separately within each age group and weighted by the municipal population.",
    "SII/RII were based on quasi-binomial models fitted separately by age group with an identity link, using all municipalities matched to FDep without applying the N ≥ 100 threshold; SII = predicted difference between the extremes of the ridit score and RII = ratio of predicted coverage.",
    "A negative SII or an RII < 1 indicates lower coverage at higher levels of deprivation. The threshold of 100 women is used only for mapping."
  )
)

export_csv(T3_FINAL, "TABLEAU_3_INEGALITES_FDEP_B_CSTRICT.csv", DIR_TABLEAUX)
sauver_table_word(ft_T3, file.path(DIR_TABLEAUX, "TABLEAU_3_INEGALITES_FDEP_B_CSTRICT.docx"))


# ==============================================================================
# 9. SUPPLEMENTARY TABLES S1A A S1F
# ==============================================================================

# ------------------------------------------------------------------------------
# S1A — profils CCAM / codes numériques parmi A
# ------------------------------------------------------------------------------

S1A <- as.data.table(CACHE_23$profils_codes)
S1A[, ordre_age := match(groupe_age, GROUPES_AGE)]
S1A[, ordre_profil := match(
  profil_code_reference,
  c("CCAM uniquement", "Code numérique uniquement", "CCAM + code numérique", "Autre")
)]
setorder(S1A, ordre_age, ordre_profil)

S1A_PRINT <- S1A[
  ,
  .(
    `Age group` = fifelse(groupe_age == "25–29 ans", "25–29 years", fifelse(groupe_age == "30–65 ans", "30–65 years", fifelse(groupe_age == "25–65 ans", "25–65 years", groupe_age))),
    `Coding profile` = data.table::fcase(
      profil_code_reference == "CCAM uniquement", "CCAM only",
      profil_code_reference == "Code numérique uniquement", "Numerical code only",
      profil_code_reference == "CCAM + code numérique", "CCAM + numerical code",
      profil_code_reference == "Autre", "Other",
      default = as.character(profil_code_reference)
    ),
    `Women, n (%)` = fmt_npct(n_femmes, pct_femmes_A_reference)
  )
]

ft_S1A <- style_table(flextable(S1A_PRINT), size = 8.5)
ft_S1A <- set_caption(
  ft_S1A,
  caption = "Table S1A. Contribution of CCAM codes and numerical reference codes to identification of the expected test"
)
ft_S1A <- add_footer_lines(
  ft_S1A,
  values = "Percentages are calculated among women meeting definition A based on the full set of reference codes."
)

export_csv(S1A, "TABLEAU_S1A_PROFILS_CODES.csv", DIR_SUPPL_TABLEAUX)
sauver_table_word(ft_S1A, file.path(DIR_SUPPL_TABLEAUX, "TABLEAU_S1A_PROFILS_CODES.docx"))


# ------------------------------------------------------------------------------
# S1B — codes observés dans les épisodes documentant le test attendu
# Titre clarifié : un code observé dans B n'est pas nécessairement qualifiant A.
# ------------------------------------------------------------------------------

S1B <- as.data.table(CACHE_22$distribution_codes)
S1B_PRINT <- S1B[
  ,
  .(
    `Age group` = fifelse(groupe_age == "25–29 ans", "25–29 years", fifelse(groupe_age == "30–65 ans", "30–65 years", fifelse(groupe_age == "25–65 ans", "25–65 years", groupe_age))),
    `Modality` = data.table::fcase(
      modalite == "Cytologie", "Cytology",
      modalite == "HPV", "HPV",
      default = as.character(modalite)
    ),
    `Code` = code,
    `Code family` = data.table::fcase(
      famille_code == "CCAM", "CCAM",
      famille_code == "Code numérique du référentiel source", "Numerical code from source reference system",
      famille_code == "Autre code", "Other code",
      default = as.character(famille_code)
    ),
    `Occurrences, n (%)` = fmt_npct(n_lignes_source, pct_lignes_source),
    `Episodes` = fmt_n(n_episodes),
    `Women` = fmt_n(n_femmes)
  )
]

ft_S1B <- style_table(flextable(S1B_PRINT), size = 7.5)
ft_S1B <- set_caption(
  ft_S1B,
  caption = "Table S1B. Distribution of codes observed in episodes documenting the expected test"
)
ft_S1B <- add_footer_lines(
  ft_S1B,
  values = c(
    "Occurrences correspond to source rows containing the code; the same episode or woman may contribute to several codes.",
    "The presence of a code in a B episode does not necessarily imply that this code, considered in isolation, qualifies for definition A. JKQX… and ZZQX… codes are classified as CCAM codes; numerical codes are classified as numerical codes from the source reference system."
  )
)

export_csv(S1B, "TABLEAU_S1B_DISTRIBUTION_CODES_OBSERVES_EPISODES_B.csv", DIR_SUPPL_TABLEAUX)
sauver_table_word(ft_S1B, file.path(DIR_SUPPL_TABLEAUX, "TABLEAU_S1B_DISTRIBUTION_CODES.docx"))


# ------------------------------------------------------------------------------
# S1C — profondeur documentaire des épisodes B
# La colonne ancienne « finalité dépistage explicite » est volontairement retirée.
# Le script 03 distingue explicitement existence documentée du test et finalité.
# ------------------------------------------------------------------------------

S1C <- as.data.table(CACHE_22$profondeur_episodes)
S1C[, ordre_age := match(groupe_age, c("30–65 ans", "25–29 ans"))]
setorder(S1C, ordre_age)

S1C_PRINT <- S1C[
  ,
  .(
    `Age group` = fifelse(groupe_age == "25–29 ans", "25–29 years", fifelse(groupe_age == "30–65 ans", "30–65 years", fifelse(groupe_age == "25–65 ans", "25–65 years", groupe_age))),
    `Expected test` = data.table::fcase(
      modalite_attendue == "Cytologie", "Cytology",
      modalite_attendue == "HPV", "HPV",
      default = as.character(modalite_attendue)
    ),
    `B episodes` = fmt_n(n_episodes_B),
    `Code retained for definition A, n (%)` = fmt_npct(n_code_reference, pct_code_reference),
    `Any code identifying the test modality, n (%)` = fmt_npct(n_code_quelconque, pct_code_quelconque),
    `No code identifying the test modality, n (%)` = fmt_npct(n_sans_aucun_code, pct_sans_aucun_code),
    `Documented result, n (%)` = fmt_npct(n_resultat_documente, pct_resultat_documente),
    `No identifying code + documented result, n (%)` = fmt_npct(n_sans_code_avec_resultat, pct_sans_code_avec_resultat)
  )
]

ft_S1C <- style_table(flextable(S1C_PRINT), size = 7.8)
ft_S1C <- set_caption(
  ft_S1C,
  caption = "Table S1C. Documentary depth of episodes meeting definition B"
)
ft_S1C <- add_footer_lines(
  ft_S1C,
  values = c(
    "B identifies the expected test irrespective of the documentary pathway. Percentages are calculated among B episodes within each age group.",
    "“No code identifying the test modality” means that none of the codes identifying the expected test was present in the coding fields considered.",
    "A specific test result provides direct evidence that the test was performed but does not necessarily establish that it was performed for primary screening."
  )
)

export_csv(S1C, "TABLEAU_S1C_PROFONDEUR_EPISODES_B.csv", DIR_SUPPL_TABLEAUX)
sauver_table_word(ft_S1C, file.path(DIR_SUPPL_TABLEAUX, "TABLEAU_S1C_PROFONDEUR_EPISODES.docx"))


# ------------------------------------------------------------------------------
# S1D — résultats des épisodes B sans code identifiable
# ------------------------------------------------------------------------------

S1D <- as.data.table(CACHE_22$resultats_sans_code)
S1D_PRINT <- S1D[
  ,
  .(
    `Age group` = fifelse(groupe_age == "25–29 ans", "25–29 years", fifelse(groupe_age == "30–65 ans", "30–65 years", fifelse(groupe_age == "25–65 ans", "25–65 years", groupe_age))),
    `Expected test` = data.table::fcase(
      modalite_attendue == "Cytologie", "Cytology",
      modalite_attendue == "HPV", "HPV",
      default = as.character(modalite_attendue)
    ),
    `Observed result` = data.table::fcase(
      statut_resultat_sans_code == "Résultat cytologique documenté non classé anormal", "Documented cytology result not classified as abnormal",
      statut_resultat_sans_code == "Résultat cytologique anormal", "Abnormal cytology result",
      statut_resultat_sans_code == "Aucun résultat visible", "No visible result",
      statut_resultat_sans_code == "HPV négatif", "HPV negative",
      statut_resultat_sans_code == "HPV positif", "HPV positive",
      statut_resultat_sans_code == "HPV non contributif", "Non-contributory HPV result",
      default = as.character(statut_resultat_sans_code)
    ),
    `Episodes, n (%)` = fmt_npct(n_episodes, pct_episodes_sans_code),
    `Women` = fmt_n(n_femmes)
  )
]

ft_S1D <- style_table(flextable(S1D_PRINT), size = 8)
ft_S1D <- set_caption(
  ft_S1D,
  caption = "Table S1D. Documented results among B episodes without an identifiable code for the expected test"
)
ft_S1D <- add_footer_lines(
  ft_S1D,
  values = "Percentages are calculated among B episodes without an identifiable code for the expected modality within each age group."
)

export_csv(S1D, "TABLEAU_S1D_RESULTATS_SANS_CODE.csv", DIR_SUPPL_TABLEAUX)
sauver_table_word(ft_S1D, file.path(DIR_SUPPL_TABLEAUX, "TABLEAU_S1D_RESULTATS_SANS_CODE.docx"))


# ------------------------------------------------------------------------------
# S1E — femmes B hors A
# ------------------------------------------------------------------------------

S1E_SRC <- as.data.table(CACHE_22$synthese_B_hors_A)

s1e_val <- function(groupe, var_n, var_pct) {
  r <- S1E_SRC[groupe_age == groupe]
  if (nrow(r) == 0L || !var_n %in% names(r)) return("—")
  n <- r[[var_n]][1]
  if (is.na(n)) return("—")
  if (!var_pct %in% names(r) || is.na(r[[var_pct]][1])) return(fmt_n(n))
  fmt_npct(n, r[[var_pct]][1])
}

S1E_PRINT <- data.table(
  `Documentary indicator` = c(
    "Women meeting B but not A",
    "No identifiable code for the expected test",
    "With documented result",
    "No identifiable code + documented result",
    "Screening explicitly identifiable in the available fields",
    "Abnormal cytology without an identifying code",
    "HPV-positive result without an identifying code",
    "HPV-negative result without an identifying code"
  ),
  `25–29 years` = c(
    fmt_n(S1E_SRC[groupe_age == "25–29 ans", n_femmes][1]),
    s1e_val("25–29 ans", "sans_aucun_code", "pct_sans_aucun_code"),
    s1e_val("25–29 ans", "avec_resultat", "pct_avec_resultat"),
    s1e_val("25–29 ans", "sans_code_avec_resultat", "pct_sans_code_avec_resultat"),
    s1e_val("25–29 ans", "depistage_direct_explicitement_documente", "pct_depistage_direct_explicitement_documente"),
    s1e_val("25–29 ans", "cyto_anormale_sans_code", "pct_cyto_anormale_sans_code"),
    "—",
    "—"
  ),
  `30–65 years` = c(
    fmt_n(S1E_SRC[groupe_age == "30–65 ans", n_femmes][1]),
    s1e_val("30–65 ans", "sans_aucun_code", "pct_sans_aucun_code"),
    s1e_val("30–65 ans", "avec_resultat", "pct_avec_resultat"),
    s1e_val("30–65 ans", "sans_code_avec_resultat", "pct_sans_code_avec_resultat"),
    s1e_val("30–65 ans", "depistage_direct_explicitement_documente", "pct_depistage_direct_explicitement_documente"),
    "—",
    s1e_val("30–65 ans", "hpv_positif_sans_code", "pct_hpv_positif_sans_code"),
    s1e_val("30–65 ans", "hpv_negatif_sans_code", "pct_hpv_negatif_sans_code")
  )
)

ft_S1E <- style_table(flextable(S1E_PRINT), size = 8)
ft_S1E <- set_caption(
  ft_S1E,
  caption = "Table S1E. Documentary characteristics of women meeting B but not A"
)
ft_S1E <- add_footer_lines(
  ft_S1E,
  values = c(
    "Indicators are not mutually exclusive. Percentages are calculated among women meeting B but not A in the corresponding age group.",
    "Explicitly identifiable screening is based on the documentary fields available and should not be interpreted as an exhaustive measure of clinical indication."
  )
)

export_csv(S1E_SRC, "TABLEAU_S1E_FEMMES_B_HORS_A_SOURCE.csv", DIR_SUPPL_TABLEAUX)
export_csv(S1E_PRINT, "TABLEAU_S1E_FEMMES_B_HORS_A_AFFICHAGE.csv", DIR_SUPPL_TABLEAUX)
sauver_table_word(ft_S1E, file.path(DIR_SUPPL_TABLEAUX, "TABLEAU_S1E_FEMMES_B_HORS_A.docx"))


# ------------------------------------------------------------------------------
# S1F — règles de classement A/B/C et niveaux N3/N2/N1# Strictement dérivé du bloc 09 du script 03.
# ------------------------------------------------------------------------------

S1F <- data.table(
  `Population / level` = c(
    "All ages — A-CCAM",
    "All ages — A",
    "All ages — B",
    "25–29 years — N3",
    "25–29 years — N2",
    "25–29 years — N1",
    "30–65 years — N3",
    "30–65 years — N2",
    "30–65 years — N1",
    "All ages — C-strict",
    "All ages — C-broad",
    "All ages — N0"
  ),
  `Documentary rule` = c(
    "Age-appropriate expected test identified using only the retained CCAM codes within the coverage window.",
    "Age-appropriate expected test identified using the full set of reference codes within the coverage window.",
    "The same expected test directly documented within the window, irrespective of the documentary pathway.",
    "B not met; HPV test performed in 2023–2025 and explicitly documented as screening.",
    "N3 not met; recent ambiguous/non-explicit HPV test AND recent colposcopy or histology follow-up evidence in 2023–2025.",
    "N3/N2 not met; isolated recent ambiguous HPV test OR isolated recent colposcopy or histology follow-up evidence.",
    "B not met; cytology performed in 2021–2025 and directly identified as screening/organized screening.",
    "N3 not met; recent cytology explicitly documented as follow-up OR convergence of a recent cytology not directly identified as screening with colposcopy or histology follow-up evidence in 2021–2025.",
    "N3/N2 not met; compatible residual activity: isolated recent non-direct cytology, cytological abnormality, colposcopy/histology, or other recent follow-up evidence without sufficient convergence for N2.",
    "B + N3 + N2.",
    "C-strict + N1.",
    "No qualifying signal among N1, N2 or N3 within the corresponding window."
  ),
  `Interpretation` = c(
    "CCAM-coded identification of the expected test.",
    "Broader coded identification of the expected test.",
    "Primary documentary coverage based on the expected test; the clinical indication is not systematically observable.",
    "Alternative cervical test directly documented; documentary sensitivity analysis, not guideline-concordant coverage.",
    "Strong documentary continuity.",
    "Compatible but less specific cervical pathway.",
    "Alternative cervical test directly documented; documentary sensitivity analysis, not guideline-concordant coverage.",
    "Strong documentary continuity.",
    "Compatible but less specific cervical pathway.",
    "Strong documentary sensitivity analysis.",
    "Broad documentary sensitivity analysis.",
    "No documentary activity sufficient for C."
  )
)

ft_S1F <- style_table(flextable(S1F), size = 7.4)
ft_S1F <- set_caption(
  ft_S1F,
  caption = "Table S1F. Classification rules according to documentary depth and age group"
)
ft_S1F <- add_footer_lines(
  ft_S1F,
  values = c(
    "Among women not meeting B, levels N3, N2, N1 and N0 are mutually exclusive.",
    "An isolated colposcopy or histology result is never considered evidence of the expected primary test. An isolated cytological abnormality or histology result is not, by itself, an autonomous N2 criterion among women aged 30–65 years.",
    "C-strict and C-broad are documentary sensitivity analyses, not alternative estimates of guideline-concordant coverage."
  )
)

export_csv(S1F, "TABLEAU_S1F_REGLES_CLASSEMENT_DOCUMENTAIRE.csv", DIR_SUPPL_TABLEAUX)
sauver_table_word(ft_S1F, file.path(DIR_SUPPL_TABLEAUX, "TABLEAU_S1F_REGLES_CLASSEMENT_DOCUMENTAIRE.docx"))


# ==============================================================================
# 10. TABLEAU S2 — SENSIBILITE D0 / D1 / D2
# ==============================================================================

S2 <- as.data.table(CACHE_14$sensibilite_D012)
S2[, ordre_age := match(groupe_age, c("25–29 ans", "30–65 ans", "25–65 ans"))]
S2[, ordre_scenario := match(scenario, c("D0", "D1", "D2"))]
setorder(S2, ordre_age, ordre_scenario)

S2[, N_D0 := N[scenario == "D0"][1], by = groupe_age]
S2[, B_pct_D0 := B_pct[scenario == "D0"][1], by = groupe_age]
S2[, C_strict_pct_D0 := C_strict_pct[scenario == "D0"][1], by = groupe_age]
S2[, `:=`(
  exclusions_vs_D0_n = N_D0 - N,
  exclusions_vs_D0_pct = 100 * (N_D0 - N) / N_D0,
  ecart_B_vs_D0_pp = B_pct - B_pct_D0,
  ecart_Cstrict_vs_D0_pp = C_strict_pct - C_strict_pct_D0
)]

S2_PRINT <- S2[
  ,
  .(
    `Age group` = fifelse(groupe_age == "25–29 ans", "25–29 years", fifelse(groupe_age == "30–65 ans", "30–65 years", fifelse(groupe_age == "25–65 ans", "25–65 years", groupe_age))),
    `Scenario` = scenario,
    `Population, N` = fmt_n(N),
    `Exclusions vs D0, n (%)` = fmt_npct(exclusions_vs_D0_n, exclusions_vs_D0_pct),
    `B, n (%)` = fmt_npct(B, B_pct),
    `Difference in B vs D0, pp` = fmt_num(ecart_B_vs_D0_pp, 2, signed = TRUE),
    `C-strict, n (%)` = fmt_npct(C_strict, C_strict_pct),
    `Difference in C-strict vs D0, pp` = fmt_num(ecart_Cstrict_vs_D0_pp, 2, signed = TRUE)
  )
]

ft_S2 <- style_table(flextable(S2_PRINT), size = 7.7)
ft_S2 <- merge_v(ft_S2, j = 1)
ft_S2 <- set_caption(
  ft_S2,
  caption = "Table S2. Sensitivity of coverage estimates to documented medical exclusions using denominators D0, D1 and D2"
)
ft_S2 <- add_footer_lines(
  ft_S2,
  values = c(
    "D0: primary target population, without removing documented medical exclusions; D1: conservative scenario; D2: broader scenario.",
    "Screening refusal is never considered an exclusion from the denominator.",
    "Differences are expressed relative to the D0 scenario within the same age group. Because exclusion information is not exhaustive, D1 and D2 are sensitivity analyses only."
  )
)

export_csv(S2, "TABLEAU_S2_SENSIBILITE_D0_D1_D2.csv", DIR_SUPPL_TABLEAUX)
sauver_table_word(ft_S2, file.path(DIR_SUPPL_TABLEAUX, "TABLEAU_S2_SENSIBILITE_D0_D1_D2.docx"))


# ==============================================================================
# 11. TABLEAU S3 — MODELES AJUSTES FDEP
# ==============================================================================

S3 <- as.data.table(CACHE_18$marginales)
S3 <- S3[indicateur %in% c("B", "C_strict", "C_broad")]
S3[, definition := fifelse(
  indicateur == "C_strict", "C-strict",
  fifelse(indicateur == "C_broad", "C-broad", indicateur)
)]
S3[, ordre_age := match(groupe_age, GROUPES_AGE)]
S3[, ordre_def := match(definition, c("B", "C-strict", "C-broad"))]
setorder(S3, ordre_age, ordre_def)

S3_PRINT <- S3[
  ,
  .(
    `Age group` = fifelse(groupe_age == "25–29 ans", "25–29 years", fifelse(groupe_age == "30–65 ans", "30–65 years", fifelse(groupe_age == "25–65 ans", "25–65 years", groupe_age))),
    `Definition` = definition,
    `FDep −1 SD, % [95% CI]` = fmt_ci(couverture_m1SD_pct, couverture_m1SD_inf, couverture_m1SD_sup, 2),
    `FDep +1 SD, % [95% CI]` = fmt_ci(couverture_p1SD_pct, couverture_p1SD_inf, couverture_p1SD_sup, 2),
    `Difference, pp [95% CI]` = fmt_ci(difference_p1_m1_pp, difference_inf_pp, difference_sup_pp, 2),
    `Ratio +1 SD / −1 SD [95% CI]` = fmt_ratio_ci(ratio_p1_m1, ratio_inf, ratio_sup, 3)
  )
]

ft_S3 <- style_table(flextable(S3_PRINT), size = 7.7)
ft_S3 <- merge_v(ft_S3, j = 1)
ft_S3 <- set_caption(
  ft_S3,
  caption = "Table S3. Adjusted marginal coverage according to municipal deprivation and documentary depth, Île-de-France, 2025"
)
ft_S3 <- add_footer_lines(
  ft_S3,
  values = c(
    "Estimates are derived from municipal quasi-binomial models with a logit link including standardized FDep, age group, their interaction, and department of residence.",
    "Marginal coverage estimates are presented at −1 and +1 standard deviation (SD) of FDep after standardization to the departmental distribution.",
    "B: expected test directly documented; C-strict: B supplemented by an alternative cervical test explicitly documented as screening or by strong cervical-care continuity; C-broad: C-strict supplemented by less specific compatible pathways."
  )
)

export_csv(S3, "TABLEAU_S3_MODELES_AJUSTES_FDEP.csv", DIR_SUPPL_TABLEAUX)
sauver_table_word(ft_S3, file.path(DIR_SUPPL_TABLEAUX, "TABLEAU_S3_MODELES_AJUSTES_FDEP.docx"))


# ==============================================================================
# 12. EXPORTS TECHNIQUES NON REDONDANTS
# ==============================================================================

export_csv(CACHE_14$partition, "TECH_01_PARTITION_DOCUMENTAIRE_D0.csv")
export_csv(CACHE_15$amplitude, "TECH_02_AMPLITUDE_INTERDEPARTEMENTALE.csv")
export_csv(CACHE_15$rangs, "TECH_03_VARIATIONS_RANGS_DEPARTEMENTS.csv")
export_csv(CACHE_15$sensibilite, "TECH_04_SENSIBILITE_DEPARTEMENTALE_D0_D1_D2.csv")
export_csv(CACHE_16$gradients, "TECH_05_GRADIENTS_FDEP_Q5_Q1.csv")
export_csv(CACHE_17$tableau_principal, "TECH_06_SII_RII_COMPLET.csv")
export_csv(CACHE_17$comparaison, "TECH_07_MODIFICATION_SII_RII_B_C.csv")
export_csv(CACHE_18$OR, "TECH_08_OR_FDEP_AJUSTES.csv")
export_csv(CACHE_18$interaction, "TECH_09_INTERACTION_FDEP_AGE.csv")
export_csv(CACHE_18$marginales, "TECH_10_MARGINALES_FDEP.csv")
export_csv(CACHE_18$comparaison, "TECH_11_MODIFICATION_GRADIENT_AJUSTE_B_C.csv")
export_csv(CACHE_22$impact_A_B, "TECH_12_IMPACT_A_VERS_B.csv")
export_csv(CACHE_22$profils_episodes, "TECH_13_PROFILS_DOCUMENTAIRES_EPISODES_B.csv")
export_csv(CACHE_22$profils_B_hors_A, "TECH_14_PROFILS_FEMMES_B_HORS_A.csv")
export_csv(CACHE_22$codes_B_hors_A, "TECH_15_CODES_OBSERVES_CHEZ_B_HORS_A.csv")
export_csv(CACHE_23$couverture, "TECH_16_CCAM_REFERENCE_B.csv")
export_csv(CACHE_23$gain_non_CCAM, "TECH_17_GAIN_CODES_NON_CCAM.csv")
export_csv(CACHE_21$seuils, "TECH_18_SEUILS_CARTES_BIVARIEES.csv")
export_csv(CACHE_21$repartition, "TECH_19_REPARTITION_CLASSES_BIVARIEES.csv")

NIVEAUX_PREUVE_FINAL <- BASE_FEMME_2025[
  B == FALSE,
  .(n_femmes = .N),
  by = .(
    groupe_age = as.character(groupe_age),
    niveau_preuve = as.character(niveau_preuve)
  )
][order(groupe_age, niveau_preuve)]
NIVEAUX_PREUVE_FINAL[, pct_non_B := 100 * n_femmes / sum(n_femmes), by = groupe_age]
export_csv(NIVEAUX_PREUVE_FINAL, "TECH_20_REPARTITION_N0_N1_N2_N3_CHEZ_NON_B.csv")

MANIFESTE_SOURCES <- data.table(
  ordre = 1:3,
  script_source = c(
    "01_SYTX_DOCCU_EQUITE_RESULTATS_TABLEAUX_FIGURES.R",
    "02_SYTX_DOCCU_EQUITE_RESULTATS_TABLEAUX_FIGURES.R",
    "03_SYTX_DOCCU_EQUITE_EFFICACITE_ARTICLE_FINAL.R"
  ),
  usage_dans_script_04 = c(
    "Historique de construction ; sorties exploratoires remplacées non reproduites",
    "Produits non redondants encore utiles, notamment lecture âge x département",
    "Définitions finales, caches de production, tableaux, figures et cartographies prioritaires"
  )
)
export_csv(MANIFESTE_SOURCES, "MANIFESTE_01_02_03.csv", DIR_METHODES)
export_csv(MANIFESTE_ETAPES, "MANIFESTE_FICHIERS_ETAPE_REQUIS.csv", DIR_METHODES)


# ==============================================================================
# 13. ELEMENTS METHODOLOGIQUES — DOCUMENT DE REFERENCE
# ==============================================================================

METHODES_TEXTE <- c(
  "DOCCU ÎLE-DE-FRANCE — ÉLÉMENTS MÉTHODOLOGIQUES DE PRODUCTION",
  "",
  "Population et date de référence",
  "La population analytique principale correspond aux femmes âgées de 25 à 65 ans au 31 décembre 2025 dans le dénominateur D0.",
  "",
  "Fenêtres de couverture",
  "Chez les 25–29 ans, le test attendu est une cytologie réalisée entre le 1er janvier 2023 et le 31 décembre 2025.",
  "Chez les 30–65 ans, le test attendu est un test HPV réalisé entre le 1er janvier 2021 et le 31 décembre 2025.",
  "",
  "Profondeur documentaire",
  "A-CCAM identifie le test attendu à partir des seuls codes CCAM retenus.",
  "A identifie le test attendu à partir de l'ensemble des codes de référence.",
  "B identifie le même test attendu lorsqu'il est directement documenté dans la fenêtre, indépendamment de la voie documentaire.",
  "Un résultat HPV positif ou négatif prouve l'existence d'un test HPV mais ne prouve pas à lui seul une finalité de dépistage primaire. De même, un résultat cytologique documenté prouve l'existence d'une cytologie sans établir systématiquement sa finalité.",
  "",
  "Hiérarchie C chez les femmes ne satisfaisant pas B",
  "N3 correspond à une activité cervicale directe alternative : HPV explicitement de dépistage chez les 25–29 ans, ou cytologie directement identifiée comme dépistage / organisé chez les 30–65 ans, dans les fenêtres définies par l'algorithme.",
  "N2 correspond à une continuité documentaire forte. Chez les 25–29 ans : HPV récent ambigu/non explicite avec BD2 récent. Chez les 30–65 ans : cytologie récente explicitement de contrôle ou convergence d'une cytologie récente non directement qualifiée de dépistage avec une preuve BD2 récente.",
  "N1 correspond à une activité ou un parcours cervical compatible mais moins spécifique, sans satisfaire N3 ou N2.",
  "N0 correspond à l'absence de signal retenu.",
  "C-strict = B + N3 + N2 ; C-broad = C-strict + N1.",
  "C-strict et C-broad sont des analyses de sensibilité documentaire et non des estimates of guideline-concordant coverage.",
  "",
  "Examens spécialisés",
  "Une colposcopie ou une histologie n'est jamais utilisée isolément comme preuve du test primaire attendu. Chez les 30–65 ans, une anomalie cytologique ou une histologie isolée n'est pas un critère autonome de N2.",
  "",
  "Exclusions",
  "D0 est le dénominateur principal. D1 et D2 sont des analyses de sensibilité aux exclusions médicales documentées. Le refus du dépistage n'est pas retiré du dénominateur.",
  "",
  "Défavorisation socio-territoriale",
  "Le FDep est utilisé au niveau communal. Les gradients descriptifs reposent sur les quintiles FDep.",
  "Les SII/RII reposent sur un ridit populationnel du FDep calculé dans la chaîne validée, sur toutes les communes FDep appariées sans seuil N ≥ 100, avec des modèles quasi-binomiaux séparés par groupe d'âge et lien identité.",
  "Les modèles ajustés des couvertures marginales à −1 et +1 SD sont des modèles quasi-binomiaux communaux à lien logit comprenant le Standardized FDep, le groupe d'âge, leur interaction et le département.",
  "Le seuil de 100 femmes par strate communale est réservé aux cartographies and is not applied to analyses of the FDep gradient.",
  "",
  "Cartographies bivariées",
  "L'axe FDep est regroupé en trois classes : Q1–Q2, Q3, Q4–Q5. L'autre axe repose sur les tertiles communaux non pondérés de la couverture B ou du gain B → C-strict, calculés séparément par groupe d'âge dans le script analytique et relus ici depuis le cache final.",
  "Les classes bivariées sont donc relatives au groupe d'âge ; leur couleur ne doit pas être utilisée pour comparer directement les niveaux absolus entre 25–29 ans et 30–65 ans."
)

writeLines(
  METHODES_TEXTE,
  file.path(DIR_METHODES, "ELEMENTS_METHODES_PRODUCTION.txt"),
  useBytes = TRUE
)

DOC_METHODES <- officer::read_docx()
DOC_METHODES <- body_add_par(
  DOC_METHODES,
  "DOCCU Île-de-France — Éléments méthodologiques de production",
  style = "heading 1"
)

TITRES_METHODES <- c(
  "Population et date de référence",
  "Fenêtres de couverture",
  "Profondeur documentaire",
  "Hiérarchie C chez les femmes ne satisfaisant pas B",
  "Examens spécialisés",
  "Exclusions",
  "Défavorisation socio-territoriale",
  "Cartographies bivariées"
)

for (ligne in METHODES_TEXTE[-c(1, 2)]) {
  if (!nzchar(ligne)) next
  if (ligne %in% TITRES_METHODES) {
    DOC_METHODES <- body_add_par(DOC_METHODES, ligne, style = "heading 2")
  } else {
    DOC_METHODES <- body_add_par(DOC_METHODES, ligne, style = "Normal")
  }
}

DOC_METHODES <- body_add_par(DOC_METHODES, "Tableau de décision documentaire", style = "heading 2")
DOC_METHODES <- body_add_flextable(DOC_METHODES, ft_S1F)
print(DOC_METHODES, target = file.path(DIR_METHODES, "ELEMENTS_METHODES_PRODUCTION.docx"))


# ==============================================================================
# 14. PREPARATION DU SHAPEFILE — PRODUCTIONS CARTOGRAPHIQUES UNIQUEMENT
# ==============================================================================

SHP_COMMUNES <- st_read(PATH_COMMUNES_SHP, quiet = TRUE)
names(SHP_COMMUNES) <- janitor::make_clean_names(names(SHP_COMMUNES))

SHP_COMMUNES$code_commune <- trimws(
  as.character(SHP_COMMUNES[[VAR_INSEE_SHP]])
)
SHP_COMMUNES$code_commune <- sub("\\.0+$", "", SHP_COMMUNES$code_commune)
SHP_COMMUNES$dep_carte <- substr(SHP_COMMUNES$code_commune, 1L, 2L)

SHP_COMMUNES <- st_make_valid(SHP_COMMUNES)

DEP_LIMITES <- SHP_COMMUNES |>
  dplyr::group_by(dep_carte) |>
  dplyr::summarise(.groups = "drop")

BASE_COMMUNE_D0 <- copy(BASE_COMMUNE_2025[scenario == "D0"])
BASE_COMMUNE_D0[, code_commune := as.character(code_commune)]
BASE_COMMUNE_D0[, groupe_age := as.character(groupe_age)]


# ==============================================================================
# 15. FONCTIONS CARTOGRAPHIQUES
# ==============================================================================

base_sf_variable <- function(groupe, variable) {
  d <- BASE_COMMUNE_D0[
    groupe_age == groupe & N >= SEUIL_N_CARTE,
    .(
      code_commune,
      valeur = get(variable)
    )
  ]

  dplyr::left_join(
    SHP_COMMUNES,
    as.data.frame(d),
    by = "code_commune"
  )
}

carte_continue <- function(
    groupe,
    variable,
    titre,
    legende,
    limites = NULL,
    caption = NULL
) {
  sf_map <- base_sf_variable(groupe, variable)

  p <- ggplot(sf_map) +
    geom_sf(aes(fill = valeur), colour = "grey78", linewidth = 0.05) +
    geom_sf(data = DEP_LIMITES, fill = NA, colour = "black", linewidth = 0.65, inherit.aes = FALSE) +
    scale_fill_viridis_c(
      option = "D",
      limits = limites,
      labels = function(x) fmt_num(x, 0),
      na.value = "grey94",
      name = legende
    ) +
    labs(
      title = titre,
      subtitle = ifelse(groupe == "25–29 ans", "25–29 years", ifelse(groupe == "30–65 ans", "30–65 years", groupe)),
      caption = if (is.null(caption)) {
        paste0("D0, reference date 31/12/2025. Municipalities with N < ", SEUIL_N_CARTE, " shown in grey.")
      } else caption
    ) +
    theme_void(base_size = 10) +
    theme(
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(face = "bold", size = 10),
      plot.caption = element_text(size = 7.5, hjust = 0),
      legend.position = "bottom"
    )

  p
}


# ==============================================================================
# 16. FIGURE 1 — ARCHITECTURE CONCEPTUELLE
# ==============================================================================

ARCH <- data.table(
  niveau = factor(NIVEAUX_DOC, levels = NIVEAUX_DOC),
  x = 1:5,
  ymin = 0,
  ymax = 1,
  texte = c(
    "Expected test\nCCAM codes only",
    "Expected test\nall reference codes",
    "Same expected test\ndirectly documented",
    "B + alternative cervical test\nexplicitly documented as screening\nor strong cervical-care continuity",
    "C-strict + less specific\ncompatible cervical pathway"
  ),
  zone = c("attendu", "attendu", "attendu", "sensibilite", "sensibilite")
)

p_fig1 <- ggplot(ARCH) +
  geom_rect(
    aes(xmin = x - 0.38, xmax = x + 0.38, ymin = ymin, ymax = ymax, fill = zone),
    colour = "grey20",
    linewidth = 0.4
  ) +
  geom_text(aes(x = x, y = 0.63, label = niveau), fontface = "bold", size = 4.4) +
  geom_text(aes(x = x, y = 0.29, label = texte), size = 3.1, lineheight = 1.05) +
  annotate("segment", x = 1.40, xend = 1.60, y = 0.5, yend = 0.5, arrow = arrow(length = unit(0.12, "in"))) +
  annotate("segment", x = 2.40, xend = 2.60, y = 0.5, yend = 0.5, arrow = arrow(length = unit(0.12, "in"))) +
  annotate("segment", x = 3.40, xend = 3.60, y = 0.5, yend = 0.5, arrow = arrow(length = unit(0.12, "in"))) +
  annotate("segment", x = 4.40, xend = 4.60, y = 0.5, yend = 0.5, arrow = arrow(length = unit(0.12, "in"))) +
  annotate("text", x = 2, y = 1.23, label = "Same expected test — increasing documentary depth of ascertainment", fontface = "bold", size = 3.8) +
  annotate("segment", x = 0.62, xend = 3.38, y = 1.13, yend = 1.13, linewidth = 0.5) +
  annotate("text", x = 4.5, y = 1.23, label = "Sensitivity to documented cervical activity and care continuity", fontface = "bold", size = 3.7) +
  annotate("segment", x = 3.62, xend = 5.38, y = 1.13, yend = 1.13, linewidth = 0.5) +
  annotate("text", x = 4.5, y = -0.23, label = "C-strict and C-broad: sensitivity analyses, not estimates of guideline-concordant coverage", size = 3.2, fontface = "italic") +
  scale_fill_manual(values = c(attendu = "#55B6BE", sensibilite = "#EA8178"), guide = "none") +
  coord_cartesian(xlim = c(0.5, 5.5), ylim = c(-0.35, 1.35), clip = "off") +
  theme_void() +
  theme(plot.margin = margin(15, 20, 20, 20))

sauver_figure(p_fig1, "FIGURE_1_ARCHITECTURE_PROFONDEUR_DOCUMENTAIRE", DIR_FIGURES, 11.5, 5.3)


# ==============================================================================
# 17. FIGURE 2 — PROGRESSION DE LA COUVERTURE SELON LA PROFONDEUR
# ==============================================================================

FIG2 <- rbindlist(list(
  TABLEAU_1_DATA[groupe_age %in% GROUPES_AGE, .(groupe_age, niveau = "A-CCAM", couverture = A_CCAM_pct)],
  TABLEAU_1_DATA[groupe_age %in% GROUPES_AGE, .(groupe_age, niveau = "A", couverture = A_pct)],
  TABLEAU_1_DATA[groupe_age %in% GROUPES_AGE, .(groupe_age, niveau = "B", couverture = B_pct)],
  TABLEAU_1_DATA[groupe_age %in% GROUPES_AGE, .(groupe_age, niveau = "C-strict", couverture = C_strict_pct)],
  TABLEAU_1_DATA[groupe_age %in% GROUPES_AGE, .(groupe_age, niveau = "C-broad", couverture = C_broad_pct)]
))
FIG2[, niveau := factor(niveau, levels = NIVEAUX_DOC)]
FIG2[, x := as.numeric(niveau)]
setorder(FIG2, groupe_age, x)
FIG2[, `:=`(
  gain = couverture - shift(couverture),
  couverture_precedente = shift(couverture)
), by = groupe_age]
FIG2[, x_gain := x - 0.5]
FIG2[, y_gain := (couverture + couverture_precedente) / 2]

p_fig2 <- ggplot(FIG2, aes(x = x, y = couverture, group = 1)) +
  annotate("rect", xmin = 0.5, xmax = 3.5, ymin = -Inf, ymax = Inf, fill = "#EAF6F7", alpha = 0.65) +
  annotate("rect", xmin = 3.5, xmax = 5.5, ymin = -Inf, ymax = Inf, fill = "#FBEFEE", alpha = 0.65) +
  geom_vline(xintercept = 3.5, linetype = "dashed", linewidth = 0.45) +
  geom_line(linewidth = 0.8) +
  geom_point(shape = 21, fill = "white", size = 3, stroke = 0.8) +
  geom_text(aes(label = paste0(fmt_num(couverture, 2), " %")), vjust = -1.0, fontface = "bold", size = 3.5) +
  geom_text(
    data = FIG2[!is.na(gain)],
    aes(x = x_gain, y = y_gain, label = paste0(ifelse(gain >= 0, "+", ""), fmt_num(gain, 2), " pp")),
    inherit.aes = FALSE,
    size = 3.1, vjust = 2.0 , hjust = -0.2 ,
    fontface = "italic"
  ) +
  facet_wrap(~ groupe_age, nrow = 1, labeller = as_labeller(c("25–29 ans" = "25–29 years", "30–65 ans" = "30–65 years"))) +
  scale_x_continuous(breaks = 1:5, labels = NIVEAUX_DOC) +
  scale_y_continuous(limits = c(30, 70), breaks = seq(30, 70, by = 5), labels = function(x) paste0(x, " %")) +
  labs(
    title = "Measured coverage according to documentary depth and age group",
    subtitle = "Values between adjacent levels indicate the absolute gain in coverage",
    x = NULL,
    y = "Proportion classified as covered (%)"
  ) +
  theme_minimal(base_size = 10.5) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 11),
    axis.text.x = element_text(face = "bold")
  ) +
  annotate("text", x = 2, y = Inf, label = "Identification of the expected test", vjust = 1.6, fontface = "bold", size = 3.3) +
  annotate("text", x = 4.5, y = Inf, label = "Broader documentary sensitivity", vjust = 1.6, fontface = "bold", size = 3.3)

sauver_figure(p_fig2, "FIGURE_2_COUVERTURE_PROFONDEUR_DOCUMENTAIRE", DIR_FIGURES, 11.5, 5.9)

p_fig2
# ==============================================================================
# 18. FIGURE 3 — CARTOGRAPHIES B / C-STRICT
# ==============================================================================

calculer_limites_couverture <- function(groupe) {
  x <- BASE_COMMUNE_D0[
    groupe_age == groupe & N >= SEUIL_N_CARTE,
    c(B_pct, C_strict_pct, C_broad_pct)
  ]
  x <- x[is.finite(x)]
  c(floor(min(x) / 5) * 5, ceiling(max(x) / 5) * 5)
}

lim25 <- calculer_limites_couverture("25–29 ans")
lim30 <- calculer_limites_couverture("30–65 ans")

m25_B <- carte_continue(
  "25–29 ans", "B_pct",
  "B — expected test documented",
  "Coverage (%)", lim25
)
m25_CS <- carte_continue(
  "25–29 ans", "C_strict_pct",
  "C-strict — broader documentary sensitivity",
  "Coverage (%)", lim25
)
m30_B <- carte_continue(
  "30–65 ans", "B_pct",
  "B — expected test documented",
  "Coverage (%)", lim30
)
m30_CS <- carte_continue(
  "30–65 ans", "C_strict_pct",
  "C-strict — broader documentary sensitivity",
  "Coverage (%)", lim30
)

p_fig3 <- ((m25_B | m25_CS) / (m30_B | m30_CS)) +
  plot_annotation(
    title = "Municipal distribution of documented coverage and its sensitivity to broader documentary ascertainment",
    subtitle = "Île-de-France, 2025"
  )

sauver_figure(p_fig3, "FIGURE_3_CARTOGRAPHIES_B_CSTRICT", DIR_FIGURES, 10.5, 13.5)


# ==============================================================================
# 19. FIGURE 4 — GRADIENT FDEP Q1–Q5
# ==============================================================================

FIG4 <- rbindlist(list(
  T3_FDEP[, .(groupe_age, quintile = quintile_fdep_num, definition = "B", couverture = B_pct)],
  T3_FDEP[, .(groupe_age, quintile = quintile_fdep_num, definition = "C-strict", couverture = C_strict_pct)],
  T3_FDEP[, .(groupe_age, quintile = quintile_fdep_num, definition = "C-broad", couverture = C_broad_pct)]
))
FIG4[, definition := factor(definition, levels = c("B", "C-strict", "C-broad"))]

p_fig4 <- ggplot(FIG4, aes(x = quintile, y = couverture, linetype = definition, shape = definition, group = definition)) +
  geom_line(linewidth = 0.75) +
  geom_point(size = 2.6) +
  facet_wrap(~ groupe_age, nrow = 1, labeller = as_labeller(c("25–29 ans" = "25–29 years", "30–65 ans" = "30–65 years"))) +
  scale_x_continuous(breaks = 1:5, labels = paste0("Q", 1:5)) +
  scale_y_continuous(limits = c(30, 70), breaks = seq(30, 70, by = 5), labels = function(x) paste0(x, " %")) +
  scale_linetype_manual(values = c("solid", "dashed", "dashed")) +
  scale_shape_manual(values = c(16, 17, 15)) +
  labs(
    title = "Social gradient in coverage according to documentary definition",
    subtitle = "Q1 = least deprived municipalities; Q5 = most deprived municipalities",
    x = "FDep deprivation quintile",
    y = "Coverage (%)",
    linetype = NULL,
    shape = NULL
  ) +
  theme_minimal(base_size = 10.5) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  )

sauver_figure(p_fig4, "FIGURE_4_GRADIENT_FDEP_Q1_Q5", DIR_FIGURES, 10.5, 5.8)


# ==============================================================================
# 20. FIGURE 5 — MODELES AJUSTES FDEP
# ==============================================================================

FIG5 <- S3[definition %in% c("B", "C-strict")]
FIG5_M1 <- FIG5[, .(
  groupe_age,
  definition,
  niveau = "−1 SD\nless deprived",
  x = -1,
  couverture = couverture_m1SD_pct,
  inf = couverture_m1SD_inf,
  sup = couverture_m1SD_sup
)]
FIG5_P1 <- FIG5[, .(
  groupe_age,
  definition,
  niveau = "+1 SD\nmore deprived",
  x = 1,
  couverture = couverture_p1SD_pct,
  inf = couverture_p1SD_inf,
  sup = couverture_p1SD_sup
)]
FIG5_LONG <- rbindlist(list(FIG5_M1, FIG5_P1))
FIG5_LONG[, definition := factor(definition, levels = c("B", "C-strict"))]

p_fig5 <- ggplot(FIG5_LONG, aes(x = x, y = couverture, group = definition, linetype = definition, shape = definition)) +
  geom_line(linewidth = 0.8) +
  geom_errorbar(aes(ymin = inf, ymax = sup), width = 0.08, linewidth = 0.45) +
  geom_point(size = 3) +
  geom_text(aes(label = paste0(fmt_num(couverture, 2), " %")), vjust = -0.9, size = 3.2) +
  facet_wrap(~ groupe_age, nrow = 1, labeller = as_labeller(c("25–29 ans" = "25–29 years", "30–65 ans" = "30–65 years"))) +
  scale_y_continuous(limits = c(30, 70), breaks = seq(30, 70, by = 5), labels = function(x) paste0(x, " %")) +
  scale_x_continuous(breaks = c(-1, 1), labels = c("−1 SD\nless deprived", "+1 SD\nmore deprived")) +
  scale_linetype_manual(values = c("solid", "dashed")) +
  scale_shape_manual(values = c(16, 21)) +
  labs(
    title = "Adjusted marginal coverage according to municipal deprivation",
    subtitle = "Estimates at −1 and +1 standard deviation of FDep, adjusted for department",
    x = "Standardized French Deprivation Index level",
    y = "Adjusted coverage (%)",
    linetype = NULL,
    shape = NULL
  ) +
  theme_minimal(base_size = 10.5) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  )

sauver_figure(p_fig5, "FIGURE_5_MODELES_AJUSTES_FDEP", DIR_FIGURES, 10.5, 5.8)


# ==============================================================================
# 21. SUPPLEMENTARY FIGURES — C-BROAD, CORRIDOR C ET MODELES COMPLETS
# ==============================================================================

# C-broad
m25_CB <- carte_continue(
  "25–29 ans", "C_broad_pct",
  "C-broad — broader documentary sensitivity",
  "Coverage (%)",
  range(BASE_COMMUNE_D0[groupe_age == "25–29 ans" & N >= SEUIL_N_CARTE, C_broad_pct], na.rm = TRUE)
)
m30_CB <- carte_continue(
  "30–65 ans", "C_broad_pct",
  "C-broad — broader documentary sensitivity",
  "Coverage (%)",
  range(BASE_COMMUNE_D0[groupe_age == "30–65 ans" & N >= SEUIL_N_CARTE, C_broad_pct], na.rm = TRUE)
)
p_s1 <- (m25_CB | m30_CB) + plot_annotation(title = "C-broad — broader documentary sensitivity")
sauver_figure(p_s1, "FIGURE_S1_CARTOGRAPHIES_CBROAD", DIR_SUPPL_FIGURES, 10.5, 6.5)

# Corridor C = C-broad - C-strict
BASE_COMMUNE_D0[, corridor_C_pp := C_broad_pct - C_strict_pct]
m25_COR <- carte_continue(
  "25–29 ans", "corridor_C_pp",
  "C corridor — C-broad minus C-strict",
  "Percentage points",
  range(BASE_COMMUNE_D0[groupe_age == "25–29 ans" & N >= SEUIL_N_CARTE, corridor_C_pp], na.rm = TRUE)
)
m30_COR <- carte_continue(
  "30–65 ans", "corridor_C_pp",
  "C corridor — C-broad minus C-strict",
  "Percentage points",
  range(BASE_COMMUNE_D0[groupe_age == "30–65 ans" & N >= SEUIL_N_CARTE, corridor_C_pp], na.rm = TRUE)
)
p_s2 <- (m25_COR | m30_COR) + plot_annotation(title = "Documentary corridor: C-broad − C-strict")
sauver_figure(p_s2, "FIGURE_S2_CORRIDOR_C", DIR_SUPPL_FIGURES, 10.5, 6.5)

# Modèles ajustés complets B / C-strict / C-broad
S3_ALL <- S3
S3_M1 <- S3_ALL[, .(
  groupe_age,
  definition,
  x = -1,
  niveau = "−1 SD",
  couverture = couverture_m1SD_pct,
  inf = couverture_m1SD_inf,
  sup = couverture_m1SD_sup
)]
S3_P1 <- S3_ALL[, .(
  groupe_age,
  definition,
  x = 1,
  niveau = "+1 SD",
  couverture = couverture_p1SD_pct,
  inf = couverture_p1SD_inf,
  sup = couverture_p1SD_sup
)]
S3_FIG <- rbindlist(list(S3_M1, S3_P1))
S3_FIG[, definition := factor(definition, levels = c("B", "C-strict", "C-broad"))]

p_s3 <- ggplot(S3_FIG, aes(x = x, y = couverture, group = definition, linetype = definition, shape = definition)) +
  geom_line(linewidth = 0.75) +
  geom_errorbar(aes(ymin = inf, ymax = sup), width = 0.08, linewidth = 0.4) +
  geom_point(size = 2.7) +
  facet_wrap(~ groupe_age, nrow = 1, labeller = as_labeller(c("25–29 ans" = "25–29 years", "30–65 ans" = "30–65 years"))) +
  scale_y_continuous(limits = c(30, 70), breaks = seq(30, 70, by = 5), labels = function(x) paste0(x, " %")) +
  scale_x_continuous(breaks = c(-1, 1), labels = c("−1 SD", "+1 SD")) +
  labs(
    title = "Adjusted marginal coverage — all documentary definitions",
    x = "Standardized FDep",
    y = "Adjusted coverage (%)",
    linetype = NULL,
    shape = NULL
  ) +
  theme_minimal(base_size = 10.5) +
  theme(legend.position = "bottom", strip.text = element_text(face = "bold"))

sauver_figure(p_s3, "FIGURE_S3_MARGINALES_FDEP_B_CSTRICT_CBROAD", DIR_SUPPL_FIGURES, 10.5, 5.8)


# ==============================================================================
# 22. CARTOGRAPHIES BIVARIEES — SEUILS RELUS DU CACHE FINAL
# ==============================================================================

SEUILS_BIVAR <- as.data.table(CACHE_21$seuils)
PALETTE_BIVAR <- CACHE_21$palette

REF_FDEP_BIVAR <- unique(
  BASE_COMMUNE_FDEP_2025[
    scenario == "D0",
    .(
      code_commune = as.character(code_commune),
      fdep20,
      quintile_fdep_num,
      quintile_fdep = as.character(quintile_fdep)
    )
  ]
)

BASE_BIVAR <- merge(
  BASE_COMMUNE_D0[N >= SEUIL_N_CARTE],
  REF_FDEP_BIVAR,
  by = "code_commune",
  all.x = TRUE,
  sort = FALSE
)

BASE_BIVAR[
  ,
  classe_fdep := fcase(
    quintile_fdep_num %in% c(1, 2), 1L,
    quintile_fdep_num == 3, 2L,
    quintile_fdep_num %in% c(4, 5), 3L,
    default = NA_integer_
  )
]

classer_selon_cache <- function(x, s1, s2) {
  fcase(
    is.na(x) | !is.finite(x), NA_integer_,
    x <= s1, 1L,
    x <= s2, 2L,
    default = 3L
  )
}

BASE_BIVAR[, `:=`(classe_B = NA_integer_, classe_gain = NA_integer_)]

for (g in GROUPES_AGE) {
  sB <- SEUILS_BIVAR[groupe_age == g & variable == "B_pct"]
  sG <- SEUILS_BIVAR[groupe_age == g & variable == "gain_B_Cstrict_pp"]

  BASE_BIVAR[groupe_age == g, classe_B := classer_selon_cache(B_pct, sB$seuil_1[1], sB$seuil_2[1])]
  BASE_BIVAR[groupe_age == g, classe_gain := classer_selon_cache(gain_B_Cstrict_pp, sG$seuil_1[1], sG$seuil_2[1])]
}

BASE_BIVAR[, classe_bivar_B := fifelse(
  !is.na(classe_fdep) & !is.na(classe_B),
  paste0(classe_fdep, "-", classe_B),
  NA_character_
)]
BASE_BIVAR[, classe_bivar_gain := fifelse(
  !is.na(classe_fdep) & !is.na(classe_gain),
  paste0(classe_fdep, "-", classe_gain),
  NA_character_
)]

export_csv(
  BASE_BIVAR[
    ,
    .(
      code_commune,
      dep,
      groupe_age,
      N,
      fdep20,
      quintile_fdep_num,
      B_pct,
      C_strict_pct,
      gain_B_Cstrict_pp,
      classe_fdep,
      classe_B,
      classe_gain,
      classe_bivar_B,
      classe_bivar_gain
    )
  ],
  "BASE_CARTOGRAPHIES_BIVARIEES_REGION_IDF.csv",
  DIR_REGION
)

legende_bivariee <- function(label_y) {
  lg <- CJ(x = 1:3, y = 1:3)
  lg[, classe := paste0(x, "-", y)]
  ggplot(lg, aes(x = x, y = y, fill = classe)) +
    geom_tile(colour = "white", linewidth = 0.7) +
    scale_fill_manual(values = PALETTE_BIVAR, guide = "none") +
    scale_x_continuous(breaks = 1:3, labels = c("Low\nQ1–Q2", "Interm.\nQ3", "High\nQ4–Q5"), expand = c(0, 0)) +
    scale_y_continuous(breaks = 1:3, labels = c("Low", "Interm.", "High"), expand = c(0, 0)) +
    coord_fixed() +
    labs(x = "FDep deprivation →", y = paste0(label_y, " →")) +
    theme_minimal(base_size = 8) +
    theme(
      panel.grid = element_blank(),
      axis.ticks = element_blank(),
      axis.title = element_text(face = "bold"),
      plot.margin = margin(2, 2, 2, 2)
    )
}

carte_bivariee <- function(groupe, variable_classe, titre, label_y, variable_seuil, unite) {
  d <- BASE_BIVAR[
    groupe_age == groupe,
    .(code_commune, classe_bivar = get(variable_classe))
  ]
  d[, classe_bivar := factor(classe_bivar, levels = names(PALETTE_BIVAR))]

  sf_map <- dplyr::left_join(SHP_COMMUNES, as.data.frame(d), by = "code_commune")
  ss <- SEUILS_BIVAR[groupe_age == groupe & variable == variable_seuil]

  sous_titre <- paste0(
    "FDep: Q1–Q2 / Q3 / Q4–Q5; ", label_y,
    ": municipal tertiles (", fmt_num(ss$seuil_1[1], 2), " ; ", fmt_num(ss$seuil_2[1], 2), " ", unite, ")"
  )

  p_map <- ggplot(sf_map) +
    geom_sf(aes(fill = classe_bivar), colour = "grey72", linewidth = 0.07) +
    geom_sf(data = DEP_LIMITES, fill = NA, colour = "black", linewidth = 0.70, inherit.aes = FALSE) +
    scale_fill_manual(values = PALETTE_BIVAR, limits = names(PALETTE_BIVAR), drop = FALSE, na.value = "grey94", guide = "none") +
    labs(
      title = paste0(titre, " — ", groupe),
      subtitle = sous_titre,
      caption = paste0("D0, reference date 31/12/2025. Municipalities with N < ", SEUIL_N_CARTE, " ou sans information FDep exploitable shown in grey.")
    ) +
    theme_void(base_size = 10) +
    theme(
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 9),
      plot.caption = element_text(size = 7.5, hjust = 0)
    )

  p_map / legende_bivariee(label_y) + plot_layout(heights = c(5, 1.25))
}

for (g in GROUPES_AGE) {
  suffix <- ifelse(g == "25–29 ans", "25_29", "30_65")

  p_gain <- carte_bivariee(
    groupe = g,
    variable_classe = "classe_bivar_gain",
    titre = "Municipal deprivation and documentary gain B → C-strict",
    label_y = "Gain B → C-strict",
    variable_seuil = "gain_B_Cstrict_pp",
    unite = "points"
  )

  p_B <- carte_bivariee(
    groupe = g,
    variable_classe = "classe_bivar_B",
    titre = "Municipal deprivation and documented coverage B",
    label_y = "B coverage",
    variable_seuil = "B_pct",
    unite = "%"
  )

  sauver_figure(
    p_gain,
    paste0("FIGURE_S4", ifelse(g == "25–29 ans", "A", "B"), "_BIVAR_FDEP_GAIN_", suffix),
    DIR_SUPPL_FIGURES,
    11,
    10
  )

  sauver_figure(
    p_B,
    paste0("FIGURE_S5", ifelse(g == "25–29 ans", "A", "B"), "_BIVAR_FDEP_B_", suffix),
    DIR_SUPPL_FIGURES,
    11,
    10
  )
}

export_csv(SEUILS_BIVAR, "TABLEAU_SEUILS_CARTES_BIVARIEES.csv", DIR_REGION)
export_csv(CACHE_21$repartition, "TABLEAU_REPARTITION_CLASSES_BIVARIEES.csv", DIR_REGION)


# ==============================================================================
# 23. CARTOGRAPHIES REGION IDF — GAIN DOCUMENTAIRE ET DONNEES REUTILISABLES
# ==============================================================================

lim_gain_25 <- range(BASE_COMMUNE_D0[groupe_age == "25–29 ans" & N >= SEUIL_N_CARTE, gain_B_Cstrict_pp], na.rm = TRUE)
lim_gain_30 <- range(BASE_COMMUNE_D0[groupe_age == "30–65 ans" & N >= SEUIL_N_CARTE, gain_B_Cstrict_pp], na.rm = TRUE)

reg_gain25 <- carte_continue(
  "25–29 ans", "gain_B_Cstrict_pp",
  "Documentary gain B → C-strict",
  "Gain (pp)", lim_gain_25
)
reg_gain30 <- carte_continue(
  "30–65 ans", "gain_B_Cstrict_pp",
  "Documentary gain B → C-strict",
  "Gain (pp)", lim_gain_30
)

p_region_gain <- (reg_gain25 | reg_gain30) +
  plot_annotation(title = "Documentary gain B → C-strict selon la commune")

sauver_figure(p_region_gain, "REGION_IDF_CARTE_GAIN_B_CSTRICT", DIR_REGION, 10.5, 6.5)

export_csv(
  BASE_COMMUNE_D0[
    ,
    .(
      dep,
      code_commune,
      groupe_age,
      N,
      A,
      B,
      C_strict,
      C_broad,
      A_pct,
      B_pct,
      C_strict_pct,
      C_broad_pct,
      gain_A_B_pp,
      gain_B_Cstrict_pp,
      gain_B_Cbroad_pp,
      corridor_C_pp
    )
  ],
  "BASE_COMMUNALE_D0_COUVERTURE_PROFONDEUR_DOCUMENTAIRE.csv",
  DIR_REGION
)


# ==============================================================================
# 24. FIGURE REGIONALE COMPLEMENTAIRE — HEATMAP AGE x DEPARTEMENT
# Héritage utile du script 02, recalculé avec la définition finale B.
# ==============================================================================

HEAT <- BASE_FEMME_2025[
  ,
  .(
    N = .N,
    B = sum(B, na.rm = TRUE)
  ),
  by = .(
    dep = as.character(dep),
    classe_age_5 = as.character(classe_age_5)
  )
]
HEAT[, B_pct := 100 * B / N]
HEAT[, departement := factor(unname(NOMS_DEPARTEMENTS[dep]), levels = unname(NOMS_DEPARTEMENTS[DEPARTEMENTS_IDF]))]

p_heat <- ggplot(HEAT, aes(x = classe_age_5, y = departement, fill = B_pct)) +
  geom_tile() +
  scale_fill_viridis_c(name = "B (%)", na.value = "grey94") +
  labs(
    title = "Documented B coverage by age group and department",
    subtitle = "Île-de-France, 2025",
    x = "Age group",
    y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank())

sauver_figure(p_heat, "REGION_IDF_HEATMAP_AGE_DEPARTEMENT_B", DIR_REGION, 9.5, 5.5)


# ==============================================================================
# 25. DOCUMENTS COMBINES — TABLEAUX ARTICLE ET SUPPLEMENT
# ==============================================================================
conflicts_prefer(officer::read_docx)

DOC_MAIN <- read_docx()
DOC_MAIN <- body_add_par(DOC_MAIN, "DOCCU Equity — Main tables", style = "heading 1")
DOC_MAIN <- body_add_par(DOC_MAIN, "Table 1", style = "heading 2")
DOC_MAIN <- body_add_flextable(DOC_MAIN, ft_T1)
DOC_MAIN <- body_add_break(DOC_MAIN)
DOC_MAIN <- body_add_par(DOC_MAIN, "Table 2", style = "heading 2")
DOC_MAIN <- body_add_flextable(DOC_MAIN, ft_T2)
DOC_MAIN <- body_add_break(DOC_MAIN)
DOC_MAIN <- body_add_par(DOC_MAIN, "Table 3", style = "heading 2")
DOC_MAIN <- body_add_flextable(DOC_MAIN, ft_T3)
print(DOC_MAIN, target = file.path(DIR_DOCUMENTS, "TABLEAUX_PRINCIPAUX_DOCCU_EQUITE.docx"))

DOC_SUPP <- read_docx()
DOC_SUPP <- body_add_par(DOC_SUPP, "DOCCU Equity — Supplementary tables", style = "heading 1")
for (obj in list(
  list("Table S1A", ft_S1A),
  list("Table S1B", ft_S1B),
  list("Table S1C", ft_S1C),
  list("Table S1D", ft_S1D),
  list("Table S1E", ft_S1E),
  list("Table S1F", ft_S1F),
  list("Table S2", ft_S2),
  list("Table S3", ft_S3)
)) {
  DOC_SUPP <- body_add_par(DOC_SUPP, obj[[1]], style = "heading 2")
  DOC_SUPP <- body_add_flextable(DOC_SUPP, obj[[2]])
  DOC_SUPP <- body_add_break(DOC_SUPP)}
print(DOC_SUPP, target = file.path(DIR_DOCUMENTS, "TABLEAUX_SUPPLEMENTAIRES_DOCCU_EQUITE.docx"))


# ==============================================================================
# 26. LEGENDES ET INDEX DES SORTIES
# ==============================================================================

LEGENDES <- c(
  "MAIN TABLES",
  "Table 1. Cervical cancer screening coverage according to documentary depth, Île-de-France, 2025.",
  "Table 2. Documented screening coverage and sensitivity to broader documentary ascertainment by department, Île-de-France, 2025.",
  "Table 3. Socio-territorial inequalities in coverage according to municipal deprivation and documentary depth, Île-de-France, 2025.",
  "",
  "MAIN FIGURES",
  "Figure 1. Conceptual architecture of documentary depth.",
  "Figure 2. Measured coverage according to documentary depth and age group.",
  "Figure 3. Municipal distribution of documented coverage and its sensitivity to broader documentary ascertainment.",
  "Figure 4. Social gradient in coverage according to documentary definition.",
  "Figure 5. Adjusted marginal coverage according to municipal deprivation.",
  "",
  "SUPPLEMENTARY TABLES",
  "Table S1A. Contribution of CCAM codes and numerical reference codes to identification of the expected test.",
  "Table S1B. Distribution of codes observed in episodes documenting the expected test.",
  "Table S1C. Documentary depth of episodes meeting definition B.",
  "Table S1D. Documented results among B episodes without an identifiable code for the expected test.",
  "Table S1E. Documentary characteristics of women meeting B but not A.",
  "Table S1F. Classification rules according to documentary depth and age group.",
  "Table S2. Sensitivity of coverage estimates to documented medical exclusions using denominators D0, D1 and D2.",
  "Table S3. Adjusted marginal coverage according to municipal deprivation and documentary depth.",
  "",
  "SUPPLEMENTARY FIGURES",
  "Figure S1. C-broad — broader documentary sensitivity par commune.",
  "Figure S2. Documentary corridor: C-broad − C-strict par commune.",
  "Figure S3. Adjusted marginal coverage for B, C-strict and C-broad.",
  "Figures S4A/S4B. Bivariate maps of FDep × documentary gain B → C-strict.",
  "Figures S5A/S5B. Bivariate maps of FDep × documented B coverage.",
  "",
  "PRODUITS REGION ÎLE-DE-FRANCE",
  "Regional map of documentary gain B → C-strict.",
  "Bivariate maps of FDep × gain and FDep × B.",
  "Municipal D0 database of coverage and documentary depth.",
  "Bivariate mapping database with 3 × 3 classes.",
  "Heatmap of B coverage by age group and department."
)

writeLines(LEGENDES, file.path(DIR_METHODES, "LEGENDES_TABLEAUX_FIGURES.txt"), useBytes = TRUE)

INDEX_SORTIES <- data.table(
  categorie = c(
    rep("Article — tableau", 3),
    rep("Article — figure", 5),
    rep("Supplément — tableau", 8),
    rep("Supplément — figure", 7),
    rep("Région IDF", 4),
    rep("Méthodes", 3)
  ),
  element = c(
    "Table 1", "Table 2", "Table 3",
    "Figure 1", "Figure 2", "Figure 3", "Figure 4", "Figure 5",
    "Table S1A", "Table S1B", "Table S1C", "Table S1D", "Table S1E", "Table S1F", "Table S2", "Table S3",
    "Figure S1", "Figure S2", "Figure S3", "Figure S4A", "Figure S4B", "Figure S5A", "Figure S5B",
    "Gain B→C-strict", "Base communale D0", "Base bivariée", "Heatmap âge×département",
    "Éléments méthodologiques TXT", "Éléments méthodologiques DOCX", "Légendes"
  ),
  usage = c(
    "Manuscrit", "Manuscrit", "Manuscrit",
    rep("Manuscrit", 5),
    rep("Matériel supplémentaire", 8),
    rep("Matériel supplémentaire / Région", 7),
    rep("Région Île-de-France / réutilisation", 4),
    rep("Traçabilité / rédaction", 3)
  )
)

export_csv(INDEX_SORTIES, "INDEX_SORTIES_PRODUCTION.csv", DIR_OUT)


# ==============================================================================
# 27. RESUME AUTOMATIQUE DES RESULTATS CENTRAUX — POUR REDACTION
# ==============================================================================

R25 <- TABLEAU_1_DATA[groupe_age == "25–29 ans"]
R30 <- TABLEAU_1_DATA[groupe_age == "30–65 ans"]
RT <- TABLEAU_1_DATA[groupe_age == "25–65 ans"]

RESULTATS_TEXTE <- c(
  "RÉSULTATS CENTRAUX — EXTRACTION AUTOMATIQUE DES CACHES FINAUX",
  "",
  paste0("Population D0 : ", fmt_n(RT$N), " femmes âgées de 25 à 65 ans."),
  paste0("25–29 ans : A-CCAM ", fmt_pct(R25$A_CCAM_pct), ", A ", fmt_pct(R25$A_pct), ", B ", fmt_pct(R25$B_pct), ", C-strict ", fmt_pct(R25$C_strict_pct), ", C-broad ", fmt_pct(R25$C_broad_pct), "."),
  paste0("30–65 ans : A-CCAM ", fmt_pct(R30$A_CCAM_pct), ", A ", fmt_pct(R30$A_pct), ", B ", fmt_pct(R30$B_pct), ", C-strict ", fmt_pct(R30$C_strict_pct), ", C-broad ", fmt_pct(R30$C_broad_pct), "."),
  paste0("25–65 ans : A-CCAM ", fmt_pct(RT$A_CCAM_pct), ", A ", fmt_pct(RT$A_pct), ", B ", fmt_pct(RT$B_pct), ", C-strict ", fmt_pct(RT$C_strict_pct), ", C-broad ", fmt_pct(RT$C_broad_pct), "."),
  "",
  "B correspond au test attendu directement documenté dans la fenêtre. C-strict et C-broad constituent des analyses de sensibilité documentaire et non des estimations alternatives d'une couverture conforme aux recommandations."
)

writeLines(
  RESULTATS_TEXTE,
  file.path(DIR_METHODES, "RESULTATS_CENTRAUX_AUTOMATIQUES.txt"),
  useBytes = TRUE
)


# ==============================================================================
# 28. FIN DE PRODUCTION
# ==============================================================================

message("")
message("==============================================================")
message("PRODUCTION DES RESULTATS TERMINEE — AUCUN QC / TEST RELANCE")
message("==============================================================")
message("Sorties : ", DIR_OUT)
message("Tableaux article : ", DIR_TABLEAUX)
message("Tableaux supplément : ", DIR_SUPPL_TABLEAUX)
message("Figures article : ", DIR_FIGURES)
message("Figures supplément : ", DIR_SUPPL_FIGURES)
message("Cartographies Région IDF : ", DIR_REGION)
message("Exports techniques : ", DIR_EXPORTS)
message("Méthodes / légendes : ", DIR_METHODES)
message("Documents combinés : ", DIR_DOCUMENTS)
message("==============================================================")


# ==============================================================================
# FIGURE BIVARIEE PRINCIPALE
# FDEP × COUVERTURE DOCUMENTEE
# B versus C-STRICT
#
# 4 panneaux :
#   - B        × FDep — 25–29 ans
#   - C-strict × FDep — 25–29 ans
#   - B        × FDep — 30–65 ans
#   - C-strict × FDep — 30–65 ans
#
# PRINCIPE IMPORTANT
# ------------------
# Pour permettre une comparaison directe B versus C-strict :
#
#   -> les seuils de couverture utilisés pour C-strict sont EXACTEMENT
#      les mêmes que ceux déjà validés pour B dans chaque groupe d'âge.
#
# Donc :
#   - aucune nouvelle définition statistique ;
#   - aucun nouveau test ;
#   - aucune nouvelle classification FDep ;
#   - simple production graphique à partir des résultats validés.
#
# Axe horizontal de la légende : couverture
# Axe vertical               : FDep
# ==============================================================================


# ==============================================================================
# 1. PARAMETRES
# ==============================================================================

SEUIL_N_BIVAR_B_CS <- 100L


DIR_FIG_BIVAR_B_CS <- file.path(
  DIR_FIGURES,
  "BIVARIEES"
)

if (!dir.exists(DIR_FIG_BIVAR_B_CS)) {
  dir.create(
    DIR_FIG_BIVAR_B_CS,
    recursive = TRUE
  )
}


# ==============================================================================
# 2. PALETTE BIVARIEE 3 × 3
#
# Convention :
#
#   lignes    = FDep croissant
#   colonnes  = couverture croissante
#
#   1-1 = faible FDep      + faible couverture
#   1-3 = faible FDep      + couverture élevée
#   3-1 = FDep élevé       + faible couverture
#   3-3 = FDep élevé       + couverture élevée
#
# La palette existante du cache est conservée.
# ==============================================================================

PALETTE_B_CS <- PALETTE_BIVAR


# ==============================================================================
# 3. RECUPERATION DES SEUILS B DEJA VALIDES
# ==============================================================================

SEUILS_B_REFERENCE <- SEUILS_BIVAR[
  variable == "B_pct",
  .(
    groupe_age,
    seuil_1,
    seuil_2
  )
]


cat("\n")
cat("=====================================================================\n")
cat(" SEUILS DE COUVERTURE B UTILISES POUR B ET C-STRICT\n")
cat("=====================================================================\n")

print(SEUILS_B_REFERENCE)


# ==============================================================================
# 4. CONSTRUCTION DES CLASSES DE COUVERTURE
#
# Aucun recalcul de seuil.
#
# Les seuils B déjà validés sont simplement appliqués :
#   - à B
#   - puis à C-strict
# ==============================================================================

BASE_BIVAR_B_CS <- data.table::copy(
  BASE_BIVAR
)


BASE_BIVAR_B_CS[
  ,
  `:=`(
    classe_couverture_B =
      NA_integer_,
    
    classe_couverture_Cstrict =
      NA_integer_
  )
]


for (g in GROUPES_AGE) {
  
  SB <- SEUILS_B_REFERENCE[
    groupe_age == g
  ]
  
  
  s1 <- SB$seuil_1[1]
  s2 <- SB$seuil_2[1]
  
  
  BASE_BIVAR_B_CS[
    groupe_age == g,
    
    classe_couverture_B :=
      data.table::fcase(
        
        is.na(B_pct) |
          !is.finite(B_pct),
        NA_integer_,
        
        B_pct <= s1,
        1L,
        
        B_pct <= s2,
        2L,
        
        default = 3L
      )
  ]
  
  
  BASE_BIVAR_B_CS[
    groupe_age == g,
    
    classe_couverture_Cstrict :=
      data.table::fcase(
        
        is.na(C_strict_pct) |
          !is.finite(C_strict_pct),
        NA_integer_,
        
        C_strict_pct <= s1,
        1L,
        
        C_strict_pct <= s2,
        2L,
        
        default = 3L
      )
  ]
}


# ==============================================================================
# 5. CLASSES BIVARIEES
#
# Convention désormais intuitive :
#
#   classe = FDep - couverture
#
# Exemple :
#
#   3-1 =
#     forte défavorisation
#     +
#     faible couverture
#
#   -> situation prioritaire en termes d'inégalité.
# ==============================================================================

BASE_BIVAR_B_CS[
  ,
  classe_bivar_B :=
    data.table::fifelse(
      
      !is.na(classe_fdep) &
        !is.na(classe_couverture_B),
      
      paste0(
        classe_fdep,
        "-",
        classe_couverture_B
      ),
      
      NA_character_
    )
]


BASE_BIVAR_B_CS[
  ,
  classe_bivar_Cstrict :=
    data.table::fifelse(
      
      !is.na(classe_fdep) &
        !is.na(classe_couverture_Cstrict),
      
      paste0(
        classe_fdep,
        "-",
        classe_couverture_Cstrict
      ),
      
      NA_character_
    )
]


# ==============================================================================
# 6. EXPORT DE LA BASE COMMUNALE UTILISEE
#
# Utile :
#   - article
#   - ARS Île-de-France
#   - analyses territoriales ultérieures
# ==============================================================================

data.table::fwrite(
  
  BASE_BIVAR_B_CS[
    ,
    .(
      code_commune,
      dep,
      groupe_age,
      N,
      fdep20,
      quintile_fdep_num,
      
      B_pct,
      C_strict_pct,
      gain_B_Cstrict_pp,
      
      classe_fdep,
      
      classe_couverture_B,
      classe_couverture_Cstrict,
      
      classe_bivar_B,
      classe_bivar_Cstrict
    )
  ],
  
  file.path(
    DIR_REGION,
    "BASE_BIVAR_FDEP_B_CSTRICT_REGION_IDF.csv"
  ),
  
  sep = ";"
)


# ==============================================================================
# 7. LEGENDE BIVARIEE
#
# Horizontal :
#   couverture faible -> élevée
#
# Vertical :
#   FDep faible -> élevé
# ==============================================================================

creer_legende_B_CS <- function(
    seuil_1,
    seuil_2
) {
  
  
  LEG <- data.table::CJ(
    
    classe_couverture = 1:3,
    
    classe_fdep = 1:3
  )
  
  
  LEG[
    ,
    classe :=
      paste0(
        classe_fdep,
        "-",
        classe_couverture
      )
  ]
  
  
  LEG[
    ,
    classe :=
      factor(
        classe,
        levels = names(PALETTE_B_CS)
      )
  ]
  
  
  ggplot2::ggplot(
    
    LEG,
    
    ggplot2::aes(
      x = classe_couverture,
      y = classe_fdep,
      fill = classe
    )
    
  ) +
    
    ggplot2::geom_tile(
      
      colour = "white",
      
      linewidth = 0.7
    ) +
    
    ggplot2::scale_fill_manual(
      
      values = PALETTE_B_CS,
      
      limits = names(PALETTE_B_CS),
      
      drop = FALSE,
      
      guide = "none"
    ) +
    
    ggplot2::scale_x_continuous(
      
      breaks = 1:3,
      
      labels = c(
        "Low",
        "Interm.",
        "High"
      ),
      
      expand = c(0, 0)
    ) +
    
    ggplot2::scale_y_continuous(
      
      breaks = 1:3,
      
      labels = c(
        "Low",
        "Interm.",
        "High"
      ),
      
      expand = c(0, 0)
    ) +
    
    ggplot2::coord_fixed() +
    
    ggplot2::labs(
      
      x = "Coverage (%) →",
      
      y = "FDep →",
      
      caption =
        paste0(
          "Coverage classes: ≤ ",
          formatC(
            seuil_1,
            format = "f",
            digits = 2
          ),
          " % ; > ",
          formatC(
            seuil_1,
            format = "f",
            digits = 2
          ),
          " to ≤ ",
          formatC(
            seuil_2,
            format = "f",
            digits = 2
          ),
          " % ; > ",
          formatC(
            seuil_2,
            format = "f",
            digits = 2
          ),
          " %."
        )
    ) +
    
    ggplot2::theme_minimal(
      base_size = 8
    ) +
    
    ggplot2::theme(
      
      panel.grid =
        ggplot2::element_blank(),
      
      axis.ticks =
        ggplot2::element_blank(),
      
      axis.title =
        ggplot2::element_text(
          face = "bold",
          size = 8.5
        ),
      
      axis.text =
        ggplot2::element_text(
          size = 7.5
        ),
      
      plot.caption =
        ggplot2::element_text(
          size = 6.5,
          hjust = 0.5
        ),
      
      plot.margin =
        ggplot2::margin(
          1,
          1,
          1,
          1
        )
    )
}


# ==============================================================================
# 8. FONCTION DE CREATION D'UN PANNEAU
# ==============================================================================

creer_panneau_B_CS <- function(
    groupe,
    niveau = c(
      "B",
      "C-strict"
    )
) {
  
  
  niveau <- match.arg(
    niveau
  )
  
  
  # ---------------------------------------------------------------------------
  # Variable à cartographier
  # ---------------------------------------------------------------------------
  
  variable_classe <-
    if (
      niveau == "B"
    ) {
      
      "classe_bivar_B"
      
    } else {
      
      "classe_bivar_Cstrict"
    }
  
  
  # ---------------------------------------------------------------------------
  # Données
  # ---------------------------------------------------------------------------
  
  DT_MAP <- BASE_BIVAR_B_CS[
    groupe_age == groupe,
    .(
      code_commune =
        as.character(
          code_commune
        ),
      
      classe_bivar =
        get(
          variable_classe
        )
    )
  ]
  
  
  DT_MAP[
    ,
    classe_bivar :=
      factor(
        classe_bivar,
        levels =
          names(
            PALETTE_B_CS
          )
      )
  ]
  
  
  # ---------------------------------------------------------------------------
  # Jointure au shapefile complet
  #
  # Les communes non éligibles à la représentation quantitative
  # restent donc visibles shown in grey.
  # ---------------------------------------------------------------------------
  
  SF_MAP <- dplyr::left_join(
    
    SHP_COMMUNES,
    
    as.data.frame(
      DT_MAP
    ),
    
    by =
      "code_commune"
  )
  
  
  # ---------------------------------------------------------------------------
  # Seuils de couverture B du groupe d'âge
  # ---------------------------------------------------------------------------
  
  SB <- SEUILS_B_REFERENCE[
    groupe_age == groupe
  ]
  
  
  s1 <- SB$seuil_1[1]
  s2 <- SB$seuil_2[1]
  
  
  # ---------------------------------------------------------------------------
  # Titres
  # ---------------------------------------------------------------------------
  
  titre_niveau <-
    if (
      niveau == "B"
    ) {
      
      "B — expected test documented"
      
    } else {
      
      paste0(
        "C-strict — broader documentary sensitivity"
      )
    }
  
  
  # ---------------------------------------------------------------------------
  # Carte
  # ---------------------------------------------------------------------------
  
  CARTE <- ggplot2::ggplot(
    SF_MAP
  ) +
    
    ggplot2::geom_sf(
      
      ggplot2::aes(
        fill = classe_bivar
      ),
      
      colour =
        "grey78",
      
      linewidth =
        0.055
    ) +
    
    ggplot2::geom_sf(
      
      data =
        DEP_LIMITES,
      
      fill =
        NA,
      
      colour =
        "black",
      
      linewidth =
        0.72,
      
      inherit.aes =
        FALSE
    ) +
    
    ggplot2::scale_fill_manual(
      
      values =
        PALETTE_B_CS,
      
      limits =
        names(
          PALETTE_B_CS
        ),
      
      drop =
        FALSE,
      
      na.value =
        "grey94",
      
      guide =
        "none"
    ) +
    
    ggplot2::labs(
      
      title =
        titre_niveau,
      
      subtitle =
        groupe,
      
      caption =
        paste0(
          "D0, reference date 31/12/2025. ",
          "Municipalities with N < ",
          SEUIL_N_BIVAR_B_CS,
          " ou sans FDep exploitable shown in grey."
        )
    ) +
    
    ggplot2::theme_void(
      base_size = 10.5
    ) +
    
    ggplot2::theme(
      
      plot.title =
        ggplot2::element_text(
          face = "bold",
          size = 12,
          hjust = 0
        ),
      
      plot.subtitle =
        ggplot2::element_text(
          face = "bold",
          size = 10,
          hjust = 0
        ),
      
      plot.caption =
        ggplot2::element_text(
          size = 7,
          hjust = 0
        ),
      
      plot.margin =
        ggplot2::margin(
          4,
          4,
          2,
          4
        )
    )
  
  
  # ---------------------------------------------------------------------------
  # Légende bivariée
  # ---------------------------------------------------------------------------
  
  LEGENDE <- creer_legende_B_CS(
    seuil_1 = s1,
    seuil_2 = s2
  )
  
  
  # ---------------------------------------------------------------------------
  # Assemblage panneau
  # ---------------------------------------------------------------------------
  
  CARTE /
    LEGENDE +
    
    patchwork::plot_layout(
      heights = c(
        5,
        1.45
      )
    )
}


# ==============================================================================
# 9. CREATION DES QUATRE PANNEAUX
# ==============================================================================

P_B_25 <- creer_panneau_B_CS(
  groupe = "25–29 ans",
  niveau = "B"
)


P_CS_25 <- creer_panneau_B_CS(
  groupe = "25–29 ans",
  niveau = "C-strict"
)


P_B_30 <- creer_panneau_B_CS(
  groupe = "30–65 ans",
  niveau = "B"
)


P_CS_30 <- creer_panneau_B_CS(
  groupe = "30–65 ans",
  niveau = "C-strict"
)


# ==============================================================================
# 10. FIGURE COMPLETE 2 × 2
# ==============================================================================

FIGURE_BIVAR_B_CS <- (
  
  P_B_25 |
    P_CS_25
  
) /
  (
    
    P_B_30 |
      P_CS_30
    
  ) +
  
  patchwork::plot_annotation(
    
    title =
      paste0(
        "Municipal distribution of documented coverage ",
        "and deprivation"
      ),
    
    subtitle =
      "Île-de-France, 2025",
    
    caption =
      paste0(
        "Interpretation: colour combines the level of municipal deprivation ",
        "(FDep) and the level of documented coverage. ",
        "For each age group, coverage thresholds defined from B ",
        "are applied identically to B and C-strict to allow a ",
        "direct comparison of the effect of broader documentary ascertainment. ",
        "FDep: low = Q1–Q2; intermediate = Q3; high = Q4–Q5."
      ),
    
    theme =
      ggplot2::theme(
        
        plot.title =
          ggplot2::element_text(
            face = "bold",
            size = 17,
            hjust = 0
          ),
        
        plot.subtitle =
          ggplot2::element_text(
            size = 12,
            hjust = 0
          ),
        
        plot.caption =
          ggplot2::element_text(
            size = 8,
            hjust = 0
          )
      )
  )


# ==============================================================================
# 11. AFFICHAGE
# ==============================================================================

FIGURE_BIVAR_B_CS


# ==============================================================================
# 12. EXPORT — ARTICLE / REGION IDF
# ==============================================================================

ggplot2::ggsave(
  
  filename =
    file.path(
      DIR_FIG_BIVAR_B_CS,
      "FIGURE_BIVAR_FDEP_B_CSTRICT_4_PANNEAUX.png"
    ),
  
  plot =
    FIGURE_BIVAR_B_CS,
  
  width =
    13,
  
  height =
    16.5,
  
  units =
    "in",
  
  dpi =
    320,
  
  bg =
    "white"
)


ggplot2::ggsave(
  
  filename =
    file.path(
      DIR_FIG_BIVAR_B_CS,
      "FIGURE_BIVAR_FDEP_B_CSTRICT_4_PANNEAUX.tiff"
    ),
  
  plot =
    FIGURE_BIVAR_B_CS,
  
  width =
    13,
  
  height =
    16.5,
  
  units =
    "in",
  
  dpi =
    600,
  
  compression =
    "lzw",
  
  bg =
    "white"
)


ggplot2::ggsave(
  
  filename =
    file.path(
      DIR_FIG_BIVAR_B_CS,
      "FIGURE_BIVAR_FDEP_B_CSTRICT_4_PANNEAUX.pdf"
    ),
    plot =
    FIGURE_BIVAR_B_CS,
  
  width =
    13,
  
  height =
    16.5,
  
  units =
    "in",
  
  device =
    cairo_pdf,
  
  bg =
    "white"
)


# ==============================================================================
# 13. TABLEAU DE REPARTITION DES COMMUNES
#
# Objectif :
# - nombre de communes dans chacune des 9 cellules FDep × couverture
# - population correspondante
# - séparément pour B et C-strict
# - séparément pour les deux groupes d'âge
# ==============================================================================


# ------------------------------------------------------------------------------
# 13.1 B
# ------------------------------------------------------------------------------

TAB_B_BIVAR <- BASE_BIVAR_B_CS[
  
  !is.na(
    classe_bivar_B
  ),
  
  .(
    niveau =
      "B",
    
    n_communes =
      .N,
    
    population =
      sum(
        N,
        na.rm = TRUE
      )
  ),
  
  by = .(
    groupe_age,
    
    classe_bivariee =
      as.character(
        classe_bivar_B
      )
  )
]


# ------------------------------------------------------------------------------
# 13.2 C-STRICT
# ------------------------------------------------------------------------------

TAB_CS_BIVAR <- BASE_BIVAR_B_CS[
  
  !is.na(
    classe_bivar_Cstrict
  ),
  
  .(
    niveau =
      "C-strict",
    
    n_communes =
      .N,
    
    population =
      sum(
        N,
        na.rm = TRUE
      )
  ),
  
  by = .(
    groupe_age,
    
    classe_bivariee =
      as.character(
        classe_bivar_Cstrict
      )
  )
]


# ------------------------------------------------------------------------------
# 13.3 REUNION
# ------------------------------------------------------------------------------

TAB_BIVAR_B_CS <- data.table::rbindlist(
  
  list(
    TAB_B_BIVAR,
    TAB_CS_BIVAR
  ),
  
  use.names =
    TRUE,
  
  fill =
    TRUE
)


# ------------------------------------------------------------------------------
# 13.4 ORDRE DES COLONNES
# ------------------------------------------------------------------------------

data.table::setcolorder(
  
  TAB_BIVAR_B_CS,
  
  c(
    "groupe_age",
    "niveau",
    "classe_bivariee",
    "n_communes",
    "population"
  )
)


# ------------------------------------------------------------------------------
# 13.5 POURCENTAGE DES COMMUNES
#
# Dénominateur :
# ensemble des communes effectivement classées dans la carte
# pour le groupe d'âge et le niveau considérés.
# ------------------------------------------------------------------------------

TAB_BIVAR_B_CS[
  ,
  pct_communes :=
    100 *
    n_communes /
    sum(
      n_communes
    ),
  by = .(
    groupe_age,
    niveau
  )
]


# ------------------------------------------------------------------------------
# 13.6 POURCENTAGE DE LA POPULATION
# ------------------------------------------------------------------------------

TAB_BIVAR_B_CS[
  ,
  pct_population :=
    100 *
    population /
    sum(
      population
    ),
  by = .(
    groupe_age,
    niveau
  )
]


# ------------------------------------------------------------------------------
# 13.7 DECOMPOSITION DES CLASSES
#
# classe_bivariee = FDep - couverture
#
# Exemples :
#   1-1 = FDep faible  + couverture faible
#   1-3 = FDep faible  + couverture élevée
#   3-1 = FDep élevé   + couverture faible
#   3-3 = FDep élevé   + couverture élevée
# ------------------------------------------------------------------------------

TAB_BIVAR_B_CS[
  ,
  `:=`(
    
    classe_fdep =
      as.integer(
        sub(
          "-.*$",
          "",
          classe_bivariee
        )
      ),
    
    classe_couverture =
      as.integer(
        sub(
          "^.*-",
          "",
          classe_bivariee
        )
      )
  )
]


# ------------------------------------------------------------------------------
# 13.8 LIBELLES INTERPRETABLES
# ------------------------------------------------------------------------------

TAB_BIVAR_B_CS[
  ,
  fdep_libelle :=
    data.table::fcase(
      
      classe_fdep == 1L,
      "Low FDep",
      
      classe_fdep == 2L,
      "Intermediate FDep",
      
      classe_fdep == 3L,
      "High FDep",
      
      default =
        NA_character_
    )
]


TAB_BIVAR_B_CS[
  ,
  couverture_libelle :=
    data.table::fcase(
      
      classe_couverture == 1L,
      "Low coverage",
      
      classe_couverture == 2L,
      "Intermediate coverage",
      
      classe_couverture == 3L,
      "High coverage",
      
      default =
        NA_character_
    )
]


# ------------------------------------------------------------------------------
# 13.9 ORDRE FINAL
# ------------------------------------------------------------------------------

data.table::setorder(
  
  TAB_BIVAR_B_CS,
  
  groupe_age,
  niveau,
  classe_fdep,
  classe_couverture
)


# ------------------------------------------------------------------------------
# 13.10 AFFICHAGE
# ------------------------------------------------------------------------------

cat("\n")
cat("=====================================================================\n")
cat(" REPARTITION DES COMMUNES — FDEP × B / C-STRICT\n")
cat("=====================================================================\n")

print(
  TAB_BIVAR_B_CS
)


# ------------------------------------------------------------------------------
# 13.11 FOCUS SUR LES SITUATIONS LES PLUS IMPORTANTES POUR L'EQUITE
#
# 3-1 = forte défavorisation + faible couverture
# 3-2 = forte défavorisation + couverture intermédiaire
# 3-3 = forte défavorisation + couverture élevée
# ------------------------------------------------------------------------------

cat("\n")
cat("---------------------------------------------------------------------\n")
cat(" FOCUS — COMMUNES LES PLUS DEFAVORISEES\n")
cat("---------------------------------------------------------------------\n")

print(
  TAB_BIVAR_B_CS[
    classe_fdep == 3L
  ]
)


# ------------------------------------------------------------------------------
# 13.12 FOCUS PRIORITAIRE
#
# Forte défavorisation + faible couverture
# ------------------------------------------------------------------------------

FOCUS_PRIORITAIRE_B_CS <- TAB_BIVAR_B_CS[
  classe_fdep == 3L &
    classe_couverture == 1L
]


cat("\n")
cat("---------------------------------------------------------------------\n")
cat(" FDEP ELEVE + COUVERTURE FAIBLE — CLASSE 3-1\n")
cat("---------------------------------------------------------------------\n")

print(
  FOCUS_PRIORITAIRE_B_CS
)


# ------------------------------------------------------------------------------
# 13.13 EXPORT
# ------------------------------------------------------------------------------

data.table::fwrite(
  
  TAB_BIVAR_B_CS,
  
  file.path(
    DIR_REGION,
    "TABLEAU_REPARTITION_BIVAR_FDEP_B_CSTRICT.csv"
  ),
  
  sep = ";"
)


data.table::fwrite(
  
  FOCUS_PRIORITAIRE_B_CS,
  
  file.path(
    DIR_REGION,
    "FOCUS_FDEP_ELEVE_COUVERTURE_FAIBLE_B_CSTRICT.csv"
  ),
  
  sep = ";"
)


cat("\n")
cat("=====================================================================\n")
cat(" TABLEAU BIVARIE B / C-STRICT TERMINE\n")
cat("=====================================================================\n")

### AJOUT NEW TAB

# ==============================================================================
# AJOUT ARTICLE FINAL — NOUVEAUX TABLEAUX 1, 2 ET 3
# ==============================================================================
#
# IMPORTANT :
# - CE BLOC S'AJOUTE A LA FIN DU SCRIPT EXISTANT.
# - AUCUN OBJET EXISTANT N'EST ECRASE.
# - AUCUN FICHIER EXISTANT N'EST ECRASE.
# - AUCUN MODELE N'EST RE-ESTIME.
# - AUCUN TEST STATISTIQUE N'EST RELANCE.
#
# Nouveaux objets : suffixe _NEW
# Nouveaux fichiers : préfixe ARTICLE_NEW_
#
# TABLEAU 1
#   Département × groupe d'âge
#   A-CCAM / A / B / C-strict / C-broad
#
# TABLEAU 2
#   Département, population 25–65 ans
#   A-CCAM / A / B / C-strict / C-broad
#
# TABLEAU 3
#   Panel A : gradients descriptifs FDep + SII/RII
#   Panel B : modèles ajustés / couvertures marginales
#
# ==============================================================================


# ==============================================================================
# 0. REPERTOIRE SPECIFIQUE — NE RIEN ECRASER
# ==============================================================================

DIR_TABLEAUX_ARTICLE_NEW <- file.path(
  DIR_TABLEAUX,
  "ARTICLE_FINAL_NEW"
)

dir.create(
  DIR_TABLEAUX_ARTICLE_NEW,
  recursive = TRUE,
  showWarnings = FALSE
)


# ==============================================================================
# 1. A-CCAM AU NIVEAU FEMME
#
# Le cache 23 contient les résultats régionaux A-CCAM mais pas l'identifiant
# individuel A-CCAM nécessaire à l'agrégation départementale.
#
# On reproduit STRICTEMENT le bloc 23C déjà validé :
#
# 25–29 ans :
#   JKQX001, JKQX008, JKQX347, JKQX147,
#   JKQX261, JKQX426, JKQX027, JKQX015
#
# 30–65 ans :
#   ZZQX628, ZZQX603, ZZQX173
#
# Aucun nouveau code n'est introduit.
# ==============================================================================

PATH_CACHE_02_NEW <- trouver_etape(
  "CACHE_02_BD1_LIGNES_REDUITES.rds"
)


BD1_CCAM_NEW <- readRDS(
  PATH_CACHE_02_NEW
)

data.table::setDT(
  BD1_CCAM_NEW
)


# ------------------------------------------------------------------------------
# 1.1 Référentiel femme / groupe d'âge issu de la base finale
# ------------------------------------------------------------------------------

REF_FEMME_AGE_NEW <- unique(
  BASE_FEMME_2025[
    ,
    .(
      id_bci =
        as.character(id_bci),
      
      groupe_age =
        as.character(groupe_age)
    )
  ]
)


# ------------------------------------------------------------------------------
# 1.2 Réduction immédiate de BD1
# ------------------------------------------------------------------------------

BD1_CCAM_NEW <- BD1_CCAM_NEW[
  ,
  .(
    id_bci =
      as.character(id_bci),
    
    date_acte =
      as.Date(date_acte),
    
    code_cyto =
      code_cyto,
    
    code_hpv =
      code_hpv
  )
]


BD1_CCAM_NEW[
  REF_FEMME_AGE_NEW,
  on = "id_bci",
  groupe_age := i.groupe_age
]


# ------------------------------------------------------------------------------
# 1.3 Fenêtres analytiques finales
# ------------------------------------------------------------------------------

BD1_CCAM_NEW <- BD1_CCAM_NEW[
  (
    groupe_age == "25–29 ans" &
      date_acte >= DATE_DEBUT_CYTO &
      date_acte <= DATE_REF
  ) |
    (
      groupe_age == "30–65 ans" &
        date_acte >= DATE_DEBUT_HPV &
        date_acte <= DATE_REF
    )
]


# ------------------------------------------------------------------------------
# 1.4 Normalisation identique des codes
# ------------------------------------------------------------------------------

normaliser_code_NEW <- function(x) {
  
  y <- toupper(
    trimws(
      as.character(x)
    )
  )
  
  y[
    y %in%
      c(
        "",
        "NA",
        "N/A",
        "NULL"
      )
  ] <- NA_character_
  
  y <- sub(
    "\\.0+$",
    "",
    y
  )
  
  idx_num <-
    !is.na(y) &
    grepl(
      "^[0-9]+$",
      y
    ) &
    nchar(y) <= 4L
  
  if (any(idx_num)) {
    
    y[idx_num] <- sprintf(
      "%04d",
      as.integer(
        y[idx_num]
      )
    )
  }
  
  y
}


BD1_CCAM_NEW[
  ,
  `:=`(
    code_cyto =
      normaliser_code_NEW(
        code_cyto
      ),
    
    code_hpv =
      normaliser_code_NEW(
        code_hpv
      )
  )
]


# ------------------------------------------------------------------------------
# 1.5 Codes CCAM strictement issus du bloc 23C validé
# ------------------------------------------------------------------------------

CCAM_CYTO_NEW <- c(
  "JKQX001",
  "JKQX008",
  "JKQX347",
  "JKQX147",
  "JKQX261",
  "JKQX426",
  "JKQX027",
  "JKQX015"
)


CCAM_HPV_NEW <- c(
  "ZZQX628",
  "ZZQX603",
  "ZZQX173"
)


# ------------------------------------------------------------------------------
# 1.6 Femmes A-CCAM
# ------------------------------------------------------------------------------

IDS_ACCAM_NEW <- unique(
  BD1_CCAM_NEW[
    (
      groupe_age == "25–29 ans" &
        code_cyto %chin% CCAM_CYTO_NEW
    ) |
      (
        groupe_age == "30–65 ans" &
          code_hpv %chin% CCAM_HPV_NEW
      ),
    .(
      id_bci,
      groupe_age
    )
  ]
)


rm(
  BD1_CCAM_NEW,
  REF_FEMME_AGE_NEW
)

invisible(
  gc()
)


# ==============================================================================
# 2. BASE FEMME DE PRODUCTION DES NOUVEAUX TABLEAUX
#
# Copie uniquement : BASE_FEMME_2025 reste intacte.
# ==============================================================================

BASE_TABLEAUX_NEW <- data.table::copy(
  BASE_FEMME_2025
)


BASE_TABLEAUX_NEW[
  ,
  `:=`(
    id_bci =
      as.character(id_bci),
    
    groupe_age =
      as.character(groupe_age),
    
    dep =
      as.character(dep),
    
    A_CCAM_NEW =
      FALSE
  )
]


BASE_TABLEAUX_NEW[
  IDS_ACCAM_NEW,
  on = .(
    id_bci,
    groupe_age
  ),
  A_CCAM_NEW := TRUE
]


rm(
  IDS_ACCAM_NEW
)

invisible(
  gc()
)


# ==============================================================================
# 3. BASE DEPARTEMENT × AGE — PROFONDEUR COMPLETE
# ==============================================================================

DEP_AGE_NEW <- BASE_TABLEAUX_NEW[
  groupe_age %in% GROUPES_AGE &
    dep %in% DEPARTEMENTS_IDF,
  .(
    N =
      .N,
    
    A_CCAM =
      sum(
        A_CCAM_NEW,
        na.rm = TRUE
      ),
    
    A =
      sum(
        A %in% TRUE
      ),
    
    B =
      sum(
        B %in% TRUE
      ),
    
    C_strict =
      sum(
        C_strict %in% TRUE
      ),
    
    C_broad =
      sum(
        C_broad %in% TRUE
      )
  ),
  by = .(
    dep,
    groupe_age
  )
]


# ------------------------------------------------------------------------------
# 3.1 Ligne régionale par groupe d'âge
# ------------------------------------------------------------------------------

REGION_AGE_NEW <- DEP_AGE_NEW[
  ,
  .(
    N =
      sum(N),
    
    A_CCAM =
      sum(A_CCAM),
    
    A =
      sum(A),
    
    B =
      sum(B),
    
    C_strict =
      sum(C_strict),
    
    C_broad =
      sum(C_broad)
  ),
  by = groupe_age
]


REGION_AGE_NEW[
  ,
  dep := "IDF"
]


T1_SOURCE_NEW <- data.table::rbindlist(
  list(
    DEP_AGE_NEW,
    REGION_AGE_NEW
  ),
  use.names = TRUE,
  fill = TRUE
)


T1_SOURCE_NEW[
  ,
  `:=`(
    A_CCAM_pct =
      100 * A_CCAM / N,
    
    A_pct =
      100 * A / N,
    
    B_pct =
      100 * B / N,
    
    C_strict_pct =
      100 * C_strict / N,
    
    C_broad_pct =
      100 * C_broad / N,
    
    gain_B_Cstrict_pp =
      100 *
      (C_strict - B) /
      N
  )
]


T1_SOURCE_NEW[
  ,
  departement :=
    data.table::fifelse(
      dep == "IDF",
      "Île-de-France",
      unname(
        NOMS_DEPARTEMENTS[dep]
      )
    )
]


T1_SOURCE_NEW[
  ,
  ordre_dep :=
    data.table::fifelse(
      dep == "IDF",
      9L,
      match(
        dep,
        DEPARTEMENTS_IDF
      )
    )
]


data.table::setorder(
  T1_SOURCE_NEW,
  ordre_dep,
  groupe_age
)


# ==============================================================================
# 4. TABLEAU 1 NEW
# COUVERTURE DEPARTEMENTALE COMPLETE PAR GROUPE D'AGE
#
# Deux grands panels :
#   25–29 ans — cytologie
#   30–65 ans — HPV
# ==============================================================================


# ------------------------------------------------------------------------------
# 4.1 Panel 25–29 ans
# ------------------------------------------------------------------------------

T1_25_NEW <- T1_SOURCE_NEW[
  groupe_age == "25–29 ans",
  .(
    dep,
    departement,
    ordre_dep,
    
    N_25 =
      N,
    
    ACCAM_25 =
      fmt_npct(
        A_CCAM,
        A_CCAM_pct
      ),
    
    A_25 =
      fmt_npct(
        A,
        A_pct
      ),
    
    B_25 =
      fmt_npct(
        B,
        B_pct
      ),
    
    CS_25 =
      fmt_npct(
        C_strict,
        C_strict_pct
      ),
    
    CB_25 =
      fmt_npct(
        C_broad,
        C_broad_pct
      ),
    
    GAIN_25 =
      fmt_num(
        gain_B_Cstrict_pp,
        2,
        signed = TRUE
      )
  )
]


# ------------------------------------------------------------------------------
# 4.2 Panel 30–65 ans
# ------------------------------------------------------------------------------

T1_30_NEW <- T1_SOURCE_NEW[
  groupe_age == "30–65 ans",
  .(
    dep,
    
    N_30 =
      N,
    
    ACCAM_30 =
      fmt_npct(
        A_CCAM,
        A_CCAM_pct
      ),
    
    A_30 =
      fmt_npct(
        A,
        A_pct
      ),
    
    B_30 =
      fmt_npct(
        B,
        B_pct
      ),
    
    CS_30 =
      fmt_npct(
        C_strict,
        C_strict_pct
      ),
    
    CB_30 =
      fmt_npct(
        C_broad,
        C_broad_pct
      ),
    
    GAIN_30 =
      fmt_num(
        gain_B_Cstrict_pp,
        2,
        signed = TRUE
      )
  )
]


# ------------------------------------------------------------------------------
# 4.3 Réunion
# ------------------------------------------------------------------------------

T1_PRINT_NEW <- merge(
  T1_25_NEW,
  T1_30_NEW,
  by = "dep",
  all = TRUE,
  sort = FALSE
)


data.table::setorder(
  T1_PRINT_NEW,
  ordre_dep
)


T1_PRINT_NEW <- T1_PRINT_NEW[
  ,
  .(
    `Department` =
      departement,
    
    `N` =
      fmt_n(
        N_25
      ),
    
    `A-CCAM, n (%)` =
      ACCAM_25,
    
    `A, n (%)` =
      A_25,
    
    `B, n (%)` =
      B_25,
    
    `C-strict, n (%)` =
      CS_25,
    
    `C-broad, n (%)` =
      CB_25,
    
    `Gain, pp` =
      GAIN_25,
    
    `N ` =
      fmt_n(
        N_30
      ),
    
    `A-CCAM, n (%) ` =
      ACCAM_30,    
    `A, n (%) ` =
      A_30,
    
    `B, n (%) ` =
      B_30,
    
    `C-strict, n (%) ` =
      CS_30,
    
    `C-broad, n (%) ` =
      CB_30,
    
    `Gain, pp ` =
      GAIN_30
  )
]


# ------------------------------------------------------------------------------
# 4.4 Flextable
# ------------------------------------------------------------------------------

FT_T1_NEW <- flextable::flextable(
  T1_PRINT_NEW
)


FT_T1_NEW <- flextable::add_header_row(
  FT_T1_NEW,
  values = c(
    "",
    "25–29 years — cytology",
    "30–65 years — HPV"
  ),
  colwidths = c(
    1,
    7,
    7
  )
)


FT_T1_NEW <- FT_T1_NEW |>
  flextable::theme_booktabs() |>
  flextable::font(
    fontname = "Arial",
    part = "all"
  ) |>
  flextable::fontsize(
    size = 6.8,
    part = "all"
  ) |>
  flextable::bold(
    part = "header"
  ) |>
  flextable::align(
    align = "center",
    part = "header"
  ) |>
  flextable::align(
    j = 1,
    align = "left",
    part = "body"
  ) |>
  flextable::valign(
    valign = "center",
    part = "all"
  )


FT_T1_NEW <- flextable::width(
  FT_T1_NEW,
  j = 1,
  width = 1.20
)


FT_T1_NEW <- flextable::width(
  FT_T1_NEW,
  j = 2:15,
  width = 0.68
)


FT_T1_NEW <- flextable::set_table_properties(
  FT_T1_NEW,
  layout = "fixed",
  width = 1
)


FT_T1_NEW <- flextable::set_caption(
  FT_T1_NEW,
  caption = paste0(
    "Table 1. Cervical cancer screening coverage ",
    "according to documentary depth, age group and department, ",
    "Île-de-France, ",
    ANNEE_REF
  )
)


FT_T1_NEW <- flextable::add_footer_lines(
  FT_T1_NEW,
  values = c(
    paste0(
      "A-CCAM: expected test identified exclusively from the retained CCAM codes; ",
      "A: expected test identified from the full set of reference codes; ",
      "B: the same expected test directly documented, irrespective of the documentary pathway."
    ),
    paste0(
      "C-strict: B supplemented, among women not meeting B, by an alternative cervical ",
      "test explicitly documented as screening or by concordant evidence ",
      "establishing strong cervical-care continuity; C-broad: C-strict supplemented by ",
      "documented cervical pathways that are compatible but less specific."
    ),
    paste0(
      "The expected test was cytology between 1 January 2023 and 31 December 2025 ",
      "for women aged 25–29 years, and an HPV test between 1 January 2021 and ",
      "31 December 2025 for women aged 30–65 years."
    ),
    paste0(
      "Gain: absolute difference C-strict − B, in percentage points (pp). ",
      "The C levels are documentary sensitivity analyses and not ",
      "estimates of guideline-concordant coverage."
    )
  )
)


FT_T1_NEW <- flextable::fontsize(
  FT_T1_NEW,
  size = 6.3,
  part = "footer"
)


FT_T1_NEW <- flextable::align(
  FT_T1_NEW,
  align = "left",
  part = "footer"
)


# ------------------------------------------------------------------------------
# 4.5 Export Tableau 1 NEW
# ------------------------------------------------------------------------------

SECTION_PAYSAGE_NEW <- officer::prop_section(
  page_size =
    officer::page_size(
      orient = "landscape"
    ),
  page_margins =
    officer::page_mar(
      top = 0.35,
      bottom = 0.35,
      left = 0.30,
      right = 0.30
    )
)


data.table::fwrite(
  T1_SOURCE_NEW,
  file.path(
    DIR_TABLEAUX_ARTICLE_NEW,
    "ARTICLE_NEW_TABLEAU_1_SOURCE_DEPARTEMENTS_PAR_AGE.csv"
  ),
  sep = ";",
  bom = TRUE
)


flextable::save_as_docx(
  `Tableau 1` = FT_T1_NEW,
  path =
    file.path(
      DIR_TABLEAUX_ARTICLE_NEW,
      "ARTICLE_NEW_TABLEAU_1_DEPARTEMENTS_PAR_AGE_PROFONDEUR_COMPLETE.docx"
    ),
  pr_section =
    SECTION_PAYSAGE_NEW
)


# ==============================================================================
# 5. TABLEAU 2 NEW
# COUVERTURE 25–65 ANS PAR DEPARTEMENT — PROFONDEUR COMPLETE
#
# Les indicateurs sont additionnés sur les deux groupes d'âge :
# chaque femme reste évaluée avec le test attendu correspondant à son âge.
# ==============================================================================

T2_SOURCE_NEW <- DEP_AGE_NEW[
  ,
  .(
    N =
      sum(N),
    
    A_CCAM =
      sum(A_CCAM),
    
    A =
      sum(A),
    
    B =
      sum(B),
    
    C_strict =
      sum(C_strict),
    
    C_broad =
      sum(C_broad)
  ),
  by = dep
]


T2_TOTAL_NEW <- T2_SOURCE_NEW[
  ,
  .(
    dep =
      "IDF",
    
    N =
      sum(N),
    
    A_CCAM =
      sum(A_CCAM),
    
    A =
      sum(A),
    
    B =
      sum(B),
    
    C_strict =
      sum(C_strict),
    
    C_broad =
      sum(C_broad)
  )
]


T2_SOURCE_NEW <- data.table::rbindlist(
  list(
    T2_SOURCE_NEW,
    T2_TOTAL_NEW
  ),
  use.names = TRUE
)


T2_SOURCE_NEW[
  ,
  `:=`(
    A_CCAM_pct =
      100 * A_CCAM / N,
    
    A_pct =
      100 * A / N,
    
    B_pct =
      100 * B / N,
    
    C_strict_pct =
      100 * C_strict / N,
    
    C_broad_pct =
      100 * C_broad / N,
    
    gain_B_Cstrict_pp =
      100 *
      (C_strict - B) /
      N,
    
    departement =
      data.table::fifelse(
        dep == "IDF",
        "Île-de-France",
        unname(
          NOMS_DEPARTEMENTS[dep]
        )
      ),
    
    ordre_dep =
      data.table::fifelse(
        dep == "IDF",
        9L,
        match(
          dep,
          DEPARTEMENTS_IDF
        )
      )
  )
]


data.table::setorder(
  T2_SOURCE_NEW,
  ordre_dep
)


T2_PRINT_NEW <- T2_SOURCE_NEW[
  ,
  .(
    `Department` =
      departement,
    
    `Population, N` =
      fmt_n(N),
    
    `A-CCAM, n (%)` =
      fmt_npct(
        A_CCAM,
        A_CCAM_pct
      ),
    
    `A, n (%)` =
      fmt_npct(
        A,
        A_pct
      ),
    
    `B, n (%)` =
      fmt_npct(
        B,
        B_pct
      ),
    
    `C-strict, n (%)` =
      fmt_npct(
        C_strict,
        C_strict_pct
      ),
    
    `C-broad, n (%)` =
      fmt_npct(
        C_broad,
        C_broad_pct
      ),
    
    `Gain, pp` =
      fmt_num(
        gain_B_Cstrict_pp,
        2,
        signed = TRUE
      )
  )
]


FT_T2_NEW <- flextable::flextable(
  T2_PRINT_NEW
)


FT_T2_NEW <- FT_T2_NEW |>
  flextable::theme_booktabs() |>
  flextable::font(
    fontname = "Arial",
    part = "all"
  ) |>
  flextable::fontsize(
    size = 8,
    part = "all"
  ) |>
  flextable::bold(
    part = "header"
  ) |>
  flextable::align(
    align = "center",
    part = "header"
  ) |>
  flextable::align(
    j = 1,
    align = "left",
    part = "body"
  ) |>
  flextable::valign(
    valign = "center",
    part = "all"
  ) |>
  flextable::autofit()


FT_T2_NEW <- flextable::set_caption(
  FT_T2_NEW,
  caption = paste0(
    "Table 2. Cervical cancer screening coverage ",
    "according to documentary depth and department among women aged ",
    "25 to 65 years, Île-de-France, ",
    ANNEE_REF
  )
)


FT_T2_NEW <- flextable::add_footer_lines(
  FT_T2_NEW,
  values = c(
    paste0(
      "A-CCAM: expected test identified exclusively from the retained CCAM codes; ",
      "A: expected test identified from the full set of reference codes; ",
      "B: the same expected test directly documented, irrespective of the documentary pathway."
    ),
    paste0(
      "C-strict: B supplemented by an alternative cervical test explicitly documented ",
      "as screening or by strong cervical-care continuity; C-broad: C-strict ",
      "complété par des documented cervical pathways that are compatible but less specific."
    ),
    paste0(
      "Indicators for ages 25–65 years combine the two age-specific expected modalities: ",
      "cytology in 2023–2025 for women aged 25–29 years and HPV testing in 2021–2025 for women aged 30–65 years."
    ),
    paste0(
      "Gain: absolute difference C-strict − B, in percentage points (pp). ",
      "The C levels are documentary sensitivity analyses."
    )
  )
)


FT_T2_NEW <- flextable::fontsize(
  FT_T2_NEW,
  size = 7,
  part = "footer"
)


FT_T2_NEW <- flextable::align(
  FT_T2_NEW,
  align = "left",
  part = "footer"
)


SECTION_PORTRAIT_NEW <- officer::prop_section(
  page_size =
    officer::page_size(
      orient = "portrait"
    ),
  page_margins =
    officer::page_mar(
      top = 0.45,
      bottom = 0.45,
      left = 0.45,
      right = 0.45
    )
)


data.table::fwrite(
  T2_SOURCE_NEW,
  file.path(
    DIR_TABLEAUX_ARTICLE_NEW,
    "ARTICLE_NEW_TABLEAU_2_SOURCE_DEPARTEMENTS_25_65.csv"
  ),
  sep = ";",
  bom = TRUE
)


flextable::save_as_docx(
  `Tableau 2` = FT_T2_NEW,
  path =
    file.path(
      DIR_TABLEAUX_ARTICLE_NEW,
      "ARTICLE_NEW_TABLEAU_2_DEPARTEMENTS_25_65_PROFONDEUR_COMPLETE.docx"
    ),
  pr_section =
    SECTION_PORTRAIT_NEW
)


# ==============================================================================
# 6. TABLEAU 3 NEW — DEUX PANELS
#
# PANEL A
#   Gradients descriptifs Q1-Q5 + Q5-Q1 + SII/RII
#
# PANEL B
#   Couvertures marginales ajustées issues du modèle déjà estimé
#
# Aucun modèle n'est recalculé.
# ==============================================================================


# ==============================================================================
# 6A. PANEL A — DESCRIPTIF + INDICES FORMELS
# ==============================================================================

T3A_FDEP_NEW <- data.table::as.data.table(
  CACHE_16$tableau_fdep
)


T3A_SII_NEW <- data.table::as.data.table(
  CACHE_17$tableau_principal
)[
  indicateur %in%
    c(
      "B",
      "C_strict"
    )
]


T3A_LONG_NEW <- data.table::rbindlist(
  list(
    T3A_FDEP_NEW[
      ,
      .(
        groupe_age,
        quintile_fdep_num,
        definition = "B",
        couverture = B_pct
      )
    ],
    
    T3A_FDEP_NEW[
      ,
      .(
        groupe_age,
        quintile_fdep_num,
        definition = "C-strict",
        couverture = C_strict_pct
      )
    ]
  )
)


T3A_WIDE_NEW <- data.table::dcast(
  T3A_LONG_NEW,
  groupe_age + definition ~ quintile_fdep_num,
  value.var = "couverture"
)


data.table::setnames(
  T3A_WIDE_NEW,
  c(
    "1",
    "2",
    "3",
    "4",
    "5"
  ),
  paste0(
    "Q",
    1:5
  )
)


T3A_WIDE_NEW[
  ,
  `Q5-Q1` :=
    Q5 - Q1
]


T3A_SII2_NEW <- T3A_SII_NEW[
  ,
  .(
    groupe_age,
    
    definition =
      data.table::fifelse(
        indicateur == "C_strict",
        "C-strict",
        indicateur
      ),
    
    SII =
      SII_pp,
    
    RII =
      RII
  )
]


T3A_FINAL_NEW <- merge(
  T3A_WIDE_NEW,
  T3A_SII2_NEW,
  by = c(
    "groupe_age",
    "definition"
  ),
  all.x = TRUE,
  sort = FALSE
)


T3A_FINAL_NEW[
  ,
  `:=`(
    ordre_age =
      match(
        groupe_age,
        GROUPES_AGE
      ),
    
    ordre_def =
      match(
        definition,
        c(
          "B",
          "C-strict"
        )
      )
  )
]


data.table::setorder(
  T3A_FINAL_NEW,
  ordre_age,
  ordre_def
)


T3A_PRINT_NEW <- T3A_FINAL_NEW[
  ,
  .(
    `Age group` =
      groupe_age,
    
    `Definition` =
      definition,
    
    `Q1` =
      fmt_num(
        Q1,
        2
      ),
    
    `Q2` =
      fmt_num(
        Q2,
        2
      ),
    
    `Q3` =
      fmt_num(
        Q3,
        2
      ),
    
    `Q4` =
      fmt_num(
        Q4,
        2
      ),
    
    `Q5` =
      fmt_num(
        Q5,
        2
      ),
    
    `Q5 – Q1, pp` =
      fmt_num(
        `Q5-Q1`,
        2
      ),
    
    `SII, pp` =
      fmt_num(
        SII,
        2
      ),
    
    `RII` =
      fmt_num(
        RII,
        3
      )
  )
]


FT_T3A_NEW <- flextable::flextable(
  T3A_PRINT_NEW
)


FT_T3A_NEW <- FT_T3A_NEW |>
  flextable::theme_booktabs() |>
  flextable::font(
    fontname = "Arial",
    part = "all"
  ) |>
  flextable::fontsize(
    size = 8,
    part = "all"
  ) |>
  flextable::bold(
    part = "header"
  ) |>
  flextable::align(
    align = "center",
    part = "header"
  ) |>
  flextable::align(
    j = 1:2,
    align = "left",
    part = "body"
  ) |>
  flextable::merge_v(
    j = 1
  ) |>
  flextable::valign(
    j = 1,
    valign = "top"
  ) |>
  flextable::autofit()


FT_T3A_NEW <- flextable::set_caption(
  FT_T3A_NEW,
  caption =
    paste0(
      "A. Socio-territorial inequalities in coverage according to municipal deprivation ",
      "and documentary depth, Île-de-France, ",
      ANNEE_REF
    )
)


# ==============================================================================
# 6B. PANEL B — MODELE AJUSTE DEJA ESTIME
# ==============================================================================

T3B_FINAL_NEW <- data.table::as.data.table(
  CACHE_18$marginales
)[
  indicateur %in%
    c(
      "B",
      "C_strict",
      "C_broad"
    )
]


T3B_FINAL_NEW[
  ,
  definition :=
    data.table::fcase(
      indicateur == "B",
      "B",
      
      indicateur == "C_strict",
      "C-strict",
      
      indicateur == "C_broad",
      "C-broad",
      
      default =
        as.character(indicateur)
    )
]


T3B_FINAL_NEW[
  ,
  `:=`(
    ordre_age =
      match(
        groupe_age,
        GROUPES_AGE
      ),
    
    ordre_def =
      match(
        definition,
        c(
          "B",
          "C-strict",
          "C-broad"
        )
      )
  )
]


data.table::setorder(
  T3B_FINAL_NEW,
  ordre_age,
  ordre_def
)


T3B_PRINT_NEW <- T3B_FINAL_NEW[
  ,
  .(
    `Age group` =
      groupe_age,
    
    `Definition` =
      definition,
    
    `FDep −1 SD, % [95% CI]` =
      fmt_ci(
        couverture_m1SD_pct,
        couverture_m1SD_inf,
        couverture_m1SD_sup,
        2
      ),
    
    `FDep +1 SD, % [95% CI]` =
      fmt_ci(
        couverture_p1SD_pct,
        couverture_p1SD_inf,
        couverture_p1SD_sup,
        2
      ),
    
    `Difference, pp [95% CI]` =
      fmt_ci(
        difference_p1_m1_pp,
        difference_inf_pp,
        difference_sup_pp,
        2
      ),
    
    `Ratio +1 SD / −1 SD [95% CI]` =
      fmt_ratio_ci(
        ratio_p1_m1,
        ratio_inf,
        ratio_sup,
        3
      )
  )
]


FT_T3B_NEW <- flextable::flextable(
  T3B_PRINT_NEW
)


FT_T3B_NEW <- FT_T3B_NEW |>
  flextable::theme_booktabs() |>
  flextable::font(
    fontname = "Arial",
    part = "all"
  ) |>
  flextable::fontsize(
    size = 8,
    part = "all"
  ) |>
  flextable::bold(
    part = "header"
  ) |>
  flextable::align(
    align = "center",
    part = "header"
  ) |>
  flextable::align(
    j = 1:2,
    align = "left",
    part = "body"
  ) |>
  flextable::merge_v(
    j = 1
  ) |>
  flextable::valign(
    j = 1,
    valign = "top"
  ) |>
  flextable::autofit()


FT_T3B_NEW <- flextable::set_caption(
  FT_T3B_NEW,
  caption =
    paste0(
      "B. Adjusted marginal coverage according to municipal deprivation ",
      "and documentary depth, Île-de-France, ",
      ANNEE_REF
    )
)


# ==============================================================================
# 6C. EXPORT SOURCE TABLEAU 3
# ==============================================================================

data.table::fwrite(
  T3A_FINAL_NEW,
  file.path(
    DIR_TABLEAUX_ARTICLE_NEW,
    "ARTICLE_NEW_TABLEAU_3A_SOURCE_FDEP_DESCRIPTIF.csv"
  ),
  sep = ";",
  bom = TRUE
)


data.table::fwrite(
  T3B_FINAL_NEW,
  file.path(
    DIR_TABLEAUX_ARTICLE_NEW,
    "ARTICLE_NEW_TABLEAU_3B_SOURCE_MODELE_AJUSTE.csv"
  ),
  sep = ";",
  bom = TRUE
)


# ==============================================================================
# 6D. DOCUMENT WORD UNIQUE — TABLEAU 3 PANELS A + B
# ==============================================================================

DOC_T3_NEW <- officer::read_docx()


DOC_T3_NEW <- officer::body_add_fpar(
  DOC_T3_NEW,
  officer::fpar(
    officer::ftext(
      paste0(
        "Table 3. Socio-territorial inequalities in coverage according to ",
        "municipal deprivation and documentary depth, ",
        "Île-de-France, ",
        ANNEE_REF
      ),
      officer::fp_text(
        font.family = "Arial",
        font.size = 11,
        bold = TRUE,
        italic = TRUE
      )
    )
  )
)


DOC_T3_NEW <- flextable::body_add_flextable(
  DOC_T3_NEW,
  FT_T3A_NEW
)


DOC_T3_NEW <- officer::body_add_par(
  DOC_T3_NEW,
  ""
)


DOC_T3_NEW <- flextable::body_add_flextable(
  DOC_T3_NEW,
  FT_T3B_NEW
)


DOC_T3_NEW <- officer::body_add_par(
  DOC_T3_NEW,
  ""
)


# ------------------------------------------------------------------------------
# Notes communes du Tableau 3
# ------------------------------------------------------------------------------

NOTES_T3_NEW <- c(
  
  paste0(
    "B: expected test directly documented; C-strict: B supplemented by an ",
    "alternative cervical test explicitly documented as screening or by ",
    "strong cervical-care continuity; C-broad: C-strict supplemented by ",
    "documented cervical pathways that are compatible but less specific."
  ),
  
  paste0(
    "FDep: French Deprivation Index. Q1 corresponds to the least ",
    "deprived municipalities and Q5 to the most deprived municipalities."
  ),
  
  paste0(
    "Panel A — SII: Slope Index of Inequality; RII: Relative Index of ",
    "Inequality. The FDep ridit score was calculated separately within each age ",
    "group and weighted by the municipal population. A negative SII or an ",
    "RII < 1 indicates lower coverage as deprivation increases."
  ),
  
  paste0(
    "Panel B — Estimates are derived from municipal quasi-binomial models ",
    "avec lien logit comprenant le Standardized FDep, le groupe d'âge, leur ",
    "interaction, and department of residence. Marginal coverage estimates ",
    "are presented at −1 and +1 standard deviation (SD) of FDep after standardization ",
    "to the departmental distribution."  ),
  
  paste0(
    "The threshold N ≥ 100 women is used only for cartographic representations ",
    "and is not applied to analyses of the FDep gradient."
  )
)


for (note_i in NOTES_T3_NEW) {
  
  DOC_T3_NEW <- officer::body_add_fpar(
    DOC_T3_NEW,
    officer::fpar(
      officer::ftext(
        note_i,
        officer::fp_text(
          font.family = "Arial",
          font.size = 8
        )
      )
    )
  )
}


DOC_T3_NEW <- officer::body_set_default_section(
  DOC_T3_NEW,
  SECTION_PAYSAGE_NEW
)


print(
  DOC_T3_NEW,
  target =
    file.path(
      DIR_TABLEAUX_ARTICLE_NEW,
      "ARTICLE_NEW_TABLEAU_3_FDEP_DEUX_PANELS_DESCRIPTIF_MODELE.docx"
    )
)


# ==============================================================================
# 7. DOCUMENT UNIQUE DES 3 NOUVEAUX TABLEAUX
# ==============================================================================

DOC_3_TABLEAUX_NEW <- officer::read_docx()


DOC_3_TABLEAUX_NEW <- officer::body_add_par(
  DOC_3_TABLEAUX_NEW,
  "DOCCU Equity — New main article tables",
  style = "heading 1"
)


DOC_3_TABLEAUX_NEW <- officer::body_add_par(
  DOC_3_TABLEAUX_NEW,
  "Table 1",
  style = "heading 2"
)


DOC_3_TABLEAUX_NEW <- flextable::body_add_flextable(
  DOC_3_TABLEAUX_NEW,
  FT_T1_NEW
)


DOC_3_TABLEAUX_NEW <- officer::body_add_break(
  DOC_3_TABLEAUX_NEW
)


DOC_3_TABLEAUX_NEW <- officer::body_add_par(
  DOC_3_TABLEAUX_NEW,
  "Table 2",
  style = "heading 2"
)


DOC_3_TABLEAUX_NEW <- flextable::body_add_flextable(
  DOC_3_TABLEAUX_NEW,
  FT_T2_NEW
)


DOC_3_TABLEAUX_NEW <- officer::body_add_break(
  DOC_3_TABLEAUX_NEW
)


DOC_3_TABLEAUX_NEW <- officer::body_add_par(
  DOC_3_TABLEAUX_NEW,
  "Table 3 — Panel A",
  style = "heading 2"
)


DOC_3_TABLEAUX_NEW <- flextable::body_add_flextable(
  DOC_3_TABLEAUX_NEW,
  FT_T3A_NEW
)


DOC_3_TABLEAUX_NEW <- officer::body_add_par(
  DOC_3_TABLEAUX_NEW,
  "Table 3 — Panel B",
  style = "heading 2"
)


DOC_3_TABLEAUX_NEW <- flextable::body_add_flextable(
  DOC_3_TABLEAUX_NEW,
  FT_T3B_NEW
)


print(
  DOC_3_TABLEAUX_NEW,
  target =
    file.path(
      DIR_TABLEAUX_ARTICLE_NEW,
      "ARTICLE_NEW_TABLEAUX_1_2_3_SOURCE_TRAVAIL.docx"
    )
)


# ==============================================================================
# 8. AFFICHAGE DANS RSTUDIO
# ==============================================================================

FT_T1_NEW
FT_T2_NEW
FT_T3A_NEW
FT_T3B_NEW


# ==============================================================================
# 9. RESUME
# ==============================================================================

cat("\n")
cat("=====================================================================\n")
cat(" NOUVEAUX TABLEAUX ARTICLE PRODUITS — ANCIENS TABLEAUX CONSERVES\n")
cat("=====================================================================\n")

cat(
  "\nTableau 1 :\n",
  file.path(
    DIR_TABLEAUX_ARTICLE_NEW,
    "ARTICLE_NEW_TABLEAU_1_DEPARTEMENTS_PAR_AGE_PROFONDEUR_COMPLETE.docx"
  ),
  "\n",
  sep = ""
)

cat(
  "\nTableau 2 :\n",
  file.path(
    DIR_TABLEAUX_ARTICLE_NEW,
    "ARTICLE_NEW_TABLEAU_2_DEPARTEMENTS_25_65_PROFONDEUR_COMPLETE.docx"
  ),
  "\n",
  sep = ""
)

cat(
  "\nTableau 3 :\n",
  file.path(
    DIR_TABLEAUX_ARTICLE_NEW,
    "ARTICLE_NEW_TABLEAU_3_FDEP_DEUX_PANELS_DESCRIPTIF_MODELE.docx"
  ),
  "\n",
  sep = ""
)

cat("\n=====================================================================\n")



#AJOUT FIGURE

# ==============================================================================
# NOUVELLE FIGURE 1 ARTICLE — 2 PANELS
#
# Panel A : architecture conceptuelle de la profondeur documentaire
# Panel B : effet quantitatif de la profondeur documentaire sur la couverture
#
# IMPORTANT :
# - les figures originales p_fig1 et p_fig2 sont conservées ;
# - aucun fichier existant n'est écrasé ;
# - aucune donnée n'est recalculée ;
# - cette figure est uniquement un assemblage éditorial.
# ==============================================================================


# ==============================================================================
# 1. REPERTOIRE SPECIFIQUE
# ==============================================================================

DIR_FIGURES_ARTICLE_NEW <- file.path(
  DIR_FIGURES,
  "ARTICLE_FINAL_NEW"
)

dir.create(
  DIR_FIGURES_ARTICLE_NEW,
  recursive = TRUE,
  showWarnings = FALSE
)


# ==============================================================================
# 2. PANEL A — ARCHITECTURE CONCEPTUELLE
# ==============================================================================

PANEL_A_FIG1_NEW <- (
  patchwork::wrap_elements(
    full = p_fig1
  )
) +
  patchwork::plot_annotation(
    title =
      "A. Construction of the coverage measure according to documentary depth",
    theme =
      ggplot2::theme(
        plot.title =
          ggplot2::element_text(
            face = "bold",
            size = 13,
            hjust = 0,
            margin = ggplot2::margin(
              b = 8
            )
          )
      )
  )



# ==============================================================================
# 3. PANEL B — COUVERTURE MESUREE
#
# IMPORTANT :
# - on n'ajoute PAS labs(title=...) directement à p_fig2
# - on encapsule p_fig2 comme un élément graphique complet
# - le titre du panel est porté par plot_annotation()
# ==============================================================================

PANEL_B_FIG1_NEW <- (
  patchwork::wrap_elements(
    full = p_fig2
  )
) +
  patchwork::plot_annotation(
    title =
      "B. Measured coverage according to documentary depth and age group",
    subtitle =NULL,
      # "Values between adjacent levels indicate the absolute gain in coverage",
    theme =
      ggplot2::theme(
        plot.title =
          ggplot2::element_text(
            face = "bold",
            size = 13,
            hjust = 0,
            margin = ggplot2::margin(
              b = 3
            )
          ),
        plot.subtitle =
          ggplot2::element_text(
            size = 10.5,
            hjust = 0,
            margin = ggplot2::margin(
              b = 8
            )
          )
      )
  )
# ==============================================================================
# 4. ASSEMBLAGE DE LA NOUVELLE FIGURE 1
#
# Le panel A est volontairement moins haut :
# il s'agit d'un schéma horizontal.
#
# Le panel B reçoit davantage d'espace pour préserver :
# - les axes ;
# - les pourcentages ;
# - les gains en points ;
# - les deux groupes d'âge.
# ==============================================================================
# ==============================================================================
# 4. ASSEMBLAGE DE LA NOUVELLE FIGURE 1
# ==============================================================================

FIGURE_1_NEW <- (
  PANEL_A_FIG1_NEW /
    PANEL_B_FIG1_NEW
) +
  patchwork::plot_layout(
    heights = c(
      0.78,
      1.22
    )
  ) +
  patchwork::plot_annotation(
    title =
      "Documentary depth of cervical cancer screening coverage measurement",
    subtitle =
      paste0(
        "Architecture of documentary ascertainment and consequences for coverage estimates — Île-de-France, ",
        ANNEE_REF
      ),
    theme =
      ggplot2::theme(
        plot.title =
          ggplot2::element_text(
            face = "bold",
            size = 16,
            hjust = 0
          ),
        plot.subtitle =
          ggplot2::element_text(
            size = 11,
            hjust = 0,
            margin = ggplot2::margin(
              b = 10
            )
          ),
        plot.background =
          ggplot2::element_rect(
            fill = "white",
            colour = NA
          ),
        plot.margin =
          ggplot2::margin(
            8,
            8,
            8,
            8
          )
      )
  )
# ==============================================================================
# 5. AFFICHAGE
# ==============================================================================

FIGURE_1_NEW


# ==============================================================================
# 6. EXPORT PNG
# ==============================================================================

ggplot2::ggsave(
  
  filename =
    file.path(
      DIR_FIGURES_ARTICLE_NEW,
      "ARTICLE_NEW_FIGURE_1_PROFONDEUR_DOCUMENTAIRE_2_PANELS.png"
    ),
  
  plot =
    FIGURE_1_NEW,
  
  width =
    14.5,
  
  height =
    14.4,
  
  units =
    "in",
  
  dpi =
    320,
  
  bg =
    "white"
)


# ==============================================================================
# 7. EXPORT TIFF — VERSION PUBLICATION
# ==============================================================================

ggplot2::ggsave(
  
  filename =
    file.path(
      DIR_FIGURES_ARTICLE_NEW,
      "ARTICLE_NEW_FIGURE_1_PROFONDEUR_DOCUMENTAIRE_2_PANELS.tiff"
    ),
  
  plot =
    FIGURE_1_NEW,
  
  width =
    14.5,
  
  height =
    11.4,
  
  units =
    "in",
  
  dpi =
    320,
  
  compression =
    "lzw",
  
  bg =
    "white"
)


# ==============================================================================
# 8. EXPORT PDF VECTORIEL
# ==============================================================================

ggplot2::ggsave(
  
  filename =
    file.path(
      DIR_FIGURES_ARTICLE_NEW,
      "ARTICLE_NEW_FIGURE_1_PROFONDEUR_DOCUMENTAIRE_2_PANELS.pdf"
    ),
  
  plot =
    FIGURE_1_NEW,
  
  width =
    13.5,
  
  height =
    11.7,
  
  units =
    "in",
  
  device =
    cairo_pdf,
  
  bg =
    "white"
)


# ==============================================================================
# 9. LEGENDE POUR LE MANUSCRIT
# ==============================================================================

LEGENDE_FIGURE_1_NEW <- paste0(
  
  "Figure 1. Documentary depth of cervical cancer screening coverage measurement, Île-de-France, ",
  ANNEE_REF,
  ". ",
  
  "Panel A: hierarchical architecture of documentary ascertainment. ",
  "A-CCAM identifies the expected test using only the retained CCAM codes; ",
  "A extends ascertainment to the full set of reference codes; ",
  "B corresponds to the same expected test directly documented, irrespective ",
  "of the documentary pathway. C-strict and C-broad then extend the analysis ",
  "to documented cervical-care continuity and constitute sensitivity analyses ",
  "rather than estimates of guideline-concordant coverage. ",
  
  "Panel B: proportion of women classified as covered at each of the five documentary ",
  "levels, separately for women aged 25–29 years and 30–65 years. ",
  "Values placed between adjacent levels indicate the absolute gain in percentage ",
  "points."
)


cat(
  "\n",
  LEGENDE_FIGURE_1_NEW,
  "\n"
)


writeLines(
  
  LEGENDE_FIGURE_1_NEW,
  
  file.path(
    DIR_FIGURES_ARTICLE_NEW,
    "ARTICLE_NEW_FIGURE_1_LEGENDE.txt"
  ),
  
  useBytes =
    TRUE
)


cat("\n")
cat("=====================================================================\n")
cat(" NOUVELLE FIGURE 1 — 2 PANELS PRODUITE\n")
cat("=====================================================================\n")

cat(
  file.path(
    DIR_FIGURES_ARTICLE_NEW,
    "ARTICLE_NEW_FIGURE_1_PROFONDEUR_DOCUMENTAIRE_2_PANELS.png"
  ),
  "\n"
)

cat("=====================================================================\n")