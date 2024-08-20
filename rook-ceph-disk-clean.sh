#!/bin/bash
kubectl apply -f disk-clean.yaml
kubectl apply -f disk-wipe.yaml
kubectl delete pods disk-clean-0 disk-clean-1 disk-clean-2
kubectl delete pods disk-wipe-0 disk-wipe-1 disk-wipe-2
