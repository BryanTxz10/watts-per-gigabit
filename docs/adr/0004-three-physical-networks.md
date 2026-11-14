# ADR-04: Three physical networks, management on a dedicated travel router

## Status

Amended by [ADR-11](0011-grid5000-as-primary-measurement-platform.md): on
Grid'5000 the management network is the site's production network and N3/N6
isolation is provided by KaVLAN; the travel router applies to the home bench
only. Originally proposed October 2026.

## Context

N3 and N6 carry the measured traffic. Kubernetes API, N2, N4, Prometheus
scraping and SSH must not share a link with them, otherwise control traffic
becomes noise in the data plane and RFC 8172's isolated-test-network
requirement is not met. A residence network may isolate clients and does not
travel to a lab.

## Decision

Three networks that share no link: a management network, N3 and N6.

- Home bench: management on a dedicated travel router (192.168.50.0/24); N3
  and N6 on direct cables between generator and DUT.
- Grid'5000 (ADR-11): management on the site network; N3 and N6 on dedicated
  interfaces placed in a KaVLAN local VLAN.

## Consequences

- The home bench moves to a lab without IP reconfiguration.
- On Grid'5000, KaVLAN gives L2 isolation but no performance isolation, so
  loss and latency are recorded at every point.

## Alternatives rejected

- **Use the residence network.** Client isolation, no portability.
- **VLAN over the N3 link.** Mixes control with the measured plane.
