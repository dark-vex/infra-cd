#!/bin/bash
# Test-only passive poll of the local Zabbix agent (no zabbix-get package on Debian 12).
#   zbx_poll.sh plain KEY
#   zbx_poll.sh psk   KEY PSK_HEX IDENTITY     (openssl s_client; the PSK is test data)
# Prints the reply with non-printable bytes blanked, so a test can look for "ZBXD" (the
# agent answered) or "ZBX_NOTSUPPORTED". An agent that refuses the connection prints nothing.
mode=$1
key=$2
# Zabbix request: "ZBXD" 0x01, the length as 8 little-endian bytes (keys here are < 256), key.
request() {
  printf 'ZBXD\001'
  printf "\\$(printf '%03o' "${#key}")\\000\\000\\000\\000\\000\\000\\000"
  printf '%s' "$key"
}
if [ "$mode" = plain ]; then
  exec 3<>/dev/tcp/127.0.0.1/10050 || exit 1
  request >&3
  timeout 3 cat <&3 | tr -c '[:print:]' ' '
else
  { request; sleep 2; } \
    | timeout 6 openssl s_client -quiet -tls1_2 -psk "$3" -psk_identity "$4" -connect 127.0.0.1:10050 2>/dev/null \
    | tr -c '[:print:]' ' '
fi
exit 0
