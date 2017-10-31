#!/bin/sh
set -x
set -e
DIR_OF_ME=$(dirname $0)
DNS_ROOT=$1
if [[ -z $SUB_ACCOUNT_ID ]]; then
    echo "FATAL: \$SUB_ACCOUNT_ID not set"
    exit 1
fi

if [[ -z $DNS_ROOT ]]; then
    echo "FATAL: \$DNS_ROOT not set"
    exit 1
fi
CLUSTER=k8.$DNS_ROOT
echo "cluster is->$CLUSTER"

# # setup kubectl
echo "Setup kubectl"
CONTEXT_RESULT=$($DIR_OF_ME/assume_sub_account.sh $SUB_ACCOUNT_ID "kops export kubecfg $CLUSTER --state s3://di_tf_user_bucket")
RC=$?
if [[ $RC == 0 ]]; then
  echo "Context setup"
else
  echo "context failed"
  return $RC
fi;

# OUTPUT=$(kubectl apply -f fluentd-logzio/daemonset_fluentd_logzio.yaml --validate=false)
# RC=$?
# if [[ $RC == 0 ]]; then
#   echo "fluentd and logzio setup"
# else
#   echo "setup failed"
#   return $RC
# fi;

EXISTS=$(kubectl describe secrets consul)
RC=$?
if [[ RC == 1 ]]; then
  echo "creating new secret"
  cfssl gencert -initca ca/ca-csr.json | cfssljson -bare ca
  cfssl gencert -ca=ca.pem  -ca-key=ca-key.pem -config=ca/ca-config.json -profile=default ca/consul-csr.json | cfssljson -bare consul
  kubectl create secret generic consul  --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}"  --from-file=ca.pem  --from-file=consul.pem  --from-file=consul-key.pem
else
  echo "Secrets exist already"
fi
EXISTS=$(kubectl describe configmap consul)
RC=$?
if [[ RC == 1 ]]; then
  kubectl create configmap consul --from-file=configs/server.json
fi

kubectl apply -f services/consul.yaml
kubectl apply -f statefulsets/consul.yaml
