# ADR-08: Two traffic modes

## Status

Proposed (pending G1 design review).

## Context

UERANSIM gives realistic end-to-end PDU sessions but its TUN-based user plane
limits the generator's rate. A pure benchmark mode with pre-built GTP-U pcaps
removes the generator bottleneck but needs a way to install sessions in the
UPF without an SMF. TRex would be the ideal generator but needs DPDK-capable
NICs on the generator.

## Decision

Support two modes with the same harness and the same results schema:

- **End-to-end (`e2e`):** UERANSIM gNB and UE, Open5GS SMF, iperf3 through
  the tunnel (RF-02, TC-05).
- **Benchmark (`bench`):** pfcpsim installs 100 sessions; Scapy builds GTP-U
  pcaps at 128 B and 1400 B inner payloads; tcpreplay replays them at a
  controlled rate on N3 (RF-03, RF-04, TC-06..TC-08).

## Consequences

- The generator ceiling is measured (TC-04) and declared per packet size.
- TRex becomes an option on Grid'5000 nodes whose NICs support DPDK
  (ADR-11), which would raise the ceiling for TC-07.

## Alternatives rejected

- **UERANSIM only.** Generator-bound.
- **TRex only.** Requires DPDK NICs on the home generator.
