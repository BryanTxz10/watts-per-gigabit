# ADR-05: N6 sink in network namespace `dn`, no NAT on N6

## Status

Proposed (pending G1 design review).

## Context

If the generator's N6 interface stayed in the main network namespace, the
kernel would deliver traffic destined to the sink locally, without ever
crossing the cable and the UPF. NAT on N6 is also tempting because many UPF
quick-start guides enable it, but each implementation performs NAT
differently, which would add non-comparable work.

## Decision

Move the generator's N6 interface into a dedicated network namespace `dn`
that hosts the sink and holds routes back to both UE pools
(10.45.0.0/16 end-to-end, 17.0.0.0/24 benchmark) via the DUT's N6 address.
No UPF performs NAT.

## Consequences

- Routes to the UE pools are versioned in the Ansible `netns-dn` role.
- UPF values files disable NAT explicitly; a UPF that cannot disable NAT is
  flagged in the interoperability matrix.

## Alternatives rejected

- **Sink in the main namespace.** Local delivery bypasses the UPF.
- **NAT in the UPF.** Implementation-specific work pollutes the comparison.
