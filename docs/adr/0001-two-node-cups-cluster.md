# ADR-01: Two-node cluster with CUPS

## Status

Proposed (pending G1 design review).

## Context

The original single-node plan put the 5G control plane, Prometheus and the
UPF on the same machine. The idle baseline would then include the control
plane and the monitoring stack, and their background activity (MongoDB,
Prometheus compactions) would be indistinguishable from UPF behaviour.
RFC 8172 asks that the generator shares no resources with the device under
test.

## Decision

Build the bench as a 5G network with real control- and user-plane separation
(CUPS). The control plane, the k3s server and the observability stack run on
the generator node; the DUT runs only the UPF under test and the measurement
agents (Kepler, node-exporter, RAPL sampler).

## Consequences

- The generator must stay powered and awake for the whole session.
- N4 (PFCP) crosses the management network.
- The topology mirrors a central control plane with the UPF at the edge,
  which is the deployment story operators recognise.
- The idle baseline of the DUT excludes the control plane; the report states
  this explicitly when quoting 3GPP EE.

## Alternatives rejected

- **Everything on one node.** Puts the control plane and Prometheus in the
  baseline.
- **Control plane in Docker outside Kubernetes.** Breaks the "UPF on
  Kubernetes" narrative and removes the Helm-values contract.
