# harness/

The Python harness that runs one measurement point end to end (RF-05): applies
the CPU configuration, starts the samplers, drives the generator, trims the
steady-state window, writes `manifest.yaml`, `series.csv.gz` and one row of
`data/results.csv`.

## Status

Scaffolding only. `pyproject.toml` holds metadata; no code yet. Implementation
starts in stage 2 with the RAPL sampler (RM-01) and continues through
stage 5.

## Planned components

| Module | Responsibility | Requirement |
| --- | --- | --- |
| `rapl_sampler` | Reads `/sys/class/powercap/intel-rapl:0/energy_uj` at 1 Hz, handles counter wrap, cross-checked against `perf` within 1 %. Runs as root. | RM-01, TC-02 |
| `power_source` | Pluggable external power reader: Kwollect API (`wattmetre_power_watt`, plus `bmc_node_power_watt` as cross-check) on Grid'5000, HTTP smart plug at home. | RM-02 |
| `prom_fetch` | Pulls Kepler pod/node power and node-exporter series from Prometheus for the steady window. | TC-09 |
| `pcap_gen` | Scapy generator of GTP-U pcaps at 128 B and 1400 B inner payloads for the benchmark mode. | RF-03, RF-04 |
| `traffic` | Drives `tcpreplay` (benchmark) or `iperf3` through UERANSIM (end-to-end); reads generator and sink counters. | RF-02, RF-03 |
| `latency_probe` | p50/p99 one-way or round-trip latency through the UPF. | TC-11 |
| `run_point` | Orchestrates warm-up (2 min), steady window (5 min), cool-down; randomized order with recorded seed; refuses to write a results row if any manifest field is missing. | RM-04, RM-06 |

## Rules

- Raw series are never edited; derived metrics (ΔP, J/Gbit, EER, EE, Kepler
  error) are computed in `analysis/`, not here.
- The harness records both the value it applied and the value it read back
  from the system for every CPU parameter (RF-06).
