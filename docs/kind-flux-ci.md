# Kind FluxCD GitOps CI Pipeline

## 📖 Panoramica

Questa pipeline GitOps crea un ambiente di test effimero basato su **kind** (Kubernetes in Docker), **FluxCD**, e **GitHub Actions** per validare le modifiche alla configurazione GitOps prima del merge su `main`.

## 🏗️ Architettura

La pipeline implementa una strategia di **overlay Kustomize** per il cluster di test che:

1. **Crea un cluster kind effimero** per ogni feature branch o PR
2. **Bootstrap FluxCD** usando il branch corrente invece di `main`
3. **Applica patch specifiche per il test**:
   - Rimuove `pod_environment_secret: postgres-object-store-credentials` dal Postgres Operator
   - Esclude i CronJob di backup: `harbor-db-backup` e `nextcloud-db-backup`
4. **Verifica** che le risorse Flux siano applicate correttamente
5. **Esegue smoke test** per validare lo stato del cluster
6. **Distrugge il cluster** al termine (anche in caso di errore)

### Flusso della Pipeline

```
┌─────────────────┐
│  Push/PR        │
│  (non main)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Checkout Code   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ Setup Tools:                │
│ - kind                      │
│ - kubectl                   │
│ - flux CLI                  │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────┐
│ Create Kind     │
│ Cluster         │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────┐
│ Generate Test Overlay        │
│ (clusters/kubenuc-kind/)     │
│                              │
│ - Patch Postgres Operator    │
│ - Remove backup CronJobs     │
│ - Point to current branch    │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│ Commit & Push Overlay        │
│ to Current Branch            │
│ (temporary, for Flux clone)  │
└────────┬─────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ Bootstrap Flux               │
│ with MAIN branch             │
│ (stable configuration)       │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ Patch GitRepository          │
│ → Use Current Branch         │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ Patch Kustomization          │
│ → Use clusters/kubenuc-kind/ │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Wait for Reconciliation │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Verify:                 │
│ - No pod_env_secret     │
│ - No backup CronJobs    │
│ - Flux resources Ready  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────┐
│ Smoke Tests     │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ Cleanup:            │
│ - Remove overlay    │
│   from branch       │
│ - Delete cluster    │
└─────────────────────┘
```

## ⚠️ Nota Importante: Bootstrap con Main + Patch al Branch Corrente

La pipeline usa un approccio in **due fasi** per permettere a Flux di testare il branch corrente:

### Fase 1: Bootstrap con Main (Stabile)
1. **Bootstrap Flux** usando il branch `main` (sempre disponibile e stabile)
2. Flux scarica la configurazione da `clusters/kubenuc/` su `main`
3. Flux components si avviano correttamente con configurazione nota

### Fase 2: Switch al Branch Corrente
4. **Genera** l'overlay in `clusters/kubenuc-kind/`
5. **Committa e pusha** l'overlay sul branch corrente (con `[skip ci]`)
6. **Patch GitRepository**: cambia da `main` → branch corrente
7. **Patch Kustomization**: cambia path da `./clusters/kubenuc` → `./clusters/kubenuc-kind`
8. **Flux riconcilia** e applica le modifiche del branch feature con l'overlay di test

### Perché questo approccio?

✅ **Flux parte sempre da configurazione stabile** (main branch)
✅ **Poi switcha al branch di test** con le modifiche
✅ **Evita problemi di bootstrap** su branch potenzialmente incompleti
✅ **Testa esattamente le modifiche** del feature branch

**Risultato**: Il branch feature conterrà **temporaneamente** la cartella `clusters/kubenuc-kind/` durante l'esecuzione della pipeline, che verrà **rimossa automaticamente** al termine.

Se la pipeline fallisce prima del cleanup, puoi rimuovere manualmente l'overlay con:
```bash
git rm -rf clusters/kubenuc-kind/
git commit -m "cleanup: remove test overlay"
git push
```

## 🎯 Modifiche Specifiche per il Test Cluster

### 1. Postgres Operator - Rimozione `pod_environment_secret`

**Problema in produzione**: Il Postgres Operator è configurato con:
```yaml
configKubernetes:
  pod_environment_secret: postgres-object-store-credentials
```

Questa configurazione abilita il WAL (Write-Ahead Logging) su S3, necessario in produzione ma problematico nel cluster kind di test.

**Soluzione**: La pipeline genera automaticamente una versione modificata di `release.yml` che rimuove questa riga:

```bash
cat clusters/kubenuc/apps/postgresql/manifests/release.yml | \
  sed '/pod_environment_secret:/d' > \
  clusters/kubenuc-kind/apps/postgresql/manifests/release.yml
```

