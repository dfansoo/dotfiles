# Hyprland Dotfiles & Dev Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `~/dotfiles` on `arch-msi` (Arch Linux + Hyprland) into a GNU Stow-managed, Catppuccin Mocha-themed dev environment covering shell, terminal, status bar, launcher/notifications, editor, multiplexer, git, language runtimes, and containers — then push it to `dfansoo/dotfiles` on GitHub so a future reinstall is `git clone` + `./install.sh`.

**Architecture:** One git repo (`~/dotfiles`) with a top-level folder per tool ("stow package") mirroring `$HOME`. `install.sh` installs all pacman packages and runs `stow */` to symlink every package into place. Each task below both (a) writes/updates the relevant file(s) in the repo and appends the matching section to `install.sh`, and (b) applies the same change live on the running machine so it's verified working before moving on.

**Tech Stack:** Arch Linux, Hyprland 0.56 (Lua config), GNU Stow, zsh + starship, kitty, waybar, wofi, mako, Neovim, tmux, git, fnm (Node), jdk-openjdk + maven, dotnet-sdk-10.0, bun, docker, azure-cli, GitHub CLI (`gh`).

## Global Constraints

- All packages must come from the official Arch `extra` repo — no AUR helper (confirmed available: zsh, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, zsh-history-substring-search, starship, ripgrep, fzf, bat, eza, zoxide, fd, lazygit, neovim, tmux, stow, github-cli, ttf-jetbrains-mono-nerd, jdk-openjdk, maven, dotnet-sdk-10.0, bun, fnm, docker, docker-compose, azure-cli).
- Theme: Catppuccin Mocha everywhere, applied via hex codes directly (no GTK theming for Thunar — out of scope, would need AUR).
- Catppuccin Mocha palette: base `#1e1e2e`, mantle `#181825`, crust `#11111b`, text `#cdd6f4`, subtext0 `#a6adc8`, overlay0 `#6c7086`, surface0 `#313244`, surface1 `#45475a`, blue `#89b4fa`, lavender `#b4befe`, mauve `#cba6f7`, red `#f38ba8`, green `#a6e3a1`, yellow `#f9e2af`, peach `#fab387`, pink `#f5c2e7`.
- Repo: `dfansoo/dotfiles`, public, pushed via `gh` CLI auth (interactive device-code flow — requires the user to visit a URL and enter a code in a browser; this cannot be automated).
- Machine specifics already in place: user `dfanso`, hostname `arch-msi`, existing `~/.config/hypr/hyprland.lua` (Lua-syntax Hyprland config, NOT the classic `.conf` format), existing `/etc/greetd/config.toml` launching `start-hyprland`.
- All commands below are written as if run in a terminal on `arch-msi` directly (that's how a future reinstall will happen). This session executes them over the existing SSH connection to `dfanso@10.42.0.158`.

---

### Task 1: Repo scaffold + package installation

**Files:**
- Create: `~/dotfiles/install.sh`
- Create: `~/dotfiles/.gitignore`

**Interfaces:**
- Produces: `~/dotfiles` git repo (already `git init`'d with one commit containing the design spec) with `install.sh` — an idempotent, re-runnable bootstrap script. Every later task appends a new section to this file between markers `# --- <task name> ---` / `# --- end <task name> ---`, in the same order as this plan.

- [ ] **Step 1: Write the verification script (fails first)**

Create `/tmp/verify-task1.sh` on the machine:

```bash
#!/bin/bash
set -e
for bin in zsh starship rg fzf bat eza zoxide fd lazygit nvim tmux stow gh mvn dotnet bun fnm docker docker-compose az; do
  command -v "$bin" >/dev/null 2>&1 || { echo "MISSING: $bin"; exit 1; }
done
fc-list | grep -qi "JetBrainsMono Nerd Font" || { echo "MISSING: JetBrainsMono Nerd Font"; exit 1; }
echo "ALL PRESENT"
```

- [ ] **Step 2: Run it, confirm it fails**

Run: `chmod +x /tmp/verify-task1.sh && /tmp/verify-task1.sh`
Expected: prints `MISSING: <first missing binary>` and exits non-zero (none of these are installed yet except whatever pacstrap already pulled in).

- [ ] **Step 3: Write `install.sh`**

```bash
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
```

- [ ] **Step 4: Create `.gitignore`**

```
.DS_Store
```

- [ ] **Step 5: Run install.sh's package section, confirm verification passes**

Run: `chmod +x ~/dotfiles/install.sh && ~/dotfiles/install.sh && /tmp/verify-task1.sh`
Expected: pacman installs the full list, `stow */` runs against an otherwise-empty repo (no-op, no packages to stow yet besides nothing — safe), then `ALL PRESENT` printed.

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles
git add install.sh .gitignore
git commit -m "Add install.sh with full package list"
```

---

### Task 2: Zsh + plugins + starship prompt

**Files:**
- Create: `~/dotfiles/zsh/.zshrc`
- Create: `~/dotfiles/starship/.config/starship.toml`
- Modify: `~/dotfiles/install.sh` (append shell section)

**Interfaces:**
- Consumes: pacman packages from Task 1 (`zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`, `zsh-history-substring-search`, `starship`, `eza`, `bat`, `zoxide`, `fzf`).
- Produces: `dfanso`'s login shell is `zsh`; `starship` initialized in every interactive shell.

- [ ] **Step 1: Write `~/dotfiles/zsh/.zshrc`**

```bash
# ~/.zshrc

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
fpath+=(/usr/share/zsh/plugins/zsh-completions/src)

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

alias ls='eza --icons'
alias ll='eza -la --icons'
alias cat='bat'
alias vim='nvim'

eval "$(fnm env --use-on-cd)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

eval "$(starship init zsh)"
```

- [ ] **Step 2: Write `~/dotfiles/starship/.config/starship.toml`**

```toml
palette = "catppuccin_mocha"

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
mauve = "#cba6f7"
blue = "#89b4fa"
green = "#a6e3a1"
yellow = "#f9e2af"
red = "#f38ba8"
text = "#cdd6f4"
surface0 = "#313244"

format = """
[](fg:surface0)$os$username[](bg:surface0 fg:blue)$directory[](fg:blue bg:surface0)$git_branch$git_status[](fg:surface0)
$character"""

[directory]
style = "bg:surface0 fg:text"
format = "[ $path ]($style)"

[git_branch]
style = "bg:surface0 fg:mauve"
format = "[ $symbol$branch ]($style)"

[git_status]
style = "bg:surface0 fg:red"
format = "[$all_status$ahead_behind ]($style)"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"
```

- [ ] **Step 3: Append shell section to `~/dotfiles/install.sh`**

Insert after the `# --- end stow ---` line:

```bash

# --- default shell ---
sudo chsh -s /usr/bin/zsh dfanso
# --- end default shell ---
```

- [ ] **Step 4: Stow and change shell, verify**

Run:
```bash
cd ~/dotfiles && stow zsh starship
sudo chsh -s /usr/bin/zsh dfanso
getent passwd dfanso | cut -d: -f7
zsh -i -c 'echo SHELL_OK'
```
Expected: `getent` prints `/usr/bin/zsh`; `zsh -i -c` prints `SHELL_OK` with no error output (confirms `.zshrc` sources cleanly — a broken plugin path would error here).

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add zsh starship install.sh
git commit -m "Add zsh config with plugins and Catppuccin starship prompt"
```

---

### Task 3: Kitty terminal theme

**Files:**
- Create: `~/dotfiles/kitty/.config/kitty/kitty.conf`

**Interfaces:**
- Consumes: `ttf-jetbrains-mono-nerd` font from Task 1.
- Produces: kitty launched from Hyprland (`Super+Q`) picks up this theme automatically via the stowed symlink.

- [ ] **Step 1: Write `~/dotfiles/kitty/.config/kitty/kitty.conf`**

```
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
font_size        11.0

background            #1e1e2e
foreground            #cdd6f4
cursor                #f5e0dc
selection_background  #585b70

color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #cba6f7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #cba6f7
color14 #94e2d5
color15 #a6adc8

background_opacity   0.95
window_padding_width 8
confirm_os_window_close 0
```

- [ ] **Step 2: Stow and verify**

Run:
```bash
cd ~/dotfiles && stow kitty
readlink -f ~/.config/kitty/kitty.conf
kitty +kitten query_terminal 2>&1 | head -1 || true
grep -c '^color' ~/.config/kitty/kitty.conf
```
Expected: `readlink -f` resolves into `~/dotfiles/kitty/.config/kitty/kitty.conf` (confirms the symlink is live); `grep -c` prints `16` (all 16 ANSI colors present, confirming the file landed intact).

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add kitty
git commit -m "Add Catppuccin Mocha kitty theme"
```

---

### Task 4: Waybar theme

**Files:**
- Create: `~/dotfiles/waybar/.config/waybar/config.jsonc`
- Create: `~/dotfiles/waybar/.config/waybar/style.css`

**Interfaces:**
- Consumes: `waybar` already installed and autostarted via `~/.config/hypr/hyprland.lua`'s `hl.on("hyprland.start", ...)` block (set up in an earlier session, launches plain `waybar` with no args — will now pick up this config since it's the default path).

- [ ] **Step 1: Write `~/dotfiles/waybar/.config/waybar/config.jsonc`**

```jsonc
{
  "layer": "top",
  "position": "top",
  "height": 32,
  "modules-left": ["hyprland/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "network", "battery", "tray"],

  "hyprland/workspaces": {
    "format": "{icon}",
    "format-icons": { "default": "", "active": "" }
  },
  "clock": {
    "format": "{:%H:%M   %a %d %b}"
  },
  "pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": " muted",
    "format-icons": { "default": ["", "", ""] }
  },
  "network": {
    "format-wifi": " {signalStrength}%",
    "format-disconnected": "⚠ disconnected"
  },
  "battery": {
    "format": "{icon} {capacity}%",
    "format-icons": ["", "", "", "", ""]
  },
  "tray": {
    "spacing": 10
  }
}
```

- [ ] **Step 2: Write `~/dotfiles/waybar/.config/waybar/style.css`**

```css
* {
  font-family: "JetBrainsMono Nerd Font";
  font-size: 13px;
}

window#waybar {
  background-color: #1e1e2e;
  color: #cdd6f4;
}

#workspaces button {
  padding: 0 8px;
  color: #a6adc8;
}

#workspaces button.active {
  color: #89b4fa;
  background-color: #313244;
}

#clock, #pulseaudio, #network, #battery, #tray {
  padding: 0 10px;
  color: #cdd6f4;
}

#battery.warning {
  color: #f9e2af;
}

#battery.critical {
  color: #f38ba8;
}
```

- [ ] **Step 3: Stow and restart waybar to verify**

Run:
```bash
cd ~/dotfiles && stow waybar
pkill waybar
HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance') waybar >/tmp/waybar-test.log 2>&1 &
sleep 2
pgrep -x waybar && echo WAYBAR_RUNNING
grep -i error /tmp/waybar-test.log || echo NO_ERRORS
```
Expected: `WAYBAR_RUNNING` printed (process survived config load without crashing); `NO_ERRORS` printed (no parse errors in the log).

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles
git add waybar
git commit -m "Add Catppuccin Mocha waybar config"
```

---

### Task 5: Wofi + Mako theme

**Files:**
- Create: `~/dotfiles/wofi/.config/wofi/config`
- Create: `~/dotfiles/wofi/.config/wofi/style.css`
- Create: `~/dotfiles/mako/.config/mako/config`

**Interfaces:**
- Consumes: `wofi` and `mako` already installed (prior session); `mako` already autostarted via `hyprland.lua`.
- Produces: styled fallback launcher (`wofi --show drun`) and styled notifications.

- [ ] **Step 1: Write `~/dotfiles/wofi/.config/wofi/config`**

```
width=600
height=400
location=center
show=drun
prompt=Search...
allow_markup=true
insensitive=true
```

- [ ] **Step 2: Write `~/dotfiles/wofi/.config/wofi/style.css`**

```css
window {
  background-color: #1e1e2e;
  border: 2px solid #89b4fa;
  border-radius: 10px;
}

#input {
  background-color: #313244;
  color: #cdd6f4;
  border-radius: 6px;
  margin: 6px;
}

