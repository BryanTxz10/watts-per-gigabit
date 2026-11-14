# ADR-11: Grid'5000 as primary measurement platform, home bench as secondary

## Status

Proposed (2026-11-14). Amends [ADR-02](0002-dedicated-mini-pc-as-dut.md) and
[ADR-04](0004-three-physical-networks.md).

## Context

The October 2026 design assumed a self-funded bench: a laptop as generator
and a mini PC as DUT, with a consumer smart plug as the external power
reference. Its declared deviations from ETSI ES 203 539 were the lack of a
calibrated meter and of a controlled environment, and its external-validity
threat was that a 2.5 GbE mini PC is not an operator-class server.

The project now has an account on
[Grid'5000](https://www.grid5000.fr/), the French large-scale testbed for
experiment-driven research in computer science. Verified on the Grid'5000
wiki:

- *Energy consumption monitoring tutorial*: some clusters have per-node
  wattmeters exposed through Kwollect as `wattmetre_power_watt` (period
  1000 ms, optional 20 ms on demand) and `bmc_node_power_watt` (period
  5000 ms, less precise). The tutorial recommends cross-checking devices.
- *Monitoring Using Kwollect*: wattmeters exist on some clusters in Lyon,
  Grenoble and Nancy (on Nancy's `gros` cluster only nodes gros-[41-76]).
- *KaVLAN*: local, routed and global VLAN types; full L2 isolation but **no
  performance isolation** (inter-switch links may be shared on hierarchical
  sites such as Nancy). Requires `-t deploy` jobs.
- *Hardware*, "Nodes with several Ethernet interfaces": most multi-NIC
  clusters expose exactly two interfaces (e.g. `gros` 2 × 25 Gbps,
  `neowise`, `ecotype`, `parasilo` 2 × 10 Gbps); a few expose three (e.g.
  `servan`, `kinovis` in Grenoble; `vianden` in Luxembourg).
- *Grid5000:UsagePolicy*: publications must carry the official
  acknowledgement and be deposited in HAL in the "GRID5000" collaboration;
  daytime jobs on weekdays are limited and large jobs belong to nights and
  weekends.

## Decision

1. **Grid'5000 is the primary platform** for the calibration (TC-01..TC-04)
   and the measurement campaign (TC-07..TC-11). Results intended for
   publication come from Grid'5000 runs.
2. **The home mini-PC bench is secondary**: a development and calibration
   bench where the harness, UPF integration and the measurement method are
   built and exercised between reservations, and a consumer-hardware
   cross-check of the method. Its results are not published as findings.
3. **Node selection criteria** (no cluster is fixed yet):
   - per-node wattmeter reachable through Kwollect (`wattmetre_power_watt`);
   - Intel or AMD CPU exposing RAPL package energy in `/sys/class/powercap`;
   - preferably ≥ 3 Ethernet interfaces (management, N3, N6) with drivers
     that support native XDP and have a DPDK poll-mode driver (`igc`,
     `ixgbe`, `i40e`, `ice`, `mlx5` class);
   - both nodes of the pair on the same cluster and, where possible, the
     same switch.
   Candidates are verified against the Hardware and site Network pages and
   recorded in the logbook before the first reservation.
4. **Two-interface fallback.** If no wattmeter-equipped cluster offers three
   interfaces, N3 and N6 share the second interface as two 802.1Q
   sub-interfaces or two address families on one KaVLAN segment, management
   stays on the first interface, and the deviation is declared in the report
   (RX on N3 and TX on N6 use opposite directions of a full-duplex link, so
   unidirectional downlink capacity is not halved, but the NIC and driver are
   shared).
5. **Workflow** per session: reserve (OAR, `-t deploy`, KaVLAN resource,
   night or weekend walltime for the matrix) → deploy (Kadeploy3 environment
   pinned by name and version) → attach N3/N6 interfaces to the VLAN →
   configure (`ansible -i inventory/grid5000.yml`) → baseline TC-01 within
   the same job → campaign → pull Kwollect series for the job window →
   archive run directories off-node → release.
6. **External power source** is the Kwollect wattmeter series, with
   `bmc_node_power_watt` as a cross-check; the home bench keeps the wall
   meter.
7. **Obligations**: the official Grid'5000 acknowledgement appears in every
   publication and in the README; publications are deposited in HAL in the
   GRID5000 collaboration; usage reports are provided on request.

## Consequences

- External validity improves: server-class hardware and a laboratory-grade
  wattmeter instead of a consumer plug; the ETSI deviation on meter accuracy
  is reduced (the wattmeter's accuracy class is reported from Grid'5000
  documentation), while the ambient-temperature deviation remains.
- Reproducibility improves: Kadeploy environments and OAR job IDs are
  recorded in the manifest, so anyone with a Grid'5000 account can re-run a
  point on the same cluster.
- New constraints: no BIOS access (ADR-09 controls are kernel-level only);
  reservation windows and the usage policy shape the schedule; KaVLAN gives
  no performance isolation, so loss and p99 latency are recorded at every
  point (TC-11) and the pair is kept on one switch where possible.
- New inventory `grid5000` and a pluggable power-source module in the
  harness (`kwollect` | `wall`); RNF-03 is now verified across three
  inventories.
- The home bench remains valuable: unlimited time, BIOS control (true turbo
  and C-state toggles for TC-10 exploration), and a consumer-hardware
  cross-check that strengthens the claim that the method, not the hardware,
  is the contribution.
- Timeline: node-selection verification and a first short reservation
  (RAPL, drivers, XDP load, Kwollect query) are added to stage 2.

## Alternatives rejected

- **Home bench only.** Consumer hardware and an uncalibrated meter as the
  sole evidence base.
- **Grid'5000 only.** Development bound to reservation windows; no BIOS-level
  mitigation experiments; no way to work offline.
- **University lab servers as primary.** Not yet available; kept as the
  `lab` inventory for portability (RNF-03).
