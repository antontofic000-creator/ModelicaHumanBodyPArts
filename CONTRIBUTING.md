# Contributing

Open an issue or pull request with the research question, active topology, receiving body/frame for each output, numerical target, tolerance and interpretation limit. Supply a known answer and negative control where appropriate. Add experiments to a separate manifest rather than silently changing the archived v0.10.0 inventory.

The archived source is immutable. The package tree is generated storage, not a separately edited implementation. Mechanical changes require a new version/hash; do not disable the identity gate to make an old release appear to pass.

Use Node.js 22, OpenModelica 1.27.1 and Modelica Standard Library 4.1.0. Preserve failed logs and choose a new directory for a documented retry. Never relax a numerical threshold merely to obtain a green badge. Compare cross-platform outputs by named signals and declared tolerances, not floating-point file-byte equality.
