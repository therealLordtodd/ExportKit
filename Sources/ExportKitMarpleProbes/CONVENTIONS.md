# ExportKitMarpleProbes — probe authoring conventions

These conventions are pattern-setting from the initial three probes
(`ExportKitRegistryProbe`, `ExportKitRoundTripProbe`,
`ExportKitImportWarningsProbe`) and mirror the canonical
CostGatePrimitiveMarpleProbes target.

## Naming

- Probe `name`: `export-kit.<aspect>` — names the aspect under test.
  Examples: `export-kit.registry`, `export-kit.round-trip`,
  `export-kit.import-warnings`.

## Logging discipline

- Probes do not log per-step or per-assertion. The `ProbeResult` is
  the structured contract.

## Assertions

- Each `ProbeAssertion.description` is part of the public contract.
  Tests pin **exact strings** when they need stability — avoid
  rephrasing in patches.
- Outcome rule: `assertions.allSatisfy(\.passed) ? .passed : .failed`.
- Always emit at least one assertion before returning, even on early-
  failure paths.

## Service construction

`ExportRegistry` is `@unchecked Sendable` (locked internally). Probes
construct their own registry inside `run` rather than reusing
`host.registry`. Reason: the registry is mutable shared state — running
probes against the host's registry would couple probe behavior to
whatever exporters/importers the host had registered. Probe-local
registries keep every run deterministic.

The probe-local `ProbeExporter` / `ProbeImporter` types in
`ExportKitRegistryProbe.swift` are reused by other probes in this
target — they implement the public protocol and round-trip the
fixture document via JSON-encoded payloads with no platform
dependency.

## Side effects

All current probes are pure (no host state mutation). Future probes
that need to reference `host.registry` (rather than constructing their
own) must document why and the residue they leave on the host.
