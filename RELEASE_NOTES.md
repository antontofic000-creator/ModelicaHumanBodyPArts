# Release and publication-companion notes

## Mechanical release v0.10.0 (24 September 2026)

The archived source remains unchanged, with SHA-256 `2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b`. Its filename retains the historical RC1 suffix. The software is MIT-licensed and archived at DOI 10.5281/zenodo.22941517. Both case-sensitive release tags are retained because the Zenodo record links to the uppercase spelling.

The release adds regional plantar-load/energy observers and aggregate energy accounting using actual scaled stiffness/damping and an explicit stiffness-modulation term. Its manifest contains 45 runtime cases and five build-only fixtures. The 98.1 N known-load case prescribes penetration with gravity disabled; it does not contain a supported 10 kg mass.

## Publication companion (October 2026)

- Standard 19-package directory layout with exact source reconstruction.
- Portable Node.js 22 runner without personal paths; fresh directories and explicit completion gates.
- Linux source/tree CI with pinned OpenModelica 1.27.1 image and Modelica Standard Library 4.1.0.
- Five additional, separately manifested integration cases: equilibrium, vertical perturbation, ideal-support bypass detection, pitch-driven regional redistribution and a nonzero parallel-support bypass control.
- External CSV contracts with four rejected data corruptions.
- Neutral documentation, executable tutorial, software-author alias clarification and a license filename alias.

The guide can carry horizontal forces/moments but no vertical force; the new examples do not demonstrate unsupported balance. These companion files are not retroactively part of the original DOI archive. Cite the exact repository commit as well as the original release. Passing mechanical contracts is not biological validation.