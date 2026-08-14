#!/bin/bash
set -euo pipefail

# --- package installation ---
sudo pacman -S --needed --noconfirm \
  zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search \
  starship \
  ripgrep fzf bat eza zoxide fd lazygit neovim tmux stow github-cli \
  ttf-jetbrains-mono-nerd \
  jdk-openjdk maven dotnet-sdk-10.0 bun fnm \
  docker docker-compose \
  azure-cli
# --- end package installation ---

# --- stow ---
cd "$(dirname "${BASH_SOURCE[0]}")"
stow */
# --- end stow ---

# --- default shell ---
sudo chsh -s /usr/bin/zsh dfanso
# --- end default shell ---

# --- node + postman cli ---
eval "$(fnm env)"
fnm install --lts
fnm use lts-latest
fnm default lts-latest
npm install -g postman-cli
# --- end node + postman cli ---

# --- docker ---
sudo systemctl enable --now docker.service
sudo usermod -aG docker dfanso
# --- end docker ---

# --- github sync ---
# Run once per machine, then git push works without prompting:
#   gh auth login
#   gh auth setup-git
# --- end github sync ---
