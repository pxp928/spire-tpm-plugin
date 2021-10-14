ARG SPIRE_VERSION=0.12.0


# official spire images
FROM --platform=linux/amd64 gcr.io/spiffe-io/spire-agent:${SPIRE_VERSION} as spire-agent-official
FROM --platform=linux/amd64 gcr.io/spiffe-io/spire-server:${SPIRE_VERSION} as spire-server-official

# spire tpm plugin images
FROM tpm_attestor_agent:simulator as tpm-attestor-agent
FROM tpm_attestor_server:simulator as tpm-attestor-server
FROM get_tpm_pubhash:simulator as get-tpm-pubhash

# debian base image
FROM debian:buster-slim AS debian-base

RUN apt-get update \
    && apt-get install -y \
        libtspi1 ca-certificates

RUN cp /usr/lib/*-linux-gnu/libtspi.so.1 /usr/lib/libtspi.so.1

# conf image
FROM debian-base AS conf

COPY --from=tpm-attestor-agent /app/tpm_attestor_agent /opt/spire/plugins/tpm_attestor_agent
COPY --from=tpm-attestor-server /app/tpm_attestor_server /opt/spire/plugins/tpm_attestor_server

COPY spire /opt/spire/conf
RUN export AGENT_PLUGIN_HASH="$(sha256sum /opt/spire/plugins/tpm_attestor_agent | cut -d' ' -f1)" \
    && export SERVER_PLUGIN_HASH="$(sha256sum /opt/spire/plugins/tpm_attestor_server | cut -d' ' -f1)" \
    && sed -i "s/__AGENT_PLUGIN_HASH__/${AGENT_PLUGIN_HASH}/g" /opt/spire/conf/agent/agent.conf \
    && sed -i "s/__SERVER_PLUGIN_HASH__/${SERVER_PLUGIN_HASH}/g" /opt/spire/conf/server/server.conf

# spire agent image
FROM debian-base AS spire-agent

COPY --from=spire-agent-official /opt/spire/bin/spire-agent /opt/spire/bin/spire-agent
COPY --from=tpm-attestor-agent /app/tpm_attestor_agent /opt/spire/plugins/tpm_attestor_agent
COPY --from=conf /opt/spire/conf/agent /opt/spire/conf/agent

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire
CMD ["spire-agent", "run", "-expandEnv"]

# spire server image
FROM debian-base AS spire-server

COPY --from=spire-server-official /opt/spire/bin/spire-server /opt/spire/bin/spire-server
COPY --from=tpm-attestor-server /app/tpm_attestor_server /opt/spire/plugins/tpm_attestor_server
COPY --from=conf /opt/spire/conf/server /opt/spire/conf/server
COPY ./hashes /opt/spire/.data/hashes

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire
CMD ["spire-server", "run", "-expandEnv"]

# spire tools image
FROM debian-base AS spire-tools

COPY --from=get-tpm-pubhash /app/get_tpm_pubhash /opt/spire/bin/get_tpm_pubhash

ENV PATH=$PATH:/opt/spire/bin
WORKDIR /opt/spire/bin
CMD ["get_tpm_pubhash"]