# My Neovim configuration

## Requirements

- general
  - git
- lazy.nvim
  - hererocks
    - Python 3.x
    - Windows: [MSVC in $PATH](https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support#msvc)
- fzf-lua
  - [rg](https://github.com/BurntSushi/ripgrep)
  - [fd](https://github.com/sharkdp/fd)
- nvim-treesitter
  - Windows: [MSVC in $PATH](https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support#msvc)
- mason.nvim
  - [pwsh](https://github.com/PowerShell/PowerShell)
  - [go](https://github.com/golang/go)
  - [node](https://github.com/nodejs/node)
  - Python 3.x
  - cargo
    - [rustup](https://rustup.rs/)
  - Java (open JDK)
- typescript-tools.nvim
  - Typescript `npm i -g typescript` (in particular `tsserver`)
  - The version of `tsserver` included with `ts_ls` on mason.nvim is outdated

## Notes

If using wezterm and artifacts are encountered while scrolling, [install the correct terminfo to fix them](https://github.com/wez/wezterm/issues/5750)
