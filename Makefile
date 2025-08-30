# Makefile to build and run Serverless Invoices via Docker as per README.md

# Configurable vars
IMAGE ?= mokuappio/serverless-invoices
CONTAINER ?= serverless-invoices
HOST_PORT ?= 80
CONTAINER_PORT ?= 8080

.PHONY: help build run up stop restart logs ps clean rm-image

help:
	@echo "Serverless Invoices - Docker helpers"
	@echo
	@echo "Targets:"
	@echo "  make build     - docker build . -t $(IMAGE)"
	@echo "  make run       - docker run -p $(HOST_PORT):$(CONTAINER_PORT) -d --rm --name $(CONTAINER) $(IMAGE)"
	@echo "  make up        - build and run"
	@echo "  make stop      - stop running container"
	@echo "  make restart   - stop then run"
	@echo "  make logs      - follow container logs"
	@echo "  make ps        - list matching container"
	@echo "  make clean     - stop container and remove dangling images"
	@echo "  make rm-image  - remove built image $(IMAGE)"
	@echo
	@echo "Variables (override with e.g. make HOST_PORT=8081 up):"
	@echo "  IMAGE=$(IMAGE)"
	@echo "  CONTAINER=$(CONTAINER)"
	@echo "  HOST_PORT=$(HOST_PORT) (maps to CONTAINER_PORT=$(CONTAINER_PORT))"

build:
	docker build . -t $(IMAGE)

run:
	docker run -p $(HOST_PORT):$(CONTAINER_PORT) -d --rm --name $(CONTAINER) $(IMAGE)

up: build run

stop:
	-@docker stop $(CONTAINER) 2>/dev/null || true

restart: stop run

logs:
	docker logs -f $(CONTAINER)

ps:
	docker ps --filter "name=$(CONTAINER)"

clean: stop
	-@docker image prune -f >/dev/null 2>&1 || true

rm-image:
	-@docker rmi $(IMAGE) || true
