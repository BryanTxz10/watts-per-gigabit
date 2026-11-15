# Methodological plan

**Project:** watts-per-gigabit — energy per bit of open-source 5G UPFs on
Kubernetes.
**Author:** Bryan Cucho. **Version:** 0.1, 2026-11-14 (supersedes the
planning sections of the October 2026 design document).
**End goal:** a master's research paper (workshop or conference format,
venue to be chosen) and the accompanying master's report, backed by an open
method, tool and dataset. There is no external submission deadline; the
paper track runs over five to seven months from November 2026 (section 8).
A KubeCon EU 2027 talk is the dissemination vehicle for the practitioner
audience, not the paper deadline.

This document is the research plan. Requirements, architecture, test plan,
ADRs and the data dictionary are separate documents under `docs/` and
`data/`; this plan references them rather than repeating them.

---

## 1. Purpose, scope and research questions

### 1.1 Purpose

Deliver an open, reproducible method to measure how many joules it costs to
move one gigabit through an open-source 5G user-plane function (UPF) running
on Kubernetes, validated against a hardware reference (RAPL) and an external
power measurement, and use it to compare three UPF implementations on
identical hardware. The value is the comparison between UPFs and the
validation of the measurement chain, not the absolute watts.

### 1.2 Problem

European operators report energy savings in the 5G core with proprietary
software, but there is no open method to measure the same thing on
Kubernetes. Public comparisons of open-source UPFs measure throughput and
CPU, not energy. Kepler, the CNCF tool for per-pod energy attribution, has
not been validated on a telco data plane, whose work (interrupts, polling,
XDP, DPDK busy loops) is unlike the application workloads it was designed
around.

### 1.3 Scope

| In scope | Out of scope |
| --- | --- |
| User plane (UPF) under controlled load | Real RAN, radio, physical UEs |
| Three implementations: Open5GS UPF (kernel), eUPF (eBPF/XDP), OMEC/SD-Core UPF (DPDK / AF_PACKET) | Control-plane energy |
| Per-CPU-package, per-pod and whole-node energy | Multi-node UPF scaling |
| CPU-level mitigations (governor, C-states, core count) | Developing a new UPF |
| Two platforms: Grid'5000 (primary), home bench (secondary) | NICs above 25 GbE |

### 1.4 Research questions

| RQ | Question |
| --- | --- |
| RQ1 | How does the energy cost per bit of open-source UPFs differ on identical hardware, and how does it depend on load level and packet size? |
| RQ2 | How accurately does Kepler attribute power to a UPF pod in a data-plane workload, relative to RAPL ΔP and external power? |
| RQ3 | Which CPU-level configuration changes reduce UPF energy per bit without violating a loss/latency SLA? |
| RQ4 | Can an ETSI ES 203 539-style laboratory method be reproduced end to end with open-source tooling on Kubernetes? |

### 1.5 Working hypotheses

Inferred from the design document; to be sharpened after the integration
report (E3.4) and before the measurement campaign.

| ID | Hypothesis | Primary evidence |
| --- | --- | --- |
| H1 | UPFs differ markedly in idle and low-load power: a busy-polling data plane (DPDK) consumes close to its full-load power at 0 % load, while kernel and XDP paths are closer to proportional. | TC-01, TC-06, TC-08 at 0–10 % |
| H2 | Energy per bit decreases with load and with packet size for all UPFs, but the ranking between UPFs changes across the load range and between 128 B and 1400 B packets. | TC-08, TC-11 |
| H3 | Kepler's per-pod attribution deviates substantially from RAPL ΔP for data-plane pods, in different directions for interrupt-driven and busy-polling UPFs, because its model apportions by CPU time. | TC-09 |
| H4 | Kernel-level CPU settings (governor, C-state depth, UPF core count) change ΔP by an amount comparable to the difference between UPFs, with a measurable p99 latency cost. | TC-10 |

### 1.6 Expected contributions

1. An open method and harness (Apache-2.0) that runs one ETSI-style
   measurement point end to end on Kubernetes and refuses to produce
   unreproducible data.