#entry:selected {
  background-color: #45475a;
}

#text {
  color: #cdd6f4;
}
```

- [ ] **Step 3: Write `~/dotfiles/mako/.config/mako/config`**

```
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#89b4fa
border-radius=8
border-size=2
padding=10
font=JetBrainsMono Nerd Font 11
default-timeout=5000

[urgency=high]
border-color=#f38ba8
```

- [ ] **Step 4: Stow and verify**

Run:
```bash
cd ~/dotfiles && stow wofi mako
pkill mako; mako >/tmp/mako-test.log 2>&1 & disown
sleep 1
pgrep -x mako && echo MAKO_RUNNING
notify-send "test" "dotfiles mako check" && echo NOTIFY_SENT
wofi --show drun --conf ~/.config/wofi/config --style ~/.config/wofi/style.css & sleep 1; pkill wofi; echo WOFI_LAUNCHED
```
Expected: `MAKO_RUNNING`, `NOTIFY_SENT`, and `WOFI_LAUNCHED` all print with no error output in between (confirms both configs parse and the binaries don't crash on load).

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add wofi mako
git commit -m "Add Catppuccin Mocha wofi and mako theme"
```

---

### Task 6: Hyprland Catppuccin decoration colors

**Files:**
- Modify: `~/dotfiles/hypr/.config/hypr/hyprland.lua` (new file in repo, copied from the machine's existing live config)

**Interfaces:**
- Consumes: the existing live `~/.config/hypr/hyprland.lua` (already has monitor/autostart/keybind sections from a prior session — this task only touches the `decoration.col` block and adds this file into the stow-managed repo for the first time).
- Produces: border colors matching Catppuccin Mocha; the file is now tracked and reinstallable.

- [ ] **Step 1: Copy the live config into the repo**

Run:
```bash
mkdir -p ~/dotfiles/hypr/.config/hypr
cp ~/.config/hypr/hyprland.lua ~/dotfiles/hypr/.config/hypr/hyprland.lua
```

- [ ] **Step 2: Edit the `general.col` block in `~/dotfiles/hypr/.config/hypr/hyprland.lua`**

Find:
```lua
        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
```

Replace with:
```lua
        col = {
            active_border   = { colors = {"rgba(89b4faee)", "rgba(cba6f7ee)"}, angle = 45 },
            inactive_border = "rgba(45475aaa)",
        },
```

- [ ] **Step 3: Remove the live file so stow can symlink over it, then stow**

Run:
```bash
rm ~/.config/hypr/hyprland.lua
cd ~/dotfiles && stow hypr
readlink -f ~/.config/hypr/hyprland.lua
```
Expected: `readlink -f` resolves into `~/dotfiles/hypr/.config/hypr/hyprland.lua`.

- [ ] **Step 4: Apply live and verify**

Run:
```bash
SIG=$(hyprctl instances -j | jq -r '.[0].instance')
HYPRLAND_INSTANCE_SIGNATURE=$SIG hyprctl eval 'hl.config({ general = { col = { active_border = { colors = {"rgba(89b4faee)", "rgba(cba6f7ee)"}, angle = 45 }, inactive_border = "rgba(45475aaa)" } } })'
```
Expected: prints `ok` (matches the "ok" response pattern already seen for successful `hyprctl eval` calls this session).

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add hypr
git commit -m "Track hyprland.lua in dotfiles, apply Catppuccin border colors"
```

---

### Task 7: Neovim config

**Files:**
- Create: `~/dotfiles/nvim/.config/nvim/init.lua`

**Interfaces:**
- Consumes: `neovim` package from Task 1.
- Produces: a working Neovim with sane defaults and a Catppuccin colorscheme, self-bootstrapping its own plugin manager on first launch (no separate install step needed).

- [ ] **Step 1: Write `~/dotfiles/nvim/.config/nvim/init.lua`**

```lua
vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 8
vim.opt.clipboard = "unnamedplus"

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
})

