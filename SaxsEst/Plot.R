#!/usr/bin/env Rscript

#' Plot.R
#'
#' Reads analysis_*.csv files produced by CsvCombine.R, then generates:
#'   Per molecule:
#'     - strat diffs:     |I_debye - I_strat| for each s value
#'     - propo diffs:     |I_debye - I_propo| for each epsilon value
#'     - intensity overlay: debye (bold) vs all strat vs all propo
#'   Cross molecule:
#'     - one plot per epsilon: |I_debye - I_propo| across all molecules
#'     - one plot per s:       |I_debye - I_strat| across all molecules
#'
#' Usage:
#'   Rscript Plot.R <input_dir>

suppressPackageStartupMessages({
  library(readr)
  library(tibble)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
  library(scales)
})

# IEEE two-column figure theme
ieee_theme <- theme(
  text             = element_text(size = 4),
  legend.key.size  = unit(2, "mm"),
  legend.text      = element_text(size = 3),
  legend.position  = c(.95, .95),
  legend.title     = element_blank()
)

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1) {
    stop("Usage: Plot.R input_dir")
  }
  setwd(args[1])

  csvFiles <- list.files(pattern = "^analysis_.*\\.csv$")
  if (length(csvFiles) == 0) stop("No analysis_*.csv files found.")

  regexMol <- "^analysis_(.*)\\.csv$"

  # Accumulators for cross-molecule plots
  crossStrat <- list()
  crossPropo <- list()

  for (csvFile in csvFiles) {
    molName <- gsub(regexMol, "\\1", csvFile)
    df      <- read_csv(csvFile, show_col_types = FALSE)
    q       <- df$q_inverse_angstroms

    # Identify estimate and diff columns by prefix
    stratCols     <-  grep("^strat\\(",     colnames(df), value = TRUE) %>%
                      grep("_diffDebye$", ., value = TRUE, invert = TRUE)
    propoCols     <-  grep("^propo\\(",     colnames(df), value = TRUE) %>%
                      grep("_diffDebye$", ., value = TRUE, invert = TRUE)
    stratDiffCols <-  grep("^strat\\(.*_diffDebye$", colnames(df), value = TRUE)
    propoDiffCols <-  grep("^propo\\(.*_diffDebye$", colnames(df), value = TRUE)

    # ── Per-molecule: strat diffs ──────────────────────────────────
    dfStratDif <- tibble(q_inverse_angstroms = q)
    for (col in stratDiffCols) {
      sVal       <- str_extract(col, "(?<=s=)[0-9.]+")
      dfStratDif <- dfStratDif %>%
        add_column(!!paste0("s=", sVal) := abs(df[[col]]))
    }

    plotStratDif <- dfStratDif %>%
      pivot_longer(-q_inverse_angstroms,
                  names_to = "s", values_to = "diff") %>%
      ggplot(aes(x = q_inverse_angstroms, y = diff, color = s)) +
      geom_line() +
      geom_point(size = 0.5) +
      scale_y_continuous(n.breaks = 10) +
      scale_x_continuous(breaks = sort(unique(q))) +
      labs(
        title = molName,
        x     = "Q (1/\u00C5)",
        y     = "|I_debye - I_strat|",
        color = "s"
      ) + ieee_theme
    ggsave(paste0(molName, "_difDebyeStrat.pdf"),
          plot = plotStratDif, width = 3.5, height = 2.5)

    # ── Per-molecule: propo diffs ──────────────────────────────────
    dfPropoDif <- tibble(q_inverse_angstroms = q)
    for (col in propoDiffCols) {
      eVal       <- str_extract(col, "(?<=e=)[0-9.]+")
      dfPropoDif <- dfPropoDif %>%
        add_column(!!paste0("e=", eVal) := abs(df[[col]]))
    }

    plotPropoDif <- dfPropoDif %>%
      pivot_longer(-q_inverse_angstroms,
                  names_to = "epsilon", values_to = "diff") %>%
      ggplot(aes(x = q_inverse_angstroms, y = diff, color = epsilon)) +
      geom_line() +
      geom_point(size = 0.5) +
      scale_y_continuous(n.breaks = 10) +
      scale_x_continuous(breaks = sort(unique(q))) +
      labs(
        title = molName,
        x     = "Q (1/\u00C5)",
        y     = "|I_debye - I_propo|",
        color = "epsilon"
      ) + ieee_theme
    ggsave(paste0(molName, "_difDebyePropo.pdf"),
          plot = plotPropoDif, width = 3.5, height = 2.5)

    # ── Per-molecule: intensity overlay ────────────────────────────
    dfOverlay <- tibble(q_inverse_angstroms = q, debye = df$debye)
    for (col in stratCols) {
      sVal      <- str_extract(col, "(?<=s=)[0-9.]+")
      dfOverlay <- dfOverlay %>%
        add_column(!!paste0("strat(s=", sVal, ")") := df[[col]])
    }
    for (col in propoCols) {
      eVal      <- str_extract(col, "(?<=e=)[0-9.]+")
      dfOverlay <- dfOverlay %>%
        add_column(!!paste0("propo(e=", eVal, ")") := df[[col]])
    }

    dfLong  <- dfOverlay %>%
      pivot_longer(-q_inverse_angstroms,
                  names_to = "method", values_to = "intensity")
    methods <- unique(dfLong$method)
    nStrat  <- length(stratCols)
    nPropo  <- length(propoCols)

    stratColors <- seq_gradient_pal("steelblue1", "navy")(
      seq(0, 1, length.out = max(nStrat, 1)))
    propoColors <- seq_gradient_pal("salmon", "darkred")(
      seq(0, 1, length.out = max(nPropo, 1)))

    colorMap <- setNames(
      c("black", stratColors, propoColors),
      c("debye",
        paste0("strat(s=", str_extract(stratCols, "(?<=s=)[0-9.]+"), ")"),
        paste0("propo(e=", str_extract(propoCols, "(?<=e=)[0-9.]+"), ")"))
    )
    sizeMap <- setNames(
      c(1.0, rep(0.3, nStrat + nPropo)),
      names(colorMap)
    )

    plotOverlay <- dfLong %>%
      ggplot(aes(x = q_inverse_angstroms, y = intensity,
                color = method, linewidth = method)) +
      geom_line() +
      geom_point(size = 0.5) +
      scale_color_manual(values = colorMap) +
      scale_linewidth_manual(values = sizeMap, guide = "none") +
      scale_y_continuous(n.breaks = 10) +
      scale_x_continuous(breaks = sort(unique(q))) +
      labs(
        title = molName,
        x     = "Q (1/\u00C5)",
        y     = "I(Q)",
        color = "Method"
      ) + ieee_theme
    ggsave(paste0(molName, "_intensity.pdf"),
          plot = plotOverlay, width = 3.5, height = 2.5)

    # ── Accumulate for cross-molecule plots ────────────────────────
    for (col in stratDiffCols) {
      sVal  <- str_extract(col, "(?<=s=)[0-9.]+")
      entry <- tibble(q_inverse_angstroms = q,
                      diff = abs(df[[col]]), molecule = molName)
      crossStrat[[sVal]] <- bind_rows(crossStrat[[sVal]], entry)
    }
    for (col in propoDiffCols) {
      eVal  <- str_extract(col, "(?<=e=)[0-9.]+")
      entry <- tibble(q_inverse_angstroms = q,
                      diff = abs(df[[col]]), molecule = molName)
      crossPropo[[eVal]] <- bind_rows(crossPropo[[eVal]], entry)
    }
  }

  # ── Cross-molecule: one plot per epsilon ───────────────────────
  for (eVal in names(crossPropo)) {
    p <- crossPropo[[eVal]] %>%
      ggplot(aes(x = q_inverse_angstroms, y = diff, color = molecule)) +
      geom_line() +
      geom_point(size = 0.5) +
      scale_y_continuous(n.breaks = 10) +
      labs(
        title = paste0("epsilon = ", eVal),
        x     = "Q (1/\u00C5)",
        y     = "|I_debye - I_propo|",
        color = "Molecule"
      ) + ieee_theme
    ggsave(paste0("crossMol_propo_e", eVal, ".pdf"),
          plot = p, width = 3.5, height = 2.5)
  }

  # ── Cross-molecule: one plot per s ─────────────────────────────
  for (sVal in names(crossStrat)) {
    p <- crossStrat[[sVal]] %>%
      ggplot(aes(x = q_inverse_angstroms, y = diff, color = molecule)) +
      geom_line() +
      geom_point(size = 0.5) +
      scale_y_continuous(n.breaks = 10) +
      labs(
        title = paste0("s = ", sVal),
        x     = "Q (1/\u00C5)",
        y     = "|I_debye - I_strat|",
        color = "Molecule"
      ) + ieee_theme
    ggsave(paste0("crossMol_strat_s", sVal, ".pdf"),
          plot = p, width = 3.5, height = 2.5)
  }
}

main()