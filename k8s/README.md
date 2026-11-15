# k8s/

Kubernetes deployment as versioned Helm values and manifests (ADR-10). One
k3s cluster with two nodes: everything that is not measured runs on the
generator node; the DUT node accepts only the UPF under test and the
measurement agents (ADR-01, RNF-02).

## Status

Scaffolding only. Values files will be added in stage 2 (`monitoring/`) and
stage 3 (`core/`, `upf/`).

## Layout

| Path | Intent | Node |
| --- | --- | --- |
| `monitoring/` | kube-prometheus-stack values (Prometheus, Grafana, node-exporter) and Kepler values. Prometheus is pinned to the generator; Kepler runs only on the DUT. | gen / dut |
| `core/` | Open5GS control plane values (NRF, AMF, SMF, AUSF, UDM, UDR, PCF, NSSF, BSF, MongoDB) with the chart's UPF disabled, plus subscriber provisioning. | gen |
| `upf/open5gs/` | Open5GS UPF (kernel GTP-U path). | dut |
| `upf/eupf/` | eUPF (eBPF/XDP). | dut |
| `upf/omec/` | OMEC/SD-Core UPF (DPDK busy-polling and AF_PACKET variants). | dut |

## The UPF values contract (RF-01)

Every UPF directory consumes the same set of values so that switching UPF is
a one-file change visible in the git diff:

| Key | Meaning |
| --- | --- |
| `n3.iface`, `n3.ip` | N3 interface and address on the DUT. |
| `n6.iface`, `n6.ip` | N6 interface and address on the DUT. |
| `pfcp.ip` | N4 listen address (management network, UDP 8805). |
| `cpus` | Exclusive CPU set; `requests == limits`, Guaranteed QoS (2 whole CPUs). |
| `uePools` | UE pools routed on N6 (`10.45.0.0/16` end-to-end, `17.0.0.0/24` benchmark). |
| `image.digest` | Images pinned by digest, never `latest`. |

## Placement rules

- DUT node: label `role=dut`, taint `dedicated=dut:NoSchedule`; kubelet with
  static CPU manager and `reserved-cpus=0-1`.
- UPF pods use `hostNetwork` and run privileged (ADR-06).
- Kepler scrape interval must match its internal collection interval.
