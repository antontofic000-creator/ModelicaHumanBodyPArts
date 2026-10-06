# Article 2 — reproduction package and upper-body inertia sensitivity

**Study:** When is a rigid pelvis–trunk approximation sufficient? An output-specific model-reduction protocol applied to lumbar mobility in multibody biomechanics

**Authors:** Toufic Antoun El Halabi and Nathalie Chahine, Lebanese University.

This study package accompanies a separate revision of the September 25 archive. The frozen v0.10.0 RC1 software and original Article 2 experiment remain byte-for-byte unchanged. The full primary and supplementary data are preserved in the versioned archive.

## Campaigns

Primary: 6 nominal cases, 45 robustness cases, 20 passive-lumbar sensitivity cases, 18 refinement cases, and one analytical two-inertia benchmark.

Supplementary: de Leva-based head and upper limbs are rigidly attached to the thoracic/cervical frame, adding 12.615 kg and 0.34314807897 kg·m² yaw inertia. Represented mass changes from 62.790 to 75.405 kg; no arbitrary rescaling or active upper-limb torque is introduced. The known-answer inertia test, three nominal audits and all 45 supplementary operating cases passed.

At the stated 10% criterion, primary pelvis/thorax yaw adequacy is 15/15 each. With added rigid upper-body inertia, it is 13/15 for pelvis yaw and 15/15 for thorax yaw. The two pelvis exceedances (11.19% and 11.95%) pass at 20%. Support/contact outputs are more sensitive. These are computational model-reduction results and do not establish human or clinical validation.

## Reproduction verification

The seven-check harness passed from a clean short path with OpenModelica 1.27.1 and MSL 4.1.0. Its largest nominal energy residual was 2.02e-6 J; the analytical added-inertia torque error was zero. `reproduction_test_summary.json` records the individual checks. The public repository layout also passed all seven checks, and the fixed portable supplementary runner passed a fresh 45/45 sweep. Recomputed adequacy summaries matched the archived results exactly; `portable_reproduction_summary.json` records that audit. A deliberately failed copied check produced verifier FAIL and OpenModelica exit 1.

## Reproduce

Verified environment: OpenModelica 1.27.1 (64-bit), MSL 4.1.0, Windows x64; Node.js is required for result verification and campaign runners. Copy/unzip to a short writable path on Windows to avoid compiler path-length failures. Set `OMC` or `OMC_PATH` if the compiler is elsewhere.

From `studies/article2` in a complete repository checkout (the archive uses the same commands from its root):

```text
omc run_test.mos
node run_article2_all.mjs smoke
node run_article2_all.mjs nominal
node run_article2_all.mjs robustness
node run_article2_all.mjs sensitivity
node run_article2_all.mjs refinement
node run_article2_all.mjs benchmark
node run_article2_all.mjs upperbody
node run_article2_all.mjs all
```

`run_test.mos` runs the known-answer model and six nominal wrappers, then verifies all CSV samples and logs using `verify_test_results.mjs`. It writes `test_summary.json` and exits non-zero on failure. The full supplementary runner reads its 15 conditions × 3 architectures from the manifest and builds each architecture once. Generated compiler outputs go under `generated/` and are not archived as research data.

A simulation must report successful completion, have `checksPassed >= 1`, cover the declared final time (1.499–1.505 s for a 1.5 s mission), and have maximum sampled absolute energy residual below 0.01 J. The known-answer check separately verifies added mass, inertia and torque. A 1.502 s final output timestamp is admitted; analyses retain the original common 0–1.5 s reporting window.

## Layout

- `../../src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo`: frozen public library.
- `ModelicaHumanBodyPArtsArticle2.mo`: unchanged primary experiment.
- `ModelicaHumanBodyPArtsArticle2_UpperBody.mo`: separate supplementary experiment.
- `test.mo`, `run_test.mos`, `verify_test_results.mjs`: thin wrappers and verification gates.
- `article2_manifest.json`: primary campaign definitions and separate supplementary block.
- `supplementary_upper_body_summary.json`, `reproduction_test_summary.json`: compact scientific and verification evidence.
- `scripts/analyze_article2_inertia.mjs`: common-time-grid adequacy analysis.
- Full raw CSV/logs, historical metadata and checksums are supplied in the versioned archive.

## Public records

Software: https://doi.org/10.5281/zenodo.22941517

Historical dataset version: https://doi.org/10.5281/zenodo.22957144

Dataset concept: https://doi.org/10.5281/zenodo.22957143

Historical preprint: https://doi.org/10.5281/zenodo.22958896

Reproduction repository: https://github.com/antontofic000-creator/ModelicaHumanBodyPArts/tree/main/studies/article2

The revision archive and new dataset/preprint versions are being prepared separately. The linked dataset and preprint DOIs above identify the September historical versions. No new version DOI is claimed before reservation/publication.

## Licensing

Software/code: MIT. Research data and non-software documentation: CC BY 4.0. See the included license files.

## Portable adequacy analysis

`scripts/analyze_article2_inertia.mjs` reproduces the original common-time-grid analysis and 5%/10%/20% threshold counts. It accepts either the flat archived primary data or the manifest runner's primary output hierarchy:

```text
node scripts/analyze_article2_inertia.mjs <primary_robustness_folder> <upper_body_robustness_folder> <output_json>
```

Full raw data belong in the versioned Zenodo dataset; this GitHub package contains source, runners and compact verification/adequacy summaries.

## Reproduction file SHA-256

| File | SHA-256 |
|---|---|
| `test.mo` | `552d4d8b16d900c7085bbad8d82f49bd46e466d3ab48bee1b5cc3b54c14c36c8` |
| `run_test.mos` | `f5f87a0740ab9714ebecf503a61ab2df08a710f6c27568bde5fe63e5ef56ebb7` |
| `verify_test_results.mjs` | `ddd3ba70e767c7e6300f5556d887eeae1a5bec2b26ca186bcf96913d8b399467` |
| `run_article2_all.mjs` | `f154c0965fc2f81450300f51858ee02e3937c9ad317f5da0f0d5ca44a9112f7a` |
| `run_article2_upperbody.mjs` | `79446233253c7ca2e7c2e568fba9921ba78f57c1924fc448f42dabc98719b1c1` |
| `scripts/analyze_article2_inertia.mjs` | `5b95b43265399e46a98c17fff5f3b53c75de347b0a3e5ed8ad5a7f5b81c3cf12` |
