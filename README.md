# ModelicaHumanBodyPArts

[![OpenModelica verification](https://github.com/antontofic000-creator/ModelicaHumanBodyPArts/actions/workflows/verification.yml/badge.svg?branch=main)](https://github.com/antontofic000-creator/ModelicaHumanBodyPArts/actions/workflows/verification.yml)

Equation-based research software for auditable reduced human multibody mechanics. Intended users are engineers who need to change support assumptions, inspect net force/moment transmission, or account for variable-impedance energy without confusing an available component with a verified experiment.

## Version and scope

The mechanical library of record is **v0.10.0**, archived at [10.5281/zenodo.22941517](https://doi.org/10.5281/zenodo.22941517). Its source filename retains the historical `RC1` suffix; this is not a second version. The exact source SHA-256 is:

`2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b`

The publication companion supplies a lossless package-tree layout, a portable runner, automated Linux verification, documentation, four publication-facing integration examples and one separately labelled exploratory diagnostic. These additions do not change the archived source or silently extend the historical 50-case manifest. Cite the original DOI for the mechanical release and the exact repository commit for the companion additions.

This is **software/mechanical verification, not human or clinical validation**. It does not recover individual muscle forces, joint-surface stress, plantar tissue pressure or injury risk. A compliant contact law is a numerical assumption, not a measured tissue property.

## Start here

Install **OpenModelica 1.27.1**, **Modelica Standard Library 4.1.0**, **Node.js 22**, and Git. Node.js 12 is not supported. Preserve LF line endings:

```sh
git -c core.autocrlf=false clone https://github.com/antontofic000-creator/ModelicaHumanBodyPArts.git
cd ModelicaHumanBodyPArts
git checkout main
omc scripts/install_dependencies.mos
node scripts/package_tree.mjs --check
node scripts/run_verification.mjs --storage tree --out results/release-01
node scripts/run_verification.mjs --storage tree --suite tutorial --out results/tutorial-01
node scripts/check_contracts.mjs --release results/release-01 --tutorial results/tutorial-01 --out results/external-01.json
```

Use `--omc /path/to/omc` or `OMC` when the compiler is not on PATH. On Windows, quote paths containing spaces, for example `--omc "C:/Program Files/OpenModelica1.27.1-64bit/bin/omc.exe"`. The runner never assumes a username, current directory or compiler installation path. Each output directory must be new; failed evidence is not overwritten. The legacy runner filename delegates to the portable implementation.

In OMEdit, load `ModelicaHumanBodyPArts/package.mo`, then `examples/Article1ContactTutorial.mo`. Do not load the monolithic and directory copies together. Dymola and macOS execution are not claimed.

## Documentation and examples

- [Documentation index](docs/index.md) and [architecture/output map](docs/architecture.md)
- [Worked guided-contact tutorial](docs/guided-contact-tutorial.md)
- [Verification, tolerances and negative controls](docs/verification.md)
- [Contributing a claim-specific test](CONTRIBUTING.md)
- [Earlier public master guide](ModelicaHumanBodyPArts_v0_10_Public_Master_Guide_Lynkorr.com.pdf), retained as historical release documentation

The publication-facing guided tutorial uses a bilateral body under gravity. Six compliant plantar elements carry its **vertical** support. A frictionless vertical guide constrains horizontal translation and rotation and may carry those reactions; it carries no vertical load. The fourth publication-facing case is a hard negative control with a deliberately unobserved parallel contact path: the audited plantar channels remain strongly loaded but carry only 6/7 of total support. Completeness is detected from the plantar-only demand gap against whole-body vertical demand; the hidden contact force is read only as a constructed-control cross-check. These are mechanical verification cases, not unsupported balance or human plantar-pressure validation.

The former pitch-redistribution example remains in the repository as an **exploratory diagnostic**, not as publication evidence. Its short-horizon assertions pass, but long-horizon extension shows continuing tipping rather than convergence to a stable equilibrium.

## Verification evidence

The unchanged release manifest contains **45 runtime cases and five build-only fixtures**. Numerical tolerances reside in the Modelica assertions. The runner checks compiler/runtime success, declared time coverage, finite completion channels and completion stages. Twenty-eight runtime cases last 0.01 s and principally check algebraic/geometric known answers, not long movement trials.

GitHub Actions executes all 50 release cases, the four publication-facing tutorial cases, and the separate pitch diagnostic for both source and package-tree layouts in a pinned OpenModelica Linux container. The badge reflects actual workflow status, not a promise of success. CSV outputs, logs, initialization files, manifests and summaries are retained as artifacts. Download the artifact for a cited run: online artifacts expire after 30 days.

`SHA256SUMS.txt` covers the immutable source, historical manifest and generated Modelica tree only. Numerical summaries contain hashes for their own evidence. The article submission archive supplies a separate complete file manifest.

## Documented research use

A developer-authored lumbar model-reduction study compares locked, axial-only and three-coordinate trunk connections using this library. Its public [preprint](https://doi.org/10.5281/zenodo.22958896) and [reproduction dataset](https://doi.org/10.5281/zenodo.22957144) document actual research use. The [Article 2 experiment directory](studies/article2/README.md) remains separate from the general library tests. This is use within the originating programme, not independent adoption or biological validation. No external-user counts or clinical applications are claimed.

## Attribution, funding and license

The software creator **Toufic Antoun El Halabi** also publishes as **Tofic Anton**; both names share [ORCID 0009-0000-5409-0417](https://orcid.org/0009-0000-5409-0417). The original copyright notice is unchanged. The SoftwareX manuscript is co-authored with Nathalie Chahine, who contributed anatomical literature interpretation and manuscript writing/review. El Halabi personally financed the research without external funding.

Lynkorr is the motivating movement-research project. El Halabi's authorship of a commercial Lynkorr book is disclosed as a competing interest; no purchase or project membership is needed to use the software.

Code is MIT-licensed: [LICENSE](LICENSE) and its identical journal-required alias [Licence.txt](Licence.txt). Modelica Standard Library is a separately licensed external dependency; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). No journal acceptance is claimed.