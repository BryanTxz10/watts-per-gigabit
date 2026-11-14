# Architecture decision records

Decisions follow Michael Nygard's format: context, decision, status,
consequences, with the alternatives that were rejected. ADR-01..ADR-10 were
drafted in the October 2026 design document in status *proposed* pending the
G1 design review; ADR-11 records the move to Grid'5000 as primary platform
and amends ADR-02 and ADR-04.

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-two-node-cups-cluster.md) | Two-node cluster with CUPS: control plane and observability on the generator, only the UPF on the DUT | Proposed |
| [0002](0002-dedicated-mini-pc-as-dut.md) | Dedicated x86 mini PC with ≥ 3 Intel I226 ports as DUT | Amended by ADR-11 (secondary bench) |
| [0003](0003-k3s-as-kubernetes-distribution.md) | k3s as Kubernetes distribution | Proposed |
| [0004](0004-three-physical-networks.md) | Three physical networks, management on a dedicated travel router | Amended by ADR-11 (KaVLAN on Grid'5000) |
| [0005](0005-n6-sink-in-network-namespace-no-nat.md) | N6 sink in network namespace `dn`, no NAT on N6 | Proposed |
| [0006](0006-upf-hostnetwork-privileged.md) | UPF with `hostNetwork` and privileged mode | Proposed |
| [0007](0007-rapl-reference-external-validation-kepler-under-test.md) | RAPL package as reference, external power as validation, Kepler as object of study | Proposed |
| [0008](0008-two-traffic-modes.md) | Two traffic modes: end-to-end (UERANSIM, iperf3) and benchmark (pfcpsim, Scapy, tcpreplay) | Proposed |
| [0009](0009-fixed-cpu-configuration-in-baseline.md) | Fixed CPU configuration in the baseline, varied only in the mitigation stage | Proposed |
| [0010](0010-infrastructure-as-code.md) | Infrastructure as code: Ansible, Helm values, Makefile entry point | Proposed |
| [0011](0011-grid5000-as-primary-measurement-platform.md) | Grid'5000 as primary measurement platform, home bench as secondary; node selection restricted to three-interface clusters | Proposed — accepted after the E1.7 acceptance reservation |

Status vocabulary: *Proposed* (awaiting G1), *Accepted*, *Amended by ADR-NN*,
*Superseded by ADR-NN*, *Rejected*.
