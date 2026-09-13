# Use Fedora as base
FROM docker.io/library/fedora:latest

# Set timezone
ARG TZ=Europe/Berlin
ENV TZ=${TZ}

# Optional CLIs — toggled at build time (see compose.yaml args).
# Claude Code and Mistral Vibe are on by default; Codex and Antigravity opt-in.
ARG INSTALL_CLAUDE=true
ARG INSTALL_VIBE=true
ARG INSTALL_CODEX=false
ARG INSTALL_ANTIGRAVITY=false

# Install basic development tools
RUN dnf install -y --setopt=install_weak_deps=False --allowerasing \
  less \
  git \
  sudo \
  man-db \
  unzip \
  tar \
  gzip \
  gnupg2 \
  vim \
  curl \
  wget \
  ca-certificates \
  jq \
  bubblewrap \
  hostname \
  && dnf clean all

# Create an agent user with UID 1000 (Fedora base has no default non-root user)
RUN groupadd -g 1000 agent \
 && useradd -m -u 1000 -g 1000 -s /bin/bash agent

# Grant agent user paswordless sudo for all commands
RUN echo "agent ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agent \
    && chmod 0440 /etc/sudoers.d/agent

# Switch to non-root user
USER agent

# Set working directory
WORKDIR /home/agent/workspace

# Set up environment for user
ENV PATH=$PATH:/home/agent/.local/bin
ENV EDITOR=vim
ENV VISUAL=vim

# Install uv 
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN echo '[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"' >> ~/.bashrc

# Install Claude Code
RUN if [ "$INSTALL_CLAUDE" = "true" ]; then curl -fsSL https://claude.ai/install.sh | bash; fi
# Install Mistral Vibe CLI
RUN if [ "$INSTALL_VIBE" = "true" ]; then uv tool install mistral-vibe; fi
# Install Codex
RUN if [ "$INSTALL_CODEX" = "true" ]; then \
      curl -fsSL https://chatgpt.com/codex/install.sh -o /tmp/install-codex.sh \
      && sh /tmp/install-codex.sh \
      && rm /tmp/install-codex.sh; \
    fi
# Install Antigravity CLI
RUN if [ "$INSTALL_ANTIGRAVITY" = "true" ]; then curl -fsSL https://antigravity.google/cli/install.sh | bash; fi

# Install personal agent config (AGENTS.md/CLAUDE.md, skills, statuslines).
ARG INSTALL_AGENT_CONFIG=true
ARG AGENT_CONFIG_REPO=https://github.com/spieseba/agent-config.git
RUN if [ "$INSTALL_AGENT_CONFIG" = "true" ]; then \
      git clone --depth 1 "${AGENT_CONFIG_REPO}" /home/agent/.agent-config \
 && if [ "$INSTALL_CLAUDE" = "true" ]; then \
      mkdir -p /home/agent/.claude \
      && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.claude/CLAUDE.md \
      && ln -sf /home/agent/.agent-config/skills /home/agent/.claude/skills \
      && cp /home/agent/.agent-config/claude/statusline-command.sh /home/agent/.claude/statusline-command.sh \
      && chmod +x /home/agent/.claude/statusline-command.sh \
      && cp /home/agent/.agent-config/claude/settings.json /home/agent/.claude/settings.json; \
    fi \
 && if [ "$INSTALL_VIBE" = "true" ]; then \
      mkdir -p /home/agent/.vibe \
      && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.vibe/AGENTS.md \
      && ln -sf /home/agent/.agent-config/skills /home/agent/.vibe/skills \
      && cp /home/agent/.agent-config/vibe/config.toml /home/agent/.vibe/config.toml; \
    fi \
 && if [ "$INSTALL_CODEX" = "true" ]; then \
      mkdir -p /home/agent/.codex \
      && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.codex/AGENTS.md \
      && ln -sf /home/agent/.agent-config/skills /home/agent/.codex/skills \
      && ln -sf /home/agent/.agent-config/codex/pets /home/agent/.codex/pets \
      && cp /home/agent/.agent-config/codex/config.toml /home/agent/.codex/config.toml; \
    fi \
 && if [ "$INSTALL_ANTIGRAVITY" = "true" ]; then \
      mkdir -p /home/agent/.gemini \
      && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.gemini/GEMINI.md \
      && ln -sf /home/agent/.agent-config/skills /home/agent/.gemini/skills; \
    fi; \
    fi


# Default command
CMD ["/bin/bash"]
