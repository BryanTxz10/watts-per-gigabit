# Requirements specification (E1.1)

Eighteen requirements in three groups. Each one has a verification that can
pass or fail. The last column names the working hypothesis
(see [`methodology.md`](methodology.md), section 1) that would be left without
evidence if the requirement fails.

Status: baseline from the October 2026 design document, amended for
Grid'5000 as primary platform (ADR-11). Amendments are marked **(ADR-11)**.

## Functional (RF)

| ID | Requirement | Verification | Hypotheses |
| --- | --- | --- | --- |
| RF-01 | One UPF active at a time, swappable without touching control plane, traffic or measurement | Switching UPF changes only the UPF's Helm values, visible in the repository diff | H1–H4 |
| RF-02 | End-to-end mode with a real PDU session | UERANSIM obtains a session and iperf3 traffic crosses the tunnel | H2, H4 |
| RF-03 | Benchmark mode without an SMF | pfcpsim creates 100 sessions and the UPF forwards the GTP-U pcaps | H1–H3 |
| RF-04 | Fixed-rate load at 0, 10, 25, 50 and 100 % of the maximum, with 128 B and 1400 B packets | Rate measured at the sink is within ±2 % of the offered rate below the maximum | H1, H2 |
| RF-05 | One command runs a complete point and writes one row to the results CSV with its metadata | Row contains every column of the data schema, no blanks | H1–H4 |
| RF-06 | CPU parameters variable between runs (governor, idle states, UPF cores) | Run manifest records both the applied value and the value read back from the system | H4 |

## Non-functional (RNF)

| ID | Requirement | Verification | Hypotheses |
| --- | --- | --- | --- |
| RNF-01 | Reproducible from scratch with infrastructure as code and pinned versions | Reinstall both hosts and re-measure one point within 5 % | H1–H4 |
| RNF-02 | DUT isolation: the DUT runs only the UPF and the measurement agents | `kubectl` shows only the allowed pods on that node | H1–H3 |
| RNF-03 | Portable across platforms by changing only inventory and values **(ADR-11: Grid'5000, home, lab)** | The same playbook runs against the `grid5000` and `home` inventories without editing roles | All, indirectly |
| RNF-04 | Secondary bench cost within budget (200–350 €) | Total of the purchase list | None |
| RNF-05 | All software open source; everything published under an open license | Licenses listed in the README | None |
| RNF-06 | Private management network; AMF, SMF and Prometheus not exposed outside the bench **(ADR-11: inside the KaVLAN / Grid'5000 site network)** | Port scan from outside the management network | None |

## Measurement (RM)

| ID | Requirement | Verification | Hypotheses |
| --- | --- | --- | --- |
| RM-01 | Energy reference is RAPL package, sampled at 1 Hz with counter-wrap handling | Own sampler and `perf` agree within 1 % over 10 minutes | H1–H4 |
| RM-02 | External validation with a power meter at ≥ 1 Hz **(ADR-11: Grid'5000 wattmeter via Kwollect, 1 s period, with BMC power as secondary cross-check; wall meter at home)** | External power series present in every validation run | H2, H3 |
| RM-03 | Baseline measured the same day, before each session **(Grid'5000: within the same OAR job)** | Baseline run with the day's date in the CSV | H1–H4 |
| RM-04 | Two minutes of warm-up, five-minute steady window, at least three repetitions, randomized order | Harness records the order seed and the timestamps of each phase | H1–H4 |
| RM-05 | Clocks of both hosts synchronized | chrony reports an offset below 10 ms | H1–H4 |
| RM-06 | Conditions recorded for every run (kernel, versions, governor, turbo, CPU temperature) | Complete run manifest | H1–H4 |

## Traceability to hypotheses

| Hypothesis | Requirements that provide its evidence |
| --- | --- |
| H1 idle / core usage | RF-01, RF-03, RF-04, RF-05, RNF-01, RNF-02, RM-01..RM-06 |
| H2 energy vs load and packet size | RF-01..RF-05, RNF-01, RNF-02, RM-01..RM-06 |
| H3 Kepler attribution accuracy | RF-01, RF-03, RF-05, RNF-01, RNF-02, RM-01..RM-06 |
| H4 CPU-level mitigations | RF-01, RF-02, RF-05, RF-06, RNF-01, RM-01, RM-03..RM-06 |
