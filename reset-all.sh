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
echo "All resources deleted" 
