#!/usr/bin/env python3
"""Verify every clusters/{cluster}/apps/kustomization.yaml is complete and accurate.

Two checks per cluster, both aimed at the same failure mode: a new or
renamed app directory silently un-owned (or double-owned) by the root
`apps` Kustomization, because `kustomize build`/`flux-local diff` produce
an empty diff for a *missing* entry rather than an error.

1. Orphan check: every directory directly under apps/ must be referenced
   by at least one entry in the `resources:` list (matched on the entry's
   first path segment, so nested references like
   `ngx-webhook/manifests/deploy.yml` still count).
2. Stale check: every listed entry must resolve to an existing file, or -
   for a bare directory entry like `fluxcd` - an existing directory that
   itself contains a kustomization.yaml/.yml.
"""
import os
import sys

import yaml

DEFAULT_CLUSTERS = "kubenuc,k8s-vms-daniele,k3s-rabbit,oc-ampere"
KUSTOMIZATION_MARKERS = ("kustomization.yaml", "kustomization.yml")


def check_cluster(clusters_root, cluster):
    apps_dir = os.path.join(clusters_root, cluster, "apps")
    kfile = os.path.join(apps_dir, "kustomization.yaml")
    errors = []

    if not os.path.isfile(kfile):
        return [f"{cluster}: no apps/kustomization.yaml found at {kfile}"]

    with open(kfile) as f:
        doc = yaml.safe_load(f)
    resources = (doc or {}).get("resources") or []

    referenced_apps = set()
    for entry in resources:
        entry = entry.rstrip("/")
        full_path = os.path.join(apps_dir, entry)
        referenced_apps.add(entry.split("/")[0])

        if os.path.splitext(entry)[1] in (".yaml", ".yml"):
            if not os.path.isfile(full_path):
                errors.append(
                    f"{cluster}: resource '{entry}' in apps/kustomization.yaml "
                    "does not resolve to an existing file"
                )
        else:
            if not os.path.isdir(full_path):
                errors.append(
                    f"{cluster}: resource '{entry}' in apps/kustomization.yaml "
                    "does not resolve to an existing directory"
                )
            elif not any(
                os.path.isfile(os.path.join(full_path, marker))
                for marker in KUSTOMIZATION_MARKERS
            ):
                errors.append(
                    f"{cluster}: directory resource '{entry}' has no "
                    "kustomization.yaml/.yml of its own"
                )

    app_dirs = {
        name
        for name in os.listdir(apps_dir)
        if os.path.isdir(os.path.join(apps_dir, name))
    }
    for orphan in sorted(app_dirs - referenced_apps):
        errors.append(
            f"{cluster}: apps/{orphan}/ is not referenced by any entry in "
            "apps/kustomization.yaml (orphaned - will silently never be applied)"
        )

    return errors


def main():
    clusters_root = os.environ.get("APPS_KUSTOMIZATION_ROOT", "clusters")
    clusters = os.environ.get(
        "APPS_KUSTOMIZATION_CLUSTERS", DEFAULT_CLUSTERS
    ).split(",")

    all_errors = []
    for cluster in clusters:
        all_errors.extend(check_cluster(clusters_root, cluster))

    if all_errors:
        print("apps/kustomization.yaml check failed:\n")
        for error in all_errors:
            print(f"  - {error}")
        print(f"\n{len(all_errors)} problem(s) found across {len(clusters)} cluster(s).")
        sys.exit(1)

    print(
        f"OK: apps/kustomization.yaml verified clean for {len(clusters)} "
        "cluster(s) - no orphaned app directories, no stale entries."
    )


if __name__ == "__main__":
    main()
