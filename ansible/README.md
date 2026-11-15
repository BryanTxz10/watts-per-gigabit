# ansible/

Host provisioning for the generator and the device under test (DUT), as
infrastructure as code (ADR-10). The same roles must run unchanged against
every inventory; only inventory variables differ (RNF-03).

## Status

Scaffolding only. Role directories exist with no tasks yet. Filled in during
stage 2 (E2.2).

## Layout

| Path | Intent |
| --- | --- |
| `inventory/home.example.yml` | Secondary bench: laptop generator + mini PC DUT. |
| `inventory/grid5000.example.yml` | Primary platform: two Grid'5000 nodes after Kadeploy, KaVLAN for N3/N6. |
| `inventory/lab.example.yml` | Reserved for a university lab inventory; same contract. |
| `roles/host-tuning` | Governor, turbo, C-states, IRQ affinity, hugepages, disabled services (ADR-09, RF-06). |
| `roles/k3s-server` | k3s server on the generator; CPU manager off (ADR-03). |
| `roles/k3s-agent` | k3s agent on the DUT with static CPU manager, `reserved-cpus`, taint `dedicated=dut:NoSchedule`. |
| `roles/netns-dn` | N6 sink in its own network namespace `dn`, routes to UE pools, no NAT (ADR-05). |
| `roles/chrony` | Clock sync between generator and DUT, offset < 10 ms (RM-05). |

## Rules

- Real inventories (`inventory/*.yml`) are git-ignored. Copy an example file,
  fill in hostnames and addresses, never commit the result. See `SECURITY.md`.
- No secrets in roles. Anything sensitive goes through Ansible Vault files
  that are also git-ignored.
- Every variable the harness records in `manifest.yaml` (governor, turbo,
  C-states, UPF CPUs) must be set by a role, not by hand.
