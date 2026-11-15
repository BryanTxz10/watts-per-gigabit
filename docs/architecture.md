# Architecture (E1.2)

Four views: physical and context, network and addressing, Kubernetes
deployment, and measurement chain. The design is platform-agnostic by
construction (RNF-03): the same two roles, generator and DUT, exist on
Grid'5000 (primary, ADR-11) and on the home bench (secondary, ADR-02).

Diagram sources: [`figures/architecture.mmd`](figures/architecture.mmd),
[`figures/measurement-chain.mmd`](figures/measurement-chain.mmd).

## 1. Physical and context view

The generator node produces traffic and hosts everything that is not
measured; the DUT node runs only the UPF under test and the agents that
measure it. That is the generator/DUT separation RFC 8172 asks for.

| Role | Grid'5000 (primary) | Home bench (secondary) |
| --- | --- | --- |
| Generator | One node of the reserved pair, Kadeploy-provisioned | Laptop, mains-powered, suspend disabled |
| DUT | Second node of the pair, on a wattmeter-equipped cluster with two usable Ethernet interfaces (candidates: `gros-[41-76]` Nancy, `chirop` Lille; selected by the acceptance reservation, ADR-11) | x86 mini PC, ≥ 4 cores, 3 × Intel I225/I226 NICs (`igc`) |
| External power | Dedicated wattmeter via Kwollect (`wattmetre_power_watt`, 1 s; 20 ms on demand) | Smart plug with local HTTP API, ≥ 1 Hz |
| Cross-check power | `bmc_node_power_watt` (5 s, less precise) | None |
| Management network | Grid'5000 site production network, first interface | Travel router, 192.168.50.0/24 |
| N3 / N6 | Second interface, shared: two 802.1Q sub-interfaces in KaVLAN local VLANs (or two subnets on one VLAN) | Direct Cat 6 cables, one NIC each |

N3 and N6 traffic never shares a link with control or measurement traffic.
On Grid'5000 N3 and N6 share one NIC (declared deviation from ADR-04, see
section 2); at home they have one NIC each. The external power measurement
sees the whole DUT, including NIC and board that RAPL does not see.

## 2. Network and addressing view

Three networks that share no link. Addresses are a proposal and are fixed in
the Ansible inventory, not in roles.

| Network | Carries | Subnet | Generator | DUT |
| --- | --- | --- | --- | --- |
| Management | Kubernetes API, N2 (SCTP), N4 (PFCP, UDP 8805), Prometheus, SSH, power-meter polling | Platform-dependent (home: 192.168.50.0/24) | home: .10 | home: .20 on port 1 |
| N3 | GTP-U between gNB/replayer and UPF | 10.3.0.0/24 | 10.3.0.1 (UERANSIM gNB or tcpreplay) | 10.3.0.2 on port 2 |
| N6 | User traffic after decapsulation | 10.6.0.0/24 | 10.6.0.1, sink inside netns `dn` | 10.6.0.2 on port 3 |
| UE pool, end-to-end | Addresses assigned by the Open5GS SMF | 10.45.0.0/16 | Route in `dn` towards 10.6.0.2 | Routed by the UPF |
| UE pool, benchmark | Addresses of pfcpsim sessions | 17.0.0.0/24 | Route in `dn` towards 10.6.0.2 | Routed by the UPF |

Rules:

- **No NAT on N6.** The sink has a return route to the UE pools, so no UPF
  performs NAT. NAT would add different work in each UPF and bias the
  comparison (ADR-05).
- **Isolated sink.** The generator's N6 interface lives in network namespace
  `dn`. In the main namespace the kernel would deliver sink-bound traffic
  locally without crossing the UPF (ADR-05).
- **MTU 1500 on N3.** IPv4 + UDP + GTP-U headers total 36 bytes, plus 8 with
  the PDU session container extension; 1400 B inner packets fit unfragmented.
- **PFCP over management.** The UPF listens for N4 on its management address,
  port 8805, for both the SMF and pfcpsim.
