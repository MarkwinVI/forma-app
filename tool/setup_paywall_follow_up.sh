#!/usr/bin/env bash
# Mints the shared secret the hourly cron job presents to the deployed
# paywall-follow-up function and stores it at both ends: as the function's
# PAYWALL_FOLLOW_UP_SECRET and in Vault, where the cron job reads it. The
# value is never printed; tool/run_paywall_follow_up.sh fetches it from
# Vault when it needs it.
#
#   tool/setup_paywall_follow_up.sh
#
# Needs a logged-in Supabase CLI linked to the project. Run it once: Vault
# refuses a second secret with the same name.

set -euo pipefail

SECRET=$(openssl rand -hex 32)

supabase secrets set "PAYWALL_FOLLOW_UP_SECRET=${SECRET}"
supabase db query --linked \
  "select vault.create_secret('${SECRET}', 'paywall_follow_up_secret', 'Authorization header the paywall-follow-up cron job sends')" \
  > /dev/null

echo "PAYWALL_FOLLOW_UP_SECRET set on the function and stored in Vault."
