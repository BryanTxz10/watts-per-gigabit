# ADR-07: RAPL package as reference, external power as validation, Kepler as object of study

## Status

Proposed (pending G1 design review).

## Context

Hypothesis H3 questions the accuracy of Kepler's per-pod attribution in a
data-plane workload. Using Kepler as the primary measurement would be
circular. External power alone cannot separate CPU from NIC, memory and
board.

## Decision

- **Reference:** RAPL package energy, read by the project's own sampler at
  1 Hz with counter-wrap handling, independent of Kepler.
- **Validation:** external node power at ≥ 1 Hz — the Grid'5000 wattmeter
  through Kwollect (`wattmetre_power_watt`) or a wall meter on the home
  bench — covering what RAPL does not see.
- **Object of study:** Kepler. Its node total must match RAPL; its per-pod
  apportionment is compared to RAPL ΔP (TC-09).

## Consequences

- A dedicated RAPL sampler must be written and validated against `perf`
  (RM-01, TC-02).
- The sampler runs as root because recent kernels restrict `energy_uj`.
- Kepler results are reported as an error relative to RAPL ΔP, not used to
  compute UPF efficiency.

## Alternatives rejected

- **Kepler as primary measurement.** Circular with H3.
- **External power only.** Cannot attribute power to the CPU or the pod.
