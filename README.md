# ModelicaHumanBodyPArts

**Version 0.10.0 RC1 — open-source publication candidate**

ModelicaHumanBodyPArts is a verification-oriented Modelica library for auditable human multibody mechanics. It connects explicit multibody assumptions to source-aware parameters, rigid-body segments and joints, distributed plantar contact, reaction wrenches, power and energy outputs, and reproducible numerical verification.

## Verified release

- OpenModelica 1.27.1 (64-bit)
- Modelica Standard Library 4.1.0
- Windows x64 verified environment
- 45 runtime simulations + 5 build-only fixtures
- 50/50 registered cases passed
- Two fresh-directory clean reruns passed
- Source SHA-256: `2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b`

## Repository layout

- `src/` — exact Modelica source used by the publication-candidate verification campaign
- `tests/` — registered verification/build manifest
- `scripts/` — native release runner
- `verification/` — retained machine-readable verification summary
- `LICENSE` — MIT License
- `THIRD_PARTY_NOTICES.md` — dependency and attribution notices
- `RELEASE_NOTES.md` — release notes
- `CITATION.cff` — software citation metadata

## Reproduction

1. Install OpenModelica 1.27.1 and Modelica Standard Library 4.1.0.
2. Place the source, test manifest and runner in a working directory, preserving relative references used by the runner.
3. Run the registered campaign from fresh build products.
4. Confirm the exact source SHA-256 shown above before interpreting results.

## Scope

This is reduced rigid-segment mechanical research software. The verification campaign checks declared numerical and mechanical contracts. It does not establish human biological or clinical validity and does not identify individual muscle forces, cartilage stress, ligament strain, injury risk or respiratory physiology.

## License

Copyright (c) 2026 Tofic Anton. Released under the MIT License. See `LICENSE`.

Modelica Standard Library 4.1.0 is an external dependency and is separately licensed by the Modelica Association. See `THIRD_PARTY_NOTICES.md`.

## Project

- Project website: https://www.lynkorr.com/
- ORCID: https://orcid.org/0009-0000-5409-0417
- Repository: https://github.com/antontofic000-creator/ModelicaHumanBodyPArts

## Publication status

The associated SoftwareX manuscript is in preparation. No acceptance or publication is claimed here.