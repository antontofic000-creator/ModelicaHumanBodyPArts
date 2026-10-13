# Tutorial: verify a vertical plantar support path

## Question and boundary conditions

Can the declared six contacts carry the bilateral body's weight, and can an observer distinguish that path from a fixed-support bypass?

`examples/Article1ContactTutorial.mo` is separate from the unchanged v0.10.0 source. It reuses the published loaded-body parameterization: a 75 kg nominal profile represents **62.79 kg** after the explicit segment/axial partition. At 9.81 m/s², represented weight is **615.9699 N**.

An unactuated vertical prismatic guide holds the support foot's orientation and horizontal position. It constrains five motions and may carry horizontal forces and moments, but its vertical reaction must be zero. This verifies vertical support and energy, not free-standing balance or an unconstrained ground wrench. The opposite foot is uncontacted.

Each contact has stiffness 200,000 N/m and damping 500 N·s/m. Initial compression is `mass*9.81/(6*contactStiffness)`, about 0.5133 mm. Flat geometry and equal stiffness imply one-third of the load per regional pair. This is a known mechanical answer, **not a human plantar-load prediction**.

## Run

Follow the repository installation instructions, then:

```sh
node scripts/run_verification.mjs --storage tree --suite tutorial --out results/tutorial-01
```

In OMEdit, load `ModelicaHumanBodyPArts/package.mo` followed by the tutorial file. Select `Article1ContactTutorial.GuidedStandingContact`, stop time 0.75 s and tolerance 1e-8. Prefer the runner when retaining CSV/log publication evidence.

The central connections from the complete executable model are:

```modelica
connect(groundFrame.frame_b, guide.frame_a);
connect(guide.frame_b, body.leftFootReference);
connect(body.leftFootReference, contact.frame_torsion);
for i in 1:6 loop
  connect(body.leftPlantarFrames[i], contact.plantarFrames[i]);
end for;
body.ankleActuation = 0;
body.hipYawActuation = 0;
der(dissipated) = body.dissipationPower + contact.lossPower;
```

All declarations, inertial parameters and initialization are supplied in the executable file, not left to the reader to infer.

## Inspect the five cases

**GuidedStandingContact** starts at vertical equilibrium. Inspect `normalLoad`, six `contact.zoneNormalForce` channels, `regionalShares` and `guideVerticalForce`. Contact forces support represented weight; the guide supplies no vertical force.

**GuidedStandingPerturbation** changes only `initialLift` to 0.1 mm. This is a dynamic integration test, not prescribed penetration. Instantaneous support need not equal weight: check `normalLoad - m*g - m*a_COM,z`. Total energy includes body kinetic/gravitational/elastic energy and contact storage; adding body/contact dissipation gives the closed balance.

**SupportBypassNegativeControl** deliberately retains ideal fixed support while attaching contact observers. Contact loads are zero and ideal support carries weight. PASS means that `bypassObserved` correctly detects this invalid route for a plantar-support claim; it does not mean the bypass satisfies that claim.

**GuidedPitchRedistribution** adds one allowed support rotation about the foot's mediolateral axis. A 3 N.m smooth internal ankle torque changes the regional load distribution; on the Windows qualification run heel share moved from the pre-pulse baseline by more than 0.01 while the independently recomputed force residual remained below 1e-3 N and the actuator-inclusive energy residual below 1e-6 J. Exact numerical values are reported by the retained checker output. This is a numerical redistribution demonstration, not a calibrated human pressure pattern.

**ParallelSupportNegativeControl** keeps the vertical guide but adds an unobserved seventh contact at the sole. The six audited plantar contacts therefore carry a large, plausible nonzero load while the extra path carries the remainder. The declared geometry uses equal stiffnesses, giving a known 6/7 versus 1/7 split. The detection criterion uses only the audited plantar total and whole-body vertical demand, `normalLoad - m*g - m*a_COM,z`; its final gap is approximately -mg/7. The hidden-path force is retained only as a constructed-control cross-check.

## Acceptance criteria

The model continuously asserts guide vertical force below 1e-7 N, force residual below 1e-3 N, body-plus-contact energy residual below 1e-6 J, contact identity below 1e-6 W and non-tensile normal forces. At 0.74 s support must be within 1% of weight and shares within 1e-8 of one-third. Stop time is 0.75 s.

After the release suite and tutorial, run:

```sh
node scripts/check_contracts.mjs --release results/release-01 --tutorial results/tutorial-01 --out results/external-01.json
```

The external checker checks eight selected contracts, recomputes force/energy identities from CSV where applicable, and rejects a wrong value, missing channel, nonfinite value and truncated time coverage. It is separate code, not an independent research group.

Change parameters only in separately named experiments. Removing the guide creates a new initialization/balance problem requiring new tests; a guided PASS cannot certify unsupported standing. Changing contact-point count without rescaling aggregate stiffness changes the mechanical model, not merely resolution.