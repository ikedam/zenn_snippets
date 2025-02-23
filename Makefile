ENV := dev

.PHONY: help
help:	## Show target helps
	@echo "set ENV variable and call targets:"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: init
init:	## run opentofu init
	docker compose run --rm opentofu init -var-file="env/_common.tfvars" -var-file="env/$(ENV).tfvars" -reconfigure

.PHONY: lint
lint:	## lint opentofu files
	docker compose run --rm opentofu validate
	docker compose run --rm opentofu fmt -recursive -check -diff .

.PHONY: format
format:	## format opentofu files
	docker compose run --rm opentofu fmt -recursive .

.PHONY: lock
lock:	## create/update .terraform.lock.hcl file
	docker compose run --rm opentofu init -backend=false
	docker compose run --rm opentofu providers lock -platform=linux_amd64 -platform=linux_arm64

.PHONY: plan
plan:	## run opentofu plan
	docker compose run --rm opentofu plan -var-file="env/_common.tfvars" -var-file="env/$(ENV).tfvars"

.PHONY: apply
apply:	## run opentofu apply
	docker compose run --rm opentofu apply -var-file="env/_common.tfvars" -var-file="env/$(ENV).tfvars"

.PHONY: destroy
destroy:	## run opentofu destroy
	docker compose run --rm opentofu destroy -var-file="env/_common.tfvars" -var-file="env/$(ENV).tfvars"
