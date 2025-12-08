# 📚 Esempi Pratici: Testing GitOps Changes

Questa guida mostra esempi pratici di come testare modifiche GitOps usando la pipeline Kind FluxCD CI.

## 🎯 Esempio 1: Aggiornare una Chart Helm

### Scenario
Vuoi aggiornare Harbor da versione 2.11.0 a 2.12.0.

### Procedura

#### 1. Crea un feature branch

```bash
git checkout -b feature/harbor-upgrade-2.12.0
```

#### 2. Modifica la configurazione

Edita il file [clusters/kubenuc/apps/harbor/manifests/release.yml](../../clusters/kubenuc/apps/harbor/manifests/release.yml):

```yaml
# Prima (linea ~13)
spec:
  chart:
    spec:
      chart: harbor
      version: "2.11.0"  # ← Cambia questa versione

# Dopo
spec:
  chart:
    spec:
      chart: harbor
      version: "2.12.0"  # ← Nuova versione
```

#### 3. Commit e push

```bash
git add clusters/kubenuc/apps/harbor/manifests/release.yml
git commit -m "chore(harbor): upgrade to v2.12.0"
git push origin feature/harbor-upgrade-2.12.0
```

#### 4. Monitora la pipeline

La pipeline parte automaticamente! Vai su GitHub Actions:

```bash
gh run watch
# oppure
gh run list --workflow=kind-flux-ci.yml --branch feature/harbor-upgrade-2.12.0
```

#### 5. Verifica i risultati

La pipeline:
- ✅ Crea cluster kind
- ✅ Installa Flux
- ✅ Applica la nuova configurazione Harbor v2.12.0
- ✅ Verifica che Harbor si avvii correttamente
- ✅ Conferma che i backup CronJob NON sono presenti (come atteso)

#### 6. Crea PR se test passano

```bash
gh pr create \
  --title "chore(harbor): upgrade to v2.12.0" \
  --body "Upgrade Harbor Helm chart from 2.11.0 to 2.12.0

## Changes
- Updated Harbor chart version

## Testing
- ✅ CI pipeline passed
- ✅ Harbor deployed successfully in kind cluster
- ✅ No backup CronJobs (as expected in test)
"
```

#### 7. Merge

Una volta approvata la PR:

```bash
gh pr merge --auto --squash
```

---

## 🎯 Esempio 2: Aggiungere una Nuova Applicazione

### Scenario
Vuoi aggiungere una nuova app chiamata `whoami` per test.

### Procedura

#### 1. Crea feature branch

```bash
git checkout -b feature/add-whoami-app
```

#### 2. Crea la struttura dell'app

```bash
mkdir -p clusters/kubenuc/apps/whoami/manifests
```

#### 3. Crea i manifest

**Namespace** (`clusters/kubenuc/apps/whoami/manifests/namespace.yml`):

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: whoami
```

**Deployment** (`clusters/kubenuc/apps/whoami/manifests/deployment.yml`):

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  namespace: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
      - name: whoami
        image: traefik/whoami:v1.10.1
        ports:
        - containerPort: 80
```

**Service** (`clusters/kubenuc/apps/whoami/manifests/service.yml`):

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: whoami
  namespace: whoami
spec:
  selector:
    app: whoami
  ports:
  - port: 80
    targetPort: 80
```

**Kustomization** (`clusters/kubenuc/apps/whoami/manifests/kustomization.yaml`):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yml
  - deployment.yml
  - service.yml
```

#### 4. Crea il deploy Flux

**Deploy** (`clusters/kubenuc/apps/whoami/deploy.yaml`):

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: whoami
  namespace: flux-system
spec:
  interval: 15m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./clusters/kubenuc/apps/whoami/manifests
  prune: true
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: whoami
      namespace: whoami
```

#### 5. Commit e push

```bash
git add clusters/kubenuc/apps/whoami/
git commit -m "feat(whoami): add whoami test application"
git push origin feature/add-whoami-app
```

#### 6. Monitora CI

```bash
gh run watch
```

La pipeline testerà automaticamente la nuova app nel cluster kind!

#### 7. Verifica che l'app si avvii

Controlla i log della pipeline, sezione "Smoke test - Check all pods":

```
NAMESPACE   NAME                      READY   STATUS    RESTARTS   AGE
whoami      whoami-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
whoami      whoami-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
```

#### 8. Crea PR

```bash
gh pr create \
  --title "feat(whoami): add whoami test application" \
  --body "Add whoami application for testing purposes"
