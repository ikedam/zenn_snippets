.PHONY: help
help:	## Show target helps
	@echo "set ENV variable and call targets:"
	@echo
	@grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: check
check:	## Run lint and unit tests
	poetry install
	poetry run black .
	poetry run isort .
	poetry run flake8 
	poetry run mypy .
	poetry run pytest
