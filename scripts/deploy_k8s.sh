#!/bin/bash
# Deploy Kubernetes resources (Assumes kubectl is set up)
kubectl apply -f pod.yaml
kubectl rollout restart deployment loadbalancer-pod
