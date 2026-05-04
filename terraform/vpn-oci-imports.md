# VPN & OCI Import Procedure

Branch: `feat/terraform-oci-netbird-tailscale`

All three root configurations (`netbird`, `tailscale`, `oci/k8s-armchair`) are scaffolds: providers, Terraform Cloud backends, and 1Password data sources are wired up, but no `resource` or `module` blocks are declared yet. The import workflow for each is:

1. Add resource/module blocks to `main.tf`
2. Add declarative `import {}` blocks (requires Terraform >= 1.5.0, which all three workspaces enforce)
3. Run `terraform plan` to preview the import
4. Run `terraform apply` to record state

---

## `terraform/netbird/` — Workspace: `netbird`

**Resources to declare and import:**

| Resource type | Description |
|---|---|
| `netbird_group` | Peer groups for policy targeting |
| `netbird_policy` | Access control policies between groups |
| `netbird_route` | Network routes distributed to peers |
| `netbird_dns` | DNS nameserver configurations |
| `netbird_setup_key` | Setup keys for enrolling new peers |

IDs are UUIDs from the Netbird management API. Retrieve them from the Netbird UI or API.

**Import block pattern:**

```hcl
import {
  id = "<group-uuid>"
  to = netbird_group.example
}

resource "netbird_group" "example" {
  # fill in attributes after first plan
}
```

Reference: <https://registry.terraform.io/providers/netbirdio/netbird/latest/docs>

---

## `terraform/tailscale/` — Workspace: `tailscale`

**Resources to declare and import:**

| Resource type | Description | Import ID |
|---|---|---|
| `tailscale_acl` | ACL policy (HuJSON format) | tailnet name (e.g. `example.ts.net`) |
| `tailscale_dns_nameservers` | Global DNS nameservers | tailnet name |
| `tailscale_dns_split_nameservers` | Split DNS per domain | tailnet name + domain |
| `tailscale_dns_preferences` | MagicDNS toggle | tailnet name |
| `tailscale_tailnet_key` | Auth keys for device enrollment | key ID |

**Import block pattern:**

```hcl
import {
  id = "<tailnet>"
  to = tailscale_acl.main
}

resource "tailscale_acl" "main" {
  acl = jsonencode({
    # paste existing HuJSON policy
  })
}
```

> **Note:** The Portainer Tailscale sidecar (`clusters/kubenuc/apps/portainer/`) uses a
> separate auth key backed by a 1Password Kubernetes secret
> (`clusters/kubenuc/apps/portainer/secrets/tailscale-auth.yml`). Manage that key here
> via `tailscale_tailnet_key` and sync it back to 1Password.

Reference: <https://registry.terraform.io/providers/tailscale/tailscale/latest/docs>

---

## `terraform/oci/k8s-armchair/` — Workspace: `oci-k8s-armchair`

The `terraform/modules/oci-instance/` module is complete and ready to use. It manages a
single `oci_core_instance` with Flex shape support, boot volume, VNIC, and SSH key
injection. It has `prevent_destroy = true` and ignores changes to `metadata` and
`source_details[0].source_id`.

**Step 1 — Add a module call to `main.tf`:**

```hcl
module "k8s_arm" {
  source = "../../modules/oci-instance"

  display_name        = "k8s-armchair-01"
  compartment_id      = "<compartment-ocid>"
  availability_domain = "<ad-name>"
  shape               = "VM.Standard.A1.Flex"
  ocpus               = 4
  memory_in_gbs       = 24
  image_id            = "<image-ocid>"
  subnet_id           = "<subnet-ocid>"
  ssh_authorized_keys = "<public-key>"
  assign_public_ip    = true
  boot_volume_size_in_gbs = 50
}
```

**Step 2 — Add an import block for each existing instance:**

```hcl
import {
  id = "ocid1.instance.oc1.<region>.<instance-ocid>"
  to = module.k8s_arm.oci_core_instance.this
}
```

**Step 3 — Apply:**

```bash
cd terraform/oci/k8s-armchair
terraform init
terraform plan    # previews import — verify no destructive changes
terraform apply   # records instance into state
```

OCIDs can be found in the OCI Console under **Compute → Instances** or via:

```bash
oci compute instance list --compartment-id <compartment-ocid> --query 'data[].id'
```
