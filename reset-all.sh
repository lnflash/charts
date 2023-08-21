#!/bin/bash

kubectl delete deployments "$1" && \
kubectl delete rs "$1" && \
kubectl delete pods "$1" && \
kubectl delete svc "$1" && \
kubectl delete daemonsets "$1" && \
kubectl delete statefulsets "$1" && \
kubectl delete jobs "$1" && \
kubectl delete cronjobs "$1" && \
kubectl delete configmaps "$1" && \
kubectl delete secrets "$1" && \
echo "All resources deleted" 
