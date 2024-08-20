#!/bin/bash
kubectl delete -n rook-ceph cephblockpool ceph-blockpool
kubectl delete storageclass ceph-block
kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
kubectl -n rook-ceph delete cephcluster rook-ceph
