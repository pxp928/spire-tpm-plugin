ARG SPIRE_VERSION
ARG SPIRE_TPM_PLUGIN_VERSION

ARG REGISTRY=ghcr.io/pxp928
ARG BASE_IMAGE_STAGE=distroless-base

# official spire images
# TODO pull from gcr when spire officially supports arm64 architecture
FROM --platform=${TARGETPLATFORM} ${REGISTRY}/spire-agent:${SPIRE_VERSION}-scratch as spire-agent-official
# FROM --platform=${TARGETPLATFORM} ${REGISTRY}/gcrio/spiffe-io/spire-agent:${SPIRE_VERSION}-scratch as spire-agent-official
FROM --platform=${TARGETPLATFORM} ${REGISTRY}/spire-server:${SPIRE_VERSION}-scratch as spire-server-official
# FROM --platform=${TARGETPLATFORM} ${REGISTRY}/gcrio/spiffe-io/spire-server:${SPIRE_VERSION}-scratch as spire-server-official

# If this does not work use wget to download the spire binary
#RUN wget https://github.com/spiffe/spire/releases/download/v0.11.3/spire-0.11.3-linux-x86_64-glibc.tar.gz && \
#tar zvxf spire-0.11.3-linux-x86_64-glibc.tar.gz && cp -r spire-0.11.3/. /opt/spire/

# spire tpm plugin images
FROM --platform=${TARGETPLATFORM} tpm_attestor_agent:simulator as tpm-attestor-agent
FROM --platform=${TARGETPLATFORM} tpm_attestor_server:simulator as tpm-attestor-server
FROM --platform=${TARGETPLATFORM} get_tpm_pubhash:simulator as get-tpm-pubhash

# debian base image
FROM --platform=${TARGETPLATFORM} debian:buster-slim AS debian-base

RUN apt-get update \
    && apt-get install -y \
        libtspi1 ca-certificates

RUN cp /usr/lib/*-linux-gnu/libtspi.so.1 /usr/lib/libtspi.so.1

# distroless base image
FROM --platform=${TARGETPLATFORM} gcr.io/distroless/cc AS distroless-base

COPY --from=debian-base /usr/lib/libtspi.so.1 /usr/lib/libtspi.so.1
ENV LD_LIBRARY_PATH /usr/lib

# conf image
FROM debian-base AS conf

COPY --from=tpm-attestor-agent /app/tpm_attestor_agent /opt/spire/plugins/tpm_attestor_agent
COPY --from=tpm-attestor-server /app/tpm_attestor_server /opt/spire/plugins/tpm_attestor_server

COPY conf /opt/spire/conf
RUN export AGENT_PLUGIN_HASH="$(sha256sum /opt/spire/plugins/tpm_attestor_agent | cut -d' ' -f1)" \
    && export SERVER_PLUGIN_HASH="$(sha256sum /opt/spire/plugins/tpm_attestor_server | cut -d' ' -f1)" \
    && sed -i "s/__AGENT_PLUGIN_HASH__/${AGENT_PLUGIN_HASH}/g" /opt/spire/conf/agent/agent.conf \
    && sed -i "s/__SERVER_PLUGIN_HASH__/${SERVER_PLUGIN_HASH}/g" /opt/spire/conf/server/server.conf \
    && sed -i "s/__SERVER_PLUGIN_HASH__/${SERVER_PLUGIN_HASH}/g" /opt/spire/conf/server/nested-server.conf

# spire agent image
FROM ${BASE_IMAGE_STAGE} AS spire-agent

COPY --from=spire-agent-official /opt/spire/bin/spire-agent /opt/spire/bin/spire-agent
COPY --from=tpm-attestor-agent /app/tpm_attestor_agent /opt/spire/plugins/tpm_attestor_agent
COPY --from=conf /opt/spire/conf/agent /opt/spire/conf/agent
COPY k8s /opt/spire/k8s

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire
CMD ["spire-agent", "run", "-expandEnv"]

# spire server image
FROM ${BASE_IMAGE_STAGE} AS spire-server

COPY --from=spire-server-official /opt/spire/bin/spire-server /opt/spire/bin/spire-server
COPY --from=tpm-attestor-server /app/tpm_attestor_server /opt/spire/plugins/tpm_attestor_server
COPY --from=conf /opt/spire/conf/server /opt/spire/conf/server

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire
CMD ["spire-server", "run", "-expandEnv"]

# spire tools image
FROM ${BASE_IMAGE_STAGE} AS spire-tools

COPY --from=get-tpm-pubhash /app/get_tpm_pubhash /opt/spire/bin/get_tpm_pubhash

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire/bin
CMD ["get_tpm_pubhash"]

FROM debian-base AS socat-spire-agent

RUN apt-get update \
    && apt-get install -y \
        socat

COPY --from=spire-agent-official /opt/spire/bin/spire-agent /opt/spire/bin/spire-agent
COPY --from=tpm-attestor-agent /app/tpm_attestor_agent /opt/spire/plugins/tpm_attestor_agent
COPY --from=conf /opt/spire/conf/agent /opt/spire/conf/agent
COPY k8s /opt/spire/k8s

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire
CMD ["spire-agent", "run", "-expandEnv"]

FROM debian-base AS socat-spire-server

RUN apt-get update \
    && apt-get install -y \
        socat

COPY --from=spire-server-official /opt/spire/bin/spire-server /opt/spire/bin/spire-server
COPY --from=tpm-attestor-server /app/tpm_attestor_server /opt/spire/plugins/tpm_attestor_server
COPY --from=conf /opt/spire/conf/server /opt/spire/conf/server

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire
CMD ["spire-server", "run", "-expandEnv"]
