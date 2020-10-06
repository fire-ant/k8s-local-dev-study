# k8s-local-dev-study
KIND based K8s harness and CKA curriculum

This is a simple build harness using the VS code dev container setup to run a K8s local dev environment.
The dev environment requires docker-for-mac on which a KIND K8s cluster is deployed. 

The caveat to this setup is that the dev container used to interact with docker needs to be hooked into the same network and Kubectl needs to be repointed at the master node. This is handled with the script under kind/cluster_up.sh

Further reading:

https://kind.sigs.k8s.io/docs/user/quick-start/

https://code.visualstudio.com/docs/remote/containers)

