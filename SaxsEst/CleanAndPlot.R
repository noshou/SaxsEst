#!/usr/bin/env Rscript

#' CleanAndPlot.R
#'
#' Reads analysis_*.csv files from SaxsEst, accumulates intensity
#' estimates and pairwise absolute differences, then produces
#' PDF plots sized for IEEE two-column figures.
#'
#' Usage:
#'   Rscript CleanAndPlot.R <input_dir> <epsilon> <sample_size>

suppressPackageStartupMessages({
  library(readr)
  library(tibble)
  library(dplyr)      
  library(tidyr)      
  library(stringr)    
  library(ggplot2)
})

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 3) {
    stop("Usage: CleanAndPlot.R input_dir epsilon sample_size")
  }

  setwd(args[1])

  csvFiles <- list.files(pattern = "\\.csv$")

  # Initialise tibbles with the shared q column
  qCol  <- read_csv(csvFiles[1], show_col_types = FALSE) %>% pull(q_inverse_angstroms)
  dfInt <- tibble(q_inverse_angstroms = qCol)
  dfDif <- tibble(q_inverse_angstroms = qCol)

  # Regex to extract molecule name from "analysis_<name>.csv"
  startString <- "analysis_"
  endString   <- "\\.csv"
  regexPat    <- paste0("^.*", startString, "(.*?)", endString, ".*$")
  namesList   <- c()

  # Loop through csv files, accumulate into dataframes
  for (csvFile in csvFiles) {
    molName   <- gsub(regexPat, "\\1", csvFile)
    namesList <- c(namesList, molName)

    dfCsvF <- read_csv(csvFile, show_col_types = FALSE)
    dfInt  <- dfInt %>% add_column(
      !!paste0("debye_", molName) := dfCsvF$intensity_debye,
      !!paste0("strat_", molName) := dfCsvF$intensity_strat,
      !!paste0("prop_", molName)  := dfCsvF$intensity_prop,
      .after = "q_inverse_angstroms"
    )
    dfDif <- dfDif %>% add_column(
      !!paste0("|debye-strat|_", molName) := abs(dfCsvF$diff_strat_debye),
      !!paste0("|debye-prop|_", molName)  := abs(dfCsvF$diff_prop_debye),
      !!paste0("|prop-strat|_", molName)  := abs(dfCsvF$diff_prop_strat),
      .after = "q_inverse_angstroms"
    )
  }

  epsilonValue <- args[2]
  sampleSize   <- args[3]

  # |debye-strat| plot
  plotDifDebStr <-
  dfDif %>%
  select(q_inverse_angstroms, contains("|debye-strat|")) %>%
  pivot_longer(-q_inverse_angstroms, names_to = "molecule", values_to = "diff") %>%
  mutate(molecule = str_remove(molecule, fixed("|debye-strat|_"))) %>%
  ggplot(aes(x = q_inverse_angstroms, y = diff, color = molecule)) +
  geom_line() +
  geom_point(size = 0.5) +
  scale_y_continuous(n.breaks = 10) + 
  scale_x_continuous(breaks = sort(unique(dfDif$q_inverse_angstroms))) +
  labs(
    title = paste0("  epsilon = ", epsilonValue, ";   sample size = ", sampleSize),
    x     = "Q (1/Å)",
    y     = "|I_debye - I_strat|",
    color = "Molecule"
  ) +
  theme(
    text = element_text(size = 4),
    legend.key.size = unit(2, "mm"),
    legend.text = element_text(size = 3),
    legend.position = c(.95, .95),
    legend.title = element_blank()
  )
  ggsave("difDebyeStrat.pdf", plot = plotDifDebStr, width = 3.5, height = 2.5)

  # |debye-prop| plot
  plotDifDebProp <-
  dfDif %>%
  select(q_inverse_angstroms, contains("|debye-prop|")) %>%
  pivot_longer(-q_inverse_angstroms, names_to = "molecule", values_to = "diff") %>%
  mutate(molecule = str_remove(molecule, fixed("|debye-prop|_"))) %>%
  ggplot(aes(x = q_inverse_angstroms, y = diff, color = molecule)) +
  geom_line() +
  geom_point(size = 0.5) +
  scale_y_continuous(n.breaks = 10) + 
  scale_x_continuous(breaks = sort(unique(dfDif$q_inverse_angstroms))) +
  labs(
    title = paste0("  epsilon = ", epsilonValue, ";   sample size = ", sampleSize),
    x     = "Q (1/Å)",
    y     = "|I_debye - I_prop|",
    color = "Molecule"
  ) +
  theme(
    text = element_text(size = 4),
    legend.key.size = unit(2, "mm"),
    legend.text = element_text(size = 3),
    legend.position = c(.95, .95),
    legend.title = element_blank()
  )
  ggsave("difDebyeProp.pdf", plot = plotDifDebProp, width = 3.5, height = 2.5)

  # |prop-strat| plot
  plotDifPropStrat <-
  dfDif %>%
  select(q_inverse_angstroms, contains("|prop-strat|")) %>%
  pivot_longer(-q_inverse_angstroms, names_to = "molecule", values_to = "diff") %>%
  mutate(molecule = str_remove(molecule, fixed("|prop-strat|_"))) %>%
  ggplot(aes(x = q_inverse_angstroms, y = diff, color = molecule)) +
  geom_line() +
  geom_point(size = 0.5) +
  scale_y_continuous(n.breaks = 10) + 
  scale_x_continuous(breaks = sort(unique(dfDif$q_inverse_angstroms))) +
  labs(
    title = paste0("  epsilon = ", epsilonValue, ";   sample size = ", sampleSize),
    x     = "Q (1/Å)",
    y     = "|I_prop - I_strat|",
    color = "Molecule"
  ) +
  theme(
    text = element_text(size = 4),
    legend.key.size = unit(2, "mm"),
    legend.text = element_text(size = 3),
    legend.position = c(.95, .95),
    legend.title = element_blank()
  )
  ggsave("difPropStrat.pdf", plot = plotDifPropStrat, width = 3.5, height = 2.5)

  # Per-molecule: overlay debye, strat, prop estimates
  for (name in namesList) {
    plotEst <-
    dfInt %>%
    select(q_inverse_angstroms, matches(paste0("(debye|strat|prop)_", name))) %>%
    pivot_longer(-q_inverse_angstroms, names_to = "method", values_to = "int") %>%
    mutate(method = str_remove(method, paste0("_", name))) %>%
    ggplot(aes(x = q_inverse_angstroms, y = int, color = method)) +
    geom_line() +
    geom_point(size = 0.5) +
    scale_y_continuous(n.breaks = 10) + 
    scale_x_continuous(breaks = sort(unique(dfDif$q_inverse_angstroms))) +
    labs(
      title = paste0("molecule: ", name, ";   epsilon = ", epsilonValue, ";   sample size = ", sampleSize),
      x     = "Q (1/Å)",
      y     = "I(Q)",
      color = "Method"
    ) +
  theme(
    text = element_text(size = 4),
    legend.key.size = unit(2, "mm"),
    legend.text = element_text(size = 3),
    legend.position = c(.95, .95),
    legend.title = element_blank()
  )
  ggsave(paste0(name, "Intensity.pdf"), plot = plotEst, width = 3.5, height = 2.5)
  }
}

main()