#!/bin/bash
# Rootless Docker + Docker Compose + OpManager Auto-Installer
# Run as NON-ROOT user on Linux (Ubuntu 20.04+/CentOS 9+ recommended)
# Prerequisites: systemd, fuse-overlayfs, slirp4netns (auto-installed where possible)

set -euo pipefail

USER_HOME="$HOME"
OPMANAGER_DIR="$USER_HOME/opmanager-docker"
REPO_URL="https://github.com/boniyeamincse/opmanager.git"

echo "=== ManageEngine OpManager Rootless Docker Installer ==="
echo "User: $(whoami) (UID: $(id -u))"
if [ "$EUID" -eq 0 ]; then
  echo "ERROR: Run as NON-ROOT user!"
  exit 1
fi

# Detect distro
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO_ID="$ID"
  DISTRO_VERSION="$VERSION_ID"
else
  echo "Unsupported distro"
  exit 1
fi

echo "Distro: $DISTRO_ID $DISTRO_VERSION"

# Function to install packages
install_prereqs() {
  case "$DISTRO_ID" in
    ubuntu|debian)
      sudo apt-get update
      sudo apt-get install -y uidmap fuse-overlayfs slirp4netns
      ;;
    centos|rhel|rocky|almalinux)
      sudo dnf install -y fuse-overlayfs slirp4netns
      ;;
    *)
      echo "Add prereqs manually: fuse-overlayfs slirp4netns"
      return 1
      ;;
  esac
}

# Install rootless Docker (official method)
install_rootless_docker() {
  if systemctl --user --version >/dev/null 2>&1; then
    echo "Installing rootless Docker..."
    curl -fsSL https://get.docker.com/rootless | sh -x
    # Source dockerd-rootless.sh
    . "$USER_HOME/.docker/bin/dockerd-rootless.sh"
  else
    echo "ERROR: systemd-user not available. Install/enable lingering: loginctl enable-linger $USER"
    exit 1
  fi
}

# Start Docker daemon rootless
start_docker() {
  if ! systemctl --user is-active --quiet docker; then
    systemctl --user start docker
    sleep 5
  fi
  export PATH="$USER_HOME/.docker/bin:$PATH"
  export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
}

# Install Docker Compose v2 (plugin)
install_docker_compose() {
  if ! docker compose version >/dev/null 2>&1; then
    echo "Installing Docker Compose plugin..."
    DOCKER_CONFIG="${XDG_CONFIG_HOME:-$USER_HOME/.config}/docker"
    mkdir -p "$DOCKER_CONFIG/cli-plugins"
    LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -SL "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
    chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
  fi
}

# Clone/Build/Deploy OpManager
deploy_opmanager() {
  if [ ! -d "$OPMANAGER_DIR" ]; then
    git clone "$REPO_URL" "$OPMANAGER_DIR"
  fi
  cd "$OPMANAGER_DIR"

  echo "Building OpManager image..."
  docker compose build --no-cache

  echo "Starting OpManager (detached)..."
  docker compose up -d

  echo "Waiting for healthy (up to 10min)..."
  timeout=600
  while [ $timeout -gt 0 ]; do
    if docker compose ps | grep -q "healthy"; then
      echo "OpManager ready!"
      break
    fi
    sleep 30
    timeout=$((timeout-30))
  done

  if [ $timeout -eq 0 ]; then
    echo "WARN: Healthcheck timeout. Check logs: docker compose logs -f"
  fi

  echo "Access: http://localhost:8060"
  echo "Logs: docker compose logs -f opmanager"
  echo "Stop: docker compose down"
}

# Main
echo "1/5: Installing prereqs..."
install_prereqs

echo "2/5: Installing rootless Docker..."
install_rootless_docker

echo "3/5: Starting Docker daemon..."
start_docker

echo "4/5: Installing Docker Compose..."
install_docker_compose

echo "5/5: Deploying OpManager..."
deploy_opmanager

echo "=== Installation Complete! ==="
echo "Add to ~/.bashrc: export PATH=\$HOME/.docker/bin:\$PATH ; export DOCKER_HOST=unix:///run/user/\$(id -u)/docker.sock"
echo "Run 'systemctl --user enable --now docker' for auto-start."
cat README.md | grep -A 5 "Quick Start"