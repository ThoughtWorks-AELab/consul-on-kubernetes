#!/bin/sh
set -x
set -e

cfssl gencert -initca ca/ca-csr.json | cfssljson -bare ca
cfssl gencert -ca=ca.pem  -ca-key=ca-key.pem -config=ca/ca-config.json -profile=default ca/consul-csr.json | cfssljson -bare consul

kubectl create secret generic consul  --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}"  --from-file=ca.pem  --from-file=consul.pem  --from-file=consul-key.pem
kubectl create configmap consul --from-file=configs/server.json
kubectl create -f services/consul.yaml
kubectl create -f statefulsets/consul.yaml