vim.keymap.set("n", "<leader>e", ":Ex<CR>")
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>q", ":q<CR>")
```

- [ ] **Step 2: Stow and verify headless load**

Run:
```bash
cd ~/dotfiles && stow nvim
nvim --headless "+colorscheme catppuccin" "+q" 2>&1
echo "EXIT_CODE:$?"
```
Expected: `lazy.nvim` clones on first run (may take a few seconds), then `EXIT_CODE:0` with no Lua error traceback printed above it.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add nvim
git commit -m "Add Neovim config with lazy.nvim and Catppuccin colorscheme"
```

---

### Task 8: Tmux + git config

**Files:**
- Create: `~/dotfiles/tmux/.tmux.conf`
- Create: `~/dotfiles/git/.gitconfig`

**Interfaces:**
- Consumes: `tmux` package from Task 1; `dfanso`'s intended git identity (name `dfanso`, email `leo@747.live` — same as used for the dotfiles repo's own commits so far).

- [ ] **Step 1: Write `~/dotfiles/tmux/.tmux.conf`**

```
set -g mouse on
set -g base-index 1
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -g status-position top

set -g status-style bg=#1e1e2e,fg=#cdd6f4
set -g window-status-current-style bg=#89b4fa,fg=#1e1e2e
set -g pane-border-style fg=#45475a
set -g pane-active-border-style fg=#89b4fa

bind | split-window -h
bind - split-window -v
unbind '"'
unbind %
```

