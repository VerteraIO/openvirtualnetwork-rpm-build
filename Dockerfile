# Multi-stage Dockerfile for building OVN RPMs following official process
ARG DISTRO=rockylinux/rockylinux
ARG VERSION=9

FROM ${DISTRO}:${VERSION} as builder

# Build arguments
ARG OVN_VERSION=24.09.0
ARG OVS_VERSION=3.6.0
ARG DISTRO
ARG VERSION

# Set environment variables
ENV OVN_VERSION=${OVN_VERSION}
ENV OVS_VERSION=${OVS_VERSION}
ENV DISTRO=${DISTRO}
ENV VERSION=${VERSION}

# Install repositories and basic tools
RUN if [ "${VERSION}" = "9" ]; then \
        dnf install -y epel-release && \
        dnf config-manager --set-enabled crb; \
    elif [ "${VERSION}" = "10" ]; then \
        dnf install -y epel-release && \
        dnf config-manager --set-enabled crb; \
    fi

# Install Development Tools and RPM build tools
RUN dnf install -y \
    @'Development Tools' \
    rpm-build \
    dnf-plugins-core \
    wget \
    git \
    python3-sphinx \
    checkpolicy \
    desktop-file-utils \
    groff \
    libbpf-devel \
    libcap-ng-devel \
    libxdp-devel \
    numactl-devel \
    openssl-devel \
    procps-ng \
    python3-devel \
    selinux-policy-devel \
    systemd-devel \
    systemtap-sdt-devel \
    unbound \
    unbound-devel \
    && dnf clean all

# Set working directory
WORKDIR /root

# Generate OVS source tarball (OVN dependency)
RUN echo "Generating OVS ${OVS_VERSION} source tarball..." && \
    wget https://github.com/openvswitch/ovs/archive/v${OVS_VERSION}.tar.gz -O ovs-${OVS_VERSION}.tar.gz && \
    tar -xzf ovs-${OVS_VERSION}.tar.gz && \
    cd ovs-${OVS_VERSION} && \
    ./boot.sh && \
    ./configure && \
    make dist

# Download and extract OVN source
RUN echo "Downloading OVN ${OVN_VERSION}..." && \
    wget https://github.com/ovn-org/ovn/archive/v${OVN_VERSION}.tar.gz -O ovn-${OVN_VERSION}.tar.gz && \
    tar -xzf ovn-${OVN_VERSION}.tar.gz

# Generate temporary spec file for build dependencies
WORKDIR /root/ovn-${OVN_VERSION}
RUN sed -e "s/@VERSION@/${OVN_VERSION}/" rhel/ovn-fedora.spec.in > /tmp/ovn.spec

# Install OVN-specific build dependencies
RUN dnf builddep -y /tmp/ovn.spec && rm -f /tmp/ovn.spec

# Bootstrap OVN build system
RUN ./boot.sh

# Configure and build OVN following official process
RUN ./configure --with-ovs-source=/root/ovs-${OVS_VERSION}

# Build OVN RPMs using official method
RUN make rpm-fedora

# Runtime stage for file extraction
FROM ${DISTRO}:${VERSION} as runtime
ARG OVN_VERSION
ENV OVN_VERSION=${OVN_VERSION}

# Copy built RPMs from OVN build (make rpm-fedora creates rpm/rpmbuild structure)
COPY --from=builder /root/ovn-*/rpm/rpmbuild/RPMS/ /rpms/
COPY --from=builder /root/ovn-*/rpm/rpmbuild/SRPMS/ /srpms/

# Create entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'echo "OVN ${OVN_VERSION} RPM build completed"' >> /entrypoint.sh && \
    echo 'echo "Copying RPMs to output directory..."' >> /entrypoint.sh && \
    echo 'mkdir -p /output' >> /entrypoint.sh && \
    echo 'find /rpms -name "*.rpm" -exec cp {} /output/ \; 2>/dev/null || true' >> /entrypoint.sh && \
    echo 'find /srpms -name "*.rpm" -exec cp {} /output/ \; 2>/dev/null || true' >> /entrypoint.sh && \
    echo 'echo "Available RPMs:"' >> /entrypoint.sh && \
    echo 'ls -la /output/' >> /entrypoint.sh && \
    echo 'echo "Build artifacts available in /output/"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
