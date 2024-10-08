# Build on top of Fedora 40 base image
FROM fedora:40

# Create a non-root user
RUN useradd -ms /bin/bash tools

# Update container libraries and install tools available from the repos
RUN dnf -y update && \
    dnf install -y vim tar wget java-17-openjdk maven sudo gzip git rsync podman bash unzip openssh-clients ansible-core python3-pip jq && \
    dnf clean all

# Install the latest version of OpenShift Do (odo)
RUN curl -L https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/odo/v3.15.0/odo-linux -o odo && \
    sudo install -o root -g root -m 0755 odo /usr/local/bin/odo

# Install the latest version of Source-to-image (s2i)
RUN curl -s https://api.github.com/repos/openshift/source-to-image/releases/latest | \
    grep browser_download_url | grep linux | cut -d '"' -f 4 | wget -qi - && \
    tar xvf source-to-image*.gz && \
    sudo mv s2i /usr/local/bin && \
    rm source-to-image*.gz

# Install the latest ArgoCD from the official GitHub repo
RUN VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -sSL -o argocd-linux https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux && \
    sudo install -m 555 argocd-linux /usr/local/bin/argocd && \
    rm argocd-linux

# Install the latest ArgoCD Autopilot from the official repo
RUN VERSION=$(curl --silent "https://api.github.com/repos/argoproj-labs/argocd-autopilot/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -L --output - https://github.com/argoproj-labs/argocd-autopilot/releases/download/"$VERSION"/argocd-autopilot-linux.tar.gz | tar zx && \
    chmod 555 argocd-autopilot-* && \
    mv ./argocd-autopilot-* /usr/local/bin/argocd-autopilot

# Install the latest Kubectl and OpenShift CLI tools
RUN mkdir /ocp-tools && \
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz -P /ocp-tools && \
    cd /ocp-tools && \
    tar xvzf openshift-client-linux.tar.gz oc kubectl && \
    chmod 777 * && \
    mv oc kubectl /usr/local/bin

# Switch to non-root user
USER tools

CMD /bin/bash