2. A validated dataset (CC BY 4.0) of UPF power, throughput, loss and latency
   on server-class hardware, with RAPL package energy cross-checked against
   node power from the platform's dedicated wattmeter.
3. The first error analysis of Kepler per-pod attribution on a telco data
   plane, reported as a reproducible issue to the Kepler maintainers.
4. Findings on CPU-level mitigations with their SLA cost, reported to the UPF
   maintainers.

---

## 2. Research design

A **comparative, within-subject experimental study**: every UPF is measured
on the same two nodes, with the same traffic, the same measurement chain and
a same-day baseline, so that hardware and environment are held constant and
only the UPF (and later the CPU configuration) varies.

### 2.1 Variables

| Class | Variable | Levels / definition |
| --- | --- | --- |
| Independent | UPF | Open5GS, eUPF, OMEC/SD-Core |
| Independent | Load level | 0, 10, 25, 50, 100 % of the UPF's no-loss maximum (TC-07) or of the generator ceiling (TC-04), whichever is lower |
| Independent | Packet size (inner) | 128 B, 1400 B |
| Independent (stage 6) | CPU configuration | Governor, C-state depth, UPF core count |
| Dependent | ΔP | P_load − P_idle on RAPL package and on external power (W) |
| Dependent | Energy per bit | ΔP / throughput (J/Gbit) |
| Dependent | EER | ETSI ES 203 539 weighted efficiency (bit/J) |
| Dependent | EE_5GC | 3GPP TS 28.554 6.7.4.2 efficiency over UPF node energy (bit/J) |
| Dependent | Throughput, loss, p50/p99 latency | From generator, sink and probe |
| Dependent | Kepler attribution error | (P_Kepler,pod − ΔP_RAPL) / ΔP_RAPL |
| Controlled | Governor, turbo, C-states, pinning, hostNetwork, images by digest, same-day baseline | Fixed by Ansible and Helm; recorded in the manifest |
| Nuisance | Thermal drift, background processes, shared switch links (Grid'5000), ambient temperature | Controls in 2.2 |

### 2.2 Experimental controls

- Randomized run order with a recorded seed (RM-04).
- 2 min warm-up, 5 min steady-state window, cool-down; only the steady window
  is analysed.
- At least 3 repetitions per point; 5 where the spread exceeds 5 %.
- Same-day baseline before every session; on Grid'5000, inside the same OAR
  job as the runs it serves (RM-03).
- CPU temperature and frequency recorded at 1 Hz; ambient temperature where
  a thermometer exists.
- Median and range reported; a difference smaller than the repetition spread
  is not a finding.
- SLA check per point (TC-11); failing points are excluded from efficiency
  and reported separately.

---

## 3. Platforms

### 3.1 Grid'5000 — primary

Grid'5000 is the French large-scale testbed for experiment-driven research
in computer science. It is the platform for calibration and for every
published result (ADR-11). Facts below are taken from the Grid'5000 wiki
pages listed in section 10.

| Aspect | Plan | Source |
| --- | --- | --- |
| Reservation | OAR jobs with `-t deploy` (required by KaVLAN and Kadeploy), plus `-t exotic` only if the selected cluster requires it (neither `gros` nor `chirop` does); on `gros` the job pins nodes 41–76; short daytime jobs for development and the acceptance check; night/weekend advance reservations (`oarsub -r`) for the matrix, within the usage policy's daytime quota rules. | Grid5000:UsagePolicy, KaVLAN, Nancy:Hardware, Lille:Hardware |
| Node selection | Restricted to clusters with a **dedicated wattmeter** (`wattmetre_power_watt`) and **at least two usable Ethernet interfaces**: management on the first, N3 and N6 sharing the second (declared deviation from ADR-04, ADR-11). Candidates on paper: `gros-[41-76]` (Nancy, 2 × 25 G `mlx5_core`) and `chirop` (Lille, 2 × 25 G `bnxt_en`); `neowise` (Lyon) only as last resort (GPU idle power, second NIC without KaVLAN). The three-interface clusters (`servan`, `kinovis`, `vianden`) have no wattmeter and are rejected (ADR-11). The acceptance reservation before G1 selects the cluster. | Hardware ("Nodes with several Ethernet interfaces"), Nancy:Hardware, Lille:Hardware, Lyon:Hardware, Monitoring Using Kwollect |
| Isolation | N3 and N6 as two 802.1Q sub-interfaces of the second NIC in two KaVLAN **local** VLANs (or two subnets on one VLAN if only one is granted); management on the site production network, first NIC. Per-sub-interface (or per-subnet `nftables`) counters keep N3 and N6 separable. KaVLAN provides L2 isolation but **no performance isolation** — inter-switch links may be shared on hierarchical sites — so loss and p99 latency are recorded at every point. | KaVLAN |
| Power collection | `wattmetre_power_watt` (period 1000 ms; 20 ms on demand with `-t monitor='wattmetre_power_watt'` for selected runs) as the external reference, pulled from the Kwollect API for the job window and aligned to the 5 min steady window (≥ 300 samples per point). `bmc_node_power_watt` (5000 ms) is collected as a secondary cross-check, as the tutorial recommends; it is less precise and excludes PSU losses. | Energy consumption monitoring tutorial, Monitoring Using Kwollect |
| Reproducibility | Kadeploy3 environment pinned by name/version; OAR job ID, KaVLAN ID, node names and environment recorded in `manifest.yaml`. | Kadeploy / Getting Started |
| Obligations | Official acknowledgement in every publication; deposit in HAL in the "GRID5000" collaboration; usage reports on request. | Grid5000:UsagePolicy |

Workflow (diagram: [`figures/grid5000-workflow.mmd`](figures/grid5000-workflow.mmd)):
reserve → deploy → attach the second NIC (N3/N6 sub-interfaces) to the
VLAN(s) → configure with
`ansible/inventory/grid5000.yml` → baseline TC-01 → campaign → pull Kwollect
series → archive run directories off-node → release.

Risks: N3 and N6 share one NIC, so the shared link sets the load ceiling
and the sharing cost is part of every measurement; Nancy is a hierarchical
site with shared inter-switch links; the Kwollect metric table omits `gros`
for `wattmetre_power_watt` although the page notes list gros-[41-76];
`chirop` has only five wattmeter nodes; usage-policy limits on long weekday
jobs; no BIOS access (turbo/C-state control only through the kernel).
Mitigations: TC-04 ceiling measured on the shared link, identical sharing
for every UPF and a three-NIC cross-check on the home bench; advance
reservations, per-UPF jobs that fit one night, manifest-based resume;
`chirop` and `gros` as mutual fallbacks, decided by the acceptance job.

### 3.2 Home bench — secondary

Laptop generator plus a mini PC DUT with three Intel I226 ports and a smart
plug (ADR-02). Its role: develop and test the harness, UPF integration and
the calibration method between reservations; exercise BIOS-level mitigations
that Grid'5000 does not allow; cross-check the method on consumer hardware.
Its numbers are not published as findings.

Risks: budget (200–350 €), uncalibrated meter, 2.5 GbE ceiling, thermal
behaviour of a small enclosure.

### 3.3 Comparison

| Criterion | Grid'5000 | Home bench |
| --- | --- | --- |
| Hardware class | Server (`gros`: 1 × Intel Xeon Gold 5220, 2 × 25 GbE ConnectX-4 Lx; or `chirop`: 2 × Intel Xeon Platinum 8358, 2 × 25 GbE BCM57414) | Consumer mini PC, 2.5 GbE |
| External power | Dedicated wattmeter via Kwollect, 1 s (20 ms on demand); BMC at 5 s as cross-check | Smart plug, ~1 Hz, uncalibrated |
| RAPL | Expected (Intel Xeon); confirmed in acceptance job | Yes (verify on receipt) |
| Networks | Two NICs: management on the first, N3 and N6 sharing the second (VLANs/subnets) | Three dedicated NICs |
| BIOS control | No | Yes |
| Availability | Reservation windows, usage policy | Always |
| N3/N6 isolation | Two KaVLAN VLANs on one shared NIC, L2 only | Direct cables, one NIC each |
| Reproducibility by others | High (same cluster + Kadeploy env) | Medium (same model required) |
| Publication role | All published results | Method cross-check, development |

---

## 4. Measurement protocol

Instrumentation chain: [`figures/measurement-chain.mmd`](figures/measurement-chain.mmd);
details in [`architecture.md`](architecture.md), section 4.

| Source | What | Rate | Notes |
| --- | --- | --- | --- |
| RAPL sampler (own) | Package energy counter, wrap-corrected | 1 Hz | Validated against `perf` within 1 % (RM-01); runs as root |
| External power | Kwollect `wattmetre_power_watt` (Grid'5000) or wall meter (home) | 1 s / ≥ 1 Hz | Covers NIC, memory, board (RM-02) |
| BMC power (cross-check) | Kwollect `bmc_node_power_watt` (Grid'5000 only) | 5 s | Secondary; excludes PSU losses |
| Kepler | Node and pod power | Internal interval | Object of study; scrape aligned to its interval |
| Interface counters | N3 RX, N6 TX on the DUT; sink RX | 1 Hz | Throughput and loss |
| Latency probe | p50/p99 through the UPF | Per run | SLA input (TC-11) |
| chrony | Clock offset between nodes | Per run | Must be < 10 ms (RM-05) |

Run lifecycle (`make run-point`): apply CPU configuration and read it back →
check chrony offset → start samplers → warm-up 2 min → steady 5 min →
cool-down → fetch Prometheus and Kwollect series for the window → write
`manifest.yaml`, `series.csv.gz` → append one row to `results.csv`.
**Manifest-or-refuse:** no row is written if any manifest field is missing.
Data artifacts and the column dictionary: [`../data/README.md`](../data/README.md).

---

## 5. Test campaign

Full table in [`test-plan.md`](test-plan.md).

| Stage | Test cases | Pass criterion (summary) | Platform |
| --- | --- | --- | --- |
| 2 Calibration | TC-01 idle baseline, TC-02 source coherence, TC-03 known load, TC-04 generator ceiling | < 5 % idle variation; sampler vs perf < 1 %; stable wall−RAPL offset; ceiling per packet size | Both |
| 3 Integration | TC-05 end-to-end, TC-06 benchmark | PDU session and traffic at sink; packets sent = received | Home, then Grid'5000 |
| 4 Max rate | TC-07 | Highest no-loss rate or generator ceiling, 60 s final trial | Grid'5000 |
| 5 Matrix | TC-08 energy matrix, TC-11 SLA | Repetition variation < 5 %; SLA flags | Grid'5000 |
| 6 Analysis | TC-09 Kepler attribution, TC-10 mitigations | Reported, no threshold | Grid'5000 (+ home for BIOS-level TC-10) |

PFCP interoperability matrix (E3.3): Open5GS SMF × {Open5GS UPF, eUPF,
OMEC UPF} for association, session establishment and traffic; where the SMF
fails, pfcpsim replaces it and the UPF is tested in benchmark mode only. The
assumption that at least two of three UPFs work with the Open5GS SMF is a
gate-G3 condition.

---

## 6. Analysis plan

- **ΔP** per point: median over repetitions of (steady-window mean power −
  same-day idle baseline), on RAPL and on external power.
- **Energy per bit:** ΔP / measured throughput (J/Gbit).
- **EER (ETSI ES 203 539):** weighted per-level efficiency with weights
  0.2 (10 %), 0.5 (50 %), 0.3 (100 %) from Annex A, declared as an
  assumption; SLA-failing points excluded.
- **EE_5GC (3GPP TS 28.554 6.7.4.2):** 8 × (N3 UL + DL octets) / UPF node
  energy, with the caveat that node energy excludes the control plane.
- **Energy proportionality:** P_idle / P_max and the shape of P(load).
- **Kepler error:** (P_Kepler,pod − ΔP_RAPL) / ΔP_RAPL per point, plus Kepler
  node total vs RAPL as a sanity check.
- **Statistics:** median and range (min–max) over repetitions; effect sizes
  expressed relative to repetition spread; no inferential tests beyond that
  unless repetitions reach five per point.
- **Notebooks:** see [`../analysis/README.md`](../analysis/README.md).
- **Figures:** P vs load per UPF and packet size; J/Gbit vs load; EER bar
  chart; Kepler error vs load per UPF; TC-10 ΔP vs p99 scatter.

---

## 7. Validity and ethics

Threats and controls are tabulated in [`test-plan.md`](test-plan.md).
Declared deviations: ETSI ambient and meter requirements (on Grid'5000 the
wattmeter's accuracy class is reported from the testbed documentation when
available; at home an uncalibrated smart plug), N3 and N6 sharing one NIC on
Grid'5000 (ADR-04 relaxed by ADR-11), RFC 2544 frame-size count and software
generator.

- Only open-source software; all code Apache-2.0, data CC BY 4.0.
- Grid'5000 usage policy respected (queues, quotas, frontends for light
  tasks only, acknowledgement, HAL deposit).
- No personal data; subscriber identities are test values.
- The manuscript is written outside this repository until publication; if
  the venue requires double-blind review, the public repository is not
  linked in the submission and an anonymized archive is used instead.
- Negative or null results (e.g. Kepler error within noise) are reported.

---

## 8. Work plan and milestones

Effort assumption: ~6–8 h/week alongside the master's programme, plus
Grid'5000 night/weekend reservations for unattended campaign runs.
Diagram: [`figures/stages-and-gates.mmd`](figures/stages-and-gates.mmd).

| Stage | Deliverables | Gate | Status / target |
| --- | --- | --- | --- |
| 0 Initiation | E0.1 charter, E0.2 CFP proposal, E0.3 lab contact | — | Done, Oct 2026 |
| 1 Design | E1.1 requirements, E1.2 architecture, E1.3 ADRs (incl. ADR-11), E1.4 test plan, E1.5 data plan; **E1.7 Grid'5000 acceptance reservation** (design validation, see below) | G1: no open decision changes the platform; E1.7 passed | Drafts done Oct 2026; migrated to this repo Nov 2026; E1.7 and G1 in Nov 2026 |
| 2 Bench as code + calibration | E1.6/E2.1 home hardware acceptance; E2.2 `make bench-up` on both inventories; E2.3 calibration report (TC-01..TC-04) | G2: idle variation < 5 % on the primary platform | Dec 2026 |
| 3 5G core + smoke | E3.1 core as code; E3.2 smoke per UPF; E3.3 PFCP matrix; E3.4 integration report | G3: two UPFs with traffic, one busy-polling and one kernel/eBPF | Dec 2026–Jan 2027 |
| 4 Max rate | TC-07 per UPF and packet size | — | Jan 2027 |
| 5 Energy matrix | TC-08, TC-11 full randomized matrix on Grid'5000 | — | Feb 2027 |
| 6 Analysis + mitigations | TC-09, TC-10; notebooks; figures | — | Feb–Mar 2027 |
| Dissemination | Tagged release + Zenodo DOI; KubeCon EU 2027 talk (16–18 March) if the proposal is accepted — a dissemination milestone, not a deadline for the paper | — | Mar 2027 |
| Paper track | See below | — | Nov 2026–Apr/Jun 2027 |

**E1.7 — Grid'5000 acceptance reservation (before G1).** One short daytime
job per candidate cluster (`gros-[41-76]` and `chirop`, `-t deploy`) with a
minimal Kadeploy environment, to validate the design assumptions that no
wiki page can confirm: `wattmetre_power_watt` retrieved from Kwollect for
the job window on the DUT node, RAPL package energy readable on every
socket (`/sys/class/powercap`), `ethtool -i` and link state on both
interfaces, the second interface attached to KaVLAN with the N3 and N6
sub-interfaces, a native XDP program loaded on it, and
`bmc_node_power_watt` retrieved as cross-check. Pass: all six checks
succeed; among passing clusters the one with the lowest idle-power
variation is selected. Fail on both: `neowise` as last resort or reopen
ADR-11. The result is recorded in the logbook and G1 is held only after
it.

**Paper track (no external deadline; venue to be chosen).** Month-level
targets over five to seven months:

| Month | Paper-track milestone |
| --- | --- |
| Nov 2026 | Related-work reading list and bibliography started; research questions frozen with G1 |
| Dec 2026 | Method section drafted from `docs/methodology.md` and `docs/test-plan.md` after G2 |
| Jan 2027 | Full outline; candidate venues (workshop vs. conference) shortlisted with their next deadlines |
| Feb 2027 | Results section drafted as the matrix completes; figures from the notebooks |
| Mar 2027 | Complete first draft; internal review (advisor, lab); KubeCon talk as a dress rehearsal of the narrative |
| Apr 2027 | Revised draft; venue chosen; dataset and code frozen for a tagged release |
| May–Jun 2027 | Submission to the chosen venue; master's report finalized in parallel |

Gate rules: a gate that fails cuts scope rather than slips indefinitely — G3
minimum is two UPFs; the third UPF, the third packet size and the Multus
variant are the first items dropped.

---

## 9. Dissemination and reproducibility

- Tagged release of repository and dataset once the analysis is frozen,
  archived on Zenodo for a citable DOI (`CITATION.cff` updated with the
  DOI).
- Dataset under CC BY 4.0 with the data dictionary in `data/README.md`.
- Paper deposited in HAL in the GRID5000 collaboration with the official
  acknowledgement.
- Reproducible issue with data to the Kepler maintainers (TC-09).
- Results and exact configuration to the eUPF, OMEC/SD-Core and Open5GS
  maintainers.
- Logbook (`docs/logbook/`) as the audit trail of what was done, what failed
  and what was decided.

---

## 10. References

Standards and methods

- ETSI ES 203 539 V1.1.1 (2019), *Environmental Engineering (EE); Measurement
  method for energy efficiency of Network Functions Virtualisation (NFV) in
  laboratory environment*.
- 3GPP TS 28.554, *Management and orchestration; 5G end to end Key
  Performance Indicators (KPI)*, clauses 6.7.4.2 and 6.7.3.1.4.
- IETF RFC 8172 (2017), *Considerations for Benchmarking Virtual Network
  Functions and Their Infrastructure*.
- IETF RFC 2544 (1999), *Benchmarking Methodology for Network Interconnect
  Devices*.
- M. Nygard, *Documenting Architecture Decisions*, 2011.

Grid'5000 wiki (accessed 2026-11-14)

- Grid5000:UsagePolicy — <https://www.grid5000.fr/w/Grid5000:UsagePolicy>
- Energy consumption monitoring tutorial —
  <https://www.grid5000.fr/w/Energy_consumption_monitoring_tutorial>
- Monitoring Using Kwollect — <https://www.grid5000.fr/w/Monitoring_Using_Kwollect>
- KaVLAN — <https://www.grid5000.fr/w/KaVLAN>
- Hardware — <https://www.grid5000.fr/w/Hardware>
- Grenoble:Hardware — <https://www.grid5000.fr/w/Grenoble:Hardware>
- Luxembourg:Hardware — <https://www.grid5000.fr/w/Luxembourg:Hardware>
- Getting Started / Kadeploy — <https://www.grid5000.fr/w/Getting_Started>

Software

- Kepler — <https://github.com/sustainable-computing-io/kepler>
- Open5GS — <https://open5gs.org/>
- eUPF — <https://github.com/edgecomllc/eupf>
- OMEC / SD-Core UPF — <https://github.com/omec-project/upf>
- pfcpsim — <https://github.com/omec-project/pfcpsim>
- UERANSIM — <https://github.com/aligungr/UERANSIM>
- DPDK igc driver guide — <https://doc.dpdk.org/guides/nics/igc.html>
- k3s — <https://k3s.io/>
