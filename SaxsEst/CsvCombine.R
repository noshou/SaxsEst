#!/usr/bin/env Rscript

#' CsvCombine.R
#'
#' Combines three SaxsEst output CSVs (Debye, stratified, proportional)
#' for a single molecule into one analysis CSV with intensities and
#' pairwise differences. Deletes the individual CSVs after combining.
#'
#' Usage:
#'   Rscript CsvCombine.R <output_dir> <molecule_name> <debye>.csv <strat>.csv <prop>.csv
#'
#' Arguments:
#'   output_dir    — directory to write the combined analysis CSV
#'   molecule_name — name of the molecule (used in output filename)
#'   <debye>.csv   — CSV with Debye intensity estimates
#'   <strat>.csv   — CSV with stratified importance-sampling estimates
#'   <prop>.csv    — CSV with proportional estimates
#'
#' Output:
#'   analysis_<molecule_name>.csv containing columns:
#'     q_inverse_angstroms, intensity_debye, intensity_strat, intensity_prop,
#'     diff_strat_debye, diff_prop_debye, diff_prop_strat

suppressPackageStartupMessages({
  library(readr)
  library(tibble)
  library(stringr)
  library(ggplot2)
})

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 5) {
    stop("Usage: CsvCombine.R output_dir molecule_name <debye>.csv <strat>.csv <prop>.csv")
  }

  # extract name of molecule, output dir
  mol <- args[2]
  dir <- args[1]

  # load csv data into data frames
  dfDeby <- read_csv(args[3], show_col_types = FALSE)
  dfStrt <- read_csv(args[4], show_col_types = FALSE)
  dfProp <- read_csv(args[5], show_col_types = FALSE)

  # combine into single df
  df <- tibble(
    q_inverse_angstroms = dfDeby$q_inv_angstrom,
    intensity_debye     = dfDeby$intensity,
    intensity_strat     = dfStrt$intensity,
    intensity_prop      = dfProp$intensity,
    diff_strat_debye    = dfDeby$intensity - dfStrt$intensity,
    diff_prop_debye     = dfDeby$intensity - dfProp$intensity,
    diff_prop_strat     = dfProp$intensity - dfStrt$intensity
  )

  path <- file.path(dir, paste0("analysis_", mol, ".csv"))
  write_csv(df, path)
  cat("raw analysis saved at:", path, "\n")

  # cleanup individual CSVs
  unlink(args[3])
  unlink(args[4])
  unlink(args[5])
}

main()