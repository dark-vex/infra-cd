# OCI Import Procedure

> **Note:** The `netbird` and `tailscale` Terraform configurations have been moved to the
> [`infra-vpn`](https://github.com/dark-vex/infra-vpn) repository. Manage VPN resources there.

---

## `terraform/oci/k8s-armchair/` — Workspace: `oci-k8s-armchair`

The `terraform/oci/k8s-armchair/` directory is a scaffold: the OCI provider is wired up with
`ResourcePrincipal` auth, but no `resource` or `module` blocks are declared yet. The OCI-side
resources for the `infra-vpn` rollout are expected to land here.

The general import workflow (once resources are declared):

1. Add resource/module blocks to `main.tf`
2. Add declarative `import {}` blocks (requires Terraform >= 1.5.0)
3. Run `terraform plan` to preview the import
4. Run `terraform apply` to record state

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
