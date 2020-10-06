#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

# Note: You can use any Debian/Ubuntu based image you want.
FROM mcr.microsoft.com/vscode/devcontainers/base:0-buster

# install eksctl

RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp \
  && mv /tmp/eksctl /usr/bin

# install aws-iam-authenticator

RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator \
    && chmod +x ./aws-iam-authenticator \
    && mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin \
    && echo 'export PATH=$PATH:$HOME/bin' >> ~/.zshrc

RUN echo $'#!/bin/bash\n\
if [[ "$@" == "is-active kubelet localkube" ]]; then\n\
exit 1\n\
fi\n\
exit 0\n '\
>> /usr/local/bin/systemctl

# install okta_aws & AWS CLI
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    zsh \
    git \
    unzip \
    python3 \
    python3-pip \
    python3-setuptools \
    build-essential \
    iptables \
    ebtables \
    ethtool \
    ca-certificates \
    conntrack \
    socat \
    git \
    nfs-common \
    glusterfs-client \
    cifs-utils \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common \
    bridge-utils \
    ipcalc \
    aufs-tools \
    sudo \
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN python3 -m pip install --upgrade awscli
RUN python3 -m pip install --upgrade okta_aws

COPY config_files/okta_aws.toml /root/.okta_aws.toml

# install starship
RUN curl -fsSL https://starship.rs/install.sh | bash /dev/stdin --yes \
    && mkdir -p ~/.config \

COPY config_files/starship.toml /root/.config/starship.toml

# install oh-my-zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# install okta-aws oh-my-zsh plugin
RUN git clone https://gist.github.com/clavery-chef/9af04d6c4a964873ddbe06a4679221d9 ~ZSH_CUSTOM/plugins/okta-aws/

# install terraform
RUN wget --quiet https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip \
    && unzip terraform_0.12.29_linux_amd64.zip \
    && mv terraform /usr/bin \
    && rm terraform_0.12.29_linux_amd64.zip

# install K8s kind
RUN curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.8.1/kind-$(uname)-amd64" \
    && chmod +x ./kind \
    && mv ./kind /usr/bin/kind

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Docker script args, location, and expected SHA - SHA generated on release
ARG DOCKER_SCRIPT_SOURCE="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/v0.128.0/script-library/docker-debian.sh"
ARG DOCKER_SCRIPT_SHA="dde4c419e3a8d9ed15f8d11d366fc7ce29817e451b949d5d7c41432d86ae3b59"
ARG ENABLE_NONROOT_DOCKER="true"
ARG SOURCE_SOCKET=/var/run/docker-host.sock
ARG TARGET_SOCKET=/var/run/docker.sock

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    # Verify common dependencies and utilities are installed
    && apt-get -y install --no-install-recommends apt-utils dialog git openssh-client curl less iproute2 procps 2>&1 \
    #
    # Create a non-root user to use if not already available - see https://aka.ms/vscode-remote/containers/non-root-user.
    && if [ $(getent passwd $USERNAME) ]; then \
        # If exists, see if we need to tweak the GID/UID
        if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then \
            groupmod --gid $USER_GID $USERNAME \
            && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
            && chown -R $USER_UID:$USER_GID /home/$USERNAME; \
        fi; \
    else \
        # Otherwise ccreate the non-root user
        groupadd --gid $USER_GID $USERNAME \
        && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
        # Add sudo support for the non-root user
        && apt-get install -y sudo \
        && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
        && chmod 0440 /etc/sudoers.d/$USERNAME; \
    fi \
    #
    # Use Docker script from script library to set things up
    && curl -sSL $DOCKER_SCRIPT_SOURCE -o /tmp/docker-setup.sh \
    && ([ "${DOCKER_SCRIPT_SHA}" = "dev-mode" ] || (echo "${DOCKER_SCRIPT_SHA} */tmp/docker-setup.sh" | sha256sum -c -)) \
    && /bin/bash /tmp/docker-setup.sh "${ENABLE_NONROOT_DOCKER}" "${SOURCE_SOCKET}" "${TARGET_SOCKET}" "${USERNAME}" \
    && rm /tmp/docker-setup.sh \
    #
    # Install kubectl
    && curl -sSL -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x /usr/bin/kubectl \
    #
    # Install Helm
    && curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash - \

    # Copy localhost's ~/.kube/config file into the container and swap out localhost
    # for host.docker.internal whenever a new shell starts to keep them in sync.
    && echo '\n\
        if [ "$SYNC_LOCALHOST_KUBECONFIG" = "true" ] && [ -d "/usr/local/share/kube-localhost" ]; then\n\
            mkdir -p $HOME/.kube\n\
            sudo cp -r /usr/local/share/kube-localhost/* $HOME/.kube\n\
            sudo chown -R $(id -u) $HOME/.kube\n\
            sed -i -e "s/localhost/host.docker.internal/g" $HOME/.kube/config\n\
        \n\
            if [ -d "/usr/local/share/minikube-localhost" ]; then\n\
                mkdir -p $HOME/.minikube\n\
                sudo cp -r /usr/local/share/minikube-localhost/ca.crt $HOME/.minikube\n\
                sudo cp -r /usr/local/share/minikube-localhost/client.crt $HOME/.minikube\n\
                sudo cp -r /usr/local/share/minikube-localhost/client.key $HOME/.minikube\n\
                sudo chown -R $(id -u) $HOME/.minikube\n\
                sed -i -r "s|(\s*certificate-authority:\s).*|\\1$HOME\/.minikube\/ca.crt|g" $HOME/.kube/config\n\
                sed -i -r "s|(\s*client-certificate:\s).*|\\1$HOME\/.minikube\/client.crt|g" $HOME/.kube/config\n\
                sed -i -r "s|(\s*client-key:\s).*|\\1$HOME\/.minikube\/client.key|g" $HOME/.kube/config\n\
            fi\n\
        fi' | tee -a /root/.bashrc /root/.zshrc /home/${USERNAME}/.bashrc >> /home/${USERNAME}/.zshrc \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to 
# the Docker socket if "overrideCommand": false is set in devcontainer.json. 
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]