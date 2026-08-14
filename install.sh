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