```

---

## 🎯 Esempio 3: Modificare Configurazione PostgreSQL Operator

### Scenario
Vuoi cambiare il `cluster_name_label` del Postgres Operator.

### ⚠️ Nota Importante
La pipeline CI **rimuove automaticamente** `pod_environment_secret` per il test, ma mantiene altre modifiche.

### Procedura

#### 1. Crea feature branch

```bash
git checkout -b feature/postgres-cluster-name-update
```

#### 2. Modifica la configurazione

Edita [clusters/kubenuc/apps/postgresql/manifests/release.yml](../../clusters/kubenuc/apps/postgresql/manifests/release.yml):

```yaml
values:
  configKubernetes:
    cluster_name_label: ranchernuc-new  # ← Cambia da 'ranchernuc' a 'ranchernuc-new'
    pod_environment_secret: postgres-object-store-credentials
```

#### 3. Commit e push

```bash
git add clusters/kubenuc/apps/postgresql/manifests/release.yml
git commit -m "chore(postgres): update cluster_name_label"
git push origin feature/postgres-cluster-name-update
```

#### 4. Verifica nella pipeline

La pipeline:
1. Applica il tuo cambio (`cluster_name_label: ranchernuc-new`)
2. **Rimuove automaticamente** `pod_environment_secret` (solo per test)
3. Verifica che il Postgres Operator si avvii con la nuova config

#### 5. Risultato atteso nel test

Nel cluster kind, il Postgres Operator avrà:

```yaml
values:
  configKubernetes:
    cluster_name_label: ranchernuc-new  # ← La tua modifica
    # pod_environment_secret rimosso automaticamente per test
```

#### 6. In produzione (dopo merge)

In produzione (`clusters/kubenuc/`), il file **originale** resta intatto:

```yaml
values:
  configKubernetes:
    cluster_name_label: ranchernuc-new  # ← La tua modifica
    pod_environment_secret: postgres-object-store-credentials  # ← Rimane in produzione!
```

---

## 🎯 Esempio 4: Aggiungere un Secret (Senza Valori Reali)

### Scenario
Vuoi aggiungere un nuovo secret per un'app, ma non vuoi committare credenziali reali.

### Procedura

#### 1. Crea feature branch

```bash
git checkout -b feature/add-myapp-secret
```

#### 2. Crea un secret template

`clusters/kubenuc/apps/myapp/secrets/myapp-credentials.yml`:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: myapp-credentials
  namespace: myapp
type: Opaque
stringData:
  username: "PLACEHOLDER_USERNAME"  # ← Placeholder, non credenziali reali
  password: "PLACEHOLDER_PASSWORD"  # ← Da sostituire in produzione
```

#### 3. Aggiungi note nel commit

```bash
git add clusters/kubenuc/apps/myapp/secrets/myapp-credentials.yml
git commit -m "feat(myapp): add credentials secret template

NOTE: Placeholder values only. Real credentials must be:
- Updated via Sealed Secrets / SOPS / Vault
- Never committed to Git
"
git push origin feature/add-myapp-secret
```

#### 4. Pipeline behavior

La pipeline:
- ✅ Copia il secret con placeholder
- ✅ Applica al cluster kind (con placeholder, ok per test struttura)
- ⚠️ L'app potrebbe non avviarsi se richiede credenziali valide

#### 5. Nota per produzione

Nel PR, specifica:

```markdown
## ⚠️ Post-Merge Action Required

After merge, update the secret with real credentials using:

\`\`\`bash
# Option 1: Sealed Secrets
kubeseal --format=yaml < secret.yml > sealed-secret.yml

# Option 2: SOPS
sops -e secret.yml > secret.enc.yml

# Option 3: Manual kubectl
kubectl create secret generic myapp-credentials \
  --from-literal=username=REAL_USER \
  --from-literal=password=REAL_PASS \
  -n myapp
\`\`\`
```

---

## 🎯 Esempio 5: Testare un Cambio Breaking (Intenzionale)

### Scenario
Vuoi testare cosa succede se rompi una configurazione (per vedere se la pipeline lo cattura).

### Procedura

#### 1. Crea feature branch

```bash
git checkout -b test/break-harbor-config
```

#### 2. Introduci un errore intenzionale

Edita [clusters/kubenuc/apps/harbor/manifests/release.yml](../../clusters/kubenuc/apps/harbor/manifests/release.yml):

```yaml
spec:
  chart:
    spec:
      chart: harbor
      version: "99.99.99"  # ← Versione inesistente!
```

#### 3. Commit e push

```bash
git add clusters/kubenuc/apps/harbor/manifests/release.yml
git commit -m "test: intentionally break Harbor config"
git push origin test/break-harbor-config
```

#### 4. Pipeline fallisce (come atteso!)

La pipeline fallirà con:

```
Error: failed to download "harbor" chart with version "99.99.99"
```

#### 5. Analizza i log

Nella sezione "Show Flux events on failure":