- [ ] **Step 2: Write `~/dotfiles/git/.gitconfig`**

```ini
[user]
	name = dfanso
	email = leo@747.live
[init]
	defaultBranch = main
[pull]
	rebase = false
[core]
	editor = nvim
[alias]
	st = status
	co = checkout
	br = branch
	lg = log --oneline --graph --decorate
```

- [ ] **Step 3: Stow and verify**

Run:
```bash
cd ~/dotfiles && stow tmux git
tmux -f ~/.tmux.conf new-session -d -s verify-test
tmux list-sessions | grep verify-test && echo TMUX_OK
tmux kill-session -t verify-test
git config --get user.email
git config --get alias.lg
```
Expected: `TMUX_OK` printed; `git config --get user.email` prints `leo@747.live`; `git config --get alias.lg` prints the log alias (confirms both configs parse correctly).

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles
git add tmux git
git commit -m "Add tmux and git config"
```

---

### Task 9: Node via fnm + Postman CLI

**Files:**
- Modify: `~/dotfiles/zsh/.zshrc` (already has `fnm env` line from Task 2 — no change needed, this task just uses it)
- Modify: `~/dotfiles/install.sh` (append Node/Postman section)

**Interfaces:**
- Consumes: `fnm` package from Task 1; `fnm env --use-on-cd` already wired into `.zshrc` from Task 2.
- Produces: `node`, `npm`, and `postman` (Postman CLI) available in every new shell.

- [ ] **Step 1: Append Node/Postman section to `~/dotfiles/install.sh`**

Insert after the `# --- end default shell ---` block:

