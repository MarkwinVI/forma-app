#!/usr/bin/env bash
# Runs the deployed paywall-follow-up function by hand — as a dry run
# unless told otherwise — and prints its summary: who is in the 24–48 hour
# window, who was skipped and why, who would be (or was) emailed.
#
#   tool/run_paywall_follow_up.sh          # dry run: reports, sends nothing
#   tool/run_paywall_follow_up.sh --send   # a real run
#
# --send still sends nothing while the function has FOLLOW_UP_DRY_RUN=true;
# unset that secret to go live. The shared secret the call needs is read
# from Vault, so a logged-in, linked Supabase CLI is all this needs.

set -euo pipefail

URL="${FOLLOW_UP_URL:-https://pcardimuewjcegourlgo.supabase.co/functions/v1/paywall-follow-up}"
case "${1:-}" in
  --send) ;;
  "") URL="${URL}?dry_run=1" ;;
  *) echo "usage: $0 [--send]" >&2; exit 2 ;;
esac

SECRET=$(
  supabase db query --linked \
    "select decrypted_secret from vault.decrypted_secrets where name = 'paywall_follow_up_secret'" \
    2>/dev/null \
  | python3 -c 'import json,sys; rows=json.load(sys.stdin)["rows"]; print(rows[0]["decrypted_secret"] if rows else "")'
)
if [[ -z "${SECRET}" ]]; then
  echo "no paywall_follow_up_secret in Vault — run tool/setup_paywall_follow_up.sh first" >&2
  exit 1
fi

curl -sS -w "\nHTTP %{http_code}\n" \
  -X POST "${URL}" \
  -H "Authorization: ${SECRET}" \
  -H "Content-Type: application/json" \
  -d '{}'
