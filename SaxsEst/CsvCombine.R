#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(readr)
  library(tibble)
  library(stringr)
})

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 4) {
    stop("Usage: CsvCombine.R output_dir molecule_name <debye_est>.csv <prop_est>.csv")
  }

  # extract name of molecule, output dir
  mol <- args[2]
  dir <- args[1]

  # load csv data into data frames
  df_deby <- read_csv(args[3], show_col_types = FALSE)
  df_prop <- read_csv(args[4], show_col_types = FALSE)

  # combine into single df
  df <- tibble(
    q_inverse_angstroms = df_deby$q_inv_angstrom,
    intensity_debye     = df_deby$intensity,
    intensity_prop      = df_prop$intensity,
    intensity_diff      = df_deby$intensity - df_prop$intensity,
    weight_debye        = df_deby$weights,
    weight_prop         = df_prop$weights
  )

  path <- file.path(dir, paste0("analysis_", mol, ".csv"))
  write_csv(df, path)
  cat("raw analysis saved at:", path, "\n")
  unlink(args[3])
  unlink(args[4])
}

main()
