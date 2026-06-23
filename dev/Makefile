TF := terraform
REPO := $(shell git rev-parse --show-toplevel)
NS-PREFIX := galoy-dev
TF_VARS := -var-file=dev.tfvars
TF_REGTEST := $(TF_VARS) -var="bitcoin_network=regtest" -var="name_prefix=$(NS-PREFIX)"
HELM_DEP_CHARTS := ../charts/price ../charts/flash-deps ../charts/flash ../charts/flash-pay

.PHONY: create-cluster delete-cluster init deploy-services deploy all destroy-services fmt plan review delete run-galoy-smoketest run-flash-pay-smoketest

create-cluster:
	k3d cluster create --image rancher/k3s:v1.27.4-k3s1 -v "$(REPO):/charts" \
		--k3s-arg "--disable=traefik@server:0" \
		--k3s-arg "--disable=servicelb@server:0"

delete-cluster:
	k3d cluster delete --all
	rm -f terraform.tfstate

init:
	helm_home=$$(mktemp -d); helm_config=$$(mktemp -d); helm_cache=$$(mktemp -d); helm_data=$$(mktemp -d); docker_config=$$(mktemp -d); \
	trap 'rm -rf "$$helm_home" "$$helm_config" "$$helm_cache" "$$helm_data" "$$docker_config"' EXIT; \
	mkdir -p "$$helm_config" "$$helm_cache" "$$helm_data" "$$docker_config"; \
	printf '{"auths":{}}\n' > "$$helm_config/registry.json"; \
	printf '{"auths":{}}\n' > "$$docker_config/config.json"; \
	run_helm() { HOME="$$helm_home" DOCKER_CONFIG="$$docker_config" HELM_CONFIG_HOME="$$helm_config" HELM_CACHE_HOME="$$helm_cache" HELM_DATA_HOME="$$helm_data" HELM_REGISTRY_CONFIG="$$helm_config/registry.json" helm "$$@"; }; \
	run_helm repo add bitnami https://charts.bitnami.com/bitnami; \
	run_helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx; \
	run_helm repo add strimzi https://strimzi.io/charts/; \
	run_helm repo add kube-monkey https://asobti.github.io/kube-monkey/charts/repo; \
	run_helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts; \
	run_helm repo add ory https://k8s.ory.sh/helm/charts; \
	run_helm repo update; \
	for chart in $(HELM_DEP_CHARTS); do \
		run_helm dependency update --skip-refresh $$chart || exit $$?; \
	done
	$(TF) init

deploy-services:
	$(TF) apply $(TF_REGTEST) -target module.galoy_deps.helm_release.cert_manager -auto-approve
	$(TF) apply $(TF_REGTEST) -target module.galoy_deps -auto-approve

deploy:
	$(TF) apply $(TF_REGTEST) -auto-approve

all: create-cluster init deploy-services deploy

destroy-services:
	$(TF) destroy $(TF_REGTEST) -auto-approve

run-galoy-smoketest:
	kubectl -n $(NS-PREFIX)-smoketest exec smoketest -- bash -c "cd /charts/ci/tasks && \
		CHART=galoy ./dev-smoketest-settings.sh && \
		./galoy-smoketest.sh && \
		rm -rf smoketest-settings response.json"

run-flash-pay-smoketest:
	kubectl -n $(NS-PREFIX)-smoketest exec smoketest -- bash -c "cd /charts/ci/tasks && \
		CHART=galoy-pay ./dev-smoketest-settings.sh && \
		./galoy-pay-smoketest.sh && \
		rm -rf smoketest-settings response.json"

fmt:
	cd ..
	$(TF) fmt -recursive

plan:
	$(TF) plan $(TF_REGTEST)

review:
	$(TF) show -json | jq

delete:
	kubectl delete namespace $(ns) --force
