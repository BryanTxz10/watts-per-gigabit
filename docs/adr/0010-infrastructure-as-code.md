# ADR-10: Infrastructure as code

## Status

Proposed (pending G1 design review).

## Context

Reproducibility (RNF-01) and portability (RNF-03) require that the whole
bench can be rebuilt from the repository by someone else, on another
platform, without manual steps.

## Decision

- **Hosts:** Ansible roles (`host-tuning`, `k3s-server`, `k3s-agent`,
  `netns-dn`, `chrony`) driven by per-platform inventories.
- **Kubernetes:** Helm charts with pinned versions and versioned values files;
  images by digest.
- **Entry point:** a Makefile with `bench-up`, `bench-down`, `smoke`,
  `run-point` and `campaign`.

## Consequences

- Anyone rebuilds the bench with `make bench-up INV=<inventory>`.
- Real inventories are git-ignored; only `*.example.yml` templates are
  committed (public repository).

## Alternatives rejected

- **Manual steps.** Not reproducible.
- **GitOps with Argo CD or Flux.** Too many moving parts for two nodes.
