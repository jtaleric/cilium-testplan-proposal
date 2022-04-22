testname=${NAME:-"$(date +%s)-test-run"}
store=${STORE:-true}
token=LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVMVENDQXBXZ0F3SUJBZ0lSQVBmU0JCV0crMnRyRk91cVU1cnBpTU13RFFZSktvWklodmNOQVFFTEJRQXcKTHpFdE1Dc0dBMVVFQXhNa01EWTFabVkzTVdJdE9HVXdaUzAwTVdVMkxXRTVZemN0Wm1KbE5UQmxZV0kxWXpFMgpNQ0FYRFRJeU1EUXhNVEV5TXpnd09Gb1lEekl3TlRJd05EQXpNVE16T0RBNFdqQXZNUzB3S3dZRFZRUURFeVF3Ck5qVm1aamN4WWkwNFpUQmxMVFF4WlRZdFlUbGpOeTFtWW1VMU1HVmhZalZqTVRZd2dnR2lNQTBHQ1NxR1NJYjMKRFFFQkFRVUFBNElCandBd2dnR0tBb0lCZ1FDUVRjWUlZNjNqbjhmdlZENFY5dUprRVNsZzhRa0xhLzE0QjFIcAp4SlJncDd5Mk5kcFJDSnAxakpBck9LS3ptMjhxeEg3cmVBVC95OVA5bmZXVDZTQWp6cFBzQnpUTzh2c3IxUjVxCjk1bkcxSDRraUJiYWorUjJMdHU2Q1VpL3RBVlNQQlNEOUVMSnV6YVVIVkZSajJxK0N2ZER0MzBPQ1pHL0F6ZHAKNGRJR0VUM1VRUm50dlBEY3k2ZUxEbmN2aTQxVTJwU1VacnhxdlJ0QmQvc2F1UFNHRjVQY2NTOHlwV3RySU8yQwo3YjBoMUh1SWI4ODdWU2xvTU4vMk1EOTRWOEpIVWE2NnNNVVp2a2I5V3hKeHZXUVNoOXRWRXErNGFIMzdkQkExClZFb3RrL3ZDdDQ5Q0QvMktyR0Y0QnJkZFNYRXQ2QmNvcG1DWVBIUFNJVjA4eTlIckJKZS84OVdlOVd1NGNDSUgKUzVJanRnenZNQnlDaXl0Vm9VV2NLY1lvVEZIeDU1WlcrMTQ3U3BnRktmcWVrcm90UzRKckcra0NqMTBiWGRrOQo4ZDJ3aFJjb2R5c3cyTnM4Z0tDb0M5ZGY0S0FCZXZ1MVdiNjQxRVYvaXplTXg5L0hXeXV6bTN1N2FyUy9MU1BkCkkvRlpuWlordU4zdGk0QXpaRk1RUXAvUDRpVUNBd0VBQWFOQ01FQXdEZ1lEVlIwUEFRSC9CQVFEQWdJRU1BOEcKQTFVZEV3RUIvd1FGTUFNQkFmOHdIUVlEVlIwT0JCWUVGRHN1TWFycjJreDRjMERVRWIxZlhEb1NlczJGTUEwRwpDU3FHU0liM0RRRUJDd1VBQTRJQmdRQjVnRDAzWG1FNHVPQ0JFTThScnd6Kzc2azVIV2MyN09oNFcxckhlZWtsClZQVTdPbHpxS2xTOFZuR1RKNUdpblNmc1lFTnNwRTA2czg0cWxEZU5ZeXFWMFdiMnR1MngrVW85UWpIUit3dmgKZGhOcUhFTmF3c0QrZmdpdC9wOTc0aDdEVElwVnBqSCs1K29kVlN4QkNrS01sMXpEc3lvdWE2VjgzV1JmeTNvdgp0Uk1YeHhNMjBYSkRkYjNsVmxhUGM2cWluUFBlNEVzTng0ZWtDUHFZWERIWldvOCtTZWtpZE1FYXNwZW1lSVpNCk9UUW4waUNxMnpBWXlXbi9xbHdSN2tWejkxSGU2Vjl3U0h5UE83amEzbDNDSGJ3SEdWTmVwajk2WUZ5MFhhTVkKZWh4N2wzTnFaVWxhL2l6VkhOVU5lM1lyb1NpSDVZblBHamY3Y1NpSTN0ak51Sm0vQytHOEZ6UFdLcmVVZ3VPTQpLQUNnQk1ZYnlVZnJIN29vd1VkOUh2OUthMHIvbjFFK3ZIK0loS1hqZWl0S0FMZ01BaE8wUkFVSDZDVTBmczY2ClpTSUVnaHV5czA4VURkNGI1Z0RLNFdoQklkeDl5Zit3ZkdLR3hJeHc4NHRFYklTRUN5TDY1VE5zSExxMXBETWgKeTlqbG4wWStWRkZLS1kvTDYxc2lHbU09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0

start=$(date +%s)
sleep 120 # provide a quiet time prior to kicking off the workload.
for n in {1..5}; do 
   kubectl exec $(kubectl get pods -l app=workload -o custom-columns=:.metadata.name --no-headers) -c benchmark -- nighthawk_client --duration 60 --rps 10 --connections 10 --concurrency 16 -v info http://baseline:9080/ | tee ${testname}-${n}-160.out  sleep 120 
done 
end=$(date +%s)
if $store; then
    kube-burner index -c burner.yaml -m rook-node-v2.yaml -t $token -u http://127.0.0.1:9090 --start $start --end $end --uuid $end-${testname}-160
fi

start=$(date +%s)
sleep 120 # provide a quiet time prior to kicking off the workload.
for n in {1..5}; do 
   kubectl exec $(kubectl get pods -l app=workload -o custom-columns=:.metadata.name --no-headers) -c benchmark -- nighthawk_client --duration 60 --rps 100 --connections 10 --concurrency 16 -v info http://baseline:9080/ | tee ${testname}-${n}-1600.out  sleep 120 
done 
end=$(date +%s)
if $store; then
    kube-burner index -c burner.yaml -m rook-node-v2.yaml -t $token -u http://127.0.0.1:9090 --start $start --end $end --uuid $end-${testname}-1600 
fi

start=$(date +%s)
sleep 120 # provide a quiet time prior to kicking off the workload.
for n in {1..5}; do 
   kubectl exec $(kubectl get pods -l app=workload -o custom-columns=:.metadata.name --no-headers) -c benchmark -- nighthawk_client --duration 60 --rps 1000 --connections 10 --concurrency 16 -v info http://baseline:9080/ | tee ${testname}-${n}-16000.out  sleep 120 
done 
end=$(date +%s)
if $store; then
    kube-burner index -c burner.yaml -m rook-node-v2.yaml -t $token -u http://127.0.0.1:9090 --start $start --end $end --uuid $end-${testname}-16000 
fi
