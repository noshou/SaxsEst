# SaxsEst

## Status
- Not fully validated. Use for research and experimentation.
- See theory.pdf for detailed background theory and motivations.

## Summary
SaxsEst is a high-performance Fortran codebase for estimating Small Angle X-ray Scattering (SAXS) intensity profiles from atomic coordinate files (XYZ). It implements:
- Debye estimator (exact O(N^2) pairwise computation)
- Proportional estimator (propoEst)
- Stratified estimator (stratEst)

## Requirements
- Fortran 90+ compiler (gfortran recommended)
- GNU make
- OCaml runtime (for CSV export bridge) - if you use CsvInterface features
- Standard POSIX utilities (bash, coreutils)
- iso_c_binding (Fortran intrinsic)

## Build & Run
This will automatically evaluate all .xyz files in the AtomXYZ/data dir 
and generate a report.

    ./saxsEst.sh [--debug] [--help]

## Outputs
- CSV files with Q vs I(Q) for each estimator
- Timing statistics
- Analysis logs in Analysis/

## Project layout
- SaxsEst/        - CLI + top-level program
- Est/            - estimators and sampling code (Est/Est.f90 + inc/*.inc)
- FormFact/       - atomic form factors and anomalous data
- Freq/           - frequency / CDF construction for stratification
- AtomXYZ/        - coordinate types, distance utilities
- CsvInterface/   - Fortran ↔ OCaml CSV bridge
- pdb_to_xyz/     - (legacy / WIP) PDB → XYZ scripts (some parts noted WIP)
- Analysis/       - saved analysis and logs
- docs/           - theory.pdf and planned documentation


## Important: how to toggle different behaviours in stratEst.inc
- There are two orthogonal toggles:
  A) Whether you sample only once (using q(1)) and reuse the same samples for all q values, OR resample for each q (resample per q).
  B) The allocation strategy to derive how many heavy vs light samples to draw:
     - Neyman allocation (variance-driven)
     - Proportional sampling
     - Heavy-rounded proportional
     - Light-rounded proportional
     - Mean-weighted sampling (active by default in the code)
     - Heavy-rounded mean-weighted (active in current build)
- The file Est/inc/stratEst.inc contains commented blocks showing all strategies and the resample option. Below are step-by-step edits for both toggles.

### A - Choosing sample-once vs resample-per-q
- Default (current code): sampling only on first q value, then reusing `es` for each q.
- To resample for each q do the following in Est/inc/stratEst.inc:
    1. Comment out lines 355-358
    2. Uncomment lines 360-362, 371, and 372
### B - Choosing sampling method
- Default (current code): heavy-rounded mean-weighted sampling is used
- To pick between estimators do the following in Est/inc/stratEst.inc:
    1. Ensure all code is commented out in lines 123 - 237
    2. Pick an estimator and uncomment the related block:
        i. Neyman Allocation (lines 123-148)
            - stratumStDev = heavyStDv * heavyPopulation + lightStDv * lightPopulation
            - strataBudget = ⌈a * total population⌉
            - minimum stratum size: 2
            - maximum stratum size: strataBudget - 2
            - heavySamples = min(max(ceilling(strataBudget * (heavyStDv * heavyPopulation)/(stratumStDev)), minimum stratum size), maximum stratum size)
            - lightSamples = min(max(ceilling(strataBudget * (lightStDv * lightPopulation)/(stratumStDev)), minimum stratum size), maximum stratum size)
            - totalSamples = heavySamples + lightSamples
        ii. Proportional Sampling (lines 154-161)
            - heavySamples = ⌈heavyPopulation * a⌉
            - lightSamples = ⌈lightPopulation * a⌉
            - totalSamples = heavySamples + lightSamples
        iii. Heavy-rounded Proportional Sampling (lines 167-173)
            - totalSamples = ⌈a * total population⌉
            - heavySamples = ⌈a * heavyPopulation⌉
            - lightSamples = totalSamples - heavySamples
        iv. Light-rounded Proportional Sampling (lines 179-185)
            - totalSamples = ⌈a * total population⌉
            - heavySamples = ⌈a * heavyPopulation⌉
            - lightSamples = totalSamples - heavySamples
        v. Mean-Weighted Sampling (lines 193-204)
            - strataBudget = ⌈a * total population⌉
            - sumStratMean = meanLight + meanHeavy
            - heavySamples = ⌈meanHeavy/(sumStratMean) * strataBudget⌉
            - lightSamples = ⌈meanLight/(sumStratMean) * strataBudget⌉
            - totalSamples = heavySamples + lightSamples
        vii. Light-Rounded Mean-Weighted Sampling (lines 228-237)
            - totalSamples = ⌈a * total population⌉
            - sumStratMean = meanLight + meanHeavy
            - lightSamples = ⌈meanLight/(sumStratMean) * totalSamples⌉
            - heavySamples = totalSamples - lightSamples
        
