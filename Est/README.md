Est — Estimators and sampling

What it contains
- Est/Est.f90 — module with public routines: debyeEst, propoEst, stratEst
- Inc files (Est/inc/*.inc) implement each estimator and sampling utilities.

Key files to inspect
- Est/inc/debyeEst.inc
- Est/inc/propoEst.inc
- Est/inc/stratEst.inc
- Est/inc/utils.inc

How to configure stratified estimator
- See top-level README section "Important: how to toggle different behaviours in stratEst.inc".
- To change sampling behaviour edit Est/inc/stratEst.inc (allocation blocks and sample/resample toggle).

Testing
- Use small XYZ files (N < 300) to validate debyeEst output then compare with stratEst and propoEst.
- Use Analysis/ logs for reference timings and outputs.

Troubleshooting
- If you see segmentation faults: check dynamic pointer arrays created during CDF construction (Freq/ functions) and verify pointers remain valid; the code uses coord pointer arrays heavily.
