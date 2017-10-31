#!/bin/bash
echo "Test that we can reach the consul install"
kubectl port-forward consul-0 8500:8500 &
KUBECTL_PID=$!
# writing this folder will not remove a folder if it exists or it's contents
# fully tested
TIME=0
while [[ $TIME -ne ${CONSUL_VAL_TIMEOUT:=600} ]]; do
	sleep ${KOPS_VAL_INTERVAL:=10}
	((TIME+=$KOPS_VAL_INTERVAL))
	echo "TIME(/$KOPS_VAL_TIMEOUT): $TIME"
	OUTPUT=$(consul members 2>&1)
	RC=$?
	if [[ $RC -eq 0 ]]; then
    kill $KUBECTL_PID
		break
	fi
	if [[ $TIME -eq $KOPS_VAL_TIMEOUT ]]; then
		echo "TIMEOUT EXPIRED - Consul install failed?"
    kill $KUBECTL_PID
		exit 1
	fi
done
