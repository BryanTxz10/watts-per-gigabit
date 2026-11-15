# ADR-03: k3s as Kubernetes distribution

## Status

Proposed (pending G1 design review).

## Context

The bench needs a Kubernetes distribution with a low idle footprint on the
DUT and a straightforward way to enable the static CPU manager and reserved
CPUs on the agent.

## Decision

Use k3s: server on the generator, agent on the DUT. The static CPU manager
and `reserved-cpus` are enabled through kubelet arguments in the agent
configuration.

## Consequences

- Lower idle baseline than a full kubeadm cluster.
- One binary per node, easy to pin to an exact version in Ansible.
- Kubelet tuning is part of the Ansible role, not a manual step.

## Alternatives rejected

- **kubeadm.** More components and higher baseline consumption.
- **MicroK8s.** Tied to snap packaging.
