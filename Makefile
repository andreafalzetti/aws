SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help install fmt check bootstrap-state bootstrap init plan apply output github-config secret-list secret-add secret-rotate

help: ## Mostra i comandi disponibili
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Installa la versione Terraform dichiarata in mise
	mise install

fmt: ## Formatta tutti i file Terraform
	mise exec -- terraform fmt -recursive

check: ## Controlla formattazione, shell e validità Terraform senza credenziali
	./scripts/check.sh

bootstrap-state: ## Crea in modo idempotente il bucket remoto iniziale
	./scripts/bootstrap-state.sh

bootstrap: bootstrap-state ## Gestisce state, KMS e GitHub OIDC (solo locale/admin)
	./scripts/tf.sh bootstrap init
	./scripts/tf.sh bootstrap apply
	./scripts/configure-github.sh

init: ## Inizializza lo stack production con backend S3
	./scripts/tf.sh production init

plan: init ## Calcola il piano dello stack production
	./scripts/tf.sh production plan

apply: init ## Applica lo stack production
	./scripts/tf.sh production apply

output: ## Mostra solo gli output non sensibili di production
	./scripts/tf.sh production output

github-config: ## Aggiorna le GitHub Actions variables (nessuna AWS key)
	./scripts/configure-github.sh

secret-list: ## Elenca i ciphertext registrati, senza valori
	./scripts/secret.sh list

secret-add: ## Aggiunge un ciphertext: make secret-add KEY=x SSM_PATH=/crm-demo/production/x [INPUT=--stdin]
	@test -n "$(KEY)" -a -n "$(SSM_PATH)" || (echo "Servono KEY e SSM_PATH" >&2; exit 2)
	./scripts/secret.sh add "$(KEY)" "$(SSM_PATH)" $(INPUT)

secret-rotate: ## Ruota un ciphertext: make secret-rotate KEY=x [INPUT=--stdin]
	@test -n "$(KEY)" || (echo "Serve KEY" >&2; exit 2)
	./scripts/secret.sh rotate "$(KEY)" $(INPUT)
