ARG SPIRE_VERSION=0.11.3

ARG BASE_IMAGE_STAGE=debian-base

# official spire images
#FROM --platform=${TARGETPLATFORM} gcr.io/spiffe-io/spire-agent:1.1.0 as spire-agent-official
#FROM --platform=${TARGETPLATFORM} gcr.io/spiffe-io/spire-server:1.1.0 as spire-server-official
 
# spire tpm plugin images
FROM --platform=${TARGETPLATFORM} tpm_attestor_agent:simulator as tpm-attestor-agent
FROM --platform=${TARGETPLATFORM} tpm_attestor_server:simulator as tpm-attestor-server
FROM --platform=${TARGETPLATFORM} get_tpm_pubhash:simulator as get-tpm-pubhash

# debian base image
FROM --platform=${TARGETPLATFORM} debian:buster-slim AS debian-base

RUN apt-get update \
    && apt-get install -y \
        libtspi-dev ca-certificates wget

#RUN cp /usr/lib/*-linux-gnu/libtspi.so.1 /usr/lib/libtspi.so.1

# conf image
FROM debian-base AS conf

COPY --from=tpm-attestor-agent /app/tpm_attestor_agent /opt/spire/plugins/tpm_attestor_agent
COPY --from=tpm-attestor-server /app/tpm_attestor_server /opt/spire/plugins/tpm_attestor_server

COPY conf /opt/spire/conf
RUN export AGENT_PLUGIN_HASH="$(sha256sum /opt/spire/plugins/tpm_attestor_agent | cut -d' ' -f1)" \
    && export SERVER_PLUGIN_HASH="$(sha256sum /opt/spire/plugins/tpm_attestor_server | cut -d' ' -f1)" \
    && sed -i "s/__AGENT_PLUGIN_HASH__/${AGENT_PLUGIN_HASH}/g" /opt/spire/conf/agent/agent.conf \
    && sed -i "s/__SERVER_PLUGIN_HASH__/${SERVER_PLUGIN_HASH}/g" /opt/spire/conf/server/server.conf

# spire agent image
FROM ${BASE_IMAGE_STAGE} AS spire-agent

#COPY --from=spire-agent-official /opt/spire/bin/spire-agent /opt/spire/bin/spire-agent
RUN wget https://github.com/spiffe/spire/releases/download/v0.11.3/spire-0.11.3-linux-x86_64-glibc.tar.gz && \
tar zvxf spire-0.11.3-linux-x86_64-glibc.tar.gz && cp -r spire-0.11.3/. /opt/spire/

COPY --from=tpm-attestor-agent /app/tpm_attestor_agent /opt/spire/plugins/tpm_attestor_agent
COPY --from=conf /opt/spire/conf/agent /opt/spire/conf/agent

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire
CMD ["spire-agent", "run", "-expandEnv", "-insecureBootstrap"]

# spire server image
FROM ${BASE_IMAGE_STAGE} AS spire-server

#COPY --from=spire-server-official /opt/spire/bin/spire-server /opt/spire/bin/spire-server
RUN wget https://github.com/spiffe/spire/releases/download/v0.11.3/spire-0.11.3-linux-x86_64-glibc.tar.gz && \
tar zvxf spire-0.11.3-linux-x86_64-glibc.tar.gz && cp -r spire-0.11.3/. /opt/spire/

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