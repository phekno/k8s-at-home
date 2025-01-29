#!/bin/bash
kubectl apply -f disk-clean.yaml
kubectl apply -f disk-zap.yaml
kubectl delete pods disk-clean-0 disk-clean-1 disk-clean-2
kubectl delete pods disk-zap-0 disk-zap-1 disk-zap-2