- **Grid'5000 specifics (ADR-11).** Wattmeter clusters expose two
  Ethernet interfaces, so management uses the first and **N3 and N6 share
  the second**. Sharing is controlled as follows:
  - *Separation:* two 802.1Q sub-interfaces (`eth1.N3`, `eth1.N6`) in two
    KaVLAN local VLANs; if a single VLAN is granted, the two subnets
    (`10.3.0.0/24`, `10.6.0.0/24`) ride one segment. KaVLAN gives L2
    isolation but no performance isolation, so loss and latency are
    recorded at every point.
  - *Counters:* N3 RX and N6 TX are read per sub-interface, or — on a
    single segment — from `nftables` counters keyed by subnet, so they stay
    separable for throughput and loss.
  - *Capacity:* downlink N3 is inbound and N6 is outbound on the DUT, so
    they use opposite directions of a full-duplex link; the generator
    ceiling (TC-04) is nevertheless measured on the shared link and sets
    the 100 % load level.
  - *Fairness:* the shared NIC, driver, interrupt vectors and XDP hook are
    the same for every UPF, so the sharing cost is a platform constant,
    declared in the report; the home bench with three NICs checks that it
    does not change the ranking.

## 3. Kubernetes deployment view

One k3s cluster, two nodes, one rule: everything not measured runs on the
generator; the DUT accepts only pods that tolerate its taint.

| Node | k3s role | Label and taint | Runs |
| --- | --- | --- | --- |
| gen | server | `role=generator` | Open5GS control plane with MongoDB, Prometheus, Grafana, node-exporter |
| dut | agent | `role=dut`, taint `dedicated=dut:NoSchedule` | UPF under test, Kepler, node-exporter |

| Namespace | Workload | Node | Network | Resources |
| --- | --- | --- | --- | --- |
| `core` | NRF, AMF, SMF, AUSF, UDM, UDR, PCF, NSSF, BSF, MongoDB | gen | Pod network; AMF and SMF published on the management IP | No strict limits |
| `upf` | One UPF at a time (Open5GS, eUPF or OMEC) | dut | `hostNetwork`, privileged | Guaranteed QoS, 2 whole CPUs |
| `kepler` | Kepler DaemonSet | dut only | Metrics on port 28282 | Fixed requests |
| `monitoring` | Prometheus, Grafana | gen | Pod network | 30-day local retention |
| `monitoring` | node-exporter | both | `hostNetwork` | Fixed requests |

Deployment rules:

- **Pinned CPUs for the UPF.** The DUT kubelet starts with the static CPU
  manager and `reserved-cpus=0-1`. The UPF requests 2 whole CPUs with
  `requests == limits` and lands on CPUs 2–3. Spare cores on larger nodes
  stay idle and are recorded in the manifest.
- **Same contract for all UPFs.** Each UPF has its own chart or manifests but
  receives the same values (N3 interface, N6 interface, PFCP IP, CPUs, UE
  pools). Switching UPF is a one-file change (RF-01).
- **Pinned versions.** Exact chart versions, images by digest, never `latest`.
- **Prometheus off the measured node.** TSDB compactions cause CPU spikes that
  would be noise in the baseline.
- **Kepler scrape aligned with its internal interval.** Verify the interval in
  the chart configuration before fixing the scrape.

## 4. Measurement chain and data view

Every time series goes through Prometheus on the generator and the harness
trims it to the steady window. Only generator and sink counters are read by
the harness directly.

Kepler reads the same RAPL counter as the project's own sampler, so its node
total must match RAPL. What is under test is its per-pod apportionment,
against RAPL ΔP and against external power. The sampler runs privileged
because on recent kernels `energy_uj` is readable only by root.

| Signal | Source | Rate | Consumer |
| --- | --- | --- | --- |
| RAPL package energy | Own sampler on the DUT | 1 Hz | Prometheus → harness |
| External node power | Kwollect `wattmetre_power_watt` (Grid'5000) or smart plug (home) | 1 s / ≥ 1 Hz | Harness |
| BMC node power (cross-check) | Kwollect `bmc_node_power_watt` | 5 s | Harness |
| Pod and node power | Kepler | Internal interval | Prometheus → harness |
| CPU temperature, frequency | node-exporter / hwmon | Scrape interval | Prometheus → harness |
| N3/N6 counters | DUT interfaces or UPF | 1 Hz | Harness |
| Offered and received rate, loss | Generator and sink counters | Per run | Harness |
| p50/p99 latency | Latency probe | Per run | Harness |

Outputs per run are defined in [`../data/README.md`](../data/README.md).
