FROM ghcr.io/oracle/oci-cli:latest

# Install kubectl as root, then switch back
USER root
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl
USER oracle

# Reset entrypoint so the container stays alive for exec-based usage
ENTRYPOINT []
CMD ["tail", "-f", "/dev/null"]
