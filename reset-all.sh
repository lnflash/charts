#!/bin/bash

kubectl delete deployments --all && \
kubectl delete rs --all && \
kubectl delete pods --all && \
kubectl delete svc --all && \
kubectl delete daemonsets --all && \
kubectl delete statefulsets --all && \
kubectl delete jobs --all && \
kubectl delete cronjobs --all && \
kubectl delete configmaps --all && \
kubectl delete secrets --all && \
kubectl delete KafkaConnect kafka -n default && \
kubectl delete ServiceAccount kubemonkey -n default && \
echo "All resources deleted" 
