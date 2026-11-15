# ADR-06: UPF with `hostNetwork` and privileged mode

## Status

Proposed (pending G1 design review).

## Context

The three UPFs need direct access to the N3 and N6 interfaces (XDP program
attachment, DPDK device binding, raw sockets). Multus with `macvlan` or
`host-device` is the more production-like option but adds a CNI layer whose
own cost would differ between UPFs.

## Decision

Run the UPF pod with `hostNetwork: true` and privileged security context,
with the N3/N6 interfaces passed through the shared values contract.

## Consequences

- Declared in every report and talk as a simplification.
- A Multus variant is left for the end of the project if time allows, as a
  comparison of the CNI overhead itself.

## Alternatives rejected

- **Multus with macvlan or host-device.** More realistic, but an extra layer
  to control and explain.
