# Base image
FROM centos:9

# Metadata
LABEL maintainer="Boni Yeamin <boniyeamin.cse@gmail.com>"
LABEL description="Docker image for ManageEngine OpManager on CentOS 9"

# Set environment variables
ENV OP_MANAGER_INSTALLER_URL="https://www.manageengine.com/network-monitoring/29809517/ManageEngine_OpManager_64bit.bin"
ENV OP_MANAGER_INSTALL_DIR="/opt/ManageEngine/OpManager"
ENV OP_MANAGER_USER="opmanager"
ENV OP_MANAGER_HOME="/home/${OP_MANAGER_USER}"

# Install dependencies
RUN dnf -y update && \
    dnf -y install wget tar gzip java-17-openjdk java-17-openjdk-devel \
                   net-tools vim sudo which && \
    dnf clean all

# Create non-root user
RUN useradd -m -d ${OP_MANAGER_HOME} -s /bin/bash ${OP_MANAGER_USER} && \
    echo "${OP_MANAGER_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set temporary working directory for download
WORKDIR /tmp

# Download OpManager installer
RUN wget -O OpManager.bin ${OP_MANAGER_INSTALLER_URL} && \
    chmod +x OpManager.bin

# Install OpManager in silent mode (requires root)
RUN ./OpManager.bin -q -i console -DUSER_INSTALL_DIR=${OP_MANAGER_INSTALL_DIR} && \
    chown -R ${OP_MANAGER_USER}:${OP_MANAGER_USER} ${OP_MANAGER_INSTALL_DIR} && \
    rm OpManager.bin

# Switch to non-root user for runtime
USER ${OP_MANAGER_USER}

WORKDIR ${OP_MANAGER_INSTALL_DIR}

# Expose default ports (adjust if needed)
EXPOSE 8060 8443

# Set entrypoint to start OpManager and keep container running
ENTRYPOINT ["sh", "-c", "${OP_MANAGER_INSTALL_DIR}/bin/startOpManager.sh && tail -f /dev/null"]
