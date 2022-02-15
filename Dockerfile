#
# SFTP only Container - thomasw64/sshd
#
# Under Apache 2.0 License see LICENSE file.
#
# Copyright IBM 2021,2022
# SPDX-License-Identifier: Apache2.0
#
# Authors:
#  - Thomas Weinzettl <thomasw@ae.ibm.com>
#
#===============================================================================

# Choose from one of the two:
#  ubi8-minimal:latest ..... if you have RH licenses
#  fedora-minimal:latest ... if you prefer complete open source
# FROM registry.access.redhat.com/ubi8-minimal:latest
FROM registry.fedoraproject.org/fedora-minimal:latest

LABEL org.opencontainers.image.title="SFTP only Container"
LABEL org.opencontainers.image.description="A container that allows to share docker/podman volumes via a secure SFTP only connection."
LABEL org.opencontainers.image.authors="thomasw@ae.ibm.com"
LABEL org.opencontainers.image.source="https://github.com/IBM/sftp-only-container.git"
LABEL org.opencontainers.image.vendor="IBM"
LABEL org.opencontainers.image.licenses="Apache-2.0"
#LABEL description="A ssh container with an simple method to import public keys"
LABEL org.opencontainers.image.version="0.3.1"

RUN microdnf --nodocs -y install openssh-server sudo && \
    microdnf clean all

RUN mkdir -p /home/.sshd/ && \
    chmod 700 /home/.sshd

RUN sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config && \
    sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config && \
    sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config && \
    sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g" /etc/ssh/sshd_config && \
    sed -i "s/#PermitEmptyPasswords no/PermitEmptyPasswords no/g" /etc/ssh/sshd_config

COPY entrypoint.sh /entrypoint.sh
COPY ssh-key.sh /bin/ssh-key.sh
COPY ssh-functions.sh /bin/ssh-functions.sh
COPY containeradm /bin/containeradm

ENV SFTP_ONLY=no
ENV DEBUG=0

VOLUME ["/Volume","/home/"]

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/sbin/sshd","-D","-e"]