```bash

# --- node + postman cli ---
eval "$(fnm env)"
fnm install --lts
fnm use lts-latest
fnm default lts-latest
npm install -g postman-cli
# --- end node + postman cli ---
```

- [ ] **Step 2: Run it and verify**

Run:
```bash
eval "$(fnm env)"
fnm install --lts
fnm use lts-latest
fnm default lts-latest
node --version
npm --version
npm install -g postman-cli
postman --version
```
Expected: `node --version` prints a `v22.x` or later LTS version; `postman --version` prints a version string (confirms the npm-installed binary is on `PATH` and runs).

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add install.sh
git commit -m "Add Node (fnm) and Postman CLI to install.sh"
```

---

### Task 10: Docker service + group

**Files:**
- Modify: `~/dotfiles/install.sh` (append Docker section)

**Interfaces:**
- Consumes: `docker`, `docker-compose` packages from Task 1.
- Produces: `docker.service` running and enabled at boot; `dfanso` in the `docker` group (takes effect on next login).

- [ ] **Step 1: Append Docker section to `~/dotfiles/install.sh`**

Insert after `# --- end node + postman cli ---`:

```bash

# --- docker ---
sudo systemctl enable --now docker.service
sudo usermod -aG docker dfanso
# --- end docker ---
```

- [ ] **Step 2: Run it and verify**

