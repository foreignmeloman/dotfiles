# dotfiles

This repo uses unnecessarily overengineered combination of [chezmoi](https://github.com/twpayne/chezmoi) and [pyinfra](https://pyinfra.com/) to manage my dotfiles and system setup.

### Requirements

Tested on (including WSL):
* openSUSE Tumbleweed
* Ubuntu 22.04
* Ubuntu 24.04

### Quick bootstrap

Install chezmoi on:

* Tumbleweed:
    ```bash
    sudo zypper in -y chezmoi
    ```

* Ubuntu:
    ```bash
    BINDIR="${HOME}/.local/bin" sh -c "$(curl -fsLS get.chezmoi.io)"
    ```
---
Init command for:

* the repo owner:
    ```bash
    export PATH="${PATH}:${HOME}/.local/bin"
    chezmoi init --apply git@github.com:foreignmeloman/dotfiles.git
    ```

* the guests:
    ```bash
    export PATH="${PATH}:${HOME}/.local/bin"
    chezmoi init --apply foreignmeloman
    ```
