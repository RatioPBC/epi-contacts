DKC_RUN := docker-compose run --rm epi_contacts
MAKEFLAGS += --no-print-directory

export UID := $(shell id -u)
export USER := $(shell id -u -n)

.PHONY: console logs mix new test

default: new



build-test:
	@docker build \
		--build-arg OBAN_KEY=${OBAN_KEY} \
		--build-arg UID=$(UID) \
		--build-arg USER=$(USER) \
		--target test \
		-t epi_contacts:test \
		docker/

console:
	@$(DKC_RUN) iex --sname repl --cookie foo --remsh server@epi_contacts

logs:
	@docker-compose logs -f epi_contacts

mix:
	@$(DKC_RUN) mix $(CMD)

new:
	@docker-compose build epi_contacts
	@docker-compose up -d postgres
	@$(DKC_RUN) mix do deps.get, deps.compile
	@$(DKC_RUN) sh -c 'cd assets && npm ci'
	@$(DKC_RUN) mix ecto.migrate
	@docker-compose up -d epi_contacts

test: build-test
	@docker run --rm -it \
		--network epi-contacts_default \
		-v $(shell pwd):/epi-contacts:cached \
		-v epi-contacts_epi_contacts_build:/epi-contacts/_build \
		-v epi-contacts_epi_contacts_deps:/epi-contacts/deps \
		-v epi-contacts_epi_contacts_node_modules:/epi-contacts/assets/node_modules \
		-e DATABASE_SECRET='{"password": "abc123", "dbname": "epi_contacts_dev", "engine": "postgres", "port": 5432, "host": "postgres", "username": "cc"}' \
		epi_contacts:test \
		mix test

