# ADR-11: Grid'5000 as primary measurement platform, home bench as secondary

## Status

Proposed (2026-11-14; node-selection rule revised twice the same day, see
logbook). Amends [ADR-02](0002-dedicated-mini-pc-as-dut.md) and
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
  cluster exposes at most two Ethernet interfaces. Among those, the site
  hardware pages (Nancy, Lille, Lyon, Rennes) show the following for
  clusters with two interfaces:

  | Cluster | Site, access | Nodes with wattmeter | Interfaces (driver) | CPU | Notes |
  | --- | --- | --- | --- | --- | --- |
  | `gros` | Nancy, default queue | gros-[41-76] (36 of 123) | 2 × 25 G Mellanox ConnectX-4 Lx (`mlx5_core`), both usable | 1 × Intel Xeon Gold 5220, 18 cores | Nancy is a hierarchical site (shared inter-switch links, KaVLAN page); the Kwollect metric table omits `gros` for `wattmetre_power_watt` while the page notes list gros-[41-76] — to confirm in the acceptance job |
  | `chirop` | Lille, default queue | 5 | 2 × 25 G Broadcom BCM57414 (`bnxt_en`), both usable | 2 × Intel Xeon Platinum 8358, 32 cores each | No accelerators |
  | `neowise` | Lyon, `-t exotic` | 10 | 2 × 10 G ConnectX-4 Lx (`mlx5_core`); `eth1` marked "no KaVLAN" | 1 × AMD EPYC 7642 | 8 × AMD MI50 GPUs add idle power; second NIC cannot join a KaVLAN |
  | `paradoxe` | Rennes, default queue | 64 | 25 G `bnxt_en`; `eth1` "unavailable for experiment" | 2 × Intel Xeon Gold 5320 | Excluded: one usable interface |

  All other wattmeter clusters (`gemini`, `hydra`, `nova`, `orion`,
  `pyxis`, `sagittaire`, `sirius`, `taurus`) expose a single Ethernet
  interface and are excluded.
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
3. **Node selection targets clusters with a dedicated wattmeter and at
   least two usable Ethernet interfaces.** Energy precision is the core of
   the study, so `wattmetre_power_watt` takes precedence over a dedicated
   NIC per network. Criteria within that set:
   - `wattmetre_power_watt` available for the DUT node (confirmed in
     Kwollect, not only on the wiki);
   - Intel or AMD CPU exposing RAPL package energy in `/sys/class/powercap`;
   - a second interface usable for experiments and attachable to KaVLAN,
     with a driver that supports native XDP and has a DPDK poll-mode driver
     (`mlx5_core`, `bnxt_en` qualify on paper; confirmed in the acceptance
     job);
   - no accelerators whose idle power would dominate the node;
   - both nodes of the pair on the same cluster and, where possible, the
     same switch.

   Candidates meeting the criteria on paper: `gros-[41-76]` (Nancy) and
   `chirop` (Lille). `neowise` is kept as a last resort (GPU idle power,
   `eth1` without KaVLAN). No cluster is final: the acceptance reservation
   (decision 6) selects it.
4. **N3 and N6 share the second interface; management stays on the first
   (declared deviation from ADR-04).** On the DUT and on the generator the
   second NIC carries two L3 subnets (`10.3.0.0/24` for N3,
   `10.6.0.0/24` for N6), either as two 802.1Q sub-interfaces in two KaVLAN
   local VLANs or, if only one VLAN is granted, as two subnets on one
   segment. The generator keeps the sink in the `dn` namespace (ADR-05) so
   N6 traffic still cannot short-circuit the UPF. Controls: per-subnet
   interface counters (sub-interface counters when VLANs are used, otherwise
   `nftables` counters keyed by subnet) keep N3 RX and N6 TX separable; the
   generator ceiling (TC-04) is measured on the shared link so the
   full-duplex budget — N3 inbound to the DUT and N6 outbound from it use
   opposite directions — is known; the shared NIC, driver, interrupt
   vectors and XDP hook are identical for every UPF, so the sharing cost is
   a constant of the platform, not a per-UPF bias, and is declared in the
   report.
5. **External power source on Grid'5000 is `wattmetre_power_watt`** (1 s;
   20 ms on demand with `-t monitor='wattmetre_power_watt'` for selected
   runs), with `bmc_node_power_watt` (5 s) as a secondary cross-check as the
   tutorial recommends. RAPL remains the primary energy signal (ADR-07). The
   home bench keeps the wall meter.
