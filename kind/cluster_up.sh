#!/bin/zsh

# set_network:
	export KIND_EXPERIMENTAL_DOCKER_NETWORK=kubernetes-node

# cluster_up:
  kind create cluster --config=kind.yml

# replace_loopback:
  sed -i "s/127.0.0.1.*/$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane):6443/" ~/.kube/config 

# get_context:
  kubectl cluster-info --context kind-kind