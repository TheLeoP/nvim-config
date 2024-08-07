# My Neovim configuration

## Requirements

- general
  - git
- coq_nvim
  - Python >= 3.8.2
  - pip
  - python venv
  - git symlinks
    - Windows: `git config --global core.symlinks true` (may require additional config)
    - [Workaround for when not available on Windows](https://github.com/ms-jpq/coq_nvim/issues/589#issuecomment-1651436348)
    - [Another (untested) workaround](https://github.com/ms-jpq/coq_nvim/issues/589#issuecomment-1980518977)
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
