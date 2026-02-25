# Please note that...
This project is being **activley developed**! It is not fully validated yet, and is still undergoing **major** revisions. 
The automated analysis will change over time and will eventually be removed or completley refactored. 

The software is currently beign validated on:
1. Chignolin (135 atoms)
2. CSGC (772 atoms)
3. GPX (3,111 atoms)
4. KdelR1 (1,243 atoms)
5. PHGDH (3,972 atoms)
6. Plastocyanin (827 atoms)
7. Strip1-iso2 (6,000 atoms)
   
# SaxsEst

A high-performance Fortran-based tool for estimating Small Angle X-ray Scattering (SAXS) intensities from molecular structures, 
implementing and adapting algorithms from [Better Sum Estimation via Weighted Sampling](https://arxiv.org/abs/2110.14948v1) 

## Overview

SaxsEst is a scientific computation software designed to estimate SAXS intensity profiles from atomic coordinates. It implements two complementary estimation approaches:

- **Debye Estimation**
- **Proportional Estimation**
- **Harmonic Estimation** (work in progress; see better sum paper)
- **Hybrid Estimator** (work in progress; see better sum paper)
- **Combined Estimator** (work in progress; combines all three for better estimation)
## Requirements

- **Fortran Compiler**: Fortran 90 or later (e.g., gfortran, ifort)
- **Make**: GNU Make for building
- **OCaml Runtime**: For CSV export functionality
- **Standard Libraries**: iso_c_binding for C interoperability

## Building

### Prerequisites
Ensure you have a Fortran compiler, opam, C compiler and Make installed.

### Build Commands

Build the project using the provided Makefile:

```bash
# Clean build
make clean

# Debug build (with debugging symbols)
make debug

# Release build (optimized)
make release
```

Build outputs will be created in the appropriate directories.

## Usage

### Automated Analysis

Run batch analysis on multiple molecular systems with varying parameters:

```bash
# Standard analysis with epsilon values from 0.01 to 0.50
./automate-run.sh

# Debug mode analysis
./automate-run-debug.sh
```

### PDB to XYZ Conversion

Convert PDB (Protein Data Bank) files to XYZ format:

```bash
./pdb_to_xyz input.pdb output.xyz
```

Or with interactive prompts:
```bash
./pdb_to_xyz
```

### Command-Line Interface

Run single-molecule analysis through the CLI:

```bash
./SaxsEst <xyz_modules_path> <output_directory>
```

The CLI will prompt for:
- **Advice parameter (a)**: Controls estimation parameters
- **Epsilon (ε)**: Precision/approximation parameter (0.01 - 0.9)
- **Rounding Mode**: DOWN or other rounding strategies

### Output

Analysis produces CSV files containing:
- Scattering vector (Q) values in Å⁻¹
- Intensity estimates from both Debye and proportional methods
- Weight distributions for form factors
- Comparative analysis between estimation methods

## Project Structure

```
.
├── SaxsEst/              # Main CLI application module
├── Est/                  # Intensity estimation algorithms
├── FormFact/             # Atomic form factor calculations
│   ├── F0Factor.f90      # f0 form factor data & functions
│   └── f1_f2.f90         # Anomalous scattering factors
├── Freq/                 # Frequency & weight distributions
├── AtomXYZ/              # Atomic coordinate types & operations
├── CsvInterface/         # Fortran-OCaml CSV export bridge
├── pdb_to_xyz/           # PDB file conversion utility
├── Analysis/             # Analysis scripts & R utilities
│   └── CsvCombine.R      # Combine analysis CSVs
├── Makefile              # Main build configuration
├── BuildRelease.mk       # Release build rules
├── BuildDebug.mk         # Debug build rules
├── BuildClean.mk         # Clean build rules
└── docs/                 # Documentation
```

## Form Factor Data

The software includes comprehensive atomic form factor data from:
- **International Tables for Crystallography Vol. C**
- DOI: 10.1107/97809553602060000600

Supports 24 common elements and ions including:
H, He, Li, Be, B, C, N, O, F, Ne, Na, Mg, Al, Si, P, S, Cl, Ar, K, Ca, Mn²⁺, Cu²⁺, Se, Mg²⁺

## License

This project is licensed under the **GNU Lesser General Public License v2.1** - see the LICENSE file for details.

## Authors

- Nathan Ouedraogo (noshou)
