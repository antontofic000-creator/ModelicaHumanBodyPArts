# Verification contract and interpretation

## Three layers

**Modelica assertions** contain each fixture's numerical targets and tolerances. Of 45 historical runtime cases, 28 last 0.01 s and chiefly check algebraic/geometric known answers. Five further fixtures test executable generation only.

**The portable runner** checks source/dependency versions, fresh directories, compiler/runtime diagnostics, finite time/completion channels, final time and `checksPassed >= 1`. It does not replace numerical assertions. Build and runtime limits are 600 seconds each.

**The external CSV checker** checks six selected contracts, recomputes tutorial force/energy balances and must reject four corrupted-data controls. This is implementation verification, not biological validation.

The historical release and new tutorial have separate manifests. Do not add three new cases and call the total the old 50-case release.

```sh
node scripts/package_tree.mjs --check
node scripts/run_verification.mjs --storage source --out results/source-01
node scripts/run_verification.mjs --storage tree --out results/tree-01
node scripts/run_verification.mjs --storage tree --suite tutorial --out results/tutorial-01
node scripts/check_contracts.mjs --release results/tree-01 --tutorial results/tutorial-01 --out results/external-01.json
```

Each output directory retains a manifest, machine-readable summary, input scripts/logs and runtime CSV where applicable. Summary hashes identify retained evidence. Early termination must remain FAIL/INCOMPLETE, not a smaller passing campaign.

## Linux automation and preservation

The workflow runs on pushes and pull requests. Source/tree layouts have separate jobs. It uses a digest-pinned OpenModelica 1.27.1 container, Node.js 22 and checked Modelica Standard Library 4.1.0. Repository access is read-only; tags are untouched. The initial setup attempt failed before simulation because system Node.js 12 was incompatible; its Actions log is retained. Evaluate subsequent runs by their own results.

Online artifacts expire after 30 days. Preserve evidence for the cited commit in the article archive; a green badge is not permanent storage. The submission package includes actual outputs and logs rather than success inferred from workflow syntax.

## Windows reproduction record

The 2026-10-12 Windows audit completed all 50 distinct cases across two attempts. Attempt 1 passed cases 1–34, then a new 120-second compiler timeout stopped case 35 before runtime. Restoring the release runner's original 600-second limit allowed cases 35–50 to pass in new directories. Preserve the interruption; it was not a numerical assertion failure and was not an uninterrupted campaign. Three new tutorial cases also passed on Windows using tree storage.

## Correct interpretation of the release fixtures

`AuditedPlantarKnownLoadTest` disables gravity and contains no moving mass. Six prescribed penetrations of 0.1635 mm into 100,000 N/m springs give 16.35 N each, 98.1 N total and 32.7 N per pair. This equals the weight of 10 kg at 9.81 m/s², but it is not a supported 10 kg body.

`AuditedPlantarHeelUnloadTest` prescribes the heel above ground and the other regions loaded; it does not simulate a heel-lift trajectory. The existing variable-impedance energy test is gravity-loaded but uses ideal fixed support. The separate guided tutorial demonstrates a gravity-loaded distributed vertical load path.

No human participants, clinical outcomes, unsupported balance, Dymola/macOS execution, independent-user adoption or general stability guarantee is established. A source hash identifies bytes, not physiology. Biological use requires task-specific comparison with matched measurements, anatomy, represented mass and boundary conditions.
