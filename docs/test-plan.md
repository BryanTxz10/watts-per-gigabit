# Test plan (E1.4)

The plan follows the laboratory method of ETSI ES 203 539, reports efficiency
as defined by 3GPP TS 28.554, and takes the isolation, duration and reporting
rules from IETF benchmarking RFCs, so that results speak the same language as
an operator's energy team.

## Reference standards

| Standard | What is taken | Where it applies |
| --- | --- | --- |
| ETSI ES 203 539 (2019) | VNF power as power under load minus power without the VNF deployed. Efficiency per load level and weighted. SLA check at each level. Minimum report content. | ΔP, load levels, TC-11, campaign report |
| 3GPP TS 28.554, 6.7.4.2 | 5GC energy efficiency in bit/J, with N3 uplink and downlink volume as useful output. | Metric reported alongside J/Gbit |
| 3GPP TS 28.554, 6.7.3.1.4 | VNF energy estimated from its share of mean vCPU usage over measured node energy. | Same attribution principle Kepler uses; TC-09 tests it on a data plane (H3) |
| IETF RFC 8172 (2017) | Generator shares no resources with the DUT. Internal metrics corroborated by external observation. Full platform configuration in the report. Isolated test network. | ADR-01, ADR-04, ADR-07, ADR-11, run manifest |
| IETF RFC 2544 (1999) | Throughput as the highest rate with no loss, final trials ≥ 60 s, several frame sizes. | TC-04, TC-07 |

## Normalized metrics

ETSI's per-level efficiency is the inverse of energy per bit, so the protocol
does not change, only how results are reported. Level weights follow the
example in Annex A of the standard (0.2 for 10 %, 0.5 for 50 %, 0.3 for 100 %)
and are declared as an assumption.

$$
\mathrm{EER}_{\mathrm{UPF}} =
  \sum_{i=1}^{N} w_i \cdot \frac{U_i}{P_{i,\mathrm{load}} - P_{\mathrm{idle}}}
  \quad [\mathrm{bit/J}]
$$

The 3GPP metric uses N3 volume and total energy, not incremental energy. On
this bench the energy is that of the UPF node without the control plane, and
the report says so.

$$
\mathrm{EE}_{\mathrm{5GC}} =
  \frac{8 \cdot (\mathrm{oct}_{N3,UL} + \mathrm{oct}_{N3,DL})}{E_{\mathrm{UPF\ node}}}
  \quad [\mathrm{bit/J}]
$$

Derived quantities also reported: $\Delta P = P_{\mathrm{load}} - P_{\mathrm{idle}}$ (W),
energy per gigabit $= \Delta P / R$ with $R$ in Gbit/s (J/Gbit), and Kepler
attribution error $\varepsilon_K = (P_{\mathrm{Kepler,pod}} - \Delta P_{\mathrm{RAPL}}) / \Delta P_{\mathrm{RAPL}}$.

## Test cases

| ID | What it tests | Conditions | Pass criterion | Stage |
| --- | --- | --- | --- | --- |
| TC-01 | Idle baseline | 30 min without UPF, only agents on the DUT | Variation between 5-min blocks below 5 % | 2 |
| TC-02 | Source coherence | Kepler node, RAPL sampler and `perf` in parallel | Sampler vs `perf` within 1 %; Kepler node within 5 % | 2 |
| TC-03 | Calibration with known load | `stress-ng` on 1 and 2 pinned cores; external power and RAPL | External − RAPL offset stable across repetitions | 2 |
| TC-04 | Generator ceiling | `tcpreplay` at maximum towards the DUT N3 port, no UPF | Maximum rate recorded per packet size | 2 |
| TC-05 | End-to-end functional | PDU session and 60 s iperf3 per UPF | Session established and traffic at the sink | 3 |
| TC-06 | Benchmark functional | pfcpsim with 100 sessions; 128 B and 1400 B pcaps at 10 % | Packets at the sink equal packets sent | 3 |
| TC-07 | Maximum rate per UPF | Binary search with 60 s final trial | Highest no-loss rate, or generator ceiling | 4 |
| TC-08 | Energy matrix | UPF × load × packet size × repetitions | Variation between repetitions below 5 % | 5 |
| TC-09 | Kepler attribution (H3) | Kepler UPF pod power vs RAPL ΔP at each point | Error is reported; no threshold, it is a finding | 6 |
| TC-10 | Mitigations (H4) | Governor, idle states, UPF cores | ΔP and p99 latency reported per setting | 6 |
| TC-11 | SLA per level | Loss and p99 latency at each TC-08 point | A point failing the SLA is flagged and excluded from efficiency | 5 |

Platform note (ADR-11): TC-01..TC-04 are executed on both platforms; TC-03
uses the Kwollect wattmeter series on Grid'5000 and the wall meter at home.
TC-07..TC-11 are executed on Grid'5000; the home bench repeats a subset for
cross-platform sanity, not for publication.

## Threats to validity

| Type | Threat | Control |
| --- | --- | --- |
| Internal | Thermal drift and background processes change power | Same-day baseline (RM-03), randomized order, disabled services, CPU temperature recorded; on Grid'5000 the baseline runs inside the same OAR job |
| Internal | Shared inter-switch links on Grid'5000 (KaVLAN gives L2 isolation but no performance isolation) | Record loss and latency at every point (TC-11); prefer nodes on the same switch; repeat and report range |
| Construct | RAPL does not see NIC or board; Kepler apportions by CPU time | External power covers the first; TC-09 measures the second |
| External | A mini PC with 2.5 GbE or a single Grid'5000 server class is not an operator's platform | UPFs are compared with each other; absolute watts are not published as representative |
| Conclusion | 3–5 repetitions | Median and range reported; a difference smaller than repetition spread is not a finding |

## Declared deviations from the standards

- ETSI ES 203 539 requires 25 ± 2 °C ambient and a calibrated meter with ±1 %
  accuracy. Neither platform is controlled to that level: ambient temperature
  is recorded at home where available and is unknown in Grid'5000 machine
  rooms; wattmeter and wall-meter readings are used for comparison, not as
  absolute values.
- RFC 2544 recommends at least five frame sizes. The plan uses two for time
  reasons; a third enters the full scope if time allows.
- RFC 2544 assumes dedicated test equipment; here the generator is a
  software traffic source whose ceiling (TC-04) is measured and declared.
