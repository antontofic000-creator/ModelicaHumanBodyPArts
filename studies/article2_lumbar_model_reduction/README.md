# Article 2: lumbar model-reduction study

This folder contains the public experiment package and reproduction scripts for the study:

**When is a rigid pelvis-trunk approximation sufficient? A controlled model-reduction study of lumbar mobility in multibody biomechanics**

## Software dependency

The experiments are run against the exact public **ModelicaHumanBodyPArts v0.10.0 RC1** source:

- File: `src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo`
- SHA-256: `2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b`
- Software DOI: https://doi.org/10.5281/zenodo.22941517
- Verified environment: OpenModelica 1.27.1 (64-bit), Modelica Standard Library 4.1.0, Windows x64

The v0.10.0 library itself is not modified by this study. Study-specific fixtures are isolated in `ModelicaHumanBodyPArtsArticle2.mo`.

## Reproduction scripts

- `run_nominal_v010.mjs` — six mirrored nominal cases: locked, yaw-only, and full 3-D lumbar architecture
- `run_robustness_v010.mjs` — 45 simulations: 15 operating conditions x 3 architectures
- `run_lumbar_sensitivity_v010.mjs` — 20 simulations: 10 passive-lumbar settings x yaw-only/full 3-D
- `run_refinement_v010.mjs` — 18 numerical-refinement simulations: 2 sides x 3 architectures x 3 numerical settings

The analytical two-inertia benchmark is retained separately in the study archive.

## Verified rerun status

The full migration campaign was rerun against v0.10.0 RC1:

- nominal: 6/6 PASS
- operating robustness: 45/45 PASS
- passive-lumbar sensitivity: 20/20 PASS
- numerical refinement: 18/18 PASS
- analytical two-inertia benchmark: PASS, maximum angular error approximately 7.57e-10 rad

For the nominal, robustness, sensitivity, and refinement evidence, the rerun reproduced the previous campaign outputs with maximum reported numerical difference of 0 in the compared machine-readable summaries.

## Scope

This is a computational multibody model-reduction study. The simulations test declared mechanical and numerical behavior of the model. They do not constitute human or clinical validation.

## Data archive

A separate archival research-data DOI will contain the raw CSV outputs, logs, exact experiment package, manifests, refinement data, robustness data, passive-lumbar sensitivity data, and analytical-benchmark evidence. The DOI will be inserted here and in the manuscript once the dataset record is deposited.
