ENV := dev

.PHONY: help
help:	## Show target helps
	@echo "set ENV variable and call targets:"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: init
init:	## run terraform init
	docker compose run --rm terraform init -backend-config="env/$(ENV)/backend.tfbackend" -reconfigure

.PHONY: lint
lint:	## lint terraform files
	docker compose run --rm terraform validate
	docker compose run --rm terraform fmt -recursive -check -diff .

.PHONY: format
format:	## format terraform files
	docker compose run --rm terraform fmt -recursive .

.PHONY: lock
lock:	## create/update .terraform.lock.hcl file
	docker compose run --rm terraform init -backend=false
	docker compose run --rm terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -enable-plugin-cache

.PHONY: plan
plan:	## run terraform plan
	docker compose run --rm terraform plan -var-file="env/$(ENV)/terraform.tfvars"

.PHONY: apply
apply:	## run terraform apply
	docker compose run --rm terraform apply -var-file="env/$(ENV)/terraform.tfvars"

.PHONY: destroy
destroy:	## run terraform destroy
	docker compose run --rm terraform destroy -var-file="env/$(ENV)/terraform.tfvars"
