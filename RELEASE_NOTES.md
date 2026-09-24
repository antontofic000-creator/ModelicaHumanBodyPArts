# Release notes: ModelicaHumanBodyPArts v0.10.0 RC1

## Baseline preservation
The previous v0.9.2 source remains unchanged. The publication candidate is a new source file with its own hash.

## Changes relative to v0.9.2
1. Added Contact.AuditedPlantarContact as a generic observer wrapper around the existing six-zone plantar contact.
2. Added heel, midfoot and forefoot normal-load outputs, heel share, support validity and broad-support status.
3. Added contact stored energy, dissipative loss, power-to-body and energy-identity diagnostics.
4. Corrected aggregate LoadedSupportBody elastic-energy and damping accounting so time-varying stiffness/damping scales are reflected in the totals.
5. Added actualStiffness and actualDamping outputs and an explicit modulation-power sign alias for aggregate ledgers.
6. Added three verification cases: known regional load, heel-unloading detection and gravity-loaded variable-impedance aggregate energy balance.

## Native verification
OpenModelica 1.27.1 / Modelica Standard Library 4.1.0:
- 45 runtime simulations PASS.
- 5 build-only fixtures PASS.
- Total: 50/50 registered cases PASS.
- New external contract checker PASS, including a deliberate-perturbation negative control.

## Limits
The release is mechanical software verification, not human validation. Contact regions are numerical zones. The library does not resolve plantar tissue pressure, individual muscle forces, cartilage stress, injury probability or respiratory physiology.

## License
Released under the MIT License. See LICENSE and THIRD_PARTY_NOTICES.md.