```
LAST SEEN   TYPE     REASON                OBJECT                MESSAGE
2m ago      Warning  ChartPullFailed       HelmRelease/harbor    chart version "99.99.99" not found
```

#### 6. Fix e re-test

```bash
# Ripristina la versione corretta
git revert HEAD
git push origin test/break-harbor-config

# La pipeline riparte automaticamente e passa ✅
```

---

## 🎯 Esempio 6: Test Locale Prima del Push

### Scenario
Vuoi testare localmente prima di pushare.

### Procedura

#### 1. Usa lo script helper

```bash
# Rendi eseguibile lo script
chmod +x scripts/test-kind-flux-local.sh

# Esegui
./scripts/test-kind-flux-local.sh
```

Lo script:
1. Crea cluster kind locale
2. Genera overlay come fa la CI
3. Installa Flux
4. Applica configurazioni
5. Verifica che tutto funzioni

#### 2. Interagisci con il cluster

```bash
# Verifica Flux
flux get all -A

# Verifica pods
kubectl get pods -A

# Verifica HelmRelease specifico
kubectl get helmrelease harbor -n harbor -o yaml

# Test port-forward
kubectl port-forward -n harbor svc/harbor 8080:80
# Visita: http://localhost:8080
```

#### 3. Debug se necessario

```bash
# Logs Flux controllers
kubectl logs -n flux-system -l app=helm-controller --tail=100

# Describe risorsa fallita
kubectl describe helmrelease harbor -n harbor

# Eventi namespace
kubectl get events -n harbor --sort-by='.lastTimestamp'
```

#### 4. Cleanup dopo test

```bash
# Distruggi cluster
kind delete cluster --name kind-test-local

# Rimuovi overlay
rm -rf clusters/kubenuc-kind
```

#### 5. Push se tutto ok

```bash
git push origin your-feature-branch
```

---

## 📊 Tabella Riepilogativa: Quando Usare Cosa

| Scenario | Test Locale | Pipeline CI | Produzione |
|----------|-------------|-------------|------------|
| Quick test modifica | ✅ Usa script locale | - | - |
| Validazione pre-PR | ✅ Usa script locale | ✅ Push feature branch | - |
| PR review | - | ✅ Automatico su PR | - |
| Deploy produzione | - | - | ✅ Merge su main |
| Debug approfondito | ✅ Port-forward, logs | ⚠️ Log limitati | ✅ Accesso completo |

---

## 🔧 Tips & Tricks

### Velocizzare i Test Locali

```bash
# Riusa il cluster se esiste
if kind get clusters | grep -q "kind-test"; then
  echo "Cluster già esistente, riuso"
else
  # crea nuovo cluster
fi
```

### Testare Solo una App Specifica

Modifica lo script locale per copiare solo l'app che ti interessa:

```bash
# Invece di copiare tutto clusters/kubenuc/apps/
# Copia solo l'app target
cp -r clusters/kubenuc/apps/myapp clusters/kubenuc-kind/apps/
```

### Vedere Diff tra Produzione e Test

```bash
# Dopo generazione overlay
diff -r clusters/kubenuc/apps/postgresql/manifests/ \
        clusters/kubenuc-kind/apps/postgresql/manifests/

# Output mostra rimozione pod_environment_secret
```

### Skip Reconciliation per Debug

```bash
# Sospendi reconciliation Flux
flux suspend kustomization myapp

# Debug manuale
kubectl apply -f my-test-manifest.yml

# Riprendi reconciliation
flux resume kustomization myapp
```

---

## ❓ FAQ

### Q: La pipeline fallisce ma localmente funziona?

**A**: Possibili cause:
- Branch non pushato su GitHub (Flux non può clonare)
- Secret mancanti in CI (in locale li hai)
- Differenze nella versione Flux/Kubernetes

### Q: Come testo modifiche a secret criptati (Sealed Secrets)?

**A**:
1. Decripta localmente (se hai accesso)
2. Testa nel cluster locale con secret non criptato
3. In CI, la pipeline testa la struttura (ma non i valori)

### Q: Posso testare modifiche a `main` branch?

**A**: No, la pipeline triggera solo su branch NON-main. Per testare `main`:
```bash
git checkout -b test/main-validation
git push origin test/main-validation
```

### Q: Come testo una nuova versione di Postgres Operator?

**A**: Modifica `version` in `release.yml` e segui **Esempio 1**.

---

## 📚 Riferimenti

- [Documentazione completa pipeline](../kind-flux-ci.md)
- [Quick Start](../../KIND-FLUX-CI-README.md)
- [FluxCD Best Practices](https://fluxcd.io/flux/guides/)
- [Kustomize Overlays](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#overlay)

---

**Hai altri esempi da aggiungere?** Contribuisci aprendo una PR! 🚀
