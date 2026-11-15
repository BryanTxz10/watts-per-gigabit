# ADR-02: Dedicated x86 mini PC with ≥ 3 Intel I226 ports as DUT

## Status

Amended by [ADR-11](0011-grid5000-as-primary-measurement-platform.md): the
mini PC is the **secondary** development and calibration bench; Grid'5000 is
the primary measurement platform. Originally proposed October 2026.

## Context

A laptop is a poor device under test: battery management, turbo behaviour
and thermal throttling vary power independently of the workload. The
decisive component is the NIC: Intel I225/I226 controllers work with the
DPDK `igc` poll-mode driver and with the Linux `igc` driver, which has
native XDP and AF_XDP support, so all three UPF data-plane technologies
(kernel, eBPF/XDP, DPDK) can be tested on the same hardware.

## Decision

Use a dedicated, fanless or fixed-fan x86 mini PC with RAPL exposed in
`/sys/class/powercap`, ≥ 4 cores, 16 GB RAM, NVMe storage and three Intel
I225/I226 ports (management, N3, N6). RAPL, NICs and BIOS options are
verified on receipt within the return window (E2.1).

## Consequences

- Budget of roughly 200–350 € (RNF-04).
- A full bench that fits in a bag and can be carried to a lab.
- With ADR-11 the mini PC is where the harness, the UPF integration and the
  calibration method are developed before each Grid'5000 reservation, and
  where the method is cross-checked on consumer-class hardware.

## Alternatives rejected

- **The laptop as DUT.** Battery, turbo and thermal control add noise.
- **A desktop PC.** More expensive and not portable.
