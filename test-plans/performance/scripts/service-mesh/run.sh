testname=${NAME:-"$(date +%s)-test-run"}
store=${STORE:-true}
hubble=${HUBBLE:-true}
export start=$(date +%s)
sleep 120 # provide a quiet time prior to kicking off the workload.
for n in {1..3}; do 
   kubectl exec $(kubectl get pods -l app=workload -o custom-columns=:.metadata.name --no-headers) -- nighthawk_client --duration 60 --rps 5000 --connections 10 --concurrency auto -v info http://baseline:9080/ | tee ${testname}-${n}.out
  sleep 120 
done 
export end=$(date +%s)
if $store; then
    kube-burner index -c burner.yaml -m rook-node-v2.yaml -t $token -u http://127.0.0.1:9090 --start $start --end $end --uuid $end-${testname}-nohubble 
fi

if $hubble; then
  cilium hubble enable 
  sleep 120

  export start=$(date +%s)
  sleep 120
  for n in {1..3}; do 
    kubectl exec $(kubectl get pods -l app=workload -o custom-columns=:.metadata.name --no-headers) -- nighthawk_client --duration 60 --rps 5000 --connections 10 --concurrency auto -v info http://baseline:9080/ | tee ${testname}-hubble-$n.out
    sleep 120
  done
  export end=$(date +%s)
  if $store; then
    kube-burner index -c burner.yaml -m rook-node-v2.yaml -t $token -u http://127.0.0.1:9090 --start $start --end $end --uuid $end-${testname}-hubble;
  fi
fi
