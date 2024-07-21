# dotfiles

This repo uses [chezmoi](https://github.com/twpayne/chezmoi) to manage my dotfiles. Use [this](https://www.chezmoi.io/quick-start/#set-up-a-new-machine-with-a-single-command) gude to setup a new machine.

### Requirements

Tested on:
* openSUSE Tumbleweed
* Ubuntu 22.04

### Quick bootstrap

Install chezmoi on Ubuntu:
```bash
BINDIR=$HOME/.local/bin sh -c "$(curl -fsLS get.chezmoi.io)"
```

Install chezmoi on Tumbleweed:
```bash
sudo zypper in -y chezmoi
```

Init command for the repo owner:

```bash
chezmoi init --apply git@github.com:foreignmeloman/dotfiles.git
```

Init command for the guests:

```bash
chezmoi init --apply foreignmeloman
```
