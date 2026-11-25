# Documentary depth and cervical cancer screening coverage in Île-de-France

This repository contains the analytical production code accompanying the study on **documentary depth, latent coverage and socio-territorial inequalities in cervical cancer screening coverage in Île-de-France**.

## Documentary hierarchy

- **A-CCAM**: age-appropriate expected test identified using the retained CCAM codes only.
- **A**: age-appropriate expected test identified using the full set of retained reference codes.
- **B**: the same expected test directly documented within the appropriate screening interval, irrespective of the documentary pathway.
- **C-strict**: B supplemented by an alternative cervical test explicitly documented as screening or by strong documentary evidence of cervical-care continuity.
- **C-broad**: C-strict supplemented by compatible but less specific documented cervical pathways.

C-strict and C-broad are **documentary sensitivity analyses** and should not be interpreted as alternative estimates of guideline-concordant screening coverage.

## Study population and screening windows

The reference population comprises women aged 25–65 years living in Île-de-France at 31 December 2025.

- **25–29 years**: expected test = cytology performed between 1 January 2023 and 31 December 2025.
- **30–65 years**: expected test = HPV test performed between 1 January 2021 and 31 December 2025.

## Repository structure

```text
.
├── R/
│   └── 04_production_results.R
├── data/
│   └── README.md
├── docs/
├── .gitignore
├── CITATION.cff
├── LICENSE
└── README.md
```

## Data availability and confidentiality

Individual-level E-SIS data are **not publicly available** because they contain sensitive health information and are subject to applicable data-protection and governance requirements. The repository does not contain patient-level records, identifiers, dates of individual screening events, or derived caches based on individual-level data.

## Required intermediate objects

The production script expects validated `.rds` intermediate objects. These are not distributed publicly. The script does not rerun analytical QC, statistical testing or model estimation; it produces publication outputs from validated final intermediate objects.

## Configuration

```r
Sys.setenv(
  DOCCU_ROOT_DERE = "PATH_TO_AUTHORISED_PROJECT_ROOT",
  DOCCU_OUT_PRODUCTION = "PATH_TO_OUTPUT_DIRECTORY",
  DOCCU_COMMUNES_SHP = "PATH_TO_IDF_COMMUNES_SHAPEFILE"
)
```

## Reproducibility

The public code documents the analytical definitions and production logic used for the article. Full numerical reproduction requires authorised access to the underlying E-SIS data and validated intermediate objects generated in the secure analysis environment.

## Software

The workflow is implemented in **R** and uses, among others, `data.table`, `dplyr`, `ggplot2`, `sf`, `flextable`, `officer`, `patchwork`, `scales` and `janitor`.

## Citation

Please cite the associated article and the archived software release. A machine-readable citation file is provided in `CITATION.cff`.

## Licence

Code is released under the **MIT License**. This licence applies to the source code only and does not grant access to, or rights over, the underlying health data.

## Contact

Pôle Data, Étude, Recherche et Évaluation (DERE)  
CRCDC Île-de-France
