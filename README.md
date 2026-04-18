# SaxsEst

> **Status:** Not fully validated. Use for research and experimentation.
> See `theory.pdf` for detailed background theory and motivations.

SaxsEst is a high-performance Fortran codebase for estimating Small Angle X-ray Scattering (SAXS) intensity profiles from atomic coordinate files (XYZ). It implements three estimators for the Debye equation:

- **debyeEst** — exact O(N²) pairwise computation exploiting symmetry
- **propoEst** — constant-factor approximation of the atomic weight factor, based on the PropEstimator algorithm of Beretta & Tetek (2022)
- **stratEst** — stratified importance sampling with Hansen–Hurwitz correction, partitioning atoms into heavy/light strata by scattering weight

Both `propoEst` and `stratEst` treat I(q) as a purely computational object rather than a physical/geometric one.

## Requirements

- Fortran 90+ compiler (gfortran recommended)
- GNU Make
- OCaml runtime (for the Fortran ↔ CSV bridge in `CsvInterface/`)
- R with `ggplot2` (for the analysis pipeline in `Analysis/`)
- Standard POSIX utilities (bash, coreutils)

## Build & Run

This evaluates all `.xyz` files in `AtomXYZ/data/` and generates a report:

```
./saxsEst.sh [--debug] [--help]
```

## Outputs

- CSV files with Q vs I(Q) for each estimator
- Timing statistics
- Analysis logs and plots in `Analysis/`

## Project Layout

```
SaxsEst/       CLI and top-level program
Est/            Estimators and sampling code (Est.f90 + inc/*.inc)
FormFact/       Atomic form factors and anomalous scattering data
Freq/           Frequency/CDF construction for stratification
AtomXYZ/        Coordinate types, distance utilities, benchmark .xyz files
CsvInterface/   Fortran ↔ OCaml CSV bridge
Analysis/       R scripts (CsvCombine.R, Plot.R), saved logs and plots
docs/           theory.pdf and planned documentation
pdb_to_xyz/     PDB → XYZ conversion scripts (legacy, WIP)
```

## Configuring stratEst

`stratEst` has two orthogonal toggles, both controlled via commented blocks in `Est/inc/stratEst.inc`.

### Toggle A — Sample-once vs. resample-per-q

By default, stratEst samples atoms once using q(1) and reuses the same drawn set for all q values. To resample (rebuild the CDF and redraw) for each q independently:

1. Comment out lines 355–358
2. Uncomment lines 360–362, 371, and 372

### Toggle B — Allocation strategy

Seven strategies control how the sample budget is split between the heavy and light strata. Let h, l = heavy/light strata; a ∈ (0,1) = sampling fraction; budget = ⌈a × totalPopulation⌉.

To switch strategies, ensure lines 123–237 are fully commented out, then uncomment the block for your chosen strategy:

#### i. Neyman Allocation — NA (lines 123–148)

Allocates proportional to σ × N per stratum, clamped to [lowerBound, upperBound − lowerBound]:

```
upperBound   = ⌈totalPopulation × a⌉
lowerBound   = 2
denominator  = heavy.stdev × heavy.population + light.stdev × light.population
heavySamples = min(max(⌈heavy.stdev × heavy.population × upperBound / denominator⌉, lowerBound), upperBound − lowerBound)
lightSamples = min(max(⌈light.stdev × light.population × upperBound / denominator⌉, lowerBound), upperBound − lowerBound)
totalSamples = heavySamples + lightSamples
```

Note: both strata are independently clamped and ceiled, so `totalSamples` may not equal `upperBound`.

#### ii. Proportional Allocation — PA (lines 154–161)

Each stratum is ceiled independently (no global budget constraint):

```
heavySamples = ⌈heavy.population × a⌉
lightSamples = ⌈light.population × a⌉
totalSamples = heavySamples + lightSamples
```

#### iii. Heavy-Rounded Proportional Allocation — HrPA (lines 167–173)

Rounds the heavy stratum; light gets the remainder:

```
totalSamples = ⌈a × totalPopulation⌉
heavySamples = ⌈a × heavy.population⌉
lightSamples = totalSamples − heavySamples
```

#### iv. Light-Rounded Proportional Allocation — LrPA (lines 179–185)

Rounds the light stratum; heavy gets the remainder:

```
totalSamples = ⌈a × totalPopulation⌉
lightSamples = ⌈a × light.population⌉
heavySamples = totalSamples − lightSamples
```

#### v. Mean-Weighted Allocation — MwA (lines 193–204)

Allocates proportional to stratum mean scattering weight. Both strata are independently ceiled (no strict budget):

```
upperBound   = ⌈a × totalPopulation⌉
sumStratMean = heavy.mean + light.mean
heavySamples = ⌈heavy.mean / sumStratMean × upperBound⌉
lightSamples = ⌈light.mean / sumStratMean × upperBound⌉
totalSamples = heavySamples + lightSamples
```

#### vi. Heavy-Rounded Mean-Weighted Allocation — HrMwA (lines 212–222)

Rounds the heavy stratum by mean weight; light gets the remainder:

```
budget       = ⌈a × totalPopulation⌉
sumStratMean = heavy.mean + light.mean
heavySamples = ⌈heavy.mean / sumStratMean × budget⌉
lightSamples = budget − heavySamples
```

**This is the default strategy in the current build.**

#### vii. Light-Rounded Mean-Weighted Allocation — LrMwA (lines 228–237)

Rounds the light stratum by mean weight; heavy gets the remainder:

```
budget       = ⌈a × totalPopulation⌉
sumStratMean = heavy.mean + light.mean
lightSamples = ⌈light.mean / sumStratMean × budget⌉
heavySamples = budget − lightSamples
```

Each strategy can be combined with either sampling mode (toggle A), giving 14 total configurations.
