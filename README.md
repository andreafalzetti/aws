# Andrea AWS infrastructure

Repository Terraform modulare per le risorse dell'account AWS personale di Andrea. È volutamente separato da account, profili, chiavi KMS e tooling OFC.

## Scelte di sicurezza

- State remoto in un bucket S3 dedicato in `eu-central-1`, con versioning, accesso pubblico bloccato e cifratura KMS.
- Lock nativo S3 (`use_lockfile = true`): DynamoDB non viene creato perché il locking DynamoDB è deprecato nelle versioni Terraform attuali.
- GitHub Actions usa OIDC e credenziali AWS temporanee. Non esistono access key AWS nei GitHub Secrets.
- Il subject OIDC è vincolato agli ID immutabili di owner/repository e al branch `main`.
- Il workflow può gestire soltanto lo state `production`, la chiave KMS dei segreti e i namespace SSM esplicitamente autorizzati (`/crm-demo/production/*`, `/n8n-demo/production/*` e `/platform/production/*`); non può modificare IAM o il proprio ruolo.
- I valori SSM usano `value_wo`: non vengono salvati nel piano o nello state Terraform.
- I segreti esterni vengono versionati esclusivamente come ciphertext KMS con encryption context legato al path SSM.

Il repository GitHub è attualmente pubblico. Il modello non espone plaintext, ma rende visibili nomi e architettura delle risorse; per ridurre questa esposizione è comunque consigliato renderlo privato prima di aggiungere altra infrastruttura.

## Struttura

```text
bootstrap/                    bucket state, KMS, GitHub OIDC e policy CI
environments/production/      composizione delle risorse production
modules/ssm-parameters/       modulo riusabile SecureString write-only
scripts/                      guardrail account, Terraform e gestione ciphertext
.github/workflows/            validate su PR, plan+apply su push a main
```

`bootstrap/` è separato intenzionalmente: si applica soltanto da una workstation amministrativa con il profilo `andrea`. GitHub Actions applica esclusivamente `environments/production/`.

## Prerequisiti

- AWS CLI autenticata con il profilo `andrea`
- `mise`
- `gh` autenticata su GitHub
- `jq`

## Prima inizializzazione

```bash
make install
make check
make bootstrap
make apply
```

`make bootstrap`:

1. crea il bucket S3 iniziale in modo idempotente;
2. importa il bucket nello state;
3. applica KMS, hardening S3, OIDC e ruolo least-privilege;
4. configura le GitHub Actions variables `AWS_ACCOUNT_ID`, `AWS_REGION`, `TF_STATE_BUCKET` e `AWS_ROLE_ARN`.

I primi parametri generati automaticamente sono:

- `/n8n-demo/production/encryption-key`
- `/n8n-demo/production/postgres/password`
- `/crm-demo/production/demo/pocketbase/encryption-key`

`n8n-demo` è un workload autonomo: non condivide namespace o tag di progetto con `crm-demo`. Credenziali account-level usate da più workload, come Hetzner o Tailscale, appartengono invece a `/platform/production/*`.

Per ruotarne uno si incrementa il relativo campo `version` in `environments/production/main.tf`; il nuovo valore viene generato in modo effimero durante l'apply.

## Segreti esterni

Per Hetzner, Tailscale o altri valori già esistenti, scegliere il namespace del workload che li consumerà:

```bash
make secret-add KEY=hetzner_api_token SSM_PATH=/platform/production/hetzner/api-token
make plan
```

Il prompt è nascosto e il plaintext non compare negli argomenti di processo. Per non copiarlo neppure fra applicazioni, si può usare qualsiasi password manager che scriva su stdout; per esempio con 1Password:

```bash
op read -n 'op://Personal/Hetzner/token' | \
  make secret-add KEY=hetzner_api_token SSM_PATH=/platform/production/hetzner/api-token INPUT=--stdin
```

Per una rotazione:

```bash
make secret-rotate KEY=hetzner_api_token
```

La CLI incrementa `version` e aggiorna `secrets.auto.tfvars.json` con il solo ciphertext. Commit e push attivano plan e apply. I ciphertext vecchi restano nella storia Git ma non sono decifrabili senza autorizzazione sulla chiave KMS.

## Flusso quotidiano

```bash
make fmt
make check
make plan
make apply
```

Sul branch `main`, GitHub Actions esegue nuovamente plan e apply con credenziali temporanee. Le pull request eseguono soltanto controlli offline: non ricevono un token AWS.
