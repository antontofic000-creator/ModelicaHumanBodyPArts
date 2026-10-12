# Documentation

ModelicaHumanBodyPArts is a reduced rigid-segment mechanical library, not a clinical model. Begin with the executable tutorial rather than treating a plausible animation as validation.

1. [Architecture and output map](architecture.md): locate components and measured interfaces.
2. [Guided-contact tutorial](guided-contact-tutorial.md): run a gravity-loaded integration example and read the signals.
3. [Verification contract](verification.md): distinguish assertions, completion checks, negative controls and interpretation limits.
4. [Contribution guide](../CONTRIBUTING.md): add a test without altering the archived source.

Load `../ModelicaHumanBodyPArts/package.mo` in OMEdit. The directory hierarchy and monolithic source are alternate storage representations of the same library; use only one in a compiler session. The package generator's round-trip checksum verifies storage identity. A package check is not cross-tool compatibility evidence.
