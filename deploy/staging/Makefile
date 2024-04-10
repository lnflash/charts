TF:=terraform
REPO:=$(shell git rev-parse --show-toplevel)
ENV:=staging

init:
	terraform init

deploy-flash-deps: 
	$(TF) apply --target module.flash-deps -var-file=$(ENV)-secrets.tfvars 	

deploy-flash:	
	$(TF) apply --target helm_release.flash -var-file="$(ENV)-secrets.tfvars"

deploy-pay:
	$(TF) apply --target helm_release.flash-pay -var-file="$(ENV)-secrets.tfvars"

deploy-otel:
	$(TF) apply --target module.otel -var-file="$(ENV)-secrets.tfvars"

# Install CRDs prior to cert-manager
# Ref: https://cert-manager.io/docs/installation/helm/
# deploy-cert-manager:
# 	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.crds.yaml
#	$(TF) apply

deploy-all: 
	$(TF) apply -var-file="$(ENV)-secrets.tfvars"
