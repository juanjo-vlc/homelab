FROM alpine:latest

RUN apk add --no-cache curl tar gnupg

WORKDIR /tools

# Download KSOPS
RUN curl -L -o ksops_4.4.0_Linux_x86_64.tar.gz \
    https://github.com/viaduct-ai/kustomize-sops/releases/download/v4.4.0/ksops_4.4.0_Linux_x86_64.tar.gz

# Download SOPS
RUN curl -L -o sops-v3.11.0.linux.amd64 \
    https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64

CMD ["sleep", "infinity"]