6. **Workflow** per session: reserve (OAR, `-t deploy`, `-t exotic` where
   the cluster requires it, KaVLAN resource, night or weekend walltime for
   the matrix) → deploy (Kadeploy3 environment pinned by name and version)
   → attach the second interface to the VLAN(s) → configure
   (`ansible -i inventory/grid5000.yml`) → baseline TC-01 within the same
   job → campaign → pull Kwollect series for the job window → archive run
   directories off-node → release.
7. **Acceptance reservation before G1.** One short job per candidate
   cluster validates the design before the gate: `wattmetre_power_watt`
   retrieved from Kwollect for the job window on the DUT node, RAPL package
   counters readable, `ethtool -i` on both interfaces, the second interface
   attached to KaVLAN with two sub-interfaces, a native XDP program loaded
   on it, and `bmc_node_power_watt` as cross-check. The cluster that passes
   with the lowest idle-power variation is selected; the outcome is recorded
   in the logbook and in this ADR's status.
8. **Obligations**: the official Grid'5000 acknowledgement appears in every
   publication and in the README; publications are deposited in HAL in the
   GRID5000 collaboration; usage reports are provided on request.

## Consequences

- External validity improves: server-class hardware and a dedicated
  wattmeter (1 s, 20 ms on demand, "high relative precision" per the
  tutorial) instead of a consumer plug. The ETSI deviation on meter accuracy
  is reduced (the wattmeter's accuracy class is reported from Grid'5000
  documentation when available); the ambient-temperature deviation remains.
- **ADR-04 is relaxed on Grid'5000.** N3 and N6 share one NIC; the sharing
  is identical for every UPF and is declared in the report. The home bench
  keeps three physical NICs, which gives a cross-check of whether sharing
  changes the ranking between UPFs (it must not, or the finding is
  reported).
- **Availability.** `gros` and `chirop` are in the default queue; the usage
  policy still pushes multi-hour matrices to nights and weekends, so
  reservations are placed in advance (`oarsub -r`), the campaign is split
  into per-UPF jobs that fit one night each, and the harness resumes from
  the manifest. On `gros` only nodes 41–76 qualify, so the reservation
  must pin the node range.
- Reproducibility improves: Kadeploy environments and OAR job IDs are
  recorded in the manifest, so anyone with a Grid'5000 account can re-run a
  point on the same cluster.
- New constraints: no BIOS access (ADR-09 controls are kernel-level only);
  KaVLAN gives no performance isolation, so loss and p99 latency are
  recorded at every point (TC-11) and the pair is kept on one switch where
  possible (Nancy is explicitly hierarchical).
- New inventory `grid5000` and a pluggable power-source module in the
  harness (`kwollect` | `wall`); RNF-03 is now verified across three
  inventories.
- The home bench remains valuable: unlimited time, BIOS control (true turbo
  and C-state toggles for TC-10 exploration), three physical NICs, and a
  consumer-hardware cross-check that strengthens the claim that the method,
  not the hardware, is the contribution.
- Timeline: the acceptance reservation is a prerequisite of G1, not a
  stage 2 task.

## Alternatives rejected

- **Three-interface clusters with BMC power as external reference**
  (`servan`, with `kinovis` and `vianden` as the only other three-interface
  clusters). It would have kept ADR-04 intact, but no three-interface
  cluster has a dedicated wattmeter: the external reference would be
  `bmc_node_power_watt` at 5 s, documented as less precise than wattmeters
  and PDUs and excluding PSU losses. Energy precision is the core of the
  study, whereas NIC sharing is a deviation that is easy to declare and to
  control (same NIC for every UPF, per-subnet counters, TC-04 ceiling on
  the shared link). Chosen on 2026-11-14, reversed by the project owner the
  same day in favour of the wattmeter. `servan` additionally has only two
  nodes behind `-t exotic`, `kinovis` is in the restricted `abaca` queue
  and `vianden` has a single node.
- **Home bench only.** Consumer hardware and an uncalibrated meter as the
  sole evidence base.
- **Grid'5000 only.** Development bound to reservation windows; no BIOS-level
  mitigation experiments; no way to work offline.
- **University lab servers as primary.** Not yet available; kept as the
  `lab` inventory for portability (RNF-03).
