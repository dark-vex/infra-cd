#!/bin/sh
# Runs INSIDE the built image (see .github/workflows/build-awx-ee.yml).
# Fails on the first problem.
set -eu

ansible --version | head -1
case "$(ansible --version | head -1)" in *2.21.*) ;; *) echo "unexpected ansible-core" >&2; exit 1 ;; esac
sops --version
ansible-runner --version
ansible-doc community.zabbix.zabbix_host >/dev/null
ansible-doc netbox.netbox.nb_inventory >/dev/null
test "$ANSIBLE_VARS_ENABLED" = "host_group_vars,community.sops.sops"
test "$ANSIBLE_INVENTORY_UNPARSED_FAILED" = "true"
# the env var name must be one ansible really reads
ansible-config dump | grep -q "INVENTORY_UNPARSED_IS_FAILED.*= True" || { echo "unparsed_is_failed not enabled" >&2; exit 1; }
test -w "$HOME"
ansible-doc -t vars community.sops.sops >/dev/null

# NetBox token templating (type follows the token prefix) against a stand-in server.
D=$(mktemp -d)
python3 /smoke/netbox-stub.py 18080 "$D/hdr" &
STUB=$!
trap 'kill $STUB 2>/dev/null || true' EXIT
sleep 1
cp /smoke/netbox.yml "$D/netbox.yml"
export NETBOX_API=http://127.0.0.1:18080
for tok in "nbt_abc.def:Bearer nbt_abc.def" "0123456789abcdef:Token 0123456789abcdef"; do
  : > "$D/hdr"
  NETBOX_TOKEN="${tok%%:*}" ansible-inventory -i "$D/netbox.yml" --list >/dev/null
  grep -qxF "${tok#*:}" "$D/hdr" || { echo "token header mismatch for ${tok%%:*}: $(sort -u "$D/hdr")" >&2; exit 1; }
done
# an unparseable inventory source must be a hard failure, not a warning
printf "plugin: netbox.netbox.nb_inventory\napi_endpoint: http://127.0.0.1:1\n" > "$D/dead.yml"
if ansible-inventory -i "$D/dead.yml" --list >/dev/null 2>&1; then echo "dead inventory source did not fail" >&2; exit 1; fi
echo "smoke test OK"
