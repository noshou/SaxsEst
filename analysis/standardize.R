#!/usr/bin/env Rscript

suppressPackageStartupMessages({
    library(readr)
    library(stringr)
})

# concatenates dataset and outputs normalized and un-normalized data
main <- function() {
    
    normalize <- function(x) {
        (x - min(x)) / (max(x) - min(x))
    }


    # get cli args for files, load into dataframe
    # NOTE: first arg assumed to be output directory, 
    # second arg assumed to be control (debye_radial)
    args <- commandArgs(trailingOnly = TRUE)
    if (length(args) < 3) {
        stop("Usage: standardized.R cntrl.csv file2.csv ...")
    }

    # initialize df as control, standardize first col
    df      <- read_csv(args[2], show_col_types = FALSE)
    df_og   <- df
    name    <- tools::file_path_sans_ext(basename(args[2]))
    names(df_og)[2] <- name
    names(df)[2]    <- name
    df[[2]] <- normalize(df[[2]])

    # loop through rest, add to df, calculate RMSE
    for (i in 3:length(args)) {
        
        # populate dataframes
        name <- tools::file_path_sans_ext(basename(args[i]))
        temp <- read_csv(args[i], show_col_types = FALSE)[[2]]
        if (length(temp) != nrow(df)) {stop(paste("Length mismatch in", args[i]))}
        df[name]    <- normalize(temp)
        df_og[name] <- temp

        # calculate RMSE
        rmse <- sqrt(sum((df[[name]]-df[[2]])^2) / nrow(df))
        cat("RMSE for ", name, ": ", rmse, "\n")
    }

    # write dataframes to csv
    base <- sub("^[^_]+_[^_]+_(.+)\\.csv", "\\1", basename(args[2]))
    ext1 <- "_normalized.csv"
    ext2 <- "_raw.csv" 
    nme1 <- paste0(base, ext1)
    nme2 <- paste0(base, ext2)
    path1 <- file.path(args[1], nme1)
    path2 <- file.path(args[1], nme2)
    write_csv(df,   path1)
    write_csv(df_og,path2)
    cat("raw analysis saved at:        ", path2, "\n")
    cat("normalized analysis saved at: ", path1, "\n")
    # clean unused files
    for (i in 2:length(args)) {
        unlink(args[i])
    }

}

main()