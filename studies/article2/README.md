# Article 2 — lumbar model-reduction study

Reproduction materials for:

**Toufic Antoun El Halabi**, *When is a rigid pelvis–trunk approximation sufficient? An output-specific model-reduction protocol applied to lumbar mobility in multibody biomechanics.*

**Status:** manuscript in preparation / not yet published.

## Public software dependency

This study is reproduced against the exact public **ModelicaHumanBodyPArts v0.10.0 RC1** source already archived with the software release.

- Software DOI: [10.5281/zenodo.22941517](https://doi.org/10.5281/zenodo.22941517)
- Software source: [`src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo`](../../src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo)
- SHA-256: `2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b`
- Verified environment: OpenModelica 1.27.1 (64-bit), Modelica Standard Library 4.1.0, Windows x64

The public v0.10.0 library is **not modified** by this study.

## Article 2 experiment package

- [`ModelicaHumanBodyPArtsArticle2.mo`](ModelicaHumanBodyPArtsArticle2.mo) — experiment models and controlled architecture wrapper
- [`article2_manifest.json`](article2_manifest.json) — complete nominal, robustness, sensitivity and refinement case definitions
- [`run_article2_all.mjs`](run_article2_all.mjs) — portable campaign runner
- [`A2TwoInertiaBenchmark.mo`](A2TwoInertiaBenchmark.mo) — analytical two-inertia verification model

The exact experiment file used for the archived execution campaign has SHA-256:

`ae354a846f66823457e01520d49bd55e5b863177481bc3fad96abe5439ac6aa6`

GitHub's text representation has SHA-256:

`1402b0cc88661f632bddd0f9f597b07e2c58c0ddec1858fac9c891aeebf1db85`

The text content is identical; the byte-level difference is only the text-file ending/encoding representation. The Zenodo study-data archive preserves the exact executed bytes.

## Verified v0.10.0 campaign

The complete campaign was re-executed against the public v0.10.0 RC1 library:

- **6/6** nominal right/left architecture cases passed
- **45/45** operating-robustness simulations passed
- **20/20** passive-lumbar sensitivity simulations passed
- **18/18** numerical-refinement simulations passed
- analytical two-inertia benchmark passed, with maximum relative-angle error **7.5721 × 10⁻¹⁰ rad**

The v0.10.0 nominal, robustness and passive-lumbar sensitivity results reproduced the prior study values with no numerical change in the compared reported metrics.

## Run the study

Requirements:

1. OpenModelica **1.27.1**
2. Modelica Standard Library **4.1.0**
3. Node.js
4. Clone/download this repository.

From the repository root:

```text
node studies/article2/run_article2_all.mjs nominal
node studies/article2/run_article2_all.mjs robustness
node studies/article2/run_article2_all.mjs sensitivity
node studies/article2/run_article2_all.mjs refinement
node studies/article2/run_article2_all.mjs benchmark
```

Or run the complete campaign:

```text
node studies/article2/run_article2_all.mjs all
```

If `omc` is not on your system PATH, set the environment variable `OMC_PATH` to the OpenModelica compiler executable.

Results are written to:

```text
studies/article2/article2_results/
```

## Scope

The study is a controlled **computational multibody model-reduction** experiment. It does not establish human clinical validity, individual muscle forces, tissue stress, injury risk or physiological validity.

## Research-data archive

The exact raw outputs, logs, refinement results, source snapshots and reproduction scripts are archived as a separate Zenodo dataset:

- Article 2 dataset DOI: [10.5281/zenodo.22957144](https://doi.org/10.5281/zenodo.22957144)
- Archive file: `ModelicaHumanBodyPArts_Article2_v010_REPRO_ZENODO_FINAL_20260925.zip`
- Archive SHA-256: `e8bf10157470ceeee28715d8603d4572f13630011fa618d37973df85852c16f7`
- Research data / non-software documentation: CC BY 4.0
- Software/code: MIT License
