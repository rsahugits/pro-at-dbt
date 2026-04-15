# Use a slim Ubuntu image to keep costs/size down
FROM ubuntu:24.04

# Avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install system dependencies
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y curl \
    gnupg \
    apt-transport-https \
    ca-certificates \
    python3

RUN apt-get install -y vim \
    && rm -rf /var/lib/apt/lists/*

# 2. Add the Google Cloud public key
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

# 3. Add the gcloud repository
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# 4. Install the SDK
RUN apt-get update
RUN apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://claude.ai/install.sh | bash
RUN echo 'export PATH="$HOME/.local/bin:$PATH"'

# Export Claude vars
RUN echo "export CLAUDE_CODE_USE_VERTEX=1" >> /root/.bashrc
RUN echo "export ANTHROPIC_VERTEX_PROJECT_ID=anthropic-ai-models" >> /root/.bashrc
RUN echo "export CLOUD_ML_REGION=global" >> /root/.bashrc
RUN echo "export ANTHROPIC_MODEL='claude-opus-4-6'" >> /root/.bashrc
RUN echo "export ANTHROPIC_SMALL_FAST_MODEL='claude-haiku-4-5@20251001'" >> /root/.bashrc

RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-venv \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN echo "export PS1='${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV)) }\W# '"

# Set the default command
CMD ["gcloud", "--version"]


# docker build -t pro-at-dbt -f ./Dockerfile .
# docker run -itd \
#   --name pro-at-dbt \
#   -v "$(pwd)":/app \
#   -w /app \
#   pro-at-dbt bash

# gcloud auth login
# gcloud auth application-default login
# gcloud config set project anthropic-ai-models
