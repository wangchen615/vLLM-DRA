#!/bin/bash

function delay_command() {
  echo "Press any key to run: $@"
  read -n 1 -s
  sleep 2
  "$@"
}

#Create the resource
echo 

echo "Welcome to demo of running vLLM workloads on OpenShift with DRA enabled"

echo

delay_command oc apply -f vllm_dra_mig.yaml

pod_status=""
while [ "$pod_status" != "Running" ]; do
  pod_status=$(oc get pod -n gpu-test1 -l app=vllm -o jsonpath='{.items[0].status.phase}')
  if [ "$pod_status" != "Running" ]; then
    sleep 5
  fi
done

echo

#wait for server to come up
echo "Waiting for vLLM server to come up"

echo

sleep 10

oc logs -n gpu-test1 -l app=vllm

echo

# Port-forward the service
delay_command oc port-forward svc/vllm 8000:8000 -n gpu-test1 &
port_forward_pid=$!

# Wait for the port-forward to be ready
sleep 5

echo 

# Print the curl request
echo "Sending curl request:"
echo
delay_command echo "curl http://localhost:8000/v1/completions \
  -H \"Content-Type: application/json\" \
  -d '{
    \"model\": \"facebook/opt-125m\",
    \"prompt\": \"San Francisco is a\",
    \"max_tokens\": 7,
    \"temperature\": 0
  }'"

echo 
# Send the curl request
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "facebook/opt-125m",
    "prompt": "San Francisco is a",
    "max_tokens": 7,
    "temperature": 0
  }'

echo 
# Clean up the port-forward
kill $port_forward_pid
