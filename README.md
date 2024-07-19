# dotfiles

This repo uses [chezmoi](https://github.com/twpayne/chezmoi) to manage my dotfiles. Use [this](https://www.chezmoi.io/quick-start/#set-up-a-new-machine-with-a-single-command) gude to setup a new machine.

### Requirements

Tested on:
* openSUSE Tumbleweed
* Ubuntu 22.04

### Quick bootstrap

Install chezmoi:

```bash
BINDIR=$HOME/.local/bin sh -c "$(curl -fsLS get.chezmoi.io)"
```

Init command for the repo owner:

```bash
$HOME/.local/bin/chezmoi init --apply git@github.com:foreignmeloman/dotfiles.git
```

Init command for the guests:

```bash
$HOME/.local/bin/chezmoi init --apply foreignmeloman
```
