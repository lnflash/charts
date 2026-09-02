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

# kratos pre-persist/post-persist registration hook chain: NOT smoketested here.
#
# selfservice.flows.registration.after.password.hooks in charts/flash/values.yaml
# chains a pre-persist validation webhook (POST /kratos/preregistration) and the
# post-persist account-creation webhook (POST /kratos/registration) ahead of the
# session hook. An earlier version of this smoketest curled kratos-public
# directly to exercise a real registration through both hooks. Reverted: the
# `flash-kratos-public` ClusterIP service and its endpoint are confirmed present
# and healthy in this cluster (kubectl get svc/endpoints, galoy-dev-galoy
# namespace), yet DNS resolution of
# `flash-kratos-public.galoy-dev-galoy.svc.cluster.local` from the smoketest pod
# (a different namespace, galoy-dev-smoketest) failed for a sustained 60s in two
# separate CI runs, unlike the identically-shaped flash-oathkeeper-proxy and
# flash-price-history lookups above, which resolve immediately — most likely
# network segmentation between the two namespaces with no existing allow-rule
# for kratos. Root-causing that is an infra change, not a chart-code change, and
# out of scope here.
#
# The hook chain itself is not un-tested: flash's own
# test/flash/unit/dev/kratos-registration-hooks.spec.ts parses this repo's
# rendered dev/ory/kratos.yml and quickstart/dev/ory/kratos.yml and asserts the
# pre-persist hook is present and ordered ahead of the post-persist one, and
# flash#503 unit-tests the /kratos/preregistration route handler directly.

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
