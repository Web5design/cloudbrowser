node run --start-clients=0 --end-clients=10 --step-size=5 --server-address="http://192.168.1.123:3000" --ssh-host="-p6060 192.168.1.123" --ssh-cmd="cd ~/projects/cloudbrowser/benchmarks/framework/apps/benchmark && ./run.sh"