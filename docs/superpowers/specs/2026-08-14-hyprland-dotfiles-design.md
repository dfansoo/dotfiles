# Hyprland Dotfiles & Dev Environment — Design

## Purpose

Turn this fresh Arch + Hyprland install (MSI GL65 Leopard, `arch-msi`) into a fully
customized daily-driver dev machine, with the whole setup captured in a git repo so a
future reinstall is `git clone` + `./install.sh` instead of redoing everything by hand.

## Repo structure (GNU Stow)

`~/dotfiles` mirrors `$HOME`, one top-level folder per "package":

```
~/dotfiles/
├── install.sh
├── zsh/.zshrc
├── starship/.config/starship.toml
├── hypr/.config/hypr/hyprland.lua
├── kitty/.config/kitty/kitty.conf
├── waybar/.config/waybar/{config.jsonc,style.css}
├── wofi/.config/wofi/{config,style.css}
├── mako/.config/mako/config
├── nvim/.config/nvim/init.lua
├── tmux/.tmux.conf
└── git/.gitconfig
```

`stow */` from the repo root symlinks every package into `$HOME` in one shot. Adding a
new tool later just means adding a new top-level folder and stowing it.

## Package list

All confirmed available in the official Arch `extra` repo — no AUR helper needed.

- **Shell**: `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`,
  `zsh-completions`, `zsh-history-substring-search` (sourced directly in `.zshrc`, no
  framework), `starship`
- **CLI toolkit**: `ripgrep`, `fzf`, `bat`, `eza`, `zoxide`, `fd`, `lazygit`, `neovim`,
  `tmux`, `stow`, `github-cli`
- **Fonts**: `ttf-jetbrains-mono-nerd`
- **Languages/runtimes**: `jdk-openjdk` + `maven` (Spring Boot projects),
  `dotnet-sdk-10.0` (game-provider), `bun` (kyc-frontend), `fnm` for Node version
  management
- **Containers**: `docker`, `docker-compose` (service enabled, `dfanso` added to
  `docker` group)
- **Cloud/API**: `azure-cli` (official package); Postman CLI via
  `npm install -g postman-cli` (not packaged for Arch)

## Theming — Catppuccin Mocha

Applied via hex codes directly in each tool's own config: Hyprland decoration colors,
Kitty, Waybar CSS, Wofi CSS, Mako, Starship (`catppuccin-powerline` preset), Neovim
colorscheme plugin.

**Known gap**: no GTK theming for Thunar (Catppuccin GTK theme isn't in official
repos, would need an AUR helper). Left default-themed for now; can be revisited if
wanted later.

## Bootstrap flow (`install.sh`)

1. `pacman -S` the full package list above
2. `chsh -s /usr/bin/zsh` for `dfanso`
3. `stow */` from the repo root
4. Install Node LTS via `fnm`
5. `npm install -g postman-cli`
6. Enable `docker.service`, add `dfanso` to the `docker` group
7. `gh auth login` — interactive step, requires visiting a URL and entering a
   device code in a browser

## Sync

Repo pushed to GitHub as `dfansoo/dotfiles` (public), once packages are installed,
configs are stowed, and the machine is confirmed working end-to-end.

## Out of scope / explicitly deferred

- GTK theming for Thunar (would need AUR)
- VS Code / any GUI IDE (Neovim is the terminal editor; can add later on request)
- Postman desktop GUI app (CLI only, per above)
