# analysis/

Notebooks and plotting code that read the raw run artifacts under `data/` and
compute every derived figure: ΔP, J/Gbit, ETSI EER, 3GPP EE, energy
proportionality and Kepler attribution error. Derived values are never stored
in `data/`, so a formula correction never requires touching raw data.

## Status

Scaffolding only. Notebooks arrive with the first calibration data (stage 2,
E2.3).

## Planned notebooks

| Notebook | Input | Output |
| --- | --- | --- |
| `00_baseline_calibration.ipynb` | TC-01..TC-04 runs | Idle variability, RAPL vs `perf` vs Kepler node agreement, wall−RAPL offset, generator ceiling per packet size |
| `10_energy_matrix.ipynb` | TC-08 + TC-11 runs | ΔP and J/Gbit per UPF × load × packet size; SLA-filtered points |
| `20_efficiency_metrics.ipynb` | TC-08 | EER (ETSI ES 203 539, weights 0.2/0.5/0.3) and EE (3GPP TS 28.554) per UPF |
| `30_kepler_attribution.ipynb` | TC-09 | Kepler pod power vs RAPL ΔP, relative error per point |
| `40_mitigations.ipynb` | TC-10 | ΔP and p99 latency per CPU setting |

## Conventions

- Statistics: median and range over repetitions; a difference smaller than the
  repetition spread is not reported as a finding (`docs/test-plan.md`).
- Figures are exported to `analysis/figures/` as SVG and PNG, with the
  notebook and git commit that produced them in the file metadata.
- Notebooks must run top to bottom from a clean kernel.
