# data/

Raw measurement artifacts and their data dictionary (E1.5). Every run leaves a
manifest, a time series and one summary row; with these three artifacts anyone
can recompute every published figure. Raw data are never edited. Derived
metrics live in `analysis/`.

**License:** the dataset is released under
[Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).
Code elsewhere in this repository is Apache-2.0.

## Status

Scaffolding only. `data/runs/*` and `data/results.csv` are git-ignored during
the campaign and published as a tagged, Zenodo-archived release (see
`docs/methodology.md`, section 9).

## What each run produces

| Artifact | Path | Content |
| --- | --- | --- |
| Manifest | `data/runs/<run_id>/manifest.yaml` | Everything needed to reproduce the run (table below). |
| Time series | `data/runs/<run_id>/series.csv.gz` | 1 Hz samples of RAPL, external power, Kepler, interface counters and CPU temperature, covering warm-up, steady window and cool-down, with a `phase` column. |
| Summary row | `data/results.csv` | One row per run with the columns in the data dictionary. |

**Manifest-or-refuse rule.** The harness refuses to append to `results.csv` if
any manifest field is missing.

## `manifest.yaml` fields

| Field | Type | Source |
| --- | --- | --- |
| `run_id` | string, `YYYYMMDDTHHMMSSZ-<upf>-<mode>-<load>-<pkt>-r<rep>` | Harness |
| `git_commit` | 40-hex | Harness |
| `platform` | `grid5000` \| `home` \| `lab` | Inventory |
| `site`, `cluster`, `node_gen`, `node_dut`, `oar_job_id`, `kavlan_id_n3`, `kavlan_id_n6` | string / int | Grid'5000 only; null elsewhere (the two VLAN IDs are equal when N3 and N6 share one VLAN) |
| `kadeploy_env` | string | Grid'5000 only |
| `image_digests` | map of pod → `sha256:…` | Kubernetes |
| `kernel`, `k3s_version`, `kepler_version` | string | DUT |
| `cpu_model`, `cpu_count`, `upf_cpus`, `reserved_cpus` | string / int / cpuset | DUT |
| `governor_set`, `governor_read` | string | Harness applies, reads back (RF-06) |
| `turbo_set`, `turbo_read` | bool | Harness |
| `cstates_set`, `cstates_read` | string | Harness |
| `nic_model`, `nic_driver`, `nic_firmware` | string | `ethtool -i` on N3 and N6 |
| `bios_version`, `bios_notes` | string | DUT / acceptance record |
| `temp_ambient_c` | float or null | Thermometer (home) or null (Grid'5000) |
| `order_seed` | int | Harness, randomized order (RM-04) |
| `phases` | map of `warmup`/`steady`/`cooldown` → start, end (UTC) | Harness |
| `power_source` | `kwollect` \| `wall` | Inventory |
| `kwollect_metrics`, `kwollect_period_ms` | list / int | Grid'5000 only |
| `chrony_offset_ms` | float | Both hosts, must be < 10 (RM-05) |

## `series.csv.gz` columns

| Column | Unit | Source |
| --- | --- | --- |
| `ts_utc` | ISO 8601 | Harness |
| `phase` | `warmup` \| `steady` \| `cooldown` | Harness |
| `e_rapl_pkg_uj` | µJ, monotonic, wrap-corrected | RAPL sampler |
| `p_rapl_w` | W | Derived at sample time from consecutive RAPL readings |
| `p_ext_w` | W | Kwollect `wattmetre_power_watt` (Grid'5000, 1 s) or wall meter (home) |
| `p_bmc_w` | W or empty | Kwollect `bmc_node_power_watt` (Grid'5000 secondary cross-check, 5 s, forward-filled to 1 Hz) |
| `p_kepler_pod_w`, `p_kepler_node_w` | W | Prometheus |
| `rx_pkts_n3`, `tx_pkts_n6`, `rx_bytes_n3`, `tx_bytes_n6` | count / bytes | DUT interface counters |
| `sink_rx_pkts`, `sink_rx_bytes` | count / bytes | Sink in namespace `dn` |
| `temp_cpu_c` | °C | hwmon |
| `cpu_freq_mhz_upf` | MHz | cpufreq on the UPF CPUs |

## `results.csv` data dictionary

| Column | Unit | Source |
| --- | --- | --- |
| `run_id`, `git_commit` | text | Harness |
| `platform` | text | Inventory |
| `start_utc`, `steady_end_utc` | ISO 8601 | Harness |
| `upf`, `upf_digest` | text | Helm values |
| `mode` | `e2e` \| `bench` | Harness |
| `load_pct`, `offered_rate_mbps` | %, Mbit/s | Harness |
| `packet_size_b`, `sessions`, `rep` | bytes, n, n | pcap generator and pfcpsim |
| `throughput_mbps`, `loss_pct` | Mbit/s, % | Generator and sink counters |
| `oct_n3_ul`, `oct_n3_dl` | bytes | UPF counters or N3 interface |
| `lat_p50_us`, `lat_p99_us` | µs | Latency probe |
| `p_rapl_w`, `p_base_rapl_w` | W | RAPL sampler (run, same-day baseline) |
| `p_ext_w`, `p_base_ext_w` | W | Wattmeter via Kwollect (Grid'5000), or wall meter (home) |
| `p_kepler_pod_w`, `p_kepler_node_w` | W | Prometheus |
| `temp_cpu_c`, `temp_ambient_c` | °C | hwmon; thermometer or null |
| `governor`, `turbo`, `cstates`, `upf_cpus` | text | Manifest (read-back values) |
| `sla_ok` | bool | TC-11 |

Not stored, computed in `analysis/`: ΔP, J/Gbit, EER, EE (3GPP), energy
proportionality, Kepler attribution error.
