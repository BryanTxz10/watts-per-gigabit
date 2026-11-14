# ADR-11: Grid'5000 as primary measurement platform, home bench as secondary

## Status

Proposed (2026-11-14; node-selection rule fixed the same day). Amends
[ADR-02](0002-dedicated-mini-pc-as-dut.md) and
[ADR-04](0004-three-physical-networks.md). Becomes *Accepted* once the
acceptance reservation (decision 6) passes.

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

- *Energy consumption monitoring tutorial*: power is exposed through
  Kwollect from three device classes — dedicated wattmeters
  (`wattmetre_power_watt`, period 1000 ms, optional 20 ms on demand, "high
  relative precision"), PDUs (less precise) and BMCs (`bmc_node_power_watt`,
  period 5000 ms, less precise than PDUs and located downstream of the power
  supply, so PSU losses are not included). The tutorial recommends
  cross-checking devices.
- *Monitoring Using Kwollect*, metric availability table:
  `wattmetre_power_watt` is available on `chirop` (Lille), `gemini`,
  `hydra`, `neowise`, `nova`, `orion`, `pyxis`, `sagittaire`, `sirius`,
  `taurus` (Lyon), `paradoxe` (Rennes) and, per the page notes, nodes
  gros-[41-76] (Nancy). `bmc_node_power_watt` is available on, among others,
  `servan` and `kinovis` (Grenoble) and `vianden` (Luxembourg);
  `pdu_outlet_power_watt` exists for `kinovis`.
- *KaVLAN*: local, routed and global VLAN types; full L2 isolation but **no
  performance isolation** (inter-switch links may be shared on hierarchical
  sites such as Nancy). Requires `-t deploy` jobs.
- *Hardware*, "Nodes with several Ethernet interfaces", and the Grenoble and
  Luxembourg hardware pages: most multi-NIC clusters expose exactly two
  interfaces (e.g. `gros` 2 × 25 Gbps, `neowise`, `ecotype`, `parasilo`
  2 × 10 Gbps). Exactly three clusters expose three usable Ethernet
  interfaces:

  | Cluster | Site, access | Nodes | Usable interfaces (driver) | CPU | Power metrics in Kwollect |
  | --- | --- | --- | --- | --- | --- |
  | `servan` | Grenoble, `-t exotic` | 2 | 25 G + 2 × 10 G, Intel E810 (`ice`) | 2 × AMD EPYC 7352 | BMC only |
  | `kinovis` | Grenoble, `abaca` production queue | 6 | 2 × 25 G Broadcom BCM57414 (`bnxt_en`) + 100 G Mellanox ConnectX-6 (`mlx5_core`) | 2 × Intel Xeon Gold 6442Y; 2 × L40S GPU | BMC and PDU |
  | `vianden` | Luxembourg, `-t exotic` | 1 | 100 G ConnectX-6 Dx (`mlx5_core`) + 2 × 10 G BCM57504 (`bnxt_en`) | 2 × Intel Xeon Platinum 8470; 8 × MI300X GPU | BMC only |

  **None of the three has a dedicated wattmeter.** Every wattmeter-equipped
  cluster exposes at most two Ethernet interfaces.
- *Grid5000:UsagePolicy*: publications must carry the official
  acknowledgement and be deposited in HAL in the "GRID5000" collaboration;
  daytime jobs on weekdays are limited and large jobs belong to nights and
  weekends; the production (`abaca`) queue has its own access rules.

## Decision

1. **Grid'5000 is the primary platform** for the calibration (TC-01..TC-04)
   and the measurement campaign (TC-07..TC-11). Results intended for
   publication come from Grid'5000 runs.
2. **The home mini-PC bench is secondary**: a development and calibration
   bench where the harness, UPF integration and the measurement method are
   built and exercised between reservations, and a consumer-hardware
   cross-check of the method. Its results are not published as findings.
3. **Node selection is restricted to clusters with three usable Ethernet
   interfaces**, so that management, N3 and N6 each keep a dedicated NIC as
   in ADR-04. Within that set the criteria are:
   - Intel or AMD CPU exposing RAPL package energy in `/sys/class/powercap`;
   - N3/N6 drivers that support native XDP and have a DPDK poll-mode driver
     (`ice`, `mlx5_core` and `bnxt_en` all qualify on paper; confirmed in
     the acceptance job);
   - both nodes of the pair on the same cluster and, where possible, the
     same switch;
   - node power reachable through Kwollect (`bmc_node_power_watt` at
     minimum).

   Applied to the three candidates: `servan` is the working candidate (two
   nodes, exactly the pair needed, Intel E810 NICs, no accelerators that
   would add idle-power noise). `kinovis` is a fallback subject to access to
   the `abaca` production queue and to the idle power of its two L40S GPUs.
   `vianden` is excluded: a single node cannot host the generator and the
   DUT, and its eight MI300X accelerators dominate node power.
