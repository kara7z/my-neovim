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

**UI:** Flexoki Dark with transparent editor/pickers/tabs, gold active tabs, brighter syntax accents, and visible error/warning diagnostics. Terminal transparency and blur are controlled separately by Kitty and your compositor.

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
- **JDK 25+ for current JDTLS**. This runs the Java language server; projects can still target Java 8/17/21. The config first checks `~/.local/share/nvim/jdtls-jdk/bin/java`, then compatible system JDKs and `JAVA_HOME`.

## Java completion

Type `enum`, `interface`, `record`, `abstract`, `annotation`, or `method` and select the **Snippet** completion for a full declaration. `Enter` accepts it; `Tab` / `Shift-Tab` move between fields. Records require a project targeting Java 16 or newer. `Ctrl-Space` opens completion manually.

`JavaProject` creates a simple or Maven project; `JavaClass User models` creates an importable `models.User` class in a simple project. `JavaClass Status enums` creates an enum. `F5` builds/runs the current file; `F6` runs Spring projects or opens the compiler menu.

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

- Use a terminal with the Kitty keyboard protocol for distinct `Ctrl-Shift-z`; Neovim negotiates this automatically with supported Kitty versions.
- `sway/config` uses `Alt` as `$mod` (`Mod1`), `Alt+Arrows` + `Alt+h/l` for focus, `Alt+Shift+...` for move to keep `Alt-j/k` free for nvim. `Super` for `browser` etc.
- After changing `sway/config`: `swaymsg reload`

## Useful Checks

```sh
stylua --check lua/
bash tests/run_all.sh
# Optional: also test a live Java language server (JDTLS and JDK 25+ required)
NVIM_TEST_JAVA_LSP=1 bash tests/run_all.sh
nvim --headless -c "lua print('ok')" -c "qa"
# LSP
nvim --headless "+checkhealth vim.lsp" "+qa"
```

The test runner checks syntax, formatting/linting when tools are installed, keymaps, plugin startup, transparency, Java snippets/scaffolding, task commands, and bounded Spring project detection. Failed checks return a nonzero exit status. It requires the plugins to be installed first; it does not run builds in your projects.

## Customization

See `lua/config/options.lua` for editor options, `lua/config/keymaps.lua` for keymaps, `lua/plugins/` for plugin overrides. `lazyvim.json` lists enabled `extras` (add/remove e.g. `lazyvim.plugins.extras.lang.python`).
