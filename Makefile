.PHONY: help
help:	## Show target helps
	@echo "set ENV variable and call targets:"
	@echo
	@grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: check-in-docker
check-in-docker:	## Run lint and unit tests (without docker)
	poetry run black .
	poetry run isort .
	poetry run flake8 
	poetry run mypy .
	poetry run pytest

.PHONY: check
check:	## Run lint and unit tests (with docker)
	docker compose run --rm python make check-in-docker

.PHONY: terraform-init
terraform-init:	## Run terraform init
	docker compose run --rm terraform init

.PHONY: terraform-format
terraform-format:	## Run terraform fmt
	docker compose run --rm terraform fmt -recursive .

.PHONY: terraform-plan
terraform-plan:	## Run terraform plan
	docker compose run --rm terraform plan
