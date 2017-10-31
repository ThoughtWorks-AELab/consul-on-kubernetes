#!/bin/bash
echo "Test that the consul_2 pod is alive"
TIME=0
while [[ $TIME -ne ${CONSUL_POD_TIMEOUT:=600} ]]; do
	sleep ${CONSUL_POD_INTERVAL:=10}
	((TIME+=$CONSUL_POD_INTERVAL))
	echo "TIME(/$CONSUL_POD_TIMEOUT): $TIME"
	OUTPUT=$(kubectl describe pod consul-2 2>&1)
	RC=$?
	if [[ $RC -eq 0 ]]; then
    echo "consul pods up"
		break
	fi
	if [[ $TIME -eq $CONSUL_POD_TIMEOUT ]]; then
		echo "TIMEOUT EXPIRED - Consul install failed?"
		exit 1
	fi
done

echo "Test that we can reach the consul install"
kubectl port-forward consul-0 8500:8500 &
KUBECTL_PID=$!
# writing this folder will not remove a folder if it exists or it's contents
# fully tested
TIME=0
while [[ $TIME -ne ${CONSUL_TEST_TIMEOUT:=600} ]]; do
	sleep ${CONSUL_TEST_INTERVAL:=10}
	((TIME+=$CONSUL_TEST_INTERVAL))
	echo "TIME(/$CONSUL_TEST_INTERVAL): $TIME"
	OUTPUT=$(consul members 2>&1)
	RC=$?
	if [[ $RC -eq 0 ]]; then
    kill $KUBECTL_PID
    echo "Testing Successful"
		break
	fi
	if [[ $TIME -eq $CONSUL_TEST_TIMEOUT ]]; then
		echo "TIMEOUT EXPIRED - Consul install failed?"
    kill $KUBECTL_PID
		exit 1
	fi
done