Run:
```bash
sudo systemctl enable --now docker.service
sudo usermod -aG docker dfanso
systemctl is-active docker
groups dfanso
sudo docker run --rm hello-world
```
Expected: `systemctl is-active docker` prints `active`; `groups dfanso` includes `docker`; `hello-world` container prints its "Hello from Docker!" message (confirms the daemon actually runs containers, not just that the service is up). Note: `dfanso` needs to log out/in (or `newgrp docker`) before running `docker` without `sudo` in the current shell — this is expected and doesn't block verification since we used `sudo docker run` here.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add install.sh
git commit -m "Add Docker service enablement and group membership to install.sh"
```

---

### Task 11: GitHub auth + repo creation + push

**Files:**
- None created — this task only runs commands.

**Interfaces:**
- Consumes: `github-cli` (`gh`) from Task 1; the fully-built `~/dotfiles` repo from Tasks 1–10.
- Produces: `dfansoo/dotfiles` on GitHub (public), with `origin` pointing at it and all local commits pushed.

- [ ] **Step 1: Authenticate — requires the user**

Run: `gh auth login`

This is interactive: choose `GitHub.com` → `HTTPS` → `Login with a web browser`. It prints a one-time code and a URL — **the user needs to open that URL in any browser and enter the code**. Wait for `gh auth login` to report success before continuing.

- [ ] **Step 2: Verify auth**

Run: `gh auth status`
Expected: prints `Logged in to github.com as dfansoo`.

- [ ] **Step 3: Create the repo and push**

Run:
```bash
cd ~/dotfiles
git branch -M main
gh repo create dfansoo/dotfiles --public --source=. --remote=origin --push
```
Expected: prints the new repo URL, and `git log` on `origin/main` matches local `main`.

- [ ] **Step 4: Verify remote matches local**

Run:
```bash
git fetch origin
git log --oneline main
git log --oneline origin/main
```
Expected: both logs print the identical list of commits (Tasks 1 through 10, in order).

---

## Self-Review Notes

- **Spec coverage:** repo structure (Task 1), all packages (Task 1), theming for hypr/kitty/waybar/wofi/mako/starship/nvim/tmux (Tasks 2–8), fnm+Postman CLI (Task 9), Docker (Task 10), gh auth + push (Task 11) — every section of the design doc has a task.
- **No AUR helper used anywhere** — matches the confirmed-available package list from the design.
- **Type/name consistency:** `hl.eval`/`hyprctl eval` syntax in Task 6 matches the exact working pattern already used live on this machine this session (`hyprctl eval 'hl.config({...})'` returning `ok`); stow package names (`zsh`, `starship`, `kitty`, `waybar`, `wofi`, `mako`, `hypr`, `nvim`, `tmux`, `git`) match the folder names created in each task exactly.