**File coinvolti**:
- Originale: `clusters/kubenuc/apps/postgresql/manifests/release.yml`
- Test overlay: `clusters/kubenuc-kind/apps/postgresql/manifests/release.yml` (generato dinamicamente)

### 2. Backup CronJobs - Esclusione da Test

**Risorse escluse**:
- `harbor-db-backup` (CronJob in namespace `harbor`)
- `nextcloud-db-backup` (CronJob in namespace `nextcloud-fastnetserv`)

**Soluzione**: La pipeline crea overlay che:
1. Copiano tutti i manifest **tranne** `backup.yml`
2. Creano `kustomization.yaml` che esclude esplicitamente i file di backup
3. Non copiano i secret S3 relativi ai backup

**File esclusi**:
- `clusters/kubenuc/apps/harbor/manifests/backup.yml`
- `clusters/kubenuc/apps/harbor/secrets/harbor-db-s3-backup.yml`
- `clusters/kubenuc/apps/nextcloud/manifests/backup.yml`
- `clusters/kubenuc/apps/nextcloud/secrets/nextcloud-db-s3-backup.yml`

**Kustomization generata** (esempio per Harbor):
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yml
  - redis.yml
  - release.yml
  # backup.yml è intenzionalmente ESCLUSO
```

## 🚀 Come Utilizzare la Pipeline

### Prerequisiti

Nessuno! La pipeline è completamente automatizzata e si attiva automaticamente.

### Attivazione Automatica

La pipeline si attiva automaticamente quando:

1. **Push su un feature branch** (qualsiasi branch tranne `main`):
   ```bash
   git checkout -b feature/my-new-feature
   git add .
   git commit -m "Add new feature"
   git push origin feature/my-new-feature
   ```

2. **Apertura di una Pull Request** verso `main`:
   ```bash
   # Dopo il push, apri una PR su GitHub
   gh pr create --title "My new feature" --body "Description"
   ```

### Monitoraggio della Pipeline

1. **Via GitHub UI**:
   - Vai su: `Actions` tab nel repository
   - Seleziona il workflow `Kind FluxCD GitOps CI`
   - Monitora i log di ogni step

2. **Via GitHub CLI**:
   ```bash
   # Lista tutti i workflow run
   gh run list --workflow=kind-flux-ci.yml

   # Visualizza i dettagli di un run specifico
   gh run view <run-id>

   # Visualizza i log in tempo reale
   gh run watch <run-id>
   ```

### Interpretazione dei Risultati

#### ✅ Pipeline Successo

La pipeline è considerata **SUCCESS** quando:
- Il cluster kind viene creato correttamente
- Flux bootstrap completa senza errori
- Le GitRepository e Kustomization sono `Ready`
- La verifica conferma:
  - `pod_environment_secret` NON presente nel Postgres Operator
  - CronJob `harbor-db-backup` NON esistente
  - CronJob `nextcloud-db-backup` NON esistente
- I smoke test passano

#### ❌ Pipeline Fallimento

In caso di errore, la pipeline:
1. **Cattura i log** di tutti i controller Flux
2. **Mostra gli eventi** del namespace `flux-system`
3. **Lista le risorse fallite** (Kustomization, HelmRelease)
4. **Distrugge il cluster** per cleanup

**Debugging**:
```bash
# Nei log della pipeline, cerca le sezioni:
# - "Show Flux events on failure"
# - "Logs from source-controller"
# - "Logs from kustomize-controller"
# - "Logs from helm-controller"
```

## 📁 Struttura Overlay Generata

Durante la pipeline, viene creata dinamicamente la cartella `clusters/kubenuc-kind/`:

```
clusters/kubenuc-kind/
├── flux-system/
│   ├── gotk-components.yaml         # Copiato da kubenuc
│   ├── gotk-sync.yaml                # MODIFICATO: branch corrente
│   └── kustomization.yaml            # Generato
├── apps/
│   ├── postgresql/
│   │   ├── deploy.yaml               # Kustomization che punta a kubenuc-kind
│   │   ├── manifests/
│   │   │   ├── namespace.yml         # Copiato
│   │   │   ├── release.yml           # PATCHED: senza pod_environment_secret
│   │   │   └── kustomization.yaml    # Generato
│   │   ├── secrets/                  # Copiati (senza S3 credentials)
│   │   └── db/                       # Copiato
│   ├── harbor/
│   │   ├── deploy.yaml               # Kustomization che punta a kubenuc-kind
│   │   ├── manifests/
│   │   │   ├── namespace.yml         # Copiato
│   │   │   ├── redis.yml             # Copiato
│   │   │   ├── release.yml           # Copiato
│   │   │   └── kustomization.yaml    # Generato (SENZA backup.yml)
│   │   │   # backup.yml è ESCLUSO
│   │   └── secrets/
│   │       └── kustomization.yaml    # Generato (SENZA harbor-db-s3-backup.yml)
│   ├── nextcloud/
│   │   ├── deploy.yaml               # Kustomization che punta a kubenuc-kind
│   │   ├── manifests/
│   │   │   ├── namespace.yml         # Copiato
│   │   │   ├── release.yml           # Copiato
│   │   │   └── kustomization.yaml    # Generato (SENZA backup.yml)
│   │   │   # backup.yml è ESCLUSO
│   │   └── secrets/
│   │       └── kustomization.yaml    # Generato (SENZA nextcloud-db-s3-backup.yml)
│   └── [altre app]/                  # Copiate senza modifiche
├── charts/                           # Copiato da kubenuc
├── apps.yaml                         # Copiato
└── charts.yaml                       # Copiato
```

**Nota importante**: Questa struttura è **effimera** e viene creata **solo durante l'esecuzione della pipeline**. NON viene committata nel repository.

## 🔧 Personalizzazione della Pipeline

### Modificare la Versione di Flux

Nel file [.github/workflows/kind-flux-ci.yml](.github/workflows/kind-flux-ci.yml):

```yaml
env:
  FLUX_VERSION: 2.4.0  # Cambia qui
