# Notebook
## 2025-10-11

- switched to perlecan from Alphafold prediction

## 2025-11-08

- Initial commit
- got rid of multiple atoms from the scattering table due to non-standardized scale; need to check which ones I got rid of (iirc 3-4 total)
- due to rounding messing things up, all E_ev factors are rounded to nearest thousandth instead of ten-thousandth

## 2025-11-10

- saxs beamline @ CLS operates in 5-24 keV; choose whichever has best coverage in data within that range
- Cromer Coefficients only valid from 0 -> 2 A⁻¹ (ATOMIC SCATTERING FACTORS AT HIGH ANGLES)
- added functions for deriving form factor for an atom

## 2025-11-11

- implemented classic Debye formula
- AlphaFold data for perlecan obtained and converted to xyz
- script for loading xyz files added

## 2025-11-12

- classic algo time complexity is O(mn²) where m = number of "q" values, and n is the total number of atoms
- fixed weird NaN values and negative values appearing in output

## 2025-11-13

- normalization constant will be affected; have to keep track of the number of atoms visited and normalize that way

## 2025-11-19

- migrated f_0.ml from Owl_dataframe to Csv + hashtable; fully transitioned away from dataframes
- refactored code for reusability
- regex in load_xyz is borked

## 2025-11-20

- testing w/ wide range of proteins
- anon. factors are only for ground state and very spotty in coverage, so f1/f2 limited to ground state only on already limited amount of metals; f0 is not limited by this though!
- added lots of proteins (wide range); improved data set

## 2025-11-21

- mg f1/f2 factors at 12412.8eV not found, so used closest @ 12337.5
- started implementing kd-tree

## 2025-11-23

- added radial search

## 2025-12-09

- began translating codebase to Fortran

## 2025-12-17

- form_fact translation to Fortran done; now a static library
- parsing xyz files working, but generated files are massive (~2 million lines)

## 2025-12-19

- merged makefiles into one master makefile

## 2025-12-20

- finished translating OCaml code for radial search + kdt to Fortran
- added C/OCaml bridge for output

## 2025-12-22

- implemented propest function
- added kd-tree frequency distribution

## 2025-12-24

- completed Bernoulli estimator
- harmonic distributions won't work; focusing on proportional sampling

## 2025-12-30

- fixed some issues with kdt, modularized it better

## 2026-01-02

- kdt module compiles
- bug fixes in radial_search

## 2026-01-04

- estimate library compiles

## 2026-01-05

- started work on CLI, finished wrappers for main

## 2026-01-08

- saxs_est executable compiles

## 2026-01-10

- kdt trees don't seem to work, but propEst working incredibly well
- added R standardizations; did small analysis subset

## 2026-01-11

- renamed debye files to fix typos

## 2026-01-12

- accidentally unplugged monitor during perlecan debeyeEst_kdt; might not trust that
- why is kdt not consistently faster??????
- rubisco analysis is borked

## 2026-01-15

- removed normalization: need to figure this out in the future
- may need to rethink scaling...
- fixed bugs, added mg2+ to f0
- updated run automation so it does not stop at fatal errors; added sysinfo

## 2026-01-16

- test with normalization constants, where p = ##atoms in search radius, N_u = ## unique form factors in prop_est
  - N^2 for debye_rad
  - p * N^2 * (sqrt(a)/epsilon) for prop
  - p * N for debye_kdt
  - p * N * (sqrt(a)/epsilon) for prop_kdt
- added tracking for output log files

## 2026-01-19

- forgot to normalize debye rad so deleted 2026-01-16 run

## 2026-01-20

- adding in method to track w_est per I(Q) and compare w/ debye weight
- removed normalization constants for now

## 2026-01-31

- kdt-tree is out of scope - moving to remove but keeping it in another project

## 2026-02-13

- removed kdt tree, but need to fix R bc it is not merging csvs together

## 2026-02-16

- refactored code after kdt removal

## 2026-02-18