4. **External power source on Grid'5000 is `bmc_node_power_watt`** (5 s
   period), because no three-interface cluster has a dedicated wattmeter.
   RAPL remains the primary energy signal (ADR-07); BMC power is the
   external validation series and is aligned to the 5 min steady window
   (≥ 60 samples per point). The home bench keeps the wall meter.
5. **Workflow** per session: reserve (OAR, `-t deploy -t exotic`, KaVLAN
   resource, night or weekend walltime for the matrix) → deploy (Kadeploy3
   environment pinned by name and version) → attach N3/N6 interfaces to the
   VLAN → configure (`ansible -i inventory/grid5000.yml`) → baseline TC-01
   within the same job → campaign → pull Kwollect series for the job window
   → archive run directories off-node → release.
6. **Acceptance reservation before G1.** A first short job on the working
   candidate validates the design before the gate: RAPL package counters
   readable on both sockets, `ethtool -i` on the three interfaces, a native
   XDP program loaded on the N3 NIC, `bmc_node_power_watt` retrieved from
   Kwollect for the job window, and the KaVLAN attach procedure. The outcome
   is recorded in the logbook and in this ADR's status.
7. **Obligations**: the official Grid'5000 acknowledgement appears in every
   publication and in the README; publications are deposited in HAL in the
   GRID5000 collaboration; usage reports are provided on request.

## Consequences

- External validity improves: server-class hardware and a dedicated NIC per
  network, as the architecture requires; the ambient-temperature deviation
  from ETSI ES 203 539 remains.
- **The external meter is coarser than hoped.** BMC power has a 5 s period,
  is documented as less precise than wattmeters and PDUs, and excludes PSU
  losses. Consequences: the ETSI deviation on meter accuracy is *not*
  removed; TC-03 (RAPL vs. external power) compares 5 min means, not
  sub-second traces; the J/Gbit headline figures rest on RAPL package energy
  with BMC as a plausibility check; and the limitation is declared in the
  report. The home wall meter stays as a second, independent cross-check of
  the method.
- **Availability risk.** `servan` has two nodes and requires `-t exotic`:
  one other user blocks the whole cluster, and the usage policy pushes
  multi-hour matrices to nights and weekends. Reservations are therefore
  placed in advance (`oarsub -r`), the campaign is split into per-UPF jobs
  that fit one night each, and the harness resumes from the manifest.
  `kinovis` sits in the `abaca` production queue, whose access and walltime
  rules differ from the default queue and must be confirmed before it is
  counted on.
- Reproducibility improves: Kadeploy environments and OAR job IDs are
  recorded in the manifest, so anyone with a Grid'5000 account can re-run a
  point on the same cluster.
- New constraints: no BIOS access (ADR-09 controls are kernel-level only);
  KaVLAN gives no performance isolation, so loss and p99 latency are
  recorded at every point (TC-11) and the pair is kept on one switch where
  possible; AMD RAPL on `servan` (Zen 2, `/sys/class/powercap/intel-rapl`
  via the kernel's AMD support) and Kepler's handling of it are verified in
  the acceptance job.
- New inventory `grid5000` and a pluggable power-source module in the
  harness (`kwollect` | `wall`); RNF-03 is now verified across three
  inventories.
- The home bench remains valuable: unlimited time, BIOS control (true turbo
  and C-state toggles for TC-10 exploration), and a consumer-hardware
  cross-check that strengthens the claim that the method, not the hardware,
  is the contribution.
- Timeline: the acceptance reservation is a prerequisite of G1, not a
  stage 2 task.

## Alternatives rejected

- **Two-interface wattmeter clusters** (`gros`, `neowise`, `paradoxe`,
  `chirop`, …) with N3 and N6 sharing the second NIC as 802.1Q
  sub-interfaces or two address families on one KaVLAN segment. It would
  have given a dedicated wattmeter (1 s, 20 ms on demand) but violates
  ADR-04: the N3 and N6 paths would share one NIC, driver, interrupt
  vectors and XDP hook, which is exactly the resource whose cost differs
  between UPF implementations. Rejected by the project owner on
  2026-11-14; a dedicated NIC per network takes precedence over meter
  resolution.
- **Home bench only.** Consumer hardware and an uncalibrated meter as the
  sole evidence base.
- **Grid'5000 only.** Development bound to reservation windows; no BIOS-level
  mitigation experiments; no way to work offline.
- **University lab servers as primary.** Not yet available; kept as the
  `lab` inventory for portability (RNF-03).