```

### Modificare la Versione di Kind

```yaml
env:
  KIND_VERSION: v0.23.0  # Cambia qui
```

### Aggiungere Altre App da Escludere

Se vuoi escludere altre app dal cluster di test, aggiungi uno step simile:

```yaml
- name: Create MyApp manifests WITHOUT something
  run: |
    mkdir -p clusters/kubenuc-kind/apps/myapp/manifests

    # Copy all files except something.yml
    for file in clusters/kubenuc/apps/myapp/manifests/*.yml; do
      filename=$(basename "$file")
      if [ "$filename" != "something.yml" ]; then
        cp "$file" clusters/kubenuc-kind/apps/myapp/manifests/
      fi
    done
```

### Aggiungere Smoke Test Personalizzati

Aggiungi uno step dopo "Smoke test - Check all pods":

```yaml
- name: Custom smoke test
  run: |
    echo "=== Checking my custom resource ==="
    kubectl get myresource -n mynamespace
```

## 🛡️ Protezione della Configurazione di Produzione

**GARANZIA**: La configurazione in `clusters/kubenuc/` **NON viene mai modificata**.

Tutte le modifiche per il test avvengono in:
- Overlay generati dinamicamente in `clusters/kubenuc-kind/` (effimero)
- Memoria del runner GitHub Actions
- Mai committati nel repository

La configurazione di produzione resta **intatta e immutata**.

## 📊 Metriche e Timeout

- **Timeout totale pipeline**: 30 minuti
- **Timeout creazione cluster**: Default kind (~ 2-3 minuti)
- **Timeout Flux bootstrap**: 5 minuti per componente
- **Timeout GitRepository ready**: 5 minuti
- **Timeout reconciliation**: 30 secondi + monitoring

## 🐛 Troubleshooting

### Problema: GitRepository non diventa Ready

**Causa**: Branch non accessibile o repository privato senza credenziali.

**Soluzione**: La pipeline usa il repository pubblico. Se il tuo repo è privato, aggiungi:

```yaml
- name: Create GitHub token secret
  run: |
    kubectl create secret generic flux-system \
      --from-literal=username=git \
      --from-literal=password=${{ secrets.GITHUB_TOKEN }} \
      -n flux-system
```

### Problema: HelmRelease rimane in pending

**Causa**: Dipendenze non soddisfatte o chart non trovato.

**Debugging**:
```bash
# Nella pipeline, aggiungi:
kubectl describe helmrelease <nome> -n <namespace>
```

### Problema: Kustomization fallisce

**Causa**: Path non esistente o risorse malformate.

**Debugging**:
```bash
# Controlla i log del kustomize-controller:
kubectl logs -n flux-system -l app=kustomize-controller --tail=200
```

## 🔗 Riferimenti

- [FluxCD Documentation](https://fluxcd.io/docs/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Kustomize Documentation](https://kustomize.io/)

## ❓ FAQ

### La pipeline testa anche i secret?

No, i secret vengono copiati ma **non validati** (potrebbero contenere valori fittizi nel test).

### Posso eseguire la pipeline localmente?

Sì, puoi simulare la pipeline usando:
```bash
# Crea cluster kind
kind create cluster --name test

# Esegui manualmente gli step della pipeline
# (copia i comandi dalla workflow)
```

### La pipeline testa le immagini Docker?

No, la pipeline **NON build** immagini Docker. Testa solo la configurazione GitOps.

### Quanto costa eseguire questa pipeline?

Su GitHub Actions:
- **Repository pubblici**: GRATUITO (illimitato)
- **Repository privati**: Consuma minuti del piano (~ 5-10 minuti per run)