- scaling factor for propEst: N*((sqrt(24*n_tilde)/epsilon) + 1)
- re-adding scaling factor, running different ranges of epsilon to try to find optimal val

## 2026-02-19

- much better results, but need to add "multi-stepped" epsilon since results vary by region
- looking into changing normalization constant
- may change w_est to go for atom *types* and not global atom distribution

## 2026-02-22
- branch to work in progress (refactoring branch; will not compile)
  - will contain all work until refactor is done 
  - refactor is TOP PRIORITY; cannot progress until it is finished
- working on big refactor
  - module names consistent PascalCase
  - variable names consistent with camelCase
  - merging/consolidation of files for better readability/maintainability
  - renaming of directories to name of module
  - various other code quality improvements
- readding harmonic estimator
- added functions for pmf/cmf/survival functions

## 2026-02-24

- by trial and error, approximately epsilon=0.41 produces fewest errors
- some molecules (likely due to geometry/orientation/distribution) are consistently being underestimated by propest, however for most we have 4 regions: high underestimation, medium underestimation, small underestimation, and small overestimation which *may* coincide with different SAXS profile regions
- sampling size is Theta(N*((sqrt(24*n_tilde)/epsilon) + 1)), so may need to figure out how to derive a constant to properly account for it... may need to look into some quantum mech derivations of the debye equation
- try random weighted sampling on frequencies to get "idea" of shape/distribution; possibly train neural network or something similar??
- possibly reimplement kd-tree for above point; big maybe here because we don't know if the data structure is bugged or if its a waste of time

- **finished refactor**
  - enforced naming conventions
  - renamed / consolidated libraries
  - renamed "out" ot "Analysis"
  - added automate-run-debug for debug runs
  - fixed bugs with debug
  - added valgrind output for debug - no memory leaks/errors

# 2026-02-26
- normalization constants
  - proportional estimator sample size is Θ((sqrt(24\*N)/epsilon) + 1), where N is the number of atoms
  - Debye equation (derived from QM) has a normalization constant of 1/N²
  - by trial and error, normalization constant of N\*((sqrt(24\*N)/epsilon) + 1) works fairly well for the proportional estimator
  - total number of atoms sampled is still N² since distance calculations are not truncated; would love to dig into this further given more time
- rough plan for tackling estimation errors based on three general SAXS profile regions:
  - **Guinier region**: small q values, highest intensity with sharp drop; highest discrepancy between estimator and actual value (expected — form factors are largest here so errors are amplified significantly)
  - **Fourier/Debye region**: intermediate q values, after first inflection point with sharp decline toward Porod region; medium to moderate deviations
  - **Porod region**: large q values, rapid exponential decay toward zero; small to very small deviations
  - deviations are relative and dependent on molecule size (more atoms → higher amplification of errors)
- proposed algorithm for each q value:
  1. calculate rate of change between q_i and q\_(i-1), determine which region we are in (informs adaptive parameters)
  2. do importance sampling on frequency distribution; use it to calculate "real" Debye formula such that sample S = C1 ± epsilon estimation
  3. run sample through the estimator to get estimate E
  4. calculate difference, find C2 such that E = S ± epsilon ± C2; let err = epsilon ± C2
  5. run actual proportional estimate with epsilon value of err
- usually the proportional estimate underestimates until the Porod region, then slightly overestimates (weights are very small there)
  - some molecules overestimate early in the Guinier region, causing all subsequent intensity estimations to be overestimated
  - originally thought it was due to shape (globular vs cylindrical vs Gaussian chain proteins), but running xyz files in PyMOL doesn't fully support this
  - second guess: metal centers contribute large weights and are overrepresented for atoms positioned far away; doesn't fully explain it either
  - likely a combination of factors or something else entirely; out of scope for this project
- if time permits: implement DBSCAN or k-means clustering to tackle pairwise summations for distance calculations
  - other validated algorithmic methods use some version of this
  - DBSCAN issue: finding optimal search radius
  - k-means issue: finding optimal cluster size without blowing up time complexity
