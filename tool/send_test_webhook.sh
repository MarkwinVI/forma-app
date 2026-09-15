#!/usr/bin/env bash
# Posts a synthetic RevenueCat "trial cancelled" event to the deployed
# revenuecat-webhook function, so the email path can be exercised without a
# real cancellation.
#
#   REVENUECAT_WEBHOOK_SECRET=... tool/send_test_webhook.sh <supabase-user-id>
#
# The event is marked SANDBOX, so it only goes through when the function has
# ALLOW_SANDBOX_EVENTS=true set (supabase secrets set ALLOW_SANDBOX_EVENTS=true).
# Each run uses a fresh event id, so the dedupe table never swallows it.

set -euo pipefail

: "${REVENUECAT_WEBHOOK_SECRET:?set REVENUECAT_WEBHOOK_SECRET to the value registered in RevenueCat}"
USER_ID="${1:?pass the Supabase user id (public.users.id) as the first argument}"
URL="${WEBHOOK_URL:-https://pcardimuewjcegourlgo.supabase.co/functions/v1/revenuecat-webhook}"

NOW_MS=$(( $(date +%s) * 1000 ))
EXPIRES_MS=$(( NOW_MS + 5 * 24 * 60 * 60 * 1000 ))
EVENT_ID="test-$(date +%s)"

BODY=$(cat <<JSON
{
  "api_version": "1.0",
  "event": {
    "id": "${EVENT_ID}",
    "type": "CANCELLATION",
    "environment": "SANDBOX",
    "period_type": "TRIAL",
    "cancel_reason": "UNSUBSCRIBE",
    "app_user_id": "${USER_ID}",
    "original_app_user_id": "${USER_ID}",
    "product_id": "forma_pro_monthly",
    "event_timestamp_ms": ${NOW_MS},
    "purchased_at_ms": ${NOW_MS},
    "expiration_at_ms": ${EXPIRES_MS},
    "store": "APP_STORE",
    "subscriber_attributes": {}
  }
}
JSON
)

echo "event id: ${EVENT_ID}"
curl -sS -w "\nHTTP %{http_code}\n" \
  -X POST "${URL}" \
  -H "Authorization: ${REVENUECAT_WEBHOOK_SECRET}" \
  -H "Content-Type: application/json" \
  -d "${BODY}"
