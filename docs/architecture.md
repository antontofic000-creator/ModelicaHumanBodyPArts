# Architecture and output map

The 19 top-level packages preserve the original qualified names. The conversion separates packages, not individual leaf classes, and changes no equations. `scripts/package_tree.mjs --check` reconstructs the source and requires its archived SHA-256.

| Packages | Responsibility | Examples |
|---|---|---|
| Types, Records, Data, Scaling | Parameter types, provenance and mass-property reconstruction | AnthropometryProfile, SegmentProperties, SegmentProperties3D, resolveSegment |
| Base, Segments, Joints | Mechanical interfaces, rigid links and permitted coordinates | Foot, Shank, Thigh, Hip, AnkleComplex |
| Sensors, Contact | Measurements, unilateral contact and wrench/regional observers | ContactPoint, PlantarContact, AuditedPlantarContact, GroundWrenchSensor |
| Assemblies, AxialBody, Transmission | Composable lower/axial bodies, impedance and work/load outputs | PelvicRing, LumbarSpine3D, impedance and spatial-wrench components |
| SupportInitiation | Loaded bilateral body and bounded experiments | LoadedSupportBody, M2bBaseline |
| Examples, Tests, Utilities, BuildFixtures, Benchmarks, CanonicalReplay | Examples, assertions, utilities and fixtures | Named roots in tests/v010_test_manifest.json |

Connections exchange position, orientation, force and moment; they are not one-way signal flow. A support constraint and a compliant contact component answer different questions. The complete tutorial connects the selected foot's six plantar frames to the audited contact and declares every guide constraint.

A cut wrench requires a receiving body, moment reference point and coordinate basis. Generalized power is effort times its conjugate coordinate rate; spatial power is force dotted with cut-point velocity plus moment dotted with angular velocity. Repeated serial cut powers must not be added as independent energy inputs.

`AuditedPlantarContact` inherits ground-wrench outputs and adds `heelLoad`, `midfootLoad`, `forefootLoad`, `heelShare`, `storedEnergy`, `lossPower`, `powerToBody` and `identityResidual`. Six points are numerical locations, not anatomical pressure masks. `supportValid` uses a 1 N total-load threshold; `broadSupport` additionally requires each regional pair to exceed 0.1 N. These are diagnostics, not validated balance criteria.

The tutorial exposes `normalLoad`, `guideVerticalForce`, `forceResidual`, `energyResidual`, `dissipated` and `regionalShares`. Positive normal force acts upward on the body. Force balance uses whole represented-body centre-of-mass acceleration, not joint or foot acceleration.

Parameter provenance identifies a coefficient's source, not its applicability to another population. The tutorial represents 62.79 kg rather than the nominal 75 kg profile. Normalize by the represented mass.
