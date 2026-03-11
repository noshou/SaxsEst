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
  library(tools)
})

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 5) {
    stop("Usage: CsvCombine.R output_dir molecule_name <debye>.csv <other files>.csv")
  }

  # extract name of molecule, output dir
  mol <- args[2]
  dir <- args[1]


  # load csv files
  dfDeby <- read_csv(args[3], show_col_types = FALSE)
  listDf <- list()
  listName <- list()
  for (i in 4:length(args)) {
    listDf   <- append(listDf,   list(read_csv(args[i], show_col_types = FALSE)))
    listName <- append(listName, basename(tools::file_path_sans_ext(args[i])))
  }

  # combine into single df
  dfData <- tibble(
    q_inverse_angstroms = dfDeby$q_inv_angstrom,
    debye               = dfDeby$intensity,
  )
  for (i in seq_along(listDf)) {
    dfData <- dfData %>% add_column( 
      !!listName[[i]] := listDf[[i]][[2]], 
      !!paste0(listName[[i]], "_relDiffDebye") := ((abs(dfData$debye - listDf[[i]][[2]])) / dfData$debye) * 100,
      .after = "debye"
    )
}


  path <- file.path(dir, paste0("analysis_", mol, ".csv"))
  write_csv(dfData, path)
  cat("raw analysis saved at:", path, "\n")

  # cleanup individual CSVs
  for (i in 3:length(args)) {
    unlink(args[i])
  }
}

main()
