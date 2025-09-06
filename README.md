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
    sudo zypper in -y chezmoi curl tar gzip
    ```

* Ubuntu:
    ```bash
    BINDIR="${HOME}/.local/bin" sh -c "$(curl -fsLS get.chezmoi.io)"
    ```
---
Init command:

```bash
export PATH="${PATH}:${HOME}/.local/bin"
chezmoi init --apply foreignmeloman

# (Optional) Change the chezmoi git remote URL to SSH
chezmoi cd
git remote set-url origin git@github.com:foreignmeloman/dotfiles.git
```
