#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(readr)
  library(tibble)
  library(stringr)
})

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 5) {
    stop("Usage: CsvCombine.R output_dir molecule_name <debye>.csv <strat>.csv <propo>.csv]")
  }

  # extract name of molecule, output dir
  mol <- args[2]
  dir <- args[1]

  # load csv data into data frames
  df_deby <- read_csv(args[3], show_col_types = FALSE)
  df_strt <- read_csv(args[4], show_col_types = FALSE)
  df_prop <- read_csv(args[5], show_col_types = FALSE)

  # combine into single df
  df <- tibble(
    q_inverse_angstroms = df_deby$q_inv_angstrom,
    intensity_debye     = df_deby$intensity,
    intensity_strat     = df_strt$intensity,
    intensity_prop      = df_prop$intensity,
    diff_strat_debye    = df_deby$intensity - df_strt$intensity,
    diff_prop_debye     = df_deby$intensity - df_prop$intensity,
    diff_prop_strat     = df_prop$intensity - df_strt$intensity
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