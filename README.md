# ModelicaHumanBodyPArts

[![DOI](https://zenodo.org/badge/1385543378.svg)](https://doi.org/10.5281/zenodo.22941516)

**Public release:** v0.10.0  
**Verified publication-candidate source:** v0.10.0 RC1  
**Version-specific Zenodo DOI:** [10.5281/zenodo.22941517](https://doi.org/10.5281/zenodo.22941517)  
**Concept DOI / all versions:** [10.5281/zenodo.22941516](https://doi.org/10.5281/zenodo.22941516)

**Exact verified source SHA-256:**  
`2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b`

ModelicaHumanBodyPArts is a verification-oriented Modelica library for auditable human multibody mechanics. It connects explicit multibody assumptions to source-aware parameters, rigid-body segments and joints, distributed plantar contact, reaction wrenches, power and energy outputs, and reproducible numerical verification.

## Verified release

- OpenModelica 1.27.1 (64-bit)
- Modelica Standard Library 4.1.0
- Windows x64 verified environment
- 45 runtime simulations + 5 build-only fixtures
- 50/50 registered cases passed
- Two fresh-directory clean reruns passed
- Source SHA-256: `2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b`

## Downloads and archives

- **Public Master Guide:** [Read/download the 39-page teaching and reproduction guide](ModelicaHumanBodyPArts_v0_10_Public_Master_Guide_Lynkorr.com.pdf)
- **Archived v0.10.0 release:** [Zenodo DOI 10.5281/zenodo.22941517](https://doi.org/10.5281/zenodo.22941517)
- **Direct archived release ZIP:** [Download from Zenodo](https://zenodo.org/api/records/22941517/files/antontofic000-creator/ModelicaHumanBodyPArts-V0.10.0.zip/content)
- **GitHub-hosted open release ZIP:** [Download v0.10.0 open release](ModelicaHumanBodyPArts_v0_10_0_OPEN_RELEASE.zip)
- **GitHub v0.10.0 release:** [View release](https://github.com/antontofic000-creator/ModelicaHumanBodyPArts/releases/tag/v0.10.0)
- **Exact verified RC1 source:** [`src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo`](src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo)

## Studies

- **Article 2 lumbar model-reduction study:** [public experiment package and reproduction scripts](studies/article2_lumbar_model_reduction/README.md)

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
- Version DOI: https://doi.org/10.5281/zenodo.22941517
- Concept DOI: https://doi.org/10.5281/zenodo.22941516

## Publication status

The associated SoftwareX manuscript is in preparation. No acceptance or publication is claimed here.
