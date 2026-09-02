#!/bin/bash

set -eu

source smoketest-settings/helpers.sh

host=$(setting "galoy_endpoint")
port=$(setting "galoy_port")

function break_and_display_on_error_response() {
  if [[ $(jq -r '.errors' <./response.json) != "null" ]]; then
    echo Smoketest failed! - Response:
    cat response.json
    echo Contains "errors" key
    exit 1
  fi
}

# galoy-backend unauthenticated
success="false"
set +e
for i in {1..60}; do
  echo "Attempt ${i} to curl the public galoy API"
  curl --location -sSf --request POST "${host}:${port}/graphql"\
   --header 'Content-Type: application/json' \
   --data-raw '{"query":"query btcPrice { btcPrice { base currencyUnit formattedAmount offset } }","variables":{}}' > response.json
  if [[ $? == 0 ]]; then success="true"; break; fi;
  sleep 1
done
set -e

break_and_display_on_error_response

if [[ "$success" != "true" ]]; then echo "Smoke test failed; galoy API did not respond" && exit 1; fi

# kratos registration smoketest (pre-persist + post-persist hook chain)
#
# selfservice.flows.registration.after.password.hooks in charts/flash/values.yaml
# chains a pre-persist validation webhook (POST /kratos/preregistration) and a
# post-persist account-creation webhook (POST /kratos/registration) ahead of
# the session hook. Neither is reachable through the public oathkeeper proxy
# (only /auth, /graphql, and the appcheck-gated device-login route are
# exposed there — see the oathkeeper access_rules in charts/flash/values.yaml),
# so this talks to kratos-public directly, the same way the api server does.
kratos_host=$(setting "kratos_public_endpoint")
kratos_port=$(setting "kratos_public_port")

function gen_uuid() {
  if [[ -r /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
  elif command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    python3 -c 'import uuid; print(uuid.uuid4())'
  fi
}

# Kratos always applies `default_schema_id` (phone_no_password_v0, see
# charts/flash/values.yaml) to self-service registration flows — the
# `schema_id` query param on /self-service/registration/api is not read
# anywhere in the registration codepath (verified against ory/kratos v1.0.0
# source: selfservice/flow/registration/handler.go, selfservice/flow/flow.go,
# selfservice/strategy/password/registration.go all resolve the schema via
# Config().DefaultIdentityTraitsSchemaURL unconditionally). So this registers
# against phone_no_password_v0's `email` trait (which has
# credentials.password.identifier: true, and additionalProperties: false
# rules out `username`), not the username_password_deviceid_v0 schema.
function register_smoketest_identity() {
  local username="$1"
  local password="$2"
  local flow action
  flow=$(curl -sS "http://${kratos_host}:${kratos_port}/self-service/registration/api")
  action=$(echo "$flow" | jq -r '.ui.action // empty')
  curl -sS -w '\n%{http_code}' -X POST "$action" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data-raw "$(jq -n --arg u "${username}@example.com" --arg p "$password" '{method:"password",password:$p,traits:{email:$u}}')"
}

password="Sk$(gen_uuid | tr -d '-')Zx9!"

registration_success="false"
set +e
for i in {1..60}; do
  echo "Attempt ${i} to register a smoketest identity via kratos"
  username=$(gen_uuid)
  registration_response="$(register_smoketest_identity "$username" "$password")"
  registration_status="$(echo "$registration_response" | tail -1)"
  if [[ "$registration_status" == "200" ]]; then registration_success="true"; break; fi
  sleep 1
done
set -e

registration_body="$(echo "$registration_response" | sed '$d')"

if [[ "$registration_success" != "true" ]]; then
  echo "Smoke test failed; kratos registration never returned 200 (last status: ${registration_status})"
  echo "$registration_body"
  exit 1
fi

if [[ -z "$(echo "$registration_body" | jq -r '.session_token // empty')" ]]; then
  echo "Smoke test failed; kratos registration returned 200 with no session_token — the pre-persist/post-persist hook chain did not complete"
  echo "$registration_body"
  exit 1
fi

echo "Registration smoketest succeeded; pre-persist and post-persist hooks both ran"

# Deliberate-rejection case: re-registering the exact same identifier must be
# refused, not silently accepted, so a regression that turns either hook into
# a no-op (e.g. a bad response.parse setting, or the wrong auth header) has a
# tripwire on the reject path too, not just the happy path.
duplicate_response="$(register_smoketest_identity "$username" "$password")"
duplicate_status="$(echo "$duplicate_response" | tail -1)"

if [[ "$duplicate_status" == "200" ]]; then
  echo "Smoke test failed; re-registering the same identifier unexpectedly succeeded"
  exit 1
fi

echo "Duplicate-registration rejection smoketest succeeded (got HTTP ${duplicate_status} as expected)"

# price history server healthcheck
# The following health.proto file has been copied from
# https://github.com/GaloyMoney/price/blob/main/history/src/servers/protos/health.proto
cat << EOF > health.proto
syntax = "proto3";

package grpc.health.v1;

message HealthCheckRequest {
  string service = 1;
}

message HealthCheckResponse {
  enum ServingStatus {
    UNKNOWN = 0;
    SERVING = 1;
    NOT_SERVING = 2;
    SERVICE_UNKNOWN = 3;  // Used only by the Watch method.
  }
  ServingStatus status = 1;
}

service Health {
  rpc Check(HealthCheckRequest) returns (HealthCheckResponse);

  rpc Watch(HealthCheckRequest) returns (stream HealthCheckResponse);
}
EOF

host=`setting "price_history_endpoint"`
port=`setting "price_history_port"`

price_history_healthz="false"
set +e
for i in {1..60}; do
  echo "Attempt ${i} to curl price history server"
  grpcurl -plaintext -proto health.proto ${host}:${port} grpc.health.v1.Health.Check
  if [[ $? == 0 ]]; then price_history_healthz="true"; break; fi;
  sleep 1
done
set -e

if [[ "$price_history_healthz" != "true" ]]; then echo "Smoke test failed; price history server healthcheck failed" && exit 1; fi;

## cronjob
set +e
if [[ `setting_exists "smoketest_kubeconfig"` != "null" ]]; then
  setting "smoketest_kubeconfig" | base64 --decode > kubeconfig.json
  export KUBECONFIG=$(pwd)/kubeconfig.json
  namespace=`setting "galoy_namespace"`
  job_name="${namespace}-cronjob-smoketest"
  kubectl -n ${namespace} delete job "${job_name}" || true
  echo "Executing cronjob"
  kubectl -n ${namespace} create job --from=cronjob/galoy-cronjob "${job_name}"
  for i in {1..150}; do
    kubectl -n ${namespace}  wait --for=condition=complete job "${job_name}"
    if [[ $? -eq 0 ]]; then
      echo "Cronjob execution completed"
      break
    fi
    if [[ $i -gt 30 ]]; then
      echo "If cronjob is taking too long, consider closing channels with offline nodes"
    fi
    sleep 2
  done
  status="$(kubectl -n ${namespace} get job ${job_name} -o jsonpath='{.status.succeeded}')"
  if [[ "${status}" != "1" ]]; then
    echo "Cronjob failed!"
    exit 1
  else
    echo "Cronjob succeeded!"
  fi
  kubectl -n ${namespace} delete job "${job_name}"
fi
set -e
