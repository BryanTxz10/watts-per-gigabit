# ADR-09: Fixed CPU configuration in the baseline

## Status

Proposed (pending G1 design review).

## Context

Default power management (ondemand/schedutil governor, turbo enabled,
deep C-states) makes power a function of frequency decisions taken by the
kernel and firmware, not only of the UPF's work. Comparing UPFs under
varying frequency is noisy.

## Decision

Baseline runs (TC-01..TC-09) use the `performance` governor with turbo
disabled and a fixed C-state policy. These parameters are varied only in the
mitigation stage (TC-10, H4), where the applied and read-back values are
recorded for every run (RF-06).

## Consequences

- Baseline figures are not those of a default machine, and the report says
  so.
- On Grid'5000, BIOS-level settings are not user-configurable; the
  controllable surface is kernel-level (governor, `intel_idle` max C-state,
  `intel_pstate` no-turbo), which the manifest records.

## Alternatives rejected

- **Default settings.** Variable frequency adds noise to every comparison.
