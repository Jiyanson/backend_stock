SHELL := /bin/bash
MIGRATION_DATABASE:=./migrate.db

PACKAGE_SLUG=backend_stock
ifdef CI
	PYTHON_PYENV :=
	PYTHON_VERSION := $(shell python --version|cut -d" " -f2)
else
	PYTHON_PYENV := pyenv
	PYTHON_VERSION := $(shell cat .python-version)
endif
PYTHON_SHORT_VERSION := $(shell echo $(PYTHON_VERSION) | grep -o '[0-9].[0-9]*')

ifeq ($(USE_SYSTEM_PYTHON), true)
	PYTHON_PACKAGE_PATH:=$(shell python -c "import sys; print(sys.path[-1])")
	PYTHON_ENV :=
	PYTHON := python
	PYTHON_VENV :=
else
	PYTHON_PACKAGE_PATH:=.venv/lib/python$(PYTHON_SHORT_VERSION)/site-packages
	PYTHON_ENV :=  . .venv/bin/activate &&
	PYTHON := . .venv/bin/activate && python
	PYTHON_VENV := .venv
endif

# Used to confirm that pip has run at least once
PACKAGE_CHECK:=$(PYTHON_PACKAGE_PATH)/build
PYTHON_DEPS := $(PACKAGE_CHECK)


.PHONY: all
all: $(PACKAGE_CHECK)

.PHONY: install
install: $(PYTHON_PYENV) $(PYTHON_VENV) pip

.venv:
	python -m venv .venv

.PHONY: pyenv
pyenv:
	pyenv install --skip-existing $(PYTHON_VERSION)

.PHONY: pip
pip: $(PYTHON_VENV)
	$(PYTHON) -m pip install -e .[dev]

$(PACKAGE_CHECK): $(PYTHON_VENV)
	$(PYTHON) -m pip install -e .[dev]

.PHONY: pre-commit
pre-commit:
	pre-commit install

#
# Formatting
#
.PHONY: chores
chores: ruff_fixes black_fixes dapperdata_fixes tomlsort_fixes document_schema

.PHONY: ruff_fixes
ruff_fixes:
	$(PYTHON) -m ruff check . --fix

.PHONY: black_fixes
black_fixes:
	$(PYTHON) -m ruff format .

.PHONY: dapperdata_fixes
dapperdata_fixes:
	$(PYTHON) -m dapperdata.cli pretty . --no-dry-run

.PHONY: tomlsort_fixes
tomlsort_fixes:
	$(PYTHON_ENV) toml-sort $$(find . -not -path "./.venv/*" -name "*.toml") -i

#
# Testing
#
.PHONY: tests
tests: install pytest ruff_check black_check mypy_check dapperdata_check tomlsort_check paracelsus_check

.PHONY: pytest
pytest:
	$(PYTHON) -m pytest --cov=./${PACKAGE_SLUG} --cov-report=term-missing tests

.PHONY: pytest_loud
pytest_loud:
	$(PYTHON) -m pytest --log-cli-level=DEBUG -log_cli=true --cov=./${PACKAGE_SLUG} --cov-report=term-missing tests

.PHONY: ruff_check
ruff_check:
	$(PYTHON) -m ruff check

.PHONY: black_check
black_check:
	$(PYTHON) -m ruff format . --check

.PHONY: mypy_check
mypy_check:
	$(PYTHON) -m mypy ${PACKAGE_SLUG}

.PHONY: dapperdata_check
dapperdata_check:
	$(PYTHON) -m dapperdata.cli pretty .

.PHONY: tomlsort_check
tomlsort_check:
	$(PYTHON_ENV) toml-sort $$(find . -not -path "./.venv/*" -name "*.toml") --check
#
# Dependencies
#

.PHONY: rebuild_dependencies
rebuild_dependencies:
	$(PYTHON) -m uv pip compile --upgrade --output-file=requirements.txt pyproject.toml
	$(PYTHON) -m uv pip compile --upgrade --output-file=requirements-dev.txt --extra=dev pyproject.toml

.PHONY: dependencies
dependencies: requirements.txt requirements-dev.txt

requirements.txt: $(PACKAGE_CHECK) pyproject.toml
	$(PYTHON) -m uv pip compile --upgrade --output-file=requirements.txt pyproject.toml

requirements-dev.txt: $(PACKAGE_CHECK) pyproject.toml
	$(PYTHON) -m uv pip compile --upgrade --output-file=requirements-dev.txt --extra=dev pyproject.toml



#
# Packaging
#

.PHONY: build
build: $(PACKAGE_CHECK)
	$(PYTHON) -m build

#
# Database
#

.PHONY: document_schema
document_schema:
	$(PYTHON) -m paracelsus.cli inject docs/dev/database.md $(PACKAGE_SLUG).models.base:Base --import-module "$(PACKAGE_SLUG).models:*"

.PHONY: paracelsus_check
paracelsus_check:
	$(PYTHON) -m paracelsus.cli inject docs/dev/database.md $(PACKAGE_SLUG).models.base:Base --import-module "$(PACKAGE_SLUG).models:*" --check

.PHONY: run_migrations
run_migrations:
	$(PYTHON) -m alembic upgrade head

.PHONY: reset_db
reset_db: clear_db run_migrations

.PHONY: clear_db
clear_db:
	rm -Rf test.db*

.PHONY: create_migration
create_migration:
	@if [ -z "$(MESSAGE)" ]; then echo "Please add a message parameter for the migration (make create_migration MESSAGE=\"database migration notes\")."; exit 1; fi
	rm $(MIGRATION_DATABASE) | true
	. .venv/bin/activate && DATABASE_URL=sqlite:///$(MIGRATION_DATABASE) python -m alembic upgrade head
	. .venv/bin/activate && DATABASE_URL=sqlite:///$(MIGRATION_DATABASE) python -m alembic revision --autogenerate -m "$(MESSAGE)"
	rm $(MIGRATION_DATABASE)
	$(PYTHON) -m ruff format ./db

.PHONY: check_ungenerated_migrations
check_ungenerated_migrations:
	$(PYTHON) -m alembic check


