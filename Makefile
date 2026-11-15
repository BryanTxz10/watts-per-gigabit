# watts-per-gigabit — single entry point for the bench.
#
# Status: scaffolding only. Every target below is a documented stub that
# prints "not implemented yet" and exits non-zero, so that scripts fail
# loudly instead of silently succeeding. Targets will be filled in during
# stage 2 (bench as code) and stage 3 (5G core and smoke tests).
#
# Usage:
#   make                 # show this help
#   make bench-up INV=ansible/inventory/grid5000.yml
#   make smoke UPF=eupf

INV   ?= ansible/inventory/home.yml
UPF   ?= eupf
LOAD  ?= 50
PKT   ?= 1400
REP   ?= 1

.DEFAULT_GOAL := help
.PHONY: help bench-up bench-down smoke run-point campaign lint

help: ## Show available targets
	@echo "watts-per-gigabit — bench entry point (scaffolding, not implemented yet)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables: INV=$(INV) UPF=$(UPF) LOAD=$(LOAD) PKT=$(PKT) REP=$(REP)"

bench-up: ## Provision generator and DUT (Ansible), install k3s, deploy monitoring
	@echo "bench-up: not implemented yet (stage 2, E2.2). Inventory: $(INV)"; exit 1

bench-down: ## Tear the bench down and leave hosts clean
	@echo "bench-down: not implemented yet (stage 2, E2.2)"; exit 1

smoke: ## Deploy one UPF and run TC-05/TC-06 functional checks
	@echo "smoke: not implemented yet (stage 3, E3.2). UPF=$(UPF)"; exit 1

run-point: ## Run one measurement point and append a row to data/results.csv
	@echo "run-point: not implemented yet (stage 5, TC-08). UPF=$(UPF) LOAD=$(LOAD)% PKT=$(PKT)B REP=$(REP)"; exit 1

campaign: ## Run the full randomized matrix (UPF x load x packet size x repetitions)
	@echo "campaign: not implemented yet (stage 5, TC-08)"; exit 1

lint: ## Lint Markdown and YAML (requires npx and yamllint)
	@npx --yes markdownlint-cli2 "**/*.md" "#node_modules" || true
	@command -v yamllint >/dev/null 2>&1 && yamllint -s . || echo "yamllint not installed, skipping"
