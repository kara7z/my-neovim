# Neovim Config - CachyOS / Sway / LazyVim

Personal LazyVim configuration optimized for **CachyOS (Arch)** + **SwayFX** + **Kitty** with true black theme and Wayland clipboard.

## Features & Keymaps

| Key | Action |
|-----|--------|
| `Alt-j` / `Alt-k` | Move line down / up (normal/insert/visual, supports count `3Alt-j`, multi-line visual) |
| `Ctrl-z` | Undo |
| `Ctrl-Shift-z` / `Ctrl-r` | Redo (frees `Ctrl-y` for completion) |
| `Ctrl-d` | Add multicursor / find under (`q` skip, `Q` remove, `Ctrl-Shift-d` remove last) |
| `Tab` / `S-Tab` / `Enter` | `blink.cmp` next / prev / accept, `Ctrl-y` accept |
| `F2` | Snacks explorer (if enabled) |

**Language Support:** `clangd` (C/C++), `intelephense` (PHP/Laravel Blade), `vtsls`/`eslint` (TS/JS), `vue_ls`, `angularls`, `tailwindcss`, `jdtls` (Java), `json`, `yaml`, `lua`, `bash`, `docker`.

**UI:** `tokyonight night` true black `#000000` (`Normal`, `Float`, `Telescope`, `NeoTree`), `Visual` `#33467c` high contrast on black, `DiagnosticUnnecessary` subtle `#3b4261` italic for unused.

**Sway Integration:** `Alt` as main `$mod` (`set $mod Mod1`), `Focus` `Alt+Arrows` + `Alt+h/l`, `Move` `Alt+Shift+h/j/k/l+Arrows` keeps `Alt-j/k` free for nvim. `Super` (`Mod4`) for `browser`/`waypaper` to avoid conflict.

**Other:** `auto-save` 300ms debounced (no save during insert, immediate on `InsertLeave`/`BufLeave`/`FocusLost`), `wl-clipboard` (`wl-copy`/`wl-paste`) `unnamedplus`, `stylua`/`prettier`/`clang-format`/`pint` conditional.

## Prerequisites (CachyOS / Arch)

```sh
sudo pacman -S neovim git base-devel gcc clang ripgrep fd lazygit fzf curl wl-clipboard \
  nodejs npm python python-pip python-pynvim ruby luarocks tree-sitter lua51 \
  php composer jdk-openjdk

# Nerd Font (for icons)
sudo pacman -S ttf-firacode-nerd

# Optional but recommended for this config
sudo pacman -S kitty swayfx waybar wl-clipboard brightnessctl grim slurp

# Node provider for nvim
sudo npm install -g neovim
gem install neovim
pip install pynvim  # or: pipx install pynvim / pacman -S python-pynvim

# Verify
nvim --version  # >= 0.11.2
tree-sitter --version  # via npm: npm install -g tree-sitter-cli --allow-scripts
```

**Sway/Kity:** Ensure `kitty.conf` has `kitty_keyboard_mode 3` (already set) for distinct `Ctrl-Shift-z`.

## Installation on New PC

1. **Backup old config** (if any):
```sh
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

2. **Clone this config:**
```sh
git clone https://github.com/kara7z/my-neovim.git ~/.config/nvim
cd ~/.config/nvim
git checkout feat-Update  # or main, depending which branch you want
```

3. **First launch** (installs `lazy.nvim` + plugins):
```sh
nvim
# wait for Lazy to finish, press q to close, then restart
```

4. **Health checks:**
```sh
nvim --headless "+checkhealth" "+qa"
# Expected: lazy ✅, lazyvim ✅, vim.treesitter ✅, vim.provider ✅ (perl disabled), vim.pack ✅
:checkhealth
:Mason  # ensure clangd, intelephense, eslint-lsp, lua-language-server etc installed
:Lazy sync
```

5. **Sway** (if using SwayFX):
```sh
cp ~/.config/sway/config ~/.config/sway/config.bak  # backup
# already configured: $mod Mod1 (Alt), focus Alt+Arrows+Alt+h/l, move Alt+Shift+...
swaymsg reload
# test: open kitty -> nvim -> Alt-j/k should move line, Alt+Arrows should focus sway
```

6. **Project setup** (for JS/PHP/C++):
```sh
# C++: uses system clang-format 22.1.8 + .clangd in Cpp learning ( -Wunused-variable )
# JS: eslint.config.js + jsconfig.json (noUnusedLocals) already in Cpp learning
# PHP: intelephense for function-scope unused, php -l for syntax (no psalm needed)
```

## Useful Checks

```sh
# Format/style
stylua --check lua/

# Headless smoke test
nvim --headless -c "lua print('ok')" -c "qa"

# LSP
nvim Cpp\ learning/main.cpp  # :LspInfo should show clangd
nvim Cpp\ learning/index.php # :LspInfo should show intelephense
nvim Cpp\ learning/index.js  # :LspInfo should show eslint+vtsls, :lua vim.diagnostic.get(0) shows no-unused-vars
```

## Notes

- `Sway` `Alt` as `$mod` vs `nvim` `Alt-j/k`: Focus uses `Alt+Arrows` + `Alt+h/l` only, `Alt+j/k` passthrough to nvim. `Super` (`Mod4`) used for `browser`/`waypaper` to avoid `Alt+b` conflict with `splith`.
- `clipboard` uses `wl-copy`/`wl-paste` via `vim.g.clipboard`, `opt.clipboard=unnamedplus` with `UIEnter`/`VeryLazy` autocmd to survive `OSC52`.
- `true black` overrides `tokyonight` `on_colors` `bg #000000` and `on_highlights` for `Normal`, `Float`, `Telescope`, `Visual #33467c`.
- `auto-save` (`okuuva/auto-save.nvim` `1.0.0`) `debounce 300ms`, no save during insert (`TextChanged` only, `InsertLeave` immediate).
- `unused` diagnostics: `intelephense` `unusedSymbols` (function scope), `eslint` `no-unused-vars`, `clangd -Wunused-variable` (via `.clangd`), `selene` (lua), `DiagnosticUnnecessary` subtle `#3b4261` italic.
