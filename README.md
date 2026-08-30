# Neovim Config

A fast and feature-rich [LazyVim](https://github.com/LazyVim/LazyVim) configuration.

## Features & Keymaps

| Key | Action |
|-----|--------|
| `Alt-j` / `Alt-k` | Move line down / up (normal/insert/visual, `3 Alt-j` moves 3 lines, visual moves block) |
| `Ctrl-z` | Undo |
| `Ctrl-y` / `Ctrl-Shift-z` / `Ctrl-r` | Redo |
| `Ctrl-d` | Multicursor - add cursor under word (`q` skip, `Q` remove, `Ctrl-Shift-d` remove last) |
| `Tab` / `S-Tab` / `Enter` | `blink.cmp` next / prev / accept |
| `F2` | Snacks explorer (if enabled) |
| `F8` / `Ctrl-/` | Toggle bottom terminal |

**Languages:** `C/C++` (`clangd`, `codelldb`), `PHP` (`intelephense`, `Blade`), `TypeScript`/`JavaScript` (`vtsls`, `eslint`), `Vue`, `Angular`, `Tailwind`, `Java` (`jdtls`), `Python`, `Lua`, `Bash`, `Docker`, `JSON`, `YAML`, `Markdown`.

**UI:** `tokyonight` `night` true black `#000000`, high contrast `Visual` `#33467c`, subtle `DiagnosticUnnecessary` for unused.

**Other:** `auto-save` (300ms, not during insert), system clipboard (`wl-clipboard` on Wayland, `unnamedplus` elsewhere), `stylua`/`prettier`/`clang-format`/`pint`.

## Prerequisites

### Arch Linux / CachyOS - Install all tools at once (first command)

```sh
sudo pacman -S neovim git base-devel gcc clang ripgrep fd lazygit fzf curl wl-clipboard \
  nodejs npm python python-pip python-pynvim ruby luarocks tree-sitter lua51 \
  php composer jdk-openjdk ttf-firacode-nerd kitty swayfx waybar wl-clipboard brightnessctl grim slurp

# Node/Python/Ruby providers
sudo npm install -g neovim
gem install neovim
pip install pynvim  # or: pipx install pynvim / pacman -S python-pynvim

# tree-sitter CLI
npm install -g tree-sitter-cli --allow-scripts
```

### General (any OS)

- **Git** - to clone and manage plugins
- **Neovim** `>= 0.11.2` - https://neovim.io
- **A Nerd Font** - for icons (e.g. `FiraCode Nerd Font`)
- **A C Compiler** (`gcc`/`clang`) - for `nvim-treesitter`
- **Ripgrep** (`rg`) - for search (`Telescope`/`Snacks.picker`)

*Optional but recommended:*

- `fd` - faster file finder
- `lazygit` - git UI
- `fzf` - fuzzy finder
- `wl-clipboard` - Wayland clipboard (Linux Wayland)
- `Node.js` `>= 18` - for `eslint`/`vtsls`/`tailwindcss`
- `Python` + `pynvim` - for Python provider
- `Ruby` - for Ruby provider
- `tree-sitter` CLI - `npm install -g tree-sitter-cli`

## Installation

1. **Backup old config** (if any):

   ```sh
   # Linux / macOS
   mv ~/.config/nvim ~/.config/nvim.bak
   mv ~/.local/share/nvim ~/.local/share/nvim.bak
   mv ~/.local/state/nvim ~/.local/state/nvim.bak
   mv ~/.cache/nvim ~/.cache/nvim.bak

   # Windows (PowerShell)
   Rename-Item -Path $env:LOCALAPPDATA\nvim -NewName nvim.bak -ErrorAction SilentlyContinue
   ```

2. **Clone this repo:**

   ```sh
   git clone https://github.com/kara7z/my-neovim.git ~/.config/nvim
   # Linux/macOS
   # Windows: git clone https://github.com/kara7z/my-neovim.git "$env:LOCALAPPDATA\nvim"
   ```

3. **Start Neovim** (first launch installs plugins):

   ```sh
   nvim
   # wait for Lazy to finish, press q, then restart
   ```

4. **Check health:**

   ```sh
   :checkhealth
   :Mason   # install missing LSP/formatters if needed
   :Lazy sync
   ```

## Sway / Wayland Notes (optional)

If you use `Sway`/`SwayFX` with `Kitty`:

- `kitty.conf` needs `kitty_keyboard_mode 3` for distinct `Ctrl-Shift-z` (already set)
- `sway/config` uses `Alt` as `$mod` (`Mod1`), `Alt+Arrows` + `Alt+h/l` for focus, `Alt+Shift+...` for move to keep `Alt-j/k` free for nvim. `Super` for `browser` etc.
- After changing `sway/config`: `swaymsg reload`

## Useful Checks

```sh
stylua --check lua/
nvim --headless -c "lua print('ok')" -c "qa"
# LSP
nvim --headless "+checkhealth vim.lsp" "+qa"
```

## Customization

See `lua/config/options.lua` for editor options, `lua/config/keymaps.lua` for keymaps, `lua/plugins/` for plugin overrides. `lazyvim.json` lists enabled `extras` (add/remove e.g. `lazyvim.plugins.extras.lang.python